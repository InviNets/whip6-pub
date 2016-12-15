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

#include <6lowpan/uc6LoWPANNalpExtensionSoftwareAcknowledgments.h>
#include <ieee154/ucIeee154FrameManipulation.h>
#include "Ieee154.h"



/**
 * The main module of a platform-independent decorator
 * for an IEEE 802.15.4 stack that generates software
 * acknowledgments for all unicast packets that
 * employ 6LoWPAN NALP frames.
 *
 * @author Konrad Iwanicki
 */
generic module LoWPANSoftwareAcknowledgmentDecoratorPrv()
{
    provides
    {
        interface Ieee154UnpackedDataFrameReceiver as FrameReceiver @exactlyonce();
        interface Ieee154UnpackedDataFrameSender as FrameSender @exactlyonce();
    }
    uses
    {
        interface Ieee154UnpackedDataFrameReceiver as SubFrameReceiver @exactlyonce();
        interface Ieee154UnpackedDataFrameSender as SubFrameSender @exactlyonce();
        interface Ieee154UnpackedDataFrameAllocator as FrameAllocator @exactlyonce();
        interface Ieee154FrameSequenceNumberGenerator as FrameSequenceNumberGenerator @exactlyonce();
        interface Timer<TMilli, uint32_t> as AcknowledgmentTimeoutTimer @exactlyonce();
        interface ConfigValue<uint32_t> as TransmissionAndAcknowledgmentTimeoutInMillis @exactlyonce();
        interface Bit as AcknowledgmentReceivedBit;
        interface Bit as AcknowledgmentMissedBit;
        interface Bit as TransmissionFinishedBit;
        interface StatsIncrementer<uint8_t> as NumReceivedAcknowledgmentsForOutgoingFramesStat;
        interface StatsIncrementer<uint8_t> as NumMissedAcknowledgmentsForOutgoingFramesStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfullyGeneratedAcknowledgmentsForIncomingFramesStat;
    }
}
implementation
{

    whip6_ieee154_dframe_info_t *   m_outgoingUserFrame = NULL;
    whip6_ieee154_dframe_info_t *   m_outgoingAckFrame = NULL;



    error_t startSendingFrame();
    void finishSendingFrame(error_t status);
    void handleReceivedAckFrame(
            whip6_ieee154_dframe_info_t * framePtr,
            ieee154_frame_seq_no_t ackedFrameSeqNo
    );
    void handleReceivedRegularFrame(
            whip6_ieee154_dframe_info_t * framePtr
    );



    command error_t FrameSender.startSendingFrame(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        if (m_outgoingUserFrame != NULL)
        {
            return EBUSY;
        }
        m_outgoingUserFrame = framePtr;
        if (m_outgoingAckFrame != NULL)
        {
            return SUCCESS;
        }
        return startSendingFrame();
    }



    error_t startSendingFrame()
    {
        error_t   status;

        status = call SubFrameSender.startSendingFrame(m_outgoingUserFrame);
        if (status != SUCCESS)
        {
            m_outgoingUserFrame = NULL;
            return status;
        }
        if (whip6_ieee154DFrameInfoCheckIfDestinationIsBroadcast(m_outgoingUserFrame) != 0)
        {
            call AcknowledgmentReceivedBit.set();
        }
        else
        {
            call AcknowledgmentTimeoutTimer.startWithTimeoutFromNow(
                    call TransmissionAndAcknowledgmentTimeoutInMillis.get()
            );
            call AcknowledgmentReceivedBit.clear();
        }
        call AcknowledgmentMissedBit.clear();
        call TransmissionFinishedBit.clear();
        return SUCCESS;
    }



    command error_t FrameSender.stopSendingFrame(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        error_t   status = SUCCESS;
        if (m_outgoingUserFrame != framePtr)
        {
            status = EINVAL;
            goto RETURN_STATUS;
        }
        if (m_outgoingAckFrame != NULL)
        {
            goto SENDING_STOPPED;
        }
        if (call TransmissionFinishedBit.isSet())
        {
            goto SENDING_STOPPED;
        }
        status = call SubFrameSender.stopSendingFrame(framePtr);
        if (status != SUCCESS)
        {
            goto RETURN_STATUS;
        }
    SENDING_STOPPED:
        // status == SUCCESS
        call AcknowledgmentTimeoutTimer.stop();
        m_outgoingUserFrame = NULL;
    RETURN_STATUS:
        return status;
    }



    event void SubFrameSender.frameSendingFinished(
            whip6_ieee154_dframe_info_t * framePtr,
            error_t status
    )
    {
        if (framePtr == m_outgoingUserFrame)
        {
            call TransmissionFinishedBit.set();
            if (status != SUCCESS && status != ENOACK)
            {
                finishSendingFrame(status);
            }
            else if (call AcknowledgmentReceivedBit.isSet())
            {
                finishSendingFrame(SUCCESS);
            }
            else if (call AcknowledgmentMissedBit.isSet())
            {
                call NumMissedAcknowledgmentsForOutgoingFramesStat.increment(1);
                finishSendingFrame(ENOACK);
            }
        }
        else if (framePtr == m_outgoingAckFrame)
        {
            call FrameAllocator.freeFrame(m_outgoingAckFrame);
            m_outgoingAckFrame = NULL;
            if (m_outgoingUserFrame != NULL)
            {
                framePtr = m_outgoingUserFrame;
                status = startSendingFrame();
                if (status != SUCCESS)
                {
                    signal FrameSender.frameSendingFinished(framePtr, status);
                }
            }
        }
    }



    event void AcknowledgmentTimeoutTimer.fired()
    {
        if (m_outgoingUserFrame != NULL)
        {
            call AcknowledgmentMissedBit.set();
            if (call TransmissionFinishedBit.isSet())
            {
                call NumMissedAcknowledgmentsForOutgoingFramesStat.increment(1);
                finishSendingFrame(ENOACK);
            }
        }
    }



    void finishSendingFrame(error_t status)
    {
        whip6_ieee154_dframe_info_t *   framePtr;

        call AcknowledgmentTimeoutTimer.stop();
        framePtr = m_outgoingUserFrame;
        m_outgoingUserFrame = NULL;
        signal FrameSender.frameSendingFinished(framePtr, status);
    }



    command inline error_t FrameReceiver.startReceivingFrame(
        whip6_ieee154_dframe_info_t * framePtr
    )
    {
        return call SubFrameReceiver.startReceivingFrame(framePtr);
    }



    command inline error_t FrameReceiver.stopReceivingFrame(
        whip6_ieee154_dframe_info_t * framePtr
    )
    {
        return call SubFrameReceiver.stopReceivingFrame(framePtr);
    }



    event void SubFrameReceiver.frameReceivingFinished(
        whip6_ieee154_dframe_info_t * framePtr,
        error_t status
    )
    {
        ieee154_frame_seq_no_t   ackedFrameSeqNo = 0;

        if (status == SUCCESS)
        {
            if (whip6_lowpanNalpExtSoftwareAcknowledgmentIsAckFrame(framePtr, &ackedFrameSeqNo) != 0)
            {
                // Received an acknowledgment frame.
                handleReceivedAckFrame(framePtr, ackedFrameSeqNo);
            }
            else
            {
                // Received an nonacknowledgment frame.
                handleReceivedRegularFrame(framePtr);
            }
        }
        else
        {
            signal FrameReceiver.frameReceivingFinished(framePtr, status);
        }
    }



    void handleReceivedAckFrame(
            whip6_ieee154_dframe_info_t * framePtr,
            ieee154_frame_seq_no_t ackedFrameSeqNo
    )
    {
        if (m_outgoingUserFrame != NULL)
        {
            // NOTICE iwanicki 2013-09-16:
            // We may want to compare the source address
            // from the ack frame with the destination address
            // of the outgoing frame. Let's ignore this
            // for a while, though.
            if (whip6_ieee154DFrameGetSeqNo(m_outgoingUserFrame) == ackedFrameSeqNo)
            {
                call NumReceivedAcknowledgmentsForOutgoingFramesStat.increment(1);
                call AcknowledgmentReceivedBit.set();
                call AcknowledgmentTimeoutTimer.stop();
                if (call TransmissionFinishedBit.isSet())
                {
                    finishSendingFrame(SUCCESS);
                }
            }
        }
        if (call SubFrameReceiver.startReceivingFrame(framePtr) != SUCCESS)
        {
            signal FrameReceiver.frameReceivingFinished(framePtr, FAIL);
        }
    }



    void handleReceivedRegularFrame(whip6_ieee154_dframe_info_t * framePtr)
    {
        if (m_outgoingUserFrame == NULL && m_outgoingAckFrame == NULL)
        {
            m_outgoingAckFrame = call FrameAllocator.allocFrame();
            if (m_outgoingAckFrame != NULL)
            {
                if (whip6_lowpanNalpExtSoftwareAcknowledgmentCreateAckFrame(m_outgoingAckFrame, framePtr) != 0)
                {
                    whip6_ieee154DFrameSetSeqNo(
                            m_outgoingAckFrame,
                            call FrameSequenceNumberGenerator.generateSeqNo()
                    );
                    if (call SubFrameSender.startSendingFrame(m_outgoingAckFrame) != SUCCESS)
                    {
                        call FrameAllocator.freeFrame(m_outgoingAckFrame);
                        m_outgoingAckFrame = NULL;
                    }
                    else
                    {
                        call NumSuccessfullyGeneratedAcknowledgmentsForIncomingFramesStat.increment(1);
                    }
                }
                else
                {
                    call FrameAllocator.freeFrame(m_outgoingAckFrame);
                    m_outgoingAckFrame = NULL;
                }
            }
        }
        signal FrameReceiver.frameReceivingFinished(framePtr, SUCCESS);
    }



    default inline command void NumReceivedAcknowledgmentsForOutgoingFramesStat.increment(uint8_t val)
    {
    }



    default inline command void NumMissedAcknowledgmentsForOutgoingFramesStat.increment(uint8_t val)
    {
    }



    default inline command void NumSuccessfullyGeneratedAcknowledgmentsForIncomingFramesStat.increment(uint8_t val)
    {
    }
}

