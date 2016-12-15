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
#include <inc/hw_memmap.h>
#include <inc/hw_fcfg1.h>
#include <driverlib/rf_common_cmd.h>
#include <driverlib/rf_ble_cmd.h>
#include <driverlib/rf_data_entry.h>
#include <driverlib/rf_mailbox.h>
#include "ieee_cmd.h"
#include "RFCore.h"

// The stupid CC26xxware radio header (rf_mailbox.h) defines these
// clashing constants...
#undef IDLE
#undef PENDING
#undef ACTIVE
#undef SKIPPED

#include <Assert.h>
#include <BLEAddress.h>
#include <RawRSSI.h>

#ifndef CC26XX_DEFAULT_CHANNEL
#define CC26XX_DEFAULT_CHANNEL 11
#endif

#define RADIO_ASSERT(cond) do { if (!(cond)) panic(); } while (0)
#define RADIO_WARNPRINTF(...) printf(__VA_ARGS__)
//#define RADIO_DBGPRINTF(...) printf(__VA_ARGS__)
#define RADIO_DBGPRINTF(...)

module RFCoreRadioPrv {
    provides interface Init @atleastonce();

    provides interface RawFrame;
    provides interface RawFrameSender;
    provides interface RawFrameReceiver;
    provides interface RawFrameRSSI;
    provides interface RawFrameLQI;
    provides interface RawFrameCRC;
    provides interface RawFrameTimestamp<T32khz>;
    provides interface RawRSSI;
    provides interface CoreRadioReceivingNow;
    provides interface CoreRadioSimpleAutoACK;
    provides interface CoreRadioCRCFiltering;
    provides interface RawBLEAdvertiser;
    provides interface RawBLEScanner;
    provides interface RFCoreClaim as ClaimIEEE;
    provides interface RFCoreClaim as ClaimBLE;

    uses interface Init as InitAfterRadio;

    uses interface RFCore @exactlyonce();
    uses interface RFCoreXOSC @exactlyonce();

    uses interface BLEAddressProvider @atmostonce();

    uses interface Timer<TMilli, uint32_t> as TXWatchdogTimer @atmostonce();
    uses interface Timer<TMilli, uint32_t> as BLEAdvWatchdogTimer @atmostonce();

    uses interface BusyWait<TMicro, uint16_t> @exactlyonce();
    uses interface AskBeforeSleep @exactlyonce();

    uses interface Led as RadioOnLed;

    uses interface AsyncStatsIncrementer<uint8_t> as NumRadioInterruptsStat;
    uses interface AsyncStatsIncrementer<uint8_t> as NumErrorInterruptsStat;
    uses interface StatsIncrementer<uint8_t> as NumSuccessfulRXStat;
    uses interface StatsIncrementer<uint8_t> as NumSuccessfulTXStat;
    uses interface StatsIncrementer<uint8_t> as NumSuccessfulBLEAdvTXStat;
    uses interface StatsIncrementer<uint8_t> as NumLengthErrorsStat;
    uses interface StatsIncrementer<uint8_t> as NumCRCErrorsStat;
    uses interface StatsIncrementer<uint8_t> as NumTXTimeoutErrorsStat;
    uses interface StatsIncrementer<uint8_t> as NumBLEAdvTimeoutErrorsStat;
}

