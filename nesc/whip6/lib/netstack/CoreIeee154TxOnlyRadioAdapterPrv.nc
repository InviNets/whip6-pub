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




/**
 * An adapter of the radio for the IEEE 802.15.4 stack
 * for platforms based on the Whisper Core platform
 * that disables radio reception, effectively
 * transforming the radio into a pure transmitter.
 *
 * @author Konrad Iwanicki
 */
generic module CoreIeee154TxOnlyRadioAdapterPrv()
{
    provides
    {
        interface Ieee154UnpackedDataFrameSender as Ieee154FrameSender;
        interface Ieee154UnpackedDataFrameReceiver as Ieee154FrameReceiver;
    }
    uses
    {
        interface Ieee154UnpackedDataFrameSender as SubIeee154FrameSender;
        interface Ieee154UnpackedDataFrameReceiver as SubIeee154FrameReceiver;
    }
}
implementation
{
    whip6_ieee154_dframe_info_t *   m_recvFramePtr = NULL;
    

    command inline error_t Ieee154FrameSender.startSendingFrame(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        return call SubIeee154FrameSender.startSendingFrame(framePtr);
    }



    command inline error_t Ieee154FrameSender.stopSendingFrame(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        return call SubIeee154FrameSender.stopSendingFrame(framePtr);
    }



    event inline void SubIeee154FrameSender.frameSendingFinished(
            whip6_ieee154_dframe_info_t * framePtr,
            error_t status
    )
    {
        if (status == ENOACK)
        {
            status = SUCCESS;
        }
        signal Ieee154FrameSender.frameSendingFinished(framePtr, status);
    }

    

    command error_t Ieee154FrameReceiver.startReceivingFrame(
        whip6_ieee154_dframe_info_t * framePtr
    )
    {
        if (framePtr == NULL)
        {
            return EINVAL;
        }
        if (m_recvFramePtr != NULL)
        {
            return EBUSY;
        }
        m_recvFramePtr = framePtr;
        return SUCCESS;
    }



    command error_t Ieee154FrameReceiver.stopReceivingFrame(
        whip6_ieee154_dframe_info_t * framePtr
    )
    {
        if (framePtr == NULL || framePtr != m_recvFramePtr)
        {
            return EINVAL;
        }
        m_recvFramePtr = NULL;
        return SUCCESS;
    }



    event inline void SubIeee154FrameReceiver.frameReceivingFinished(
        whip6_ieee154_dframe_info_t * framePtr,
        error_t status
    )
    {
        // NOTICE iwanicki 2014-01-12:
        // Should never be invoked.
    }
}

