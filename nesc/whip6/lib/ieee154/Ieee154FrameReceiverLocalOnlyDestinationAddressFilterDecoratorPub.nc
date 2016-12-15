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

#include <ieee154/ucIeee154FrameManipulation.h>
#include "Ieee154.h"



/**
 * A platform-independent decorator for a receiver
 * of IEEE 802.15.4 frames that checks whether the
 * received frames are destined for the present node.
 * If not, their reception is not signaled up.
 *
 * @author Konrad Iwanicki
 */
generic module Ieee154FrameReceiverLocalOnlyDestinationAddressFilterDecoratorPub()
{
    provides
    {
        interface Ieee154UnpackedDataFrameReceiver as FrameReceiver;
    }
    uses
    {
        interface Ieee154UnpackedDataFrameReceiver as SubFrameReceiver;
        interface Ieee154LocalAddressProvider as AddressProvider;
        interface StatsIncrementer<uint8_t> as NumSuccessfullyReceivedFramesForMeStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfullyReceivedFramesForSomebodyElseStat;
    }
}
implementation
{
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
        if (status == SUCCESS)
        {
            uint8_t   isForMe;
            isForMe =
                    whip6_ieee154DFrameInfoCheckIfDestinationMatches(
                            framePtr,
                            call AddressProvider.getPanIdPtr(),
                            call AddressProvider.hasShortAddr() ?
                                call AddressProvider.getShortAddrPtr() : NULL,
                            call AddressProvider.getExtAddrPtr()
                    );
            if (isForMe == 0)
            {
                call NumSuccessfullyReceivedFramesForSomebodyElseStat.increment(1);
                status = call SubFrameReceiver.startReceivingFrame(framePtr);
                if (status == SUCCESS)
                {
                    // Ignore the reception.
                    return;
                }
                status = FAIL;
            }
            else
            {
                call NumSuccessfullyReceivedFramesForMeStat.increment(1);
            }
        }
        signal FrameReceiver.frameReceivingFinished(framePtr, status);
    }
    
    
    
    default event inline void FrameReceiver.frameReceivingFinished(
        whip6_ieee154_dframe_info_t * framePtr,
        error_t status
    )
    {
        // Do nothing.
    }



    default command inline void NumSuccessfullyReceivedFramesForMeStat.increment(
            uint8_t val
    )
    {
    }



    default command inline void NumSuccessfullyReceivedFramesForSomebodyElseStat.increment(
            uint8_t val
    )
    {
    }

}

