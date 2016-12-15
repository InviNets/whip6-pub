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

#include "Ieee154.h"
#include "PlatformFrame.h"
#include <ieee154/ucIeee154FrameManipulation.h>



/**
 * An adapter that transforms a platform-specific
 * frame interfaces into IEEE 802.15.4 data frame interfaces.
 *
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 * @author Konrad Iwanicki
 * @author Przemyslaw Horban
 */
module PlatformFrameToIeee154FrameAdapterPrv
{
    provides
    {
        interface Ieee154UnpackedDataFrameAllocator as Ieee154FrameAllocator;
        interface Ieee154UnpackedDataFrameMetadata as Ieee154FrameMetadata;

#ifdef WHIP6_IEEE154_OLD_STACK
        interface Ieee154UnpackedDataFrameSender as Ieee154FrameSender;
        interface Ieee154UnpackedDataFrameReceiver as Ieee154FrameReceiver;
#endif // WHIP6_IEEE154_OLD_STACK
    }
    uses
    {
        interface ObjectAllocator<platform_frame_t> as PlatformFrameAllocator;
        interface RawFrame;

#ifdef WHIP6_IEEE154_OLD_STACK
        interface RawFrameSender;
        interface RawFrameReceiver;
#endif // WHIP6_IEEE154_OLD_STACK

        interface RawFrameLQI;
        interface RawFrameRSSI;
        interface StatsIncrementer<uint8_t> as NumSuccessfulFrameAllocsStat;
        interface StatsIncrementer<uint8_t> as NumFailedFrameAllocsStat;
        interface StatsIncrementer<uint8_t> as NumFrameDisposalsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulTransmissionStartsStat;
        interface StatsIncrementer<uint8_t> as NumFailedTransmissionStartsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulTransmissionCancelsStat;
        interface StatsIncrementer<uint8_t> as NumFailedTransmissionCancelsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulTransmissionCompletionsStat;
        interface StatsIncrementer<uint8_t> as NumFailedTransmissionCompletionsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulReceptionStartsStat;
        interface StatsIncrementer<uint8_t> as NumFailedReceptionStartsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulReceptionCancelsStat;
        interface StatsIncrementer<uint8_t> as NumFailedReceptionCancelsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulReceptionCompletionsStat;
        interface StatsIncrementer<uint8_t> as NumCorruptedReceptionCompletionsStat;
        interface StatsIncrementer<uint8_t> as NumFailedReceptionCompletionsStat;
    }
}
implementation
{


    static inline whip6_ieee154_dframe_info_t * platformFrameToDFrameInfo(
            platform_frame_t * platformFramePtr
    )
    {
        return &platformFramePtr->dframe_info;
    }



    static inline platform_frame_t * dframeInfoToPlatformFrame(
            whip6_ieee154_dframe_info_t * dframeInfoPtr
    )
    {
        return (platform_frame_t *)(((uint8_t_xdata *)dframeInfoPtr) -
                offsetof(platform_frame_t, dframe_info));
    }

    
    /*static void __printRawFrame(platform_frame_t * plaftormFramePtr)
    {
        uint8_t_xdata *   ptr;
        uint8_t           cnt;

        ptr = call RawFrame.getRawPointer(plaftormFramePtr);
        cnt = call RawFrame.maxRawLength();
        if (cnt > 0)
        {
            printf("%02x", (unsigned)(*ptr));
            ++ptr;
            for (--cnt; cnt > 0; --cnt)
            {
                printf(" %02x", (unsigned)(*ptr));
                ++ptr;
            }
        }
    }

#define local_dbgFrame(pref, fr) do { printf(pref); __printRawFrame(fr); printf("\r\n"); } while (0);*/
#define local_dbgFrame(pref, fr)
//#define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

    command whip6_ieee154_dframe_info_t * Ieee154FrameAllocator.allocFrame()
    {
        platform_frame_t *              plaftormFramePtr;
        whip6_ieee154_dframe_info_t *   dframeInfoPtr;

        plaftormFramePtr = call PlatformFrameAllocator.allocate();
        if (plaftormFramePtr == NULL)
        {
            call NumFailedFrameAllocsStat.increment(1);
            return NULL;
        }
        dframeInfoPtr = platformFrameToDFrameInfo(plaftormFramePtr);
        // NOTICE iwanicki 2013-09-04:
        // This just sets a buffer in the frame.
        dframeInfoPtr->bufferPtr = call RawFrame.getRawPointer(plaftormFramePtr);
        dframeInfoPtr->bufferLen = call RawFrame.maxRawLength();
        dframeInfoPtr->frameFlags = 0;
        local_dbg(
                "[Allocator] Alloc: pp=%p fp=%p bp=%p bl=%u\r\n",
                plaftormFramePtr, dframeInfoPtr,
                dframeInfoPtr->bufferPtr, (unsigned)dframeInfoPtr->bufferLen
        );
        call NumSuccessfulFrameAllocsStat.increment(1);
        return dframeInfoPtr;
    }



    command inline void Ieee154FrameAllocator.freeFrame(
            whip6_ieee154_dframe_info_t * dframeInfoPtr
    )
    {
        call NumFrameDisposalsStat.increment(1);
        local_dbg(
                "[Allocator] Free: pp=%p fp=%p bp=%p bl=%u\r\n",
                dframeInfoToPlatformFrame(dframeInfoPtr), dframeInfoPtr,
                dframeInfoPtr->bufferPtr, (unsigned)dframeInfoPtr->bufferLen
        );
        call PlatformFrameAllocator.free(
                dframeInfoToPlatformFrame(dframeInfoPtr)
        );
    }



    command inline bool Ieee154FrameMetadata.wasPhysicalSignalQualityHighUponRx(
            whip6_ieee154_dframe_info_t * dframeInfoPtr
    )
    {
        platform_frame_t * platformFramePtr = dframeInfoToPlatformFrame(dframeInfoPtr);
        return call RawFrameLQI.getLQI(platformFramePtr) >= 105;
    }



    command inline int8_t Ieee154FrameMetadata.getReceivedPhysicalSignalStrengthUponRx(
        whip6_ieee154_dframe_info_t * dframeInfoPtr
    )
    {
        platform_frame_t * platformFramePtr = dframeInfoToPlatformFrame(dframeInfoPtr);
        return call RawFrameRSSI.getRSSI(platformFramePtr);
    }
    
    
    
    command inline uint8_t Ieee154FrameMetadata.getPhysicalLinkQualityIndicatorUponRx(
        whip6_ieee154_dframe_info_t * dframeInfoPtr
    )
    {
        platform_frame_t * platformFramePtr = dframeInfoToPlatformFrame(dframeInfoPtr);
        return call RawFrameLQI.getLQI(platformFramePtr);
    }


#ifdef WHIP6_IEEE154_OLD_STACK
    command inline error_t Ieee154FrameSender.startSendingFrame(
            whip6_ieee154_dframe_info_t * dframeInfoPtr
    )
    {
        // NOTICE iwanicki 2013-09-04:
        // It is assumed that the received frame is correct.
        error_t   status;

        local_dbgFrame("The raw outgoing frame:", dframeInfoToPlatformFrame(dframeInfoPtr));

        status =
                call RawFrameSender.startSending(
                        dframeInfoToPlatformFrame(dframeInfoPtr)
                );
        if (status == SUCCESS)
        {
            call NumSuccessfulTransmissionStartsStat.increment(1);
        }
        else
        {
            call NumFailedTransmissionStartsStat.increment(1);
        }
        return status;
    }



    command inline error_t Ieee154FrameSender.stopSendingFrame(
            whip6_ieee154_dframe_info_t * dframeInfoPtr
    )
    {
        error_t   status;

        status =
                call RawFrameSender.cancelSending(
                        dframeInfoToPlatformFrame(dframeInfoPtr)
                );
        if (status == SUCCESS)
        {
            call NumSuccessfulTransmissionCancelsStat.increment(1);
        }
        else
        {
            call NumFailedTransmissionCancelsStat.increment(1);
        }
        return status;
    }



    event inline void RawFrameSender.sendingFinished(
            platform_frame_t * plaftormFramePtr,
            error_t status
    )
    {
        whip6_ieee154_dframe_info_t *   dframeInfoPtr;

        dframeInfoPtr = platformFrameToDFrameInfo(plaftormFramePtr);
        if (status == SUCCESS)
        {
            call NumSuccessfulTransmissionCompletionsStat.increment(1);
        }
        else
        {
            call NumFailedTransmissionCompletionsStat.increment(1);
        }
        signal Ieee154FrameSender.frameSendingFinished(dframeInfoPtr, status);
    }



    command inline error_t Ieee154FrameReceiver.startReceivingFrame(
        whip6_ieee154_dframe_info_t * dframeInfoPtr
    )
    {
        error_t   status;

        status =
                call RawFrameReceiver.startReceiving(
                        dframeInfoToPlatformFrame(dframeInfoPtr)
                );
        if (status == SUCCESS)
        {
            call NumSuccessfulReceptionStartsStat.increment(1);
        }
        else
        {
            call NumFailedReceptionStartsStat.increment(1);
        }
        return status;
    }



    command inline error_t Ieee154FrameReceiver.stopReceivingFrame(
        whip6_ieee154_dframe_info_t * dframeInfoPtr
    )
    {
        error_t   status;

        status =
                call RawFrameReceiver.cancelReceiving(
                        dframeInfoToPlatformFrame(dframeInfoPtr)
                );
        if (status == SUCCESS)
        {
            call NumSuccessfulReceptionCancelsStat.increment(1);
        }
        else
        {
            call NumFailedReceptionCancelsStat.increment(1);
        }
        return status;
    }



    event void RawFrameReceiver.receivingFinished(
            platform_frame_t * plaftormFramePtr,
            error_t status
    )
    {
        // NOTICE iwanicki 2013-09-04:
        // A correct frame must be passed
        // back to the higher layer.

        whip6_ieee154_dframe_info_t *   dframeInfoPtr;

        local_dbgFrame("The raw incoming frame:", plaftormFramePtr);

        dframeInfoPtr = platformFrameToDFrameInfo(plaftormFramePtr);
        if (status == SUCCESS)
        {
            if (whip6_ieee154DFrameInfoExisting(
                    dframeInfoPtr,
                    dframeInfoPtr->bufferPtr,
                    dframeInfoPtr->bufferLen) != WHIP6_NO_ERROR)
            {
                call NumCorruptedReceptionCompletionsStat.increment(1);
                status =
                        call RawFrameReceiver.startReceiving(
                                plaftormFramePtr
                        );
                if (status == SUCCESS)
                {
                    return;
                }
                status = FAIL;
                call NumFailedReceptionCompletionsStat.increment(1);
            }
            else
            {
                call NumSuccessfulReceptionCompletionsStat.increment(1);
            }
        }
        else
        {
            call NumFailedReceptionCompletionsStat.increment(1);
        }
        signal Ieee154FrameReceiver.frameReceivingFinished(
                dframeInfoPtr,
                status
        );
    }
#endif // WHIP6_IEEE154_OLD_STACK



    default command inline void NumSuccessfulFrameAllocsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumFailedFrameAllocsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumFrameDisposalsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumSuccessfulTransmissionStartsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumFailedTransmissionStartsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumSuccessfulTransmissionCancelsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumFailedTransmissionCancelsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumSuccessfulTransmissionCompletionsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumFailedTransmissionCompletionsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumSuccessfulReceptionStartsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumFailedReceptionStartsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumSuccessfulReceptionCancelsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumFailedReceptionCancelsStat.increment(
            uint8_t val
    )
    {
    }


    default command inline void NumSuccessfulReceptionCompletionsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumCorruptedReceptionCompletionsStat.increment(
            uint8_t val
    )
    {
    }

    default command inline void NumFailedReceptionCompletionsStat.increment(
            uint8_t val
    )
    {
    }
}

