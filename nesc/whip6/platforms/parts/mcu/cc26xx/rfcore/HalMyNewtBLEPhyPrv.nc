/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */

#define __RFC_STRUCT
#include <stdio.h>
#include <driverlib/rf_common_cmd.h>
#include <driverlib/rf_ble_cmd.h>
#include <driverlib/rf_data_entry.h>
#include <driverlib/rf_mailbox.h>
#include <inc/hw_memmap.h>
#include <inc/hw_rfc_rat.h>
#include <Assert.h>
#include <MyNewtTimeTypes.h>
#include "RFCore.h"

#define BLE_PHY_ASSERT(cond) do { if (!(cond)) panic(); } while (0)
#define BLE_PHY_WARNPRINTF(...) printf("[BLEPhy] " __VA_ARGS__)
//#define BLE_PHY_DBGPRINTF(...) printf("[BLEPhy] " __VA_ARGS__)
#define BLE_PHY_DBGPRINTF(...)

extern void mynewt_glue_ble_phy_rx_adv_pkt(uint32_t start_cputime, int8_t rssi);
extern void mynewt_glue_ble_phy_adv_end(bool got_conn_req);

extern void mynewt_glue_ble_phy_conn_end(uint8_t new_conn_state,
        uint8_t anchor_valid, uint32_t anchor);
extern void mynewt_glue_ble_phy_tx_conn_pkt(void);
extern void mynewt_glue_ble_phy_rx_conn_pkt(uint32_t start_cputime, int8_t rssi);

