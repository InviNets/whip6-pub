/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "Ieee154.h"
#include <6lowpan/uc6LoWPANFragmentation.h>
#include <6lowpan/uc6LoWPANHeaderManipulation.h>
#include <ipv6/ucIpv6PacketAllocation.h>



/**
 * A send queue for the fragmenter of 6LoWPAN frames.
 *
 * @param frag_packet_pool_size The maximal number of
 *   packets that can be concurrently fragmented.
 *
 * @author Konrad Iwanicki
 */
generic module LoWPANFragmenterSendQueueAdapterPrv(
    uint8_t frag_packet_pool_size
)
{
    provides
    {
        interface Ieee154UnpackedDataFrameSender as Ieee154FrameSender @exactlyonce();
    }
    uses
    {
        interface Bit as IsSendingBit @exactlyonce();
        interface Queue<whip6_ieee154_dframe_info_t *, uint8_t> as FrameQueue @exactlyonce();
        interface Ieee154UnpackedDataFrameSender as SubIeee154FrameSender @exactlyonce();
    }
}
implementation
{
    task void processQueueTask();



    command inline error_t Ieee154FrameSender.startSendingFrame(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        if (call FrameQueue.isFull())
        {
            return EBUSY;
        }
        call FrameQueue.enqueueLast(framePtr);
        post processQueueTask();
        return SUCCESS;
    }



    command error_t Ieee154FrameSender.stopSendingFrame(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        // TODO iwanicki 2013-05-04:
        // Currently, supporting cancel is not the top priority.
        // It requires changing the interface of the queue
        // to enable removing arbitrary elements.
        return EBUSY;
    }



    event inline void SubIeee154FrameSender.frameSendingFinished(
            whip6_ieee154_dframe_info_t * framePtr,
            error_t status
    )
    {
        if (call FrameQueue.peekFirst() != framePtr)
        {
            return;
        }
        call FrameQueue.dequeueFirst();
        call IsSendingBit.clear();
        post processQueueTask();
        signal Ieee154FrameSender.frameSendingFinished(framePtr, status);
    }



    task void processQueueTask()
    {
        whip6_ieee154_dframe_info_t *   framePtr;
        error_t                         status;
        if (call FrameQueue.isEmpty() || call IsSendingBit.isSet())
        {
            return;
        }
        framePtr = call FrameQueue.peekFirst();
        status = call SubIeee154FrameSender.startSendingFrame(framePtr);
        if (status == SUCCESS)
        {
            call IsSendingBit.set();
        }
        else
        {
            call FrameQueue.dequeueFirst();
            post processQueueTask();
            signal Ieee154FrameSender.frameSendingFinished(framePtr, status);
        }
    }

}
