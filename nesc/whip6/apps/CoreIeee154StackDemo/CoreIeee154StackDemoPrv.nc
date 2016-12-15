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


#include <ieee154/ucIeee154AddressManipulation.h>
#include <ieee154/ucIeee154FrameManipulation.h>
#include "CoreIeee154StackDemo.h"



/**
 * The main module of an application
 * demonstrating the IEEE 802.15.4 stack
 * for platforms compatible with WhisperCore.
 *
 * @author Konrad Iwanicki
 */
module CoreIeee154StackDemoPrv
{
    provides
    {
        interface ConfigValue<uint32_t> as TransmissionAndAcknowledgmentTimeoutInMillis;
    }
    uses
    {
        interface Boot;
        interface SynchronousStarter as Ieee154StackStart;
        interface Ieee154UnpackedDataFrameAllocator as Ieee154FrameAllocator;
        interface Ieee154UnpackedDataFrameReceiver as Ieee154FrameReceiver;
        interface Ieee154UnpackedDataFrameSender as Ieee154FrameSender;
        interface Ieee154LocalAddressProvider;
        interface Timer<TMilli, uint32_t> as BeaconTimer;
        interface Timer<TMilli, uint32_t> as TargetTimer;
        interface Timer<TMilli, uint32_t> as StatsTimer;
        interface Random;
        interface CommonObjectPrinter;
        interface StatsRegistry;
    }    
}
implementation
{

    whip6_ieee154_dframe_info_t *   m_incomingFrame = NULL;

    whip6_ieee154_dframe_info_t *   m_currBeaconFrame = NULL;
    uint32_t                        m_currBeaconNo = 0;

    whip6_ieee154_dframe_info_t *   m_currTargetFrame = NULL;
    uint32_t                        m_currTargetNo = 0;

    whip6_ieee154_frame_seq_no_t    m_frameSeqNo = 0;

    whip6_ieee154_addr_t            m_addrBuf;
    whip6_ieee154_addr_t            m_neighborAddr;


    task void printStatsTask();

    void restartBeaconTimer();
    void restartTargetTimerIfNecessary();
    whip6_ieee154_dframe_info_t * createBeaconFrame();
    void processReceivedFrame(whip6_ieee154_dframe_info_t * framePtr);
    whip6_ieee154_dframe_info_t * createFrameWithSeqNo(
            whip6_ieee154_addr_t const * addr,
            uint32_t seqNo
    );

    

    event void Boot.booted()
    {
        error_t   err;

        m_incomingFrame = call Ieee154FrameAllocator.allocFrame();
        if (m_incomingFrame == NULL)
        {
            printf("[Demo] ERROR: Unable to allocate a buffer for incoming frames!\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        err = call Ieee154StackStart.start();
        if (err != SUCCESS && err != EALREADY)
        {
            printf("[Demo] ERROR: Unable to start the IEEE 802.15.4 stack!\r\n");
            goto FAILURE_ROLLBACK_1;
        }
        err = call Ieee154FrameReceiver.startReceivingFrame(m_incomingFrame);
        if (err != SUCCESS)
        {
            printf("[Demo] ERROR: Unable to start receiving a frame!\r\n");
            goto FAILURE_ROLLBACK_1;
        }
        m_currBeaconFrame = NULL;
        m_currTargetFrame = NULL;
        restartBeaconTimer();
        whip6_ieee154AddrAnySetNone(&m_neighborAddr);
        call StatsTimer.startWithTimeoutFromNow(STATS_TIMER_PERIOD_IN_MILLIS);
        printf("[Demo] Successfully started the IEEE 802.15.4 stack.\r\n");
        return;

    FAILURE_ROLLBACK_1:
        call Ieee154FrameAllocator.freeFrame(m_incomingFrame);
        m_incomingFrame = NULL;
    FAILURE_ROLLBACK_0:
        return;
    }



    void restartBeaconTimer()
    {
        uint32_t   dt;
        dt =
                (BEACON_TIMER_PERIOD_IN_MILLIS >> 1) +
                    (call Random.rand16() % (BEACON_TIMER_PERIOD_IN_MILLIS >> 1));
        printf("[Demo] The beacon timer will fire within %lu ms.\r\n", (long unsigned)dt);
        call BeaconTimer.startWithTimeoutFromNow(dt);
    }



    void restartTargetTimerIfNecessary()
    {
        uint32_t   dt;
        if (! call TargetTimer.isRunning())
        {
            dt =
                    (TARGET_TIMER_DELAY_IN_MILLIS >> 1) +
                        (call Random.rand16() % (TARGET_TIMER_DELAY_IN_MILLIS >> 1));
            printf("[Demo] The target timer will fire within %lu ms.\r\n", (long unsigned)dt);
            call TargetTimer.startWithTimeoutFromNow(dt);
        }
    }



    event void BeaconTimer.fired()
    {
        whip6_ieee154_dframe_info_t *   framePtr;
        error_t                         frameStatus;
        printf("[Demo] The beacon timer has fired.\r\n");
        if (m_currBeaconFrame != NULL || m_currTargetFrame != NULL)
        {
            printf("[Demo] The application is still sending some data. Skipping a beacon.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        whip6_ieee154AddrAnySetBroadcast(&m_addrBuf);
        framePtr = createFrameWithSeqNo(&m_addrBuf, m_currBeaconNo);
        if (framePtr == NULL)
        {
            printf("[Demo] Unable to create a beacon frame. Skipping a beacon.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        printf("[Demo] Prepared a frame: ");
        call CommonObjectPrinter.printIeee154DFrameInfo(framePtr);
        printf(".\r\n");
        frameStatus = call Ieee154FrameSender.startSendingFrame(framePtr);
        if (frameStatus != SUCCESS)
        {
            printf("[Demo] Error %u while sending a beacon frame.\r\n", (unsigned)frameStatus);
            goto FAILURE_ROLLBACK_1;
        }
        restartBeaconTimer();
        m_currBeaconFrame = framePtr;
        printf("[Demo] Started sending beacon no. %lu.\r\n", (long unsigned)m_currBeaconNo);
        return;

    FAILURE_ROLLBACK_1:
        call Ieee154FrameAllocator.freeFrame(framePtr);
    FAILURE_ROLLBACK_0:
        restartBeaconTimer();
    }



    whip6_ieee154_dframe_info_t * createFrameWithSeqNo(
            whip6_ieee154_addr_t const * addr,
            uint32_t seqNo
    )
    {
        whip6_ieee154_dframe_info_t *   framePtr;
        uint8_t_xdata *                 payloadPtr;

        framePtr = call Ieee154FrameAllocator.allocFrame();
        if (framePtr == NULL)
        {
            goto FAILURE_ROLLBACK_0;
        }
        if (whip6_ieee154DFrameInfoReinitializeFrameForAddresses(
                    framePtr,
                    addr,
                    call Ieee154LocalAddressProvider.getAddrPtr(),
                    call Ieee154LocalAddressProvider.getPanIdPtr(),
                    NULL
                ) != WHIP6_NO_ERROR)
        {
            goto FAILURE_ROLLBACK_1;
        }
        whip6_ieee154DFrameSetSeqNo(framePtr, ++m_frameSeqNo);
        payloadPtr = whip6_ieee154DFrameGetPayloadPtr(framePtr, sizeof(uint32_t));
        if (payloadPtr == NULL)
        {
            goto FAILURE_ROLLBACK_1;
        }
        *payloadPtr = (uint8_t)(seqNo >> 24);
        ++payloadPtr;
        *payloadPtr = (uint8_t)(seqNo >> 16);
        ++payloadPtr;
        *payloadPtr = (uint8_t)(seqNo >> 8);
        ++payloadPtr;
        *payloadPtr = (uint8_t)(seqNo);
        whip6_ieee154DFrameSetPayloadLen(framePtr, sizeof(uint32_t));
        return framePtr;
    FAILURE_ROLLBACK_1:
        call Ieee154FrameAllocator.freeFrame(framePtr);
    FAILURE_ROLLBACK_0:
        return NULL;
    }



    event void Ieee154FrameSender.frameSendingFinished(
            whip6_ieee154_dframe_info_t * framePtr,
            error_t status
    )
    {
        if (framePtr == m_currBeaconFrame)
        {
            if (status == SUCCESS)
            {
                printf("[Demo] Finished sending beacon no. %lu with success.\r\n",
                    (long unsigned)m_currBeaconNo);
            }
            else
            {
                printf("[Demo] Finished sending beacon no. %lu with error %u.\r\n",
                    (long unsigned)m_currBeaconNo, (unsigned)status);
            }
            call Ieee154FrameAllocator.freeFrame(framePtr);
            m_currBeaconFrame = NULL;
            ++m_currBeaconNo;
        }
        else if (framePtr == m_currTargetFrame)
        {
            if (status == SUCCESS || status == ENOACK)
            {
                printf("[Demo] Finished sending targeted frame no. %lu %s.\r\n",
                    (long unsigned)m_currTargetNo, status == SUCCESS ?
                        "with success" : ", but without an acknowledgment");
            }
            else
            {
                printf("[Demo] Finished sending targeted frame no. %lu with error %u.\r\n",
                    (long unsigned)m_currTargetNo, (unsigned)status);
            }
            call Ieee154FrameAllocator.freeFrame(framePtr);
            m_currTargetFrame = NULL;
            ++m_currTargetNo;
        }
        else
        {
            printf("[Demo] ERROR: A frame sending completion notification reported for an erroneous frame!\r\n");
        }
    }



    event void Ieee154FrameReceiver.frameReceivingFinished(
            whip6_ieee154_dframe_info_t * framePtr,
            error_t status
    )
    {
        if (m_incomingFrame == framePtr)
        {
            if (status == SUCCESS)
            {
                printf("[Demo] Finished receiving a frame with success.\r\n");
                processReceivedFrame(framePtr);
            }
            else
            {
                printf("[Demo] Finished receiving a frame with error %u.\r\n", (unsigned)status);
            }
            if (call Ieee154FrameReceiver.startReceivingFrame(m_incomingFrame) != SUCCESS)
            {
                printf("[Demo] ERROR: Unable to start receiving a frame!\r\n");
                call Ieee154FrameAllocator.freeFrame(m_incomingFrame);
                m_incomingFrame = NULL;
            }
        }
        else
        {
            printf("[Demo] ERROR: A frame receiving completion notification reported for an erroneous frame!\r\n");
        }
    }



    void processReceivedFrame(whip6_ieee154_dframe_info_t * framePtr)
    {
        uint32_t          seqNo;
        uint8_t_xdata *   payloadPtr;
        whip6_ieee154DFrameGetDstAddr(framePtr, &m_addrBuf);
        if (whip6_ieee154AddrAnyIsBroadcast(&m_addrBuf))
        {
            whip6_ieee154DFrameGetSrcAddr(framePtr, &m_neighborAddr);
            printf("[Demo] The received frame is a beacon from a node with address ");
            call CommonObjectPrinter.printIeee154AddrAny(&m_neighborAddr);
            printf(".\r\n");
            printf("[Demo] The received frame: ");
            call CommonObjectPrinter.printIeee154DFrameInfo(framePtr);
            printf(".\r\n");
            if (whip6_ieee154DFrameGetPayloadLen(framePtr) != sizeof(uint32_t))
            {
                printf("[Demo] ERROR: The received beacon frame has an invalid length, %u!\r\n",
                    (unsigned)whip6_ieee154DFrameGetPayloadLen(framePtr));
                return;
            }
            payloadPtr = whip6_ieee154DFrameGetPayloadPtr(framePtr, sizeof(uint32_t));
            if (payloadPtr == NULL)
            {
                printf("[Demo] ERROR: The received beacon frame has an invalid payload!\r\n");
                return;
            }
            seqNo = ((uint32_t)(*payloadPtr) << 24);
            ++payloadPtr;
            seqNo |= ((uint32_t)(*payloadPtr) << 16);
            ++payloadPtr;
            seqNo |= ((uint32_t)(*payloadPtr) << 8);
            ++payloadPtr;
            seqNo |= ((uint32_t)(*payloadPtr));
            printf("[Demo] The received beacon frame has no. %lu.\r\n", (long unsigned)seqNo);
            restartTargetTimerIfNecessary();
        }
        else
        {
            whip6_ieee154DFrameGetSrcAddr(framePtr, &m_addrBuf);
            printf("[Demo] The received frame is a targeted frame from a node with address ");
            call CommonObjectPrinter.printIeee154AddrAny(&m_addrBuf);
            printf(".\r\n");
            printf("[Demo] The received frame: ");
            call CommonObjectPrinter.printIeee154DFrameInfo(framePtr);
            printf(".\r\n");
            if (whip6_ieee154DFrameGetPayloadLen(framePtr) != sizeof(uint32_t))
            {
                printf("[Demo] ERROR: The received targeted frame has an invalid length, %u!\r\n",
                    (unsigned)whip6_ieee154DFrameGetPayloadLen(framePtr));
                return;
            }
            payloadPtr = whip6_ieee154DFrameGetPayloadPtr(framePtr, sizeof(uint32_t));
            if (payloadPtr == NULL)
            {
                printf("[Demo] ERROR: The received targeted frame has an invalid payload!\r\n");
                return;
            }
            seqNo = ((uint32_t)(*payloadPtr) << 24);
            ++payloadPtr;
            seqNo |= ((uint32_t)(*payloadPtr) << 16);
            ++payloadPtr;
            seqNo |= ((uint32_t)(*payloadPtr) << 8);
            ++payloadPtr;
            seqNo |= ((uint32_t)(*payloadPtr));
            printf("[Demo] The received targeted frame has no. %lu.\r\n", (long unsigned)seqNo);
        }
    }



    event void TargetTimer.fired()
    {
        whip6_ieee154_dframe_info_t *   framePtr;
        error_t                         frameStatus;

        printf("[Demo] The target timer has fired.\r\n");
        if (m_currBeaconFrame != NULL || m_currTargetFrame != NULL)
        {
            printf("[Demo] The application is still sending some data. Skipping a targeted frame.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        framePtr = createFrameWithSeqNo(&m_neighborAddr, m_currTargetNo);
        if (framePtr == NULL)
        {
            printf("[Demo] Unable to create a targeted frame. Skipping a targeted frame.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        printf("[Demo] Prepared a frame: ");
        call CommonObjectPrinter.printIeee154DFrameInfo(framePtr);
        printf(".\r\n");
        frameStatus = call Ieee154FrameSender.startSendingFrame(framePtr);
        if (frameStatus != SUCCESS)
        {
            printf("[Demo] Error %u while sending a targeted frame.\r\n", (unsigned)frameStatus);
            goto FAILURE_ROLLBACK_1;
        }
        m_currTargetFrame = framePtr;
        printf("[Demo] Started sending targeted frame no. %lu.\r\n", (long unsigned)m_currTargetNo);
        return;

    FAILURE_ROLLBACK_1:
        call Ieee154FrameAllocator.freeFrame(framePtr);
    FAILURE_ROLLBACK_0:
        return;
    }



    event void StatsTimer.fired()
    {
        post printStatsTask();
        call StatsTimer.startWithTimeoutFromNow(STATS_TIMER_PERIOD_IN_MILLIS);
    }



    task void printStatsTask()
    {
        printf("[Demo] STATS:\r\n[Demo]    ");
        call StatsRegistry.printAll("\r\n[Demo]    ");
        printf("\r\n");
    }



    command inline uint32_t TransmissionAndAcknowledgmentTimeoutInMillis.get()
    {
        return SOFTWARE_ACK_DELAY_IN_MILLIS;
    }
}