module HalMyNewtBLEPhyPrv {
    provides interface Init @exactlyonce();
    uses interface RFCore @exactlyonce();
    uses interface RFCoreClaim @exactlyonce();
    uses interface AsyncCounter<TMyNewtCPUTime, uint32_t> as MyNewtCPUTime;
    uses interface Timer<TMilli, uint32_t> as WatchdogTimer;
}
implementation {
    typedef enum {
        STATE_UNCLAIMED,
        STATE_IDLE,
        STATE_ADV,
        STATE_ADV_RX,
        STATE_SLAVE,
    } state_t;

    state_t state = STATE_UNCLAIMED;

    enum {
        BLE_ADV_PDU_HDR_TYPE_MASK         = (0x0F),
        BLE_ADV_PDU_HDR_TXADD_MASK        = (0x40),
        BLE_ADV_PDU_HDR_RXADD_MASK        = (0x80),
        BLE_ADV_PDU_HDR_LEN_MASK          = (0x3F),
    };

    enum {
        BLE_ADV_PDU_TYPE_ADV_IND          = (0),
        BLE_ADV_PDU_TYPE_ADV_DIRECT_IND   = (1),
        BLE_ADV_PDU_TYPE_ADV_NONCONN_IND  = (2),
        BLE_ADV_PDU_TYPE_SCAN_REQ         = (3),
        BLE_ADV_PDU_TYPE_SCAN_RSP         = (4),
        BLE_ADV_PDU_TYPE_CONNECT_REQ      = (5),
        BLE_ADV_PDU_TYPE_ADV_SCAN_IND     = (6),
    };

    enum {
        NUM_RX_ENTRIES = 2,
        NUM_TX_ENTRIES = 2,
        WATCHDOG_TIME_MS = 100,

        // "The system CPU must take the setup time of the transmitter or
        // receiver into account when calculating the start time of the
        // operation."
        //      -- CC26xx Technical Reference Manual, sec. 23.6.4
        //
        // This is the time required for the calibration of the frequency
        // synthesizer.
        //
        // TODO: maybe measure and improve
        //SLAVE_SCHEDULING_DELAY_RAT = 1200,
        SLAVE_SCHEDULING_DELAY_RAT = 2400,

        SLAVE_STANDARD_RX_WINDOW_US = 20,

        // Timeout must take into account the preamble and sync word. This is
        // total 5 bytes as 1Mbps: 40us. Experimentally, 45us is not enough,
        // 90us works.
        SLAVE_TIMEOUT_RIGHT_MARGIN_US = 90,

        // Smaller timeouts hang the device and the watchdog triggers...
        SLAVE_MIN_TIMEOUT_RAT = 1096,
    };

    uint8_t m_channel;
    uint32_t m_access_addr;
    uint32_t m_crcinit;
    uint32_t m_start_time;
    bool m_start_time_valid;

    rfCoreHal_CMD_BLE_ADV_t __attribute__((aligned(4))) bleAdvCmd;
    rfCoreHal_bleAdvPar_t bleAdvParams;

    rfCoreHal_CMD_BLE_SLAVE_t __attribute__((aligned(4))) bleSlaveCmd;
    rfCoreHal_bleSlavePar_t bleSlaveParams;
    rfCoreHal_bleMasterSlaveOutput_t bleSlaveOutput;

    rfc_dataEntryPointer_t rxEntry[NUM_RX_ENTRIES];
    dataQueue_t rxQueue;
    uint8_t headRxEntry;
    uint8_t tailRxEntry;

    rfc_dataEntryPointer_t txEntry[NUM_TX_ENTRIES];
    dataQueue_t txQueue;
    uint8_t headTxEntry;

    static void initRXQueue();
    static void initTXQueue();
    static void initBLEAdvCmd();
    static void initBLESlaveCmd();

    command error_t Init.init() {
        initRXQueue();
        initTXQueue();
        initBLEAdvCmd();
        initBLESlaveCmd();
        return SUCCESS;
    }

    static void initRXQueue() {
        uint8_t i;

        rxQueue.pCurrEntry = NULL;
        rxQueue.pLastEntry = NULL;

        // Circular buffer.
        for (i = 0; i < NUM_RX_ENTRIES; i++) {
            rxEntry[i].config.type = DATA_ENTRY_TYPE_PTR;
            rxEntry[i].config.lenSz = 0;
            rxEntry[i].pData = NULL;
            rxEntry[i].status = DATA_ENTRY_STATUS_FINISHED;
            rxEntry[i].pNextEntry = NULL;
        }
    }

    static void initTXQueue() {
        uint8_t i;

        txQueue.pCurrEntry = NULL;
        txQueue.pLastEntry = NULL;

        for (i = 0; i < NUM_TX_ENTRIES; i++) {
            txEntry[i].config.type = DATA_ENTRY_TYPE_PTR;
            txEntry[i].config.lenSz = 0;
            txEntry[i].pData = NULL;
            txEntry[i].status = DATA_ENTRY_STATUS_FINISHED;
            txEntry[i].pNextEntry = NULL;
        }
    }

    static void initBLEAdvCmd() {
        rfCoreHal_CMD_BLE_ADV_t* cmd = &bleAdvCmd;
        rfCoreHal_bleAdvPar_t* params = &bleAdvParams;

        call RFCore.initRadioOp((rfc_radioOp_t*)cmd,
                sizeof(rfCoreHal_CMD_BLE_ADV_t), CMD_BLE_ADV);

        cmd->pParams = (uint8_t*)params;

        memset(params, 0x00, sizeof(rfCoreHal_bleAdvPar_t));

        /* Set up BLE Advertisement parameters */
        params->endTrigger.triggerType = TRIG_NEVER;
        params->endTime = 0;

        params->rxConfig.bAutoFlushCrcErr = 1;
        params->rxConfig.bAutoFlushIgnored = 1;
        params->rxConfig.bAutoFlushEmpty = 0;

        params->rxConfig.bIncludeLenByte = 1;
        params->rxConfig.bIncludeCrc = 0;
        params->rxConfig.bAppendRssi = 1;
        params->rxConfig.bAppendStatus = 0;
        params->rxConfig.bAppendTimestamp = 1;

        params->pRxQ = &rxQueue;
    }

    static void initBLESlaveCmd() {
        rfCoreHal_CMD_BLE_SLAVE_t* cmd = &bleSlaveCmd;
        rfCoreHal_bleSlavePar_t* params = &bleSlaveParams;

        call RFCore.initRadioOp((rfc_radioOp_t*)cmd,
                sizeof(rfCoreHal_CMD_BLE_SLAVE_t), CMD_BLE_SLAVE);

        cmd->pParams = (uint8_t*)params;
        cmd->pOutput = (uint8_t*)&bleSlaveOutput;

        memset(params, 0x00, sizeof(rfCoreHal_bleSlavePar_t));

        params->endTrigger.triggerType = TRIG_NEVER;
        params->endTime = 0;

        params->rxConfig.bAutoFlushCrcErr = 1;
        params->rxConfig.bAutoFlushIgnored = 1;
        params->rxConfig.bAutoFlushEmpty = 0;

        params->rxConfig.bIncludeLenByte = 1;
        params->rxConfig.bIncludeCrc = 0;
        params->rxConfig.bAppendRssi = 1;
        params->rxConfig.bAppendStatus = 0;
        params->rxConfig.bAppendTimestamp = 1;

        params->pRxQ = &rxQueue;
        params->pTxQ = &txQueue;
    }

    void mynewt_glue_ble_phy_clear_rx_bufs(void) @C() @spontaneous() {
        uint8_t i;
        for (i = 0; i < NUM_RX_ENTRIES; i++) {
            rxEntry[i].pData = NULL;
            rxEntry[i].length = 0;
            rxEntry[i].status = DATA_ENTRY_STATUS_FINISHED;
        }
        rxQueue.pCurrEntry = rxQueue.pLastEntry = NULL;
        tailRxEntry = 0;
        headRxEntry = 0;
    }

    int mynewt_glue_ble_phy_add_rx_buf(uint8_t* buf, uint16_t len) @C() @spontaneous() {
        rfc_CMD_ADD_DATA_ENTRY_t cmd __attribute__((aligned(4)));
        uint32_t cmd_status;
        rfc_dataEntryPointer_t* entry;

        //BLE_PHY_DBGPRINTF("rxbuf 0x%08x %d\r\n", buf, len);

        entry = &rxEntry[headRxEntry];
        if (entry->status != DATA_ENTRY_STATUS_FINISHED) {
            BLE_PHY_WARNPRINTF("rx queue ovfl\r\n");
            return 1;
        }
        headRxEntry = (headRxEntry + 1) % NUM_RX_ENTRIES;
        entry->pData = buf;
        entry->length = len;
        entry->pNextEntry = NULL;
        entry->status = DATA_ENTRY_STATUS_PENDING;

        /* See comment in mynewt_glue_ble_phy_add_tx_buf. */

        if (state == STATE_UNCLAIMED) {
            rfc_dataEntryPointer_t* last
                = (rfc_dataEntryPointer_t*)rxQueue.pLastEntry;
            if (last != NULL) {
                last->pNextEntry = (uint8_t*)entry;
            }
            rxQueue.pLastEntry = (uint8_t*)entry;
            if (rxQueue.pCurrEntry == NULL) {
                rxQueue.pCurrEntry = (uint8_t*)entry;
            }
        } else {
            memset(&cmd, 0, sizeof(cmd));
            cmd.commandNo = CMD_ADD_DATA_ENTRY;
            cmd.pQueue = &rxQueue;
            cmd.pEntry = (uint8_t*)entry;

            if (!call RFCore.sendCmd((uint32_t)&cmd, &cmd_status, FALSE)) {
                BLE_PHY_WARNPRINTF("add_rx_buf: CMDSTA=0x%08lx pQueue=0x%08lx, "
                        "pEntry=0x%08x, buf=0x%lx, len=%d, "
                        "pLastEntry=0x%08lx\n",
                        cmd_status, &rxQueue, entry, buf, (int)len,
                        rxQueue.pLastEntry);
                return 1;
            } else {
                //BLE_PHY_DBGPRINTF("add_rx_buf: OK, buf=0x%08lx, len=%d\n",
                //        buf, (int)len);
            }
        }

        return 0;
    }

    void mynewt_glue_ble_phy_clear_tx_bufs(void) @C() @spontaneous() {
        uint8_t i;
        for (i = 0; i < NUM_TX_ENTRIES; i++) {
            txEntry[i].pData = NULL;
            txEntry[i].length = 0;
            txEntry[i].status = DATA_ENTRY_STATUS_FINISHED;
        }
        txQueue.pCurrEntry = txQueue.pLastEntry = NULL;
        headTxEntry = 0;
    }

    int mynewt_glue_ble_phy_add_tx_buf(uint8_t* buf, uint16_t len) @C() @spontaneous() {
        rfc_CMD_ADD_DATA_ENTRY_t cmd __attribute__((aligned(4)));
        uint32_t cmd_status;
        rfc_dataEntryPointer_t* entry;

        //BLE_PHY_DBGPRINTF("txbuf 0x%08x %d\r\n", buf, len);

        entry = &txEntry[headTxEntry];
        if (entry->status != DATA_ENTRY_STATUS_FINISHED) {
            BLE_PHY_WARNPRINTF("queue ovfl\r\n");
            return 1;
        }
        headTxEntry = (headTxEntry + 1) % NUM_TX_ENTRIES;
        entry->pData = buf;
        entry->length = len;
        entry->pNextEntry = NULL;
        entry->status = DATA_ENTRY_STATUS_PENDING;

        /* Another story: so there's a nice description, how the hell the MD
         * (More Data) bit is wonderfully automatically kurwa generated in the
         * datasheet. This is bullshit. It works somehow differently and it
         * actually very much matters what's in the buffer. Therefore we set
         * the MD bit here and now it's fine.
         *
         * TODO: If we want certification, which we won't want, then verify that
         *       MD is not set on the air for too many packets. */
        buf[0] |= 0x10;

        /* Ok, so here's the story:
         *
         * First, we tried to set the queue fields by hand and having a cyclic
         * queue with entry->pNextEntry. But then in rare cases we ended up
         * with txQueue.pLastEntry being NULL (and txQueue.pCurrEntry not),
         * which could not be done by our code, but by the radio and this
         * is not described in the datasheet.
         *
         * So, to be sure, we let the radio itself manage the queue if it is
         * active.
         */
        if (state == STATE_UNCLAIMED) {
            rfc_dataEntryPointer_t* last
                = (rfc_dataEntryPointer_t*)txQueue.pLastEntry;
            if (last != NULL) {
                last->pNextEntry = (uint8_t*)entry;
            }
            txQueue.pLastEntry = (uint8_t*)entry;
            if (txQueue.pCurrEntry == NULL) {
                txQueue.pCurrEntry = (uint8_t*)entry;
            }
        } else {
            memset(&cmd, 0, sizeof(cmd));
            cmd.commandNo = CMD_ADD_DATA_ENTRY;
            cmd.pQueue = &txQueue;
            cmd.pEntry = (uint8_t*)entry;

            if (!call RFCore.sendCmd((uint32_t)&cmd, &cmd_status, FALSE)) {
                BLE_PHY_WARNPRINTF("add_tx_buf: CMDSTA=0x%08lx pQueue=0x%08lx, "
                        "pEntry=0x%08x, buf=0x%lx, len=%d, "
                        "pLastEntry=0x%08lx\n",
                        cmd_status, &txQueue, entry, buf, (int)len,
                        txQueue.pLastEntry);
                return 1;
            } else {
                //BLE_PHY_DBGPRINTF("add_tx_buf: OK, buf=0x%08lx, len=%d\n",
                //        buf, (int)len);
            }
        }

        return 0;
    }

    static error_t claim(state_t s) {
        error_t ret = SUCCESS;
        if (state == STATE_UNCLAIMED) {
            ret = call RFCoreClaim.claim();
        } else if (state != STATE_IDLE) {
            BLE_PHY_WARNPRINTF("claim when not idle\r\n");
            ret = EBUSY;
        }
        if (ret == SUCCESS) {
            state = s;
        }
        return ret;
    }

    task void release() {
        if (state == STATE_IDLE) {
            call RFCoreClaim.release();
            state = STATE_UNCLAIMED;
        }
    }

    void startWatchdog() {
        call WatchdogTimer.startWithTimeoutFromNow(WATCHDOG_TIME_MS);
    }

    void stopWatchdog() {
        call WatchdogTimer.stop();
    }

    void mynewt_glue_ble_phy_init(void) @C() @spontaneous() {
        /* do nothing */
    }

    int32_t ratdelta2cputimedelta(int32_t d) {
        return d / 4;
    }

    int32_t cputimedelta2ratdelta(int32_t d) {
        return d * 4;
    }

    uint32_t us2ratdelta(uint32_t us) {
        return us * 4;
    }

    uint32_t getRAT(void) {
        return HWREG(RFC_RAT_BASE + RFC_RAT_O_RATCNT);
    }

    static uint32_t rat2cputime(uint32_t rat_time) {
        uint32_t rat_now, cputime;
        atomic {
            rat_now = getRAT();
            cputime = call MyNewtCPUTime.getNow();
        }
        cputime -= ratdelta2cputimedelta(rat_now - rat_time);
        return cputime;
    }

    static void schedule_op(rfc_radioOp_t* op) {
        if (m_start_time_valid) {
            atomic {
                int32_t cpudelta = m_start_time - call MyNewtCPUTime.getNow();
                m_start_time = getRAT() + cputimedelta2ratdelta(cpudelta);
            }
            op->startTime = m_start_time;
            op->startTrigger.triggerType = TRIG_ABSTIME;
            m_start_time_valid = FALSE;
        } else {
            op->startTrigger.triggerType = TRIG_NOW;
        }
    }

    void mynewt_glue_ble_phy_set_start_time(uint32_t cputime) @C() @spontaneous() {
        m_start_time = cputime;
        m_start_time_valid = TRUE;
    }

    int mynewt_glue_ble_phy_tx_adv(uint8_t pdu_type, uint8_t* address,
            uint8_t* adv_data, uint8_t adv_data_len, uint8_t* scan_rsp_data,
            uint8_t scan_rsp_len)
            @C() @spontaneous() {
        uint32_t cmd_status;
        rfCoreHal_CMD_BLE_ADV_t* cmd = &bleAdvCmd;
        rfCoreHal_bleAdvPar_t* params = &bleAdvParams;

        if (claim(STATE_ADV) != SUCCESS) {
            return 1;
        }

        switch (pdu_type & BLE_ADV_PDU_HDR_TYPE_MASK) {
            case BLE_ADV_PDU_TYPE_ADV_IND:
                cmd->commandNo = CMD_BLE_ADV;
                break;
            case BLE_ADV_PDU_TYPE_ADV_DIRECT_IND:
                cmd->commandNo = CMD_BLE_ADV_DIR;
                break;
            case BLE_ADV_PDU_TYPE_ADV_NONCONN_IND:
                cmd->commandNo = CMD_BLE_ADV_NC;
                break;
            case BLE_ADV_PDU_TYPE_ADV_SCAN_IND:
                cmd->commandNo = CMD_BLE_ADV_SCAN;
                break;
            default:
                panic("Invalid advertisement PDU type");
        }

        schedule_op((rfc_radioOp_t*)cmd);

        cmd->channel = m_channel;
        params->pDeviceAddress = (uint16_t*)address;
        params->advConfig.deviceAddrType =
            !!(pdu_type & BLE_ADV_PDU_HDR_TXADD_MASK);
        params->advConfig.peerAddrType =
            !!(pdu_type & BLE_ADV_PDU_HDR_RXADD_MASK);
        params->pAdvData = adv_data;
        params->advLen = adv_data_len;
        params->pScanRspData = scan_rsp_data;
        params->scanRspLen = scan_rsp_len;

        // TODO: support filter policy

        if (!call RFCore.sendCmd((uint32_t)cmd, &cmd_status, TRUE)) {
            BLE_PHY_WARNPRINTF("tx_adv: CMDSTA=0x%08lx, status=0x%04x\n",
                   cmd_status, cmd->status);
            state = STATE_IDLE;
            post release();
            return 1;
        }

        startWatchdog();
        BLE_PHY_DBGPRINTF("tx_adv\r\n");

        return 0;
    }

    int mynewt_glue_ble_phy_tx_conn(uint8_t conn_state,
            uint32_t timeout_cputime, uint32_t window_widening_us,
            bool transmit_window) @C() @spontaneous() {
        uint32_t cmd_status;
        rfCoreHal_CMD_BLE_SLAVE_t* cmd = &bleSlaveCmd;
        rfCoreHal_bleSlavePar_t* params = &bleSlaveParams;

        if (claim(STATE_SLAVE) != SUCCESS) {
            return 1;
        }

        //m_start_time_valid = FALSE;
        //timeout_cputime = 0;

        if (!m_start_time_valid) {
            panic("Slave transasction without scheduling");
        }

        cmd->channel = m_channel;
        params->accessAddress = m_access_addr;
        params->crcInit = m_crcinit;
        if (conn_state == 0) {
            conn_state = 0x0b;
        } else {
            conn_state = ~conn_state;
        }
        memcpy(&params->seqStat, &conn_state, 1);

        schedule_op((rfc_radioOp_t*)cmd);
        cmd->startTime -= SLAVE_SCHEDULING_DELAY_RAT +
            us2ratdelta(window_widening_us) +
            us2ratdelta(SLAVE_STANDARD_RX_WINDOW_US);

        params->endTrigger.triggerType = TRIG_ABSTIME;
        params->endTime = m_start_time
            + cputimedelta2ratdelta(timeout_cputime);

        // Well, that's a stupidity in the CC26xxWare-provided headers,
        // where the timeoutTrigger.triggerType is not present, and the
        // place where it should be is occupied by the highest byte of
        // crcInit...
        if (!transmit_window) {
            params->crcInit |= TRIG_ABSTIME << 24;
            params->timeoutTime = m_start_time
                + us2ratdelta(SLAVE_STANDARD_RX_WINDOW_US)
                + us2ratdelta(window_widening_us)
                + us2ratdelta(SLAVE_TIMEOUT_RIGHT_MARGIN_US);
        } else {
            params->crcInit |= TRIG_NEVER << 24;
            params->timeoutTime = params->endTime;
        }
        if (params->timeoutTime - cmd->startTime < SLAVE_MIN_TIMEOUT_RAT) {
            params->timeoutTime = cmd->startTime + SLAVE_MIN_TIMEOUT_RAT;
        }

        // TODO(accek): master mode?

        if (!call RFCore.sendCmd((uint32_t)cmd, &cmd_status, TRUE)) {
            BLE_PHY_WARNPRINTF("tx_conn: CMDSTA=0x%08lx, status=0x%04x\n",
                   cmd_status, cmd->status);
            state = STATE_IDLE;
            post release();
            return 1;
        }

        startWatchdog();
        BLE_PHY_DBGPRINTF("tx_conn ch=%d conn_state=0x%02x status=0x%02x "
                "currE=0x%08x lastE=0x%08x anchor=%lu to=%d ww=%d srel=%d "
                "trel=%d erel=%d\r\n",
                m_channel, conn_state, cmd->status,
                txQueue.pCurrEntry, txQueue.pLastEntry,
                m_start_time, timeout_cputime, window_widening_us,
                cmd->startTime - m_start_time,
                params->timeoutTime - m_start_time,
                params->endTime - m_start_time);

        return 0;
    }

    int mynewt_glue_ble_phy_txpwr_set(int dbm) @C() @spontaneous() {
        // TODO(accek)
        return dbm;
    }

    void mynewt_glue_ble_phy_setchan(int chan, uint32_t access_addr, uint32_t crcinit) @C() @spontaneous() {
        m_channel = chan;
        m_access_addr = access_addr;
        m_crcinit = crcinit;
    }

    void abortOp(void) {
        uint32_t cmd_status;
        if (!call RFCore.sendCmd(CMDR_DIR_CMD(CMD_ABORT), &cmd_status, FALSE)) {
            BLE_PHY_WARNPRINTF("CMD_ABORT status=0x%08lx\n", cmd_status);
        }
    }

    void mynewt_glue_ble_phy_disable(void) @C() @spontaneous() {
        if (state <= STATE_IDLE) {
            return;
        }
        //BLE_PHY_DBGPRINTF("off advStatus=0x%04x connStatus=0x%04x\r\n",
        //        bleAdvCmd.status, bleSlaveCmd.status);
        abortOp();
        state = STATE_IDLE;
        post release();
    }

    uint8_t mynewt_glue_ble_phy_xcvr_state_get(void) @C() @spontaneous() {
        return state;
    }

    static void onDone(void) {
        uint16_t status;
        uint8_t seq_stat;
        bool timestamp_valid;
        uint32_t timestamp;
        switch (state) {
            case STATE_ADV:
            case STATE_ADV_RX:
                /* ADV does not use the TX queue, so no TXDone interrupt is
                 * generated. */
                status = bleAdvCmd.status;
                BLE_PHY_DBGPRINTF("adv/done: status=0x%04x\r\n", status);
                mynewt_glue_ble_phy_adv_end(
                        status == RF_CORE_RADIO_OP_STATUS_BLE_DONE_CONNECT);
                break;
            case STATE_SLAVE:
                status = bleSlaveCmd.status;
                timestamp_valid = bleSlaveOutput.pktStatus.bTimeStampValid
                    && (status == RF_CORE_RADIO_OP_STATUS_BLE_DONE_OK
                        || status == RF_CORE_RADIO_OP_STATUS_BLE_DONE_NOSYNC
                        || status == RF_CORE_RADIO_OP_STATUS_BLE_DONE_ENDED);
                timestamp = rat2cputime(bleSlaveOutput.timeStamp);
                BLE_PHY_DBGPRINTF("slave/done: 0x%04x nTx=%d nTxDone=%d "
                        "nTxRetx=%d nRxBufFull=%d ts=%lu tsrat=%lu danchor=%d\r\n",
                        status, bleSlaveOutput.nTx,
                        bleSlaveOutput.nTxEntryDone, bleSlaveOutput.nTxRetrans,
                        bleSlaveOutput.nRxBufFull,
                        timestamp_valid ? timestamp : 0,
                        bleSlaveOutput.timeStamp,
                        bleSlaveOutput.timeStamp - m_start_time);
                memcpy(&seq_stat, &bleSlaveParams.seqStat, 1);
                seq_stat = ~seq_stat;
                mynewt_glue_ble_phy_conn_end(seq_stat, timestamp_valid,
                        timestamp);
                break;
            default:
                /* do nothing */
        }
        stopWatchdog();
        state = STATE_IDLE;
        post release();
    }

    async event void RFCoreClaim.onLastCommandDone() {
        onDone();
    }

    async event void RFCoreClaim.onTXPkt() {
        //BLE_PHY_DBGPRINTF("txpkt\r\n");
        switch (state) {
            case STATE_ADV:
                state = STATE_ADV_RX;
                break;
            default:
                /* do nothing */
        }
    }

    async event void RFCoreClaim.onTXDone() {
        //BLE_PHY_DBGPRINTF("txdone\r\n");
        switch (state) {
            case STATE_ADV:
            case STATE_ADV_RX:
                break;
            case STATE_SLAVE:
                mynewt_glue_ble_phy_tx_conn_pkt();
                break;
            default:
                BLE_PHY_DBGPRINTF("txdone in state %d\r\n", state);
                /* do nothing */
        }
    }

    async event void RFCoreClaim.onRXDone() {
        rfc_dataEntryPointer_t* e = &rxEntry[tailRxEntry];
        uint8_t* buf = e->pData;
        uint8_t* footer;
        int8_t rssi;
        uint32_t timestamp;
        //int i;

        footer = buf + (buf[1] & BLE_ADV_PDU_HDR_LEN_MASK) + 2;
        rssi = *(footer++);
        memcpy(&timestamp, footer, 4);
        timestamp = rat2cputime(timestamp);

        switch (state) {
            case STATE_ADV:
            case STATE_ADV_RX:
                //BLE_PHY_DBGPRINTF("rx 0x%02x %d\r\n", buf[0], cputime);
                mynewt_glue_ble_phy_rx_adv_pkt(timestamp, rssi);
                tailRxEntry = (tailRxEntry + 1) % NUM_RX_ENTRIES;
                break;
            case STATE_SLAVE:
                //BLE_PHY_DBGPRINTF("RXDone: rssi=%d ts=%d now=%d\r\n", (int)rssi,
                //        timestamp, rat_now);
                mynewt_glue_ble_phy_rx_conn_pkt(timestamp, rssi);
                tailRxEntry = (tailRxEntry + 1) % NUM_RX_ENTRIES;
                break;
            default:
                e->status = DATA_ENTRY_STATUS_PENDING;
                return;
        }

        //BLE_PHY_DBGPRINTF("rxdone %d\r\n", cputime);
    }

    event void WatchdogTimer.fired() {
        atomic {
            if (state > STATE_IDLE) {
                BLE_PHY_WARNPRINTF("watchdog timeout\r\n");
                abortOp();
                onDone();
                post release();
            }
        }
    }

    async event void RFCore.onLastFGCommandDone() { }
    async event void RFCore.onLastCommandDone() { }
    async event void RFCore.onRXDone() { }
    async event void RFCore.onTXDone() { }
    async event void RFCore.onTXPkt() { }
    event void RFCore.fatalError(const char* message) { }
}