implementation {
    // So the radio supports the notion of having two commands running
    // simultaneously: one in the foreground and one in the background.
    // This is for IEEE 802.15.4 only. To mimic this, we have two states,
    // one determining the background (and overall) state of the radio,
    // and the other one specifying the currently running foreground
    // command.
    //
    // See the datasheet for more info:
    //
    //  CC13xx, CC26xx SimpleLink Wireless MCU Technical Reference Manual
    //  23.5.4 Radio Operation Commands

    typedef enum {
        STATE_UNINITIALIZED,

        STATE_OFF,            // The radio is powered off.

        STATE_UNCONFIGURED,   // On, but not configured for any mode yet,
                              // or a reconfiguration is needed. No command
                              // active.


        STATE_IEEE_IDLE,      // Configured for IEEE 802.15.4, but no RX.

        STATE_IEEE_RX,        // RX active in background.
        STATE_IEEE_RX_FOR_TX,

        STATE_IEEE_RX_DONE,   // Set by the interrupt when posting RXDone.

        STATE_IEEE_RX_LATE_CANCEL,
                              // Receiving was cancelled after the interrupt
                              // had been handled and the RXDone task
                              // is pending.

        STATE_IEEE_RX_END,    // When the receivingFinished handler is running.

        STATE_IEEE_TX_CAL,    // An FS calibration for TX is the current
                              // background operation.

        STATE_IEEE_TX_CAL_DONE,
                              // An FS calibration for TX finished recently.

        STATE_IEEE_CLAIMED,   // Claimed by external code (RFCoreClaim
                              // interface)


        STATE_BLE_IDLE,       // Configured for BLE, no operation.

        STATE_BLE_ADV,        // Configured for BLE and sending and
                              // advertisement.

        STATE_BLE_ADV_DONE,   // Like STATE_IEEE_RX_DONE.

        STATE_BLE_ADV_END,    // When the advertisementSent handler is running.
        STATE_BLE_SCANNER,
        STATE_BLE_SCANNER_FAILED,
                              // When starting the scanned failed, until
                              // scanning request is stopped.
        STATE_BLE_CLAIMED,    // Claimed by external code (RFCoreClaim
                              // interface)
    } state_t;

    typedef enum {
        FG_STATE_NONE,
        FG_STATE_IEEE_TX,
        FG_STATE_IEEE_TX_DONE,        // Set by the interrupt when queueing the task.
        FG_STATE_IEEE_TX_LATE_CANCEL, // Sending was cancelled after the interrupt.
        FG_STATE_IEEE_TX_END,         // When the sendingFinished handler is running.
    } fgState_t;

    typedef enum {
        MODE_NONE,
        MODE_UNCONFIGURED,
        MODE_IEEE,
        MODE_BLE,
    } mode_t;

    enum {
        // Maximum length of the data part of the frame. 128 - 1 byte length
        // field - 2 bytes FCS.
        MAX_FRAME_LENGTH = 125,

        CHANNEL_MIN = 11,
        CHANNEL_MAX = 26,

        // IEEE 802.15.4-2006 channel - valid range: [11, 26]
        CHANNEL_NR = CC26XX_DEFAULT_CHANNEL,

        RSSI_THRESHOLD = 0xa6,  // Taken from the Contiki driver

        BLE_ADV_FIRST_CHANNEL = 37,
        BLE_ADV_NUM_CHANNELS = 3,
        BLE_ADV_MAX_PAYLOAD_LENGTH = 31,
        BLE_FRAME_EXTRAS_SIZE = 6,

        NUM_RX_ENTRIES = 2,
        NUM_BLE_SCANNER_ENTRIES = 4,

        TX_TIMEOUT_MS = 1024,

        // It happens sometimes that a BLE advertisement command does not
        // end with an expected interrupt. This may be our bug somewhere,
        // who knows, but the transmission is actually performed.
        BLE_ADV_TX_TIMEOUT_MS = 10,
    };

    state_t state = STATE_UNINITIALIZED;
    fgState_t fgState = FG_STATE_NONE;

    @optimistic_race_detection() error_t error;
    @optimistic_race_detection() error_t fgError;

    rfc_CMD_IEEE_RX_t __attribute__((aligned(4))) rxCmd;
    rfcore_frame_t rxFrames[NUM_RX_ENTRIES];
    rfc_dataEntryPointer_t rxDataEntries[NUM_RX_ENTRIES];
    rfc_dataEntryPointer_t* rxCurrentEntry;
    dataQueue_t rxDataQueue;
    platform_frame_t* rxFrame = NULL;

    rfc_CMD_FS_t __attribute__((aligned(4))) fsCmd;

    rfc_CMD_IEEE_TX_t __attribute__((aligned(4))) txCmd;
    platform_frame_t* txFrame = NULL;

    rfCoreHal_CMD_BLE_ADV_NC_t __attribute__((aligned(4))) bleAdvCmd[BLE_ADV_NUM_CHANNELS];
    rfCoreHal_bleAdvPar_t bleAdvParams;
    ble_address_t bleAddress;
    uint8_t* bleAdvPayload = NULL;
    uint8_t bleAdvPayloadLen;

    rfCoreHal_CMD_BLE_SCANNER_t __attribute__((aligned(4))) bleScannerCmd;
    rfCoreHal_bleScannerPar_t bleScannerParams;
    ble_frame_t bleScannerFrames[NUM_BLE_SCANNER_ENTRIES];
    rfc_dataEntryPointer_t bleScannerDataEntries[NUM_BLE_SCANNER_ENTRIES];
    rfc_dataEntryPointer_t* bleScannerCurrentEntry;
    dataQueue_t bleScannerDataQueue;
    bool bleScannerRequested = FALSE;

    /*---------------------------------------------------------------------------*/
    /* Overrides for IEEE 802.15.4, differential mode */
    /* Copied from Contiki driver. */
    static uint32_t overridesForIEEE[] = {
      0x00354038, /* Synth: Set RTRIM (POTAILRESTRIM) to 5 */
      0x4001402D, /* Synth: Correct CKVD latency setting (address) */
      0x00608402, /* Synth: Correct CKVD latency setting (value) */
    //  0x4001405D, /* Synth: Set ANADIV DIV_BIAS_MODE to PG1 (address) */
    //  0x1801F800, /* Synth: Set ANADIV DIV_BIAS_MODE to PG1 (value) */
      0x000784A3, /* Synth: Set FREF = 3.43 MHz (24 MHz / 7) */
      0xA47E0583, /* Synth: Set loop bandwidth after lock to 80 kHz (K2) */
      0xEAE00603, /* Synth: Set loop bandwidth after lock to 80 kHz (K3, LSB) */
      0x00010623, /* Synth: Set loop bandwidth after lock to 80 kHz (K3, MSB) */
      0x002B50DC, /* Adjust AGC DC filter */
      0x05000243, /* Increase synth programming timeout */
      0x002082C3, /* Increase synth programming timeout */
      0xFFFFFFFF, /* End of override list */
    };
    /*---------------------------------------------------------------------------*/

    /*---------------------------------------------------------------------------*/
    /* BLE overrides */
    /* Copied from Contiki driver. */
    static uint32_t overridesForBLE[] = {
      0x00364038, /* Synth: Set RTRIM (POTAILRESTRIM) to 6 */
      0x000784A3, /* Synth: Set FREF = 3.43 MHz (24 MHz / 7) */
      0xA47E0583, /* Synth: Set loop bandwidth after lock to 80 kHz (K2) */
      0xEAE00603, /* Synth: Set loop bandwidth after lock to 80 kHz (K3, LSB) */
      0x00010623, /* Synth: Set loop bandwidth after lock to 80 kHz (K3, MSB) */
      0x00456088, /* Adjust AGC reference level */
      0xFFFFFFFF, /* End of override list */
    };
    /*---------------------------------------------------------------------------*/

    /*---------------------------------------------------------------------------*/
    /* TX Power dBm lookup table - values from SmartRF Studio */
    typedef struct {
      int8_t dbm;
      uint8_t register_ib;
      uint8_t register_gc;
      uint8_t temp_coeff;
      uint8_t boost;
    } txpower_config_t;

    static const txpower_config_t txPowers[] = {
      {  5, 0x30, 0x00, 0x93, 0 },
      {  4, 0x24, 0x00, 0x93, 0 },
      {  3, 0x1c, 0x00, 0x5a, 0 },
      {  2, 0x18, 0x00, 0x4e, 0 },
      {  1, 0x14, 0x00, 0x42, 0 },
      {  0, 0x21, 0x01, 0x31, 0 },
      { -3, 0x18, 0x01, 0x25, 0 },
      { -6, 0x11, 0x01, 0x1d, 0 },
      { -9, 0x0e, 0x01, 0x19, 0 },
      {-12, 0x0b, 0x01, 0x14, 0 },
      {-15, 0x0b, 0x03, 0x0c, 0 },
      {-18, 0x09, 0x03, 0x0c, 0 },
      {-21, 0x07, 0x03, 0x0c, 0 },

      {-127, 0, 0, 0, 0},
    };

    /* Default TX Power - position in output_power[] */
    const txpower_config_t *txPower = &txPowers[0];

    /* Copied from Contiki driver, which specifies only the default
     * TX power settings for BLE. */
    const txpower_config_t txPowerForBLE = { 5, 0x29, 0, 0, 0 };
    /*---------------------------------------------------------------------------*/

    static inline rfcore_frame_t* getRFCoreFrame(platform_frame_t* framePtr2) {
        return &framePtr2->rfcore_frame;
    }

    static inline raw_frame_t* getRawFrame(platform_frame_t* framePtr) {
        return &getRFCoreFrame(framePtr)->raw_frame;
    }

    static error_t on();
    static void off();

    static error_t setupIEEE();
    static error_t setupBLE();

    static bool requestIEEE();
    static bool requestBLE();

    static void startRX();
    static void stopRX();

    static void startTX();
    static void cancelTX();

    static void startBLEAdvTX();
    static void startBLEScanner();

    static mode_t stateToMode(state_t state);

    static void initRXCmd();
    static void initTXCmd();
    static void initFSCmd();
    static void initBLEAddress();
    static void initBLEAdvCmd();
    static void initBLEScannerCmd();

    task void TXDone();
    task void RXDone();
    task void BLEAdvTXDone();
    task void BLEScannerResult();

    // ---- Init

    command error_t Init.init() {
        error_t error;

        /* We allow multiple calls to Init.init, so that the radio stack and the
         * BLE stack need not coordinate, who should init the radio module. */
        if (state != STATE_UNINITIALIZED) {
            return SUCCESS;
        }

        call RFCore.init();

        initRXCmd();
        initTXCmd();
        initFSCmd();
        initBLEAddress();
        initBLEAdvCmd();
        initBLEScannerCmd();

        state = STATE_OFF;
        fgState = FG_STATE_NONE;

        error = call InitAfterRadio.init();

        if (error != SUCCESS) {
            state = STATE_UNINITIALIZED;
        }

        return error;
    }

    default command inline error_t InitAfterRadio.init() {
        return SUCCESS;
    }

    static void clearRXQueue() {
        int i;
        rxCurrentEntry = &rxDataEntries[0];
        rxDataQueue.pCurrEntry = (uint8_t*)rxCurrentEntry;
        for (i = 0; i < NUM_RX_ENTRIES; i++) {
            rxDataEntries[i].status = DATA_ENTRY_STATUS_PENDING;
        }
    }

    static void popRXQueue() {
        RADIO_ASSERT(rxCurrentEntry->status == DATA_ENTRY_STATUS_FINISHED);
        rxCurrentEntry->status = DATA_ENTRY_STATUS_PENDING;
        rxCurrentEntry = (rfc_dataEntryPointer_t*)rxCurrentEntry->pNextEntry;
    }

    static void initRXCmd() {
        int i;
        rfc_CMD_IEEE_RX_t *cmd = &rxCmd;

        call RFCore.initRadioOp((rfc_radioOp_t*)cmd,
                sizeof(rfc_CMD_IEEE_RX_t), CMD_IEEE_RX);

        cmd->status = RF_CORE_RADIO_OP_STATUS_IDLE;
        cmd->pNextOp = NULL;
        cmd->startTime = 0x00000000;
        cmd->startTrigger.triggerType = TRIG_NOW;
        cmd->condition.rule = COND_NEVER;
        cmd->channel = CHANNEL_NR;

        cmd->rxConfig.bAutoFlushCrc = 1;
        cmd->rxConfig.bAutoFlushIgn = 1;

        // This config must match the layout of the rfcore_frame_t
        // structure defined in RFCoreFrame.h
        cmd->rxConfig.bIncludePhyHdr = 0;
        cmd->rxConfig.bIncludeCrc = 1;
        cmd->rxConfig.bAppendRssi = 1;
        cmd->rxConfig.bAppendCorrCrc = 1;
        cmd->rxConfig.bAppendSrcInd = 0;
        cmd->rxConfig.bAppendTimestamp = 1;

        // Circular buffer of NUM_RX_ENTRIES frames.
        rxCurrentEntry = &rxDataEntries[0];
        rxDataQueue.pCurrEntry = (uint8_t*)rxCurrentEntry;
        rxDataQueue.pLastEntry = NULL;

        for (i = 0; i < NUM_RX_ENTRIES; i++) {
            rfc_dataEntryPointer_t* entry = &rxDataEntries[i];
            entry->config.type = DATA_ENTRY_TYPE_PTR;
            entry->config.lenSz = 1;
            // TODO(accek): check if all structures are properly packed
            entry->length = sizeof(rfcore_frame_t);
            entry->pData = (uint8_t*)&rxFrames[i];
            entry->status = DATA_ENTRY_STATUS_PENDING;
            entry->pNextEntry = (uint8_t*)&rxDataEntries[(i + 1) % NUM_RX_ENTRIES];
        }

        cmd->pRxQ = &rxDataQueue;
        cmd->pOutput = NULL;

        cmd->frameFiltOpt.frameFiltEn = 0;
        cmd->frameFiltOpt.frameFiltStop = 1;
        cmd->frameFiltOpt.autoAckEn = 0;
        cmd->frameFiltOpt.slottedAckEn = 0;
        cmd->frameFiltOpt.autoPendEn = 0;
        cmd->frameFiltOpt.defaultPend = 0;
        cmd->frameFiltOpt.bPendDataReqOnly = 0;
        cmd->frameFiltOpt.bPanCoord = 0;
        cmd->frameFiltOpt.maxFrameVersion = 1;
        cmd->frameFiltOpt.bStrictLenFilter = 0;

        /* Receive all frame types */
        cmd->frameTypes.bAcceptFt0Beacon = 1;
        cmd->frameTypes.bAcceptFt1Data = 1;
        cmd->frameTypes.bAcceptFt2Ack = 1;
        cmd->frameTypes.bAcceptFt3MacCmd = 1;
        cmd->frameTypes.bAcceptFt4Reserved = 1;
        cmd->frameTypes.bAcceptFt5Reserved = 1;
        cmd->frameTypes.bAcceptFt6Reserved = 1;
        cmd->frameTypes.bAcceptFt7Reserved = 1;

        /* Configure CCA settings */
        cmd->ccaOpt.ccaEnEnergy = 1;
        cmd->ccaOpt.ccaEnCorr = 1;
        cmd->ccaOpt.ccaEnSync = 0;
        cmd->ccaOpt.ccaCorrOp = 1;
        cmd->ccaOpt.ccaSyncOp = 1;
        cmd->ccaOpt.ccaCorrThr = 3;

        cmd->ccaRssiThr = RSSI_THRESHOLD;

        cmd->numExtEntries = 0x00;
        cmd->numShortEntries = 0x00;
        cmd->pExtEntryList = 0;
        cmd->pShortEntryList = 0;

        cmd->endTrigger.triggerType = TRIG_NEVER;
        cmd->endTime = 0x00000000;
    }

    static void initTXCmd() {
        call RFCore.initRadioOp((rfc_radioOp_t*)&txCmd,
                sizeof(rfc_CMD_IEEE_TX_t), CMD_IEEE_TX);
    }

    static void initFSCmd() {
        call RFCore.initRadioOp((rfc_radioOp_t *)&fsCmd,
                sizeof(rfc_CMD_FS_t), CMD_FS);
        fsCmd.frequency = 2405 + 5 * (CHANNEL_NR - 11);
    }

    static void initBLEAddress() {
        call BLEAddressProvider.read(&bleAddress);
    }

    static void initBLEAdvCmd() {
        int i;
        rfCoreHal_bleAdvPar_t* params = &bleAdvParams;
        memset(params, 0x00, sizeof(rfCoreHal_bleAdvPar_t));

        /* Set up BLE Advertisement parameters */
        params->pDeviceAddress = (uint16_t *)bleAddress.bytes;
        params->endTrigger.triggerType = TRIG_NEVER;
        params->endTime = TRIG_NEVER;

        /* We construct a chain of commands for sending BLE advertisements
         * on all advertising channels. */
        for (i = 0; i < BLE_ADV_NUM_CHANNELS; i++) {
            rfCoreHal_CMD_BLE_ADV_NC_t* cmd = &bleAdvCmd[i];

            call RFCore.initRadioOp((rfc_radioOp_t*)cmd,
                    sizeof(rfCoreHal_CMD_BLE_ADV_NC_t), CMD_BLE_ADV_NC);

            cmd->pParams = (uint8_t*)params;
            cmd->channel = BLE_ADV_FIRST_CHANNEL + i;

            if (i < BLE_ADV_NUM_CHANNELS - 1) {
                cmd->condition.rule = COND_ALWAYS;
            }

            if (i > 0) {
                bleAdvCmd[i - 1].pNextOp = (uint8_t*)cmd;
            }
        }
    }

    static void clearBLEScannerQueue() {
        int i;
        bleScannerCurrentEntry = &bleScannerDataEntries[0];
        bleScannerDataQueue.pCurrEntry = (uint8_t*)bleScannerCurrentEntry;
        for (i = 0; i < NUM_BLE_SCANNER_ENTRIES; i++) {
            bleScannerDataEntries[i].status = DATA_ENTRY_STATUS_PENDING;
        }
    }

    static void popBLEScannerQueue() {
        RADIO_ASSERT(bleScannerCurrentEntry->status
                == DATA_ENTRY_STATUS_FINISHED);
        bleScannerCurrentEntry->status = DATA_ENTRY_STATUS_PENDING;
        bleScannerCurrentEntry = (rfc_dataEntryPointer_t*)
            bleScannerCurrentEntry->pNextEntry;
    }

    static void initBLEScannerCmd() {
        int i;
        rfCoreHal_CMD_BLE_SCANNER_t *cmd = &bleScannerCmd;
        rfCoreHal_bleScannerPar_t* params = &bleScannerParams;
        memset(params, 0x00, sizeof(rfCoreHal_bleScannerPar_t));

        call RFCore.initRadioOp((rfc_radioOp_t*)cmd,
                sizeof(rfCoreHal_CMD_BLE_SCANNER_t), CMD_BLE_SCANNER);

        cmd->status = RF_CORE_RADIO_OP_STATUS_IDLE;
        cmd->pNextOp = NULL;
        cmd->startTime = 0x00000000;
        cmd->startTrigger.triggerType = TRIG_NOW;
        cmd->condition.rule = COND_NEVER;

        cmd->pParams = (uint8_t*)params;
        cmd->channel = BLE_ADV_FIRST_CHANNEL;

        params->rxConfig.bAutoFlushCrcErr = 1;
        params->rxConfig.bAutoFlushIgnored = 1;
        params->rxConfig.bAutoFlushEmpty = 0;

        params->rxConfig.bIncludeLenByte = 1;
        params->rxConfig.bIncludeCrc = 0;
        params->rxConfig.bAppendRssi = 1;
        params->rxConfig.bAppendStatus = 1;
        params->rxConfig.bAppendTimestamp = 1;

        // Circular buffer of NUM_BLE_SCANNER_ENTRIES frames.
        bleScannerCurrentEntry = &bleScannerDataEntries[0];
        bleScannerDataQueue.pCurrEntry = (uint8_t*)bleScannerCurrentEntry;
        bleScannerDataQueue.pLastEntry = NULL;

        for (i = 0; i < NUM_BLE_SCANNER_ENTRIES; i++) {
            rfc_dataEntryPointer_t* entry = &bleScannerDataEntries[i];
            entry->config.type = DATA_ENTRY_TYPE_PTR;
            entry->config.lenSz = 1;
            // TODO(accek): check if all structures are properly packed
            entry->length = sizeof(ble_frame_t);
            entry->pData = (uint8_t*)&bleScannerFrames[i];
            entry->status = DATA_ENTRY_STATUS_PENDING;
            entry->pNextEntry = (uint8_t*)&bleScannerDataEntries[(i + 1)
                % NUM_BLE_SCANNER_ENTRIES];
        }

        params->pRxQ = &bleScannerDataQueue;
        cmd->pOutput = NULL;

        params->scanConfig.scanFilterPolicy = 0;
        params->scanConfig.bActiveScan = 0;
        params->scanConfig.deviceAddrType = 0;
        params->scanConfig.bStrictLenFilter = 1;
        params->scanConfig.bAutoWlIgnore = 0;
        params->scanConfig.bEndOnRpt = 0;

        params->pDeviceAddress = (uint16_t *)bleAddress.bytes;

        params->timeoutTrigger.triggerType = TRIG_NEVER;
        params->timeoutTime = 0x00000000;
        params->endTrigger.triggerType = TRIG_NEVER;
        params->endTime = 0x00000000;
    }

    // ---- Logic

#include "../native/cc26xxware/rf_patches/rf_patch_cpe_ble.h"
#include "../native/cc26xxware/rf_patches/rf_patch_rfe_ble.h"

    static error_t on() {
        error_t ret = SUCCESS;
        uint32_t cmd_status;

        RADIO_ASSERT(state == STATE_OFF);

        call RFCoreXOSC.requestXOSC();

        if (!call RFCore.powerUp(TRUE)) {
            ret = EINTERNAL;
            goto out;
        }

        /* Assert bus request towards PRCM (needed to allow MCU IDLE sleep) */
        if (!call RFCore.sendCmd(CMDR_DIR_CMD_1BYTE(CMD_BUS_REQUEST, 1),
                    &cmd_status, FALSE)) {
            RADIO_WARNPRINTF("on(): CMD_BUS_REQUEST fail, CMDSTA=0x%08lx\n",
                cmd_status);
            ret = EINTERNAL;
            goto out;
        }

        rf_patch_cpe_ble();
        rf_patch_rfe_ble();

        state = STATE_UNCONFIGURED;

        call RadioOnLed.on();

out:
        call RFCoreXOSC.switchToXOSC();
        if (ret != SUCCESS) {
            call RFCoreXOSC.releaseXOSC();
        }

        return ret;
    }

    static void off() {
        RADIO_ASSERT(state == STATE_UNCONFIGURED
                || state == STATE_IEEE_IDLE
                || state == STATE_BLE_IDLE);

        call RFCore.powerDown();
        call RFCoreXOSC.releaseXOSC();

        // TODO(accek): Contiki clears the command status flags here,
        //              verify if we need this too.

        state = STATE_OFF;

        call RadioOnLed.off();
    }

    static void resetRadio() {
        // TODO
        panic("Radio reset requested");
    }

    static error_t setupRadio(uint8_t mode,
            const txpower_config_t* txPowerConfig,
            const uint32_t* overrides,
            state_t finalState) {
        uint32_t cmd_status;
        rfc_CMD_RADIO_SETUP_t __attribute__((aligned(4))) cmd;

        if (state == STATE_OFF) {
            error_t err = on();
            if (err != SUCCESS) {
                RADIO_WARNPRINTF("setupRadio: on() failed with %d\n", err);
                return err;
            }
        }

        RADIO_ASSERT(state == STATE_UNCONFIGURED
                || state == STATE_IEEE_IDLE
                || state == STATE_BLE_IDLE);
        RADIO_ASSERT(fgState == FG_STATE_NONE);

        /* Create radio setup command */
        call RFCore.initRadioOp((rfc_radioOp_t *)&cmd, sizeof(cmd),
                CMD_RADIO_SETUP);

        cmd.txPower.IB = txPowerConfig->register_ib;
        cmd.txPower.GC = txPowerConfig->register_gc;
        cmd.txPower.tempCoeff = txPowerConfig->temp_coeff;
        cmd.txPower.boost = txPowerConfig->boost;
        cmd.pRegOverride = (uint32_t*)overrides;
        cmd.mode = mode;

        if(!call RFCore.sendCmd((uint32_t)&cmd, &cmd_status, FALSE)) {
            RADIO_WARNPRINTF("setupRadio: CMD_RADIO_SETUP, CMDSTA=0x%08lx, status=0x%04x\n",
               cmd_status, cmd.status);
            return EINTERNAL;
        }

        if(!call RFCore.waitCmdDone((rfc_radioOp_t*)&cmd)) {
            RADIO_WARNPRINTF("setupRadio: CMD_RADIO_SETUP wait, CMDSTA=0x%08lx, status=0x%04x\n",
               cmd_status, cmd.status);
            return EINTERNAL;
        }

        state = finalState;

        return SUCCESS;
    }

    static error_t setupIEEE() {
        RADIO_DBGPRINTF("setupIEEE\r\n");
        return setupRadio(1, txPower, overridesForIEEE, STATE_IEEE_IDLE);
    }

    static error_t setupBLE() {
        RADIO_DBGPRINTF("setupBLE\r\n");
        return setupRadio(0, &txPowerForBLE, overridesForBLE, STATE_BLE_IDLE);
    }

    static mode_t stateToMode(state_t state) {
        switch (state) {
            case STATE_UNINITIALIZED:
            case STATE_OFF:
                return MODE_NONE;
            case STATE_UNCONFIGURED:
                return MODE_UNCONFIGURED;
            case STATE_IEEE_IDLE:
            case STATE_IEEE_RX:
            case STATE_IEEE_RX_FOR_TX:
            case STATE_IEEE_RX_DONE:
            case STATE_IEEE_RX_LATE_CANCEL:
            case STATE_IEEE_RX_END:
            case STATE_IEEE_TX_CAL:
            case STATE_IEEE_TX_CAL_DONE:
            case STATE_IEEE_CLAIMED:
                return MODE_IEEE;
            case STATE_BLE_IDLE:
            case STATE_BLE_ADV:
            case STATE_BLE_ADV_DONE:
            case STATE_BLE_ADV_END:
            case STATE_BLE_SCANNER:
            case STATE_BLE_SCANNER_FAILED:
            case STATE_BLE_CLAIMED:
                return MODE_BLE;
        }

        // To silence the compiler which does not recognize that the switch is
        // enough to handle all cases and return a value.
        panic();
        return MODE_NONE;
    }

    static inline bool isClaimed() {
        return state == STATE_IEEE_CLAIMED || state == STATE_BLE_CLAIMED;
    }

    static inline bool canSwitchMode() {
        RADIO_ASSERT(state != STATE_UNINITIALIZED);
        return state == STATE_OFF
            || state == STATE_UNCONFIGURED || (state == STATE_IEEE_IDLE &&
                fgState == FG_STATE_NONE) || state == STATE_BLE_IDLE;
    }

    static inline bool requestIEEE() {
        if (stateToMode(state) == MODE_IEEE) {
            // Already configured for IEEE
            return TRUE;
        }
        if (canSwitchMode()) {
            if (setupIEEE() != SUCCESS) {
                // TODO(accek): consider if better handling is needed
                panic("setupIEEE failed");
                return FALSE;
            }
            return TRUE;
        } else {
            return FALSE;
        }
    }

    static inline bool requestBLE() {
        if (stateToMode(state) == MODE_BLE) {
            // Already configured for BLE
            return TRUE;
        }
        if (canSwitchMode()) {
            if (setupBLE() != SUCCESS) {
                // TODO(accek): consider if better handling is needed
                panic("setupBLE failed");
                return FALSE;
            }
            return TRUE;
        } else {
            return FALSE;
        }
    }

    static void startRX() {
        uint32_t cmd_status;
        rfc_CMD_IEEE_RX_t* cmd = &rxCmd;

        clearRXQueue();

        RADIO_ASSERT(stateToMode(state) == MODE_IEEE);

        RADIO_DBGPRINTF("startRX\r\n");

        if (!call RFCore.sendCmd((uint32_t)cmd, &cmd_status, FALSE)) {
            RADIO_WARNPRINTF("startRX: CMDSTA=0x%08lx, status=0x%04x\n",
                   cmd_status, cmd->status);
            resetRadio();
            return;
        }

        if (rxFrame) {
            state = STATE_IEEE_RX;
        } else {
            state = STATE_IEEE_RX_FOR_TX;
        }
    }

    static void stopRX() {
        uint32_t cmd_status;
        RADIO_ASSERT(stateToMode(state) == MODE_IEEE);

        RADIO_DBGPRINTF("stopRX\r\n");

        /* This was CMD_STOP at some point in the past, but this resulted in at
         * least one INTERNAL_ERROR interrupt and I changed it to CMD_ABORT,
         * and never seen those after... --accek */
        if (!call RFCore.sendCmd(CMDR_DIR_CMD(CMD_ABORT), &cmd_status, FALSE)) {
            RADIO_WARNPRINTF("stopRX: CMD_ABORT status=0x%08lx\n", cmd_status);
            resetRadio();
            return;
        }

        // TODO(accek): wait?

        state = STATE_IEEE_IDLE;
    }

    static void startSynthesizer() {
        uint32_t cmd_status;
        rfc_CMD_FS_t* cmd = &fsCmd;

        cmd->synthConf.bTxMode = 1;

        RADIO_DBGPRINTF("startSynthesizer\r\n");

        if(!call RFCore.sendCmd((uint32_t)cmd, &cmd_status, TRUE)) {
            RADIO_WARNPRINTF("startSynthesizer: CMD_FS, CMDSTA=0x%08lx, status=0x%04x\n",
               cmd_status, cmd->status);
            return;
        }
    }

    static void stopSynthesizer() {
        // TODO
        state = STATE_IEEE_IDLE;
    }

    static void startTX() {
        uint32_t cmd_status;
        rfc_CMD_IEEE_TX_t* cmd = &txCmd;
        uint32_t cmd_num = (uint32_t)cmd;

        RADIO_ASSERT(txFrame != NULL);
        RADIO_ASSERT(stateToMode(state) == MODE_IEEE);

        if (state == STATE_IEEE_TX_CAL) {
            // Wait for the calibration to finish.
            return;
        }

        if (state == STATE_IEEE_IDLE) {
            startRX();
        }

        cmd->payloadLen = call RawFrame.getLength(txFrame);
        cmd->pPayload = call RawFrame.getData(txFrame);

        fgError = SUCCESS;
        fgState = FG_STATE_IEEE_TX;

        RADIO_DBGPRINTF("startTX\r\n");

        if (!call RFCore.sendCmd(cmd_num, &cmd_status, TRUE)) {
            RADIO_WARNPRINTF("startTX: CMDSTA=0x%08lx, status=0x%04x\n",
                   cmd_status, cmd->status);
            fgError = EINTERNAL;
            fgState = FG_STATE_IEEE_TX_DONE;
            post TXDone();
        }
    }

    static void cancelTX() {
        uint32_t cmd_status;
        RADIO_ASSERT(fgState == FG_STATE_IEEE_TX);

        RADIO_DBGPRINTF("cancelTX\r\n");

        fgState = FG_STATE_NONE;

        if (!call RFCore.sendCmd(CMDR_DIR_CMD(CMD_IEEE_ABORT_FG), &cmd_status, FALSE)) {
            RADIO_WARNPRINTF("cancelTX: CMD_IEEE_ABORT_FG status=0x%08lx\n", cmd_status);
        }
    }

    static void startBLEAdvTX() {
        uint32_t cmd_status;
        rfCoreHal_CMD_BLE_ADV_NC_t* cmd = &bleAdvCmd[0];

        bleAdvParams.advLen = bleAdvPayloadLen;
        bleAdvParams.pAdvData = bleAdvPayload;

        error = SUCCESS;
        state = STATE_BLE_ADV;

        call BLEAdvWatchdogTimer.startWithTimeoutFromNow(BLE_ADV_TX_TIMEOUT_MS);

        if (!call RFCore.sendCmd((uint32_t)cmd, &cmd_status, TRUE)) {
            RADIO_WARNPRINTF("startBLEAdvTX: CMDSTA=0x%08lx, status=0x%04x\n",
                   cmd_status, cmd->status);
            error = EINTERNAL;
            state = STATE_BLE_ADV_DONE;
            post BLEAdvTXDone();
        }
    }

    static void startBLEScanner() {
        uint32_t cmd_status;
        rfCoreHal_CMD_BLE_SCANNER_t* cmd = &bleScannerCmd;

        error = SUCCESS;
        state = STATE_BLE_SCANNER;

        if (!call RFCore.sendCmd((uint32_t)cmd, &cmd_status, TRUE)) {
            RADIO_WARNPRINTF("startBLEScanner: CMDSTA=0x%08lx, status=0x%04x\n",
                   cmd_status, cmd->status);
            error = EINTERNAL;
            state = STATE_BLE_SCANNER_FAILED;
        }
    }

    static void stopBLEScanner() {
        uint32_t cmd_status;
        RADIO_ASSERT(stateToMode(state) == MODE_BLE);

        RADIO_DBGPRINTF("stopBLEScanner\r\n");

        // State needs to be set before running the command so that the
        // LAST_COMMAND_DONE handler will not set state to
        // STATE_BLE_SCANNER_FAILED.
        state = STATE_BLE_IDLE;

        if (!call RFCore.sendCmd(CMDR_DIR_CMD(CMD_ABORT), &cmd_status, FALSE)) {
            RADIO_WARNPRINTF("stopBLEScanner: CMD_ABORT status=0x%08lx\n", cmd_status);
            resetRadio();
            return;
        }

        // TODO(accek): wait?
    }

    static inline void tryToDoSomething() {
        // TODO: this REALLY should not be atomic; and probably does not
        //       need to be
        //atomic {
            if (isClaimed()) {
                return;
            }
            if (txFrame != NULL && fgState == FG_STATE_NONE) {
                if (requestIEEE()) {
                    startTX();
                }
            } else if (txFrame == NULL && state == STATE_IEEE_TX_CAL_DONE) {
                // After cancelled TX...
                stopSynthesizer();
            }
            if (rxFrame != NULL && state == STATE_IEEE_RX_FOR_TX) {
                state = STATE_IEEE_RX;
            } else if (rxFrame != NULL &&
                    state != STATE_IEEE_TX_CAL &&
                    state != STATE_IEEE_RX &&
                    state != STATE_IEEE_RX_DONE &&
                    state != STATE_IEEE_RX_LATE_CANCEL) {
                if (requestIEEE()) {
                    startRX();
                }
            } else if (bleAdvPayload != NULL &&
                    state != STATE_BLE_ADV &&
                    state != STATE_BLE_ADV_DONE &&
                    state != STATE_BLE_SCANNER &&
                    state != STATE_BLE_SCANNER_FAILED) {
                if (requestBLE()) {
                    startBLEAdvTX();
                }
            } else if (bleScannerRequested &&
                    state != STATE_BLE_ADV &&
                    state != STATE_BLE_ADV_DONE &&
                    state != STATE_BLE_SCANNER &&
                    state != STATE_BLE_SCANNER_FAILED) {
                if (requestBLE()) {
                    startBLEScanner();
                }
            }
            if (state != STATE_OFF && txFrame == NULL && rxFrame == NULL
                    && bleAdvPayload == NULL && canSwitchMode()) {
                off();
            }
        //}
    }

    // ---- Interrupts

    task void TXCalDone() {
        // TODO: check for errors
        tryToDoSomething();
    }

    task void TXDone() {
        platform_frame_t* frame = txFrame;
        rfcore_frame_t* rfcf = getRFCoreFrame(frame);
        uint16_t status;

        call TXWatchdogTimer.stop();

        atomic {
            if (fgState == FG_STATE_IEEE_TX_LATE_CANCEL) {
                fgState = FG_STATE_NONE;
                tryToDoSomething();
                return;
            }
            RADIO_ASSERT(fgState == FG_STATE_IEEE_TX_DONE);
            txFrame = NULL;
            fgState = FG_STATE_IEEE_TX_END;
        }

        status = txCmd.status;
        txCmd.status = RF_CORE_RADIO_OP_STATUS_IDLE;
        if (status != RF_CORE_RADIO_OP_STATUS_IEEE_DONE_OK) {
            fgError = EINTERNAL;
            RADIO_WARNPRINTF("TXDone: status=0x%04x fsStatus=0x%04x\n", status,
                    fsCmd.status);
        }

        rfcf->extras.timestamp = txCmd.timeStamp;

        if (fgError == SUCCESS) {
            call NumSuccessfulTXStat.increment(1);
        }

        signal RawFrameSender.sendingFinished(frame, fgError);
        atomic {
            if (fgState == FG_STATE_IEEE_TX_END) {
                if (state == STATE_IEEE_TX_CAL_DONE) {
                    state = STATE_IEEE_IDLE;
                }
                fgState = FG_STATE_NONE;
                tryToDoSomething();
            }
        }
    }

    task void BLEAdvTXDone() {
        uint8_t* payload = bleAdvPayload;
        uint8_t len = bleAdvPayloadLen;
        int i;

        RADIO_ASSERT(state == STATE_BLE_ADV_DONE);
        state = STATE_BLE_ADV_END;
        bleAdvPayload = NULL;
        bleAdvPayloadLen = 0;

        for (i = 0; i < BLE_ADV_NUM_CHANNELS; i++) {
            uint16_t status = bleAdvCmd[i].status;
            if (status != RF_CORE_RADIO_OP_STATUS_BLE_DONE_OK) {
                error = EINTERNAL;
                RADIO_WARNPRINTF("BLEAdvTXDone: op=%d, status=0x%04x\n", i,
                        status);
            }
        }

        if (error == SUCCESS) {
            call NumSuccessfulBLEAdvTXStat.increment(1);
        }

        signal RawBLEAdvertiser.sendingFinished(payload, len, error);

        if (state == STATE_BLE_ADV_END) {
            state = STATE_BLE_IDLE;
            tryToDoSomething();
        }
    }

    task void RXDone() {
        platform_frame_t* frame = rxFrame;
        rfcore_frame_t* rfcore_frame = getRFCoreFrame(frame);
        atomic {
            if (state == STATE_IEEE_RX_LATE_CANCEL) {
                stopRX();
                tryToDoSomething();
                return;
            }
            RADIO_ASSERT(state == STATE_IEEE_RX_DONE && frame != NULL);
        }
        // TODO(accek): audit those atomics; they seem unneeded

        // Here we check if the radio state machine is in one of the AUTO-ACK
        // states.  If it is, then we will repost this task and quit. We only
        // want to report receivingFinished if the ack has been sent.
        /*{
            uint8_t fsmState = call FSM_FFCTRL_STATE.get();
            if (48 <= fsmState && fsmState <= 55) {
                post RXDone();
                return;
            }
        }*/
        // TODO(accek): do something about it

        if (error == SUCCESS) {
            uint8_t* buf;
            uint8_t len;
            atomic {
                buf = rxCurrentEntry->pData;
                popRXQueue();
                // FIXME(accek): oh well, popRXQueue() should not be called
                // before copying the data from the buffer...
            }
            len = buf[0] - sizeof(rfcore_frame_extras_t);
            if (len > call RawFrame.maxLength()) {
                call NumLengthErrorsStat.increment(1);
                atomic {
                    state = STATE_IEEE_RX;
                }
                return;
            }
            memcpy(call RawFrame.getRawPointer(frame), buf, len + 1);
            call RawFrame.setLength(frame, len);
            memcpy(&rfcore_frame->extras, buf + len + 1,
                    sizeof(rfcore_frame_extras_t));
        }
        atomic rxFrame = NULL;
        atomic state = STATE_IEEE_RX_END;
        call NumSuccessfulRXStat.increment(1);
        signal RawFrameReceiver.receivingFinished(frame, error);
        atomic {
            if (state == STATE_IEEE_RX_END) {
                stopRX();
                tryToDoSomething();
            }
        }
    }

    task void BLEScannerResult() {
        ble_frame_t* frame;
        uint8_t* buf;
        uint8_t len;
        buf = bleScannerCurrentEntry->pData;
        buf[0] -= BLE_FRAME_EXTRAS_SIZE;
        len = buf[0];
        //RADIO_ASSERT(len <= BLE_MAX_FRAME_LEN);
        frame = (ble_frame_t*)buf;
        // FIXME(accek): memcpy -> memmove
        memmove(&frame->timestamp, &buf[len + 3], 4);
        frame->crcerr = buf[len + 2] & 0x40;
        frame->rssi = buf[len + 1];
        signal RawBLEScanner.advertisementReceived(frame);
        popBLEScannerQueue();
    }

    task void BLEScannerFailed() {
        uint16_t status = bleScannerCmd.status;
        if (status != RF_CORE_RADIO_OP_STATUS_IEEE_DONE_OK) {
            RADIO_WARNPRINTF("BLEScannerFailed: status=0x%04x\n",
                    bleScannerCmd.status);
        } else {
            RADIO_WARNPRINTF("BLEScannerFailed, but command returned OK\n");
        }
    }

    async event void RFCore.onLastFGCommandDone() {
        RADIO_DBGPRINTF("onLastFGCommandDone\r\n");
        if (fgState == FG_STATE_IEEE_TX) {
            fgState = FG_STATE_IEEE_TX_DONE;
            post TXDone();
        }
    }

    async event void RFCore.onLastCommandDone() {
        RADIO_DBGPRINTF("onLastCommandDone\r\n");
        switch (state) {
            case STATE_IEEE_TX_CAL:
                state = STATE_IEEE_TX_CAL_DONE;
                post TXCalDone();
                break;
            case STATE_BLE_ADV:
                state = STATE_BLE_ADV_DONE;
                post BLEAdvTXDone();
                break;
            case STATE_BLE_SCANNER:
                state = STATE_BLE_SCANNER_FAILED;
                post BLEScannerFailed();
                break;
            case STATE_IEEE_CLAIMED:
                signal ClaimIEEE.onLastCommandDone();
                break;
            case STATE_BLE_CLAIMED:
                signal ClaimBLE.onLastCommandDone();
                break;
            default:
                /* do nothing */
        }
    }

    async event void RFCore.onRXDone() {
        // FIXME(accek): I think there may be races here, namely if state
        //       has just changed to BLE and we are handling an old IEEE
        //       RX completion. :-( Or, if there is no such race, then three
        //       last branches are not needed.
        if (state == STATE_IEEE_RX) {
            state = STATE_IEEE_RX_DONE;
            post RXDone();
        } else if (state == STATE_BLE_SCANNER) {
            post BLEScannerResult();
        } else if (rxCurrentEntry->status == DATA_ENTRY_STATUS_FINISHED) {
            popRXQueue();
        } else if (bleScannerCurrentEntry->status == DATA_ENTRY_STATUS_FINISHED) {
            popBLEScannerQueue();
        } else if (state == STATE_IEEE_CLAIMED) {
            signal ClaimIEEE.onRXDone();
        } else if (state == STATE_BLE_CLAIMED) {
            signal ClaimBLE.onRXDone();
        } else {
            panic("Spurious RXDone interrupt");
        }
    }

    async event void RFCore.onTXDone() {
        // We do not use TXDone on regular operations (we use onLastCommandDone
        // and friends)
        if (state == STATE_IEEE_CLAIMED) {
            signal ClaimIEEE.onTXDone();
        } else if (state == STATE_BLE_CLAIMED) {
            signal ClaimBLE.onTXDone();
        }
    }

    async event void RFCore.onTXPkt() {
        // We do not use TXDone on regular operations (we use onLastCommandDone
        // and friends)
        if (state == STATE_IEEE_CLAIMED) {
            signal ClaimIEEE.onTXPkt();
        } else if (state == STATE_BLE_CLAIMED) {
            signal ClaimBLE.onTXPkt();
        }
    }

    default inline async event void ClaimIEEE.onLastCommandDone() { }
    default inline async event void ClaimIEEE.onRXDone() { }
    default inline async event void ClaimIEEE.onTXDone() { }
    default inline async event void ClaimIEEE.onTXPkt() { }
    default inline async event void ClaimBLE.onLastCommandDone() { }
    default inline async event void ClaimBLE.onRXDone() { }
    default inline async event void ClaimBLE.onTXDone() { }
    default inline async event void ClaimBLE.onTXPkt() { }

    // ---- RFCore.fatalError

    event void RFCore.fatalError(const char* message) {
        panic("Fatal error from RFCore");
    }

    // ---- RawFrameSender

    command error_t RawFrameSender.startSending(platform_frame_t* frame) {
        uint8_t len;

        atomic {
            if (state == STATE_UNINITIALIZED) {
                return EOFF;
            }
        }
        if (frame == NULL) {
            return EINVAL;
        }
        if (txFrame != NULL) {
            return EBUSY;
        }
        len = call RawFrame.getLength(frame);
        if (len > call RawFrame.maxLength()) {
            return ESIZE;
        }

        txFrame = frame;

        call TXWatchdogTimer.startWithTimeoutFromNow(TX_TIMEOUT_MS);
        tryToDoSomething();
        return SUCCESS;
    }

    command error_t RawFrameSender.cancelSending(platform_frame_t* frame) {
        if (txFrame == NULL || txFrame != frame) {
            return EINVAL;
        }
        call TXWatchdogTimer.stop();
        atomic {
            txFrame = NULL;
            if (fgState == FG_STATE_IEEE_TX_DONE) {
                // The TXDONE interrupt has been handled and the TXDone task
                // is already pending.
                fgState = FG_STATE_IEEE_TX_LATE_CANCEL;
            } else if (fgState == FG_STATE_IEEE_TX) {
                cancelTX();
                tryToDoSomething();
            }
        }
        return SUCCESS;
    }

    command bool RawFrameSender.isSending() {
        return txFrame != NULL;
    }

    default inline event void RawFrameSender.sendingFinished(platform_frame_t* frame, error_t result) { }

    // ---- RawBLEAdvertiser

    command error_t RawBLEAdvertiser.sendAdvertisement(uint8_t_xdata* payload,
            uint8_t length) {
        atomic {
            if (state == STATE_UNINITIALIZED) {
                return EOFF;
            }
        }
        if (payload == NULL || length == 0) {
            return EINVAL;
        }
        if (bleAdvPayload != NULL) {
            return EBUSY;
        }
        if (length > BLE_ADV_MAX_PAYLOAD_LENGTH) {
            return ESIZE;
        }

        bleAdvPayload = payload;
        bleAdvPayloadLen = length;

        tryToDoSomething();
        return SUCCESS;
    }

    default event void RawBLEAdvertiser.sendingFinished(uint8_t_xdata* payload, uint8_t length, error_t status) { }

    // ---- RawBLEScanner

    command error_t RawBLEScanner.startScan() {
        atomic {
            if (state == STATE_UNINITIALIZED) {
                return EOFF;
            }
        }
        if (bleScannerRequested) {
            return EALREADY;
        }

        bleScannerRequested = TRUE;

        tryToDoSomething();
        return SUCCESS;
    }

    command error_t RawBLEScanner.stopScan() {
        atomic {
            if (state == STATE_UNINITIALIZED) {
                return EOFF;
            }
        }
        if (!bleScannerRequested) {
            return EALREADY;
        }

        bleScannerRequested = FALSE;
        if (state == STATE_BLE_SCANNER) {
            stopBLEScanner();
        }
        if (state == STATE_BLE_SCANNER || state == STATE_BLE_SCANNER_FAILED) {
            state = STATE_BLE_IDLE;
        }

        tryToDoSomething();
        return SUCCESS;
    }

    default event void RawBLEScanner.advertisementReceived(ble_frame_t* frame) { }

    // ---- TXWatchdogTimer

    event void TXWatchdogTimer.fired() {
        atomic {
            if (fgState == FG_STATE_IEEE_TX) {
                call NumTXTimeoutErrorsStat.increment(1);
                panic("TX timeout");
            }
        }
    }

    default command inline void TXWatchdogTimer.startWithTimeoutFromNow(uint32_t dt) { }
    default command inline void TXWatchdogTimer.stop() { }

    // ---- BLEAdvWatchdogTimer

    event void BLEAdvWatchdogTimer.fired() {
        atomic {
            if (state == STATE_BLE_ADV) {
                uint32_t cmd_status;

                call NumBLEAdvTimeoutErrorsStat.increment(1);
                RADIO_WARNPRINTF("BLE advertisement TX timeout\n");
                state = STATE_BLE_ADV_DONE;

                if (!call RFCore.sendCmd(CMDR_DIR_CMD(CMD_ABORT), &cmd_status, FALSE)) {
                    RADIO_WARNPRINTF("BLEAdvWatchdogTimer: CMD_ABORT status=0x%08lx\n", cmd_status);
                    resetRadio();
                    return;
                }

                post BLEAdvTXDone();
            }
        }
    }

    default command inline void BLEAdvWatchdogTimer.startWithTimeoutFromNow(uint32_t dt) { }
    default command inline void BLEAdvWatchdogTimer.stop() { }

    // ---- RawFrameReceiver

    command error_t RawFrameReceiver.startReceiving(platform_frame_t* frame) {
        atomic {
            if (state == STATE_UNINITIALIZED) {
                return EOFF;
            }
        }
        if (frame == NULL) {
            return EINVAL;
        }
        if (rxFrame != NULL) {
            return EBUSY;
        }
        atomic rxFrame = frame;

        // Handle a common situation when startReceiving is called from within
        // receivingFinished.
        if (state == STATE_IEEE_RX_END) {
            state = STATE_IEEE_RX;
        } else {
            tryToDoSomething();
        }

        return SUCCESS;
    }

    command error_t RawFrameReceiver.cancelReceiving(platform_frame_t* frame) {
        if (rxFrame == NULL || rxFrame != frame) {
            return EINVAL;
        }
        atomic {
            rxFrame = NULL;
            if (state == STATE_IEEE_RX_DONE) {
                // The RXDONE interrupt has been handled and the RXDone task
                // is already pending.
                state = STATE_IEEE_RX_LATE_CANCEL;
                stopRX();
            } else if (state == STATE_IEEE_RX) {
                stopRX();
            }
        }
        tryToDoSomething();
        return SUCCESS;
    }

    command bool RawFrameReceiver.isReceiving() {
        return rxFrame != NULL;
    }

    default inline event void RawFrameReceiver.receivingFinished(platform_frame_t* frame, error_t result) { }

    // ---- RFCoreClaim

    command error_t ClaimIEEE.claim() {
        if (canSwitchMode() && requestIEEE()) {
            state = STATE_IEEE_CLAIMED;
            return SUCCESS;
        }
        return EBUSY;
    }

    command void ClaimIEEE.release() {
        RADIO_ASSERT(state == STATE_IEEE_CLAIMED);
        state = STATE_IEEE_IDLE;
        tryToDoSomething();
    }

    command error_t ClaimBLE.claim() {
        if (canSwitchMode() && requestBLE()) {
            state = STATE_BLE_CLAIMED;
            return SUCCESS;
        }
        return EBUSY;
    }

    command void ClaimBLE.release() {
        RADIO_ASSERT(state == STATE_BLE_CLAIMED);
        state = STATE_BLE_IDLE;
        tryToDoSomething();
    }

    // ---- AUTO-ACK (autoack - for searching)

    command void CoreRadioSimpleAutoACK.setDstAddrFilter(
            whip6_ieee154_pan_id_t const *panIdPtr,
            whip6_ieee154_ext_addr_t const *extAddrPtr,
            whip6_ieee154_short_addr_t const *shrtAddrPtr) {
        memcpy(&rxCmd.localPanID, panIdPtr->data, 2);
        memcpy(&rxCmd.localShortAddr, shrtAddrPtr->data, 2);
        memcpy(&rxCmd.localExtAddr, extAddrPtr->data, 8);
    }

    command void CoreRadioSimpleAutoACK.enebaleDataFrameFilteringAndAutoACK() {
        // TODO(accek): consider if other types should be received or not
        //              received, ask Przemo
        rxCmd.frameTypes.bAcceptFt0Beacon = 0;
        rxCmd.frameTypes.bAcceptFt2Ack = 0;
        rxCmd.frameTypes.bAcceptFt3MacCmd = 0;
        rxCmd.frameTypes.bAcceptFt1Data = 1;
        rxCmd.frameFiltOpt.frameFiltEn = 1;
        rxCmd.frameFiltOpt.autoAckEn = 1;

        // TODO(accek): apply changes
    }

    command void CoreRadioSimpleAutoACK.disableDataFrameFilteringAndAutoACK() {
        rxCmd.frameFiltOpt.frameFiltEn = 1;
        rxCmd.frameFiltOpt.autoAckEn = 1;

        // TODO(accek): apply changes
    }

    // ---- RawFrame

    command uint8_t RawFrame.getLength(platform_frame_t* framePtr) {
        raw_frame_t* rf = getRawFrame(framePtr);
        return rf->length;
    }

    command void RawFrame.setLength(platform_frame_t* framePtr, uint8_t length) {
        raw_frame_t* rf = getRawFrame(framePtr);
        rf->length = length;
    }

    command uint8_t RawFrame.maxLength() {
        if (sizeof(((raw_frame_t*)0)->data) < MAX_FRAME_LENGTH) {
            return sizeof(((raw_frame_t*)0)->data);
        } else {
            return MAX_FRAME_LENGTH;
        }
    }

    command uint8_t_xdata* RawFrame.getData(platform_frame_t* framePtr) {
        raw_frame_t* rf = getRawFrame(framePtr);
        return rf->data;
    }

    command uint8_t_xdata* RawFrame.getRawPointer(platform_frame_t* framePtr) {
        return (uint8_t_xdata*)getRawFrame(framePtr);
    }

    command uint8_t RawFrame.maxRawLength() {
        return call RawFrame.maxLength() + 1;
    }

    command uint8_t_xdata* RawFrame.nextHeader(platform_frame_t* framePtr) {
        return call RawFrame.getRawPointer(framePtr) + sizeof(raw_frame_t);
    }

    // ---- CoreRadioReceivingNow

    command bool CoreRadioReceivingNow.receivingBytesNow() {
        atomic {
            if (state == STATE_IEEE_RX_DONE) {
                return TRUE;
            } else if (state != STATE_IEEE_RX) {
                return FALSE;
            }
            return rxCurrentEntry->status == DATA_ENTRY_STATUS_BUSY
                || rxCurrentEntry->status == DATA_ENTRY_STATUS_FINISHED;
        }
    }

    // ---- CoreRadioCRCFiltering

    command void CoreRadioCRCFiltering.enableCRCFiltering() {
        rxCmd.rxConfig.bAutoFlushCrc = 1;
        // TODO(accek): restart listening or panic etc.
    }

    command void CoreRadioCRCFiltering.disableCRCFiltering() {
        rxCmd.rxConfig.bAutoFlushCrc = 0;
        // TODO(accek): restart listening or panic etc.
    }

    // ---- RSSI & LQI & CRC

    command int8_t RawFrameRSSI.getRSSI(platform_frame_t* framePtr) {
        rfcore_frame_t* rfcf = getRFCoreFrame(framePtr);
        return rfcf->extras.rssi;
    }

    command uint8_t RawFrameLQI.getLQI(platform_frame_t* framePtr) {
        rfcore_frame_t* rfcf = getRFCoreFrame(framePtr);
        return rfcf->extras.corr;
    }

    command bool RawFrameCRC.hasGoodCRC(platform_frame_t * framePtr) {
        rfcore_frame_t* rfcf = getRFCoreFrame(framePtr);
        return !rfcf->extras.crcerr;
    }

    command uint16_t RawFrameCRC.getCRC(platform_frame_t * framePtr) {
        rfcore_frame_t* rfcf = getRFCoreFrame(framePtr);
        return rfcf->extras.fcs;
    }

    command int8_t RawRSSI.getRSSI() {
        uint32_t cmd_status;
        if (!call RFCore.sendCmd(CMDR_DIR_CMD(CMD_GET_RSSI), &cmd_status, FALSE)) {
            return RAW_RSSI_INVALID;
        }
        return (cmd_status >> 16) & 0xff;
    }

    // ---- Timestamp

    command uint32_t RawFrameTimestamp.getTimestamp(platform_frame_t* framePtr) {
        rfcore_frame_t* rfcf = getRFCoreFrame(framePtr);

        // TODO(accek): this is a hack, as we have a 4MHz radio clock; RIMAC
        //              currently assumes that it's a 32kHz clock.
        //              We will need a new API for this.
        //              And the overflow is not handled.

        // 4000000/(65536/2) = 122,0703125
        return rfcf->extras.timestamp / 122;
    }

    // ---- Sleep prevention when radio is working

    event inline sleep_level_t AskBeforeSleep.maxSleepLevel() {
        return (state <= STATE_OFF) ? SLEEP_LEVEL_DEEP : SLEEP_LEVEL_IDLE;
    }

    // ---- Stats

    default async command inline void NumRadioInterruptsStat.increment(uint8_t increment) { }
    default async command inline void NumErrorInterruptsStat.increment(uint8_t increment) { }
    default command inline void NumSuccessfulRXStat.increment(uint8_t increment) { }
    default command inline void NumSuccessfulTXStat.increment(uint8_t increment) { }
    default command inline void NumSuccessfulBLEAdvTXStat.increment(uint8_t increment) { }
    default command inline void NumLengthErrorsStat.increment(uint8_t increment) { }
    default command inline void NumCRCErrorsStat.increment(uint8_t increment) { }
    default command inline void NumTXTimeoutErrorsStat.increment(uint8_t increment) { }
    default command inline void NumBLEAdvTimeoutErrorsStat.increment(uint8_t increment) { }

    // ---- Default BLE address

    default command void BLEAddressProvider.read(ble_address_t* addr) {
        /* Well, this is not good if we don't have a BLEAddressProvider
         * connected, but we allow this, as BLE may be unused.
         *
         * But... if it's used without BLEAddressProvider connected, we
         * use a clearly visible DE:AD:DE:AD:DE:AD address. */
        addr->bytes[0] = addr->bytes[2] = addr->bytes[4] = 0xde;
        addr->bytes[1] = addr->bytes[3] = addr->bytes[5] = 0xad;
    }

    // ---- Defaults

    default command inline void RadioOnLed.on() { }
    default command inline void RadioOnLed.off() { }
}
