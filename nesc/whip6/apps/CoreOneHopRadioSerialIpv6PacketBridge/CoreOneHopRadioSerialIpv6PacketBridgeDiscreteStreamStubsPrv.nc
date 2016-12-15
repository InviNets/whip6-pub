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

#include <base/ucIoVec.h>


/**
 * A stub of discrete stream operations for the
 * application that forms an IPv6 bridge between
 * a one-hop radio network and a serial interface.
 *
 * This component can be used until the operations
 * have been implemented.
 *
 * @author Konrad Iwanicki
 */
module CoreOneHopRadioSerialIpv6PacketBridgeDiscreteStreamStubsPrv
{
    provides
    {
        interface DiscreteStreamWriter;
        interface DiscreteStreamReader;
    }
}
implementation
{
    command inline error_t DiscreteStreamWriter.startWritingDataUnit(
            whip6_iov_blist_t * iov,
            size_t size
    )
    {
        return EBUSY;
    }



    command inline error_t DiscreteStreamReader.startReadingDataUnit(
            size_t maxSize
    )
    {
        return EBUSY;
    }
}

