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

interface CoreRadioSimpleAutoACK
{
    /**
     * Sets the filter that will be applied to the destination address of
     * incoming frames. Only packets, whose dst. address matches this
     * filter, will be received and auto-acknowledged.
     * @param panId - Must not be NULL.
     * @param extAddr - Must not be NULL.
     * @param shrtAddr - Can be NULL. In that case, only short address
     *                   that will match the filter is the boradcast
     *                   address 0xFFFF.
     */
    command void setDstAddrFilter(
            whip6_ieee154_pan_id_t const *panIdPtr,
            whip6_ieee154_ext_addr_t const *extAddrPtr,
            whip6_ieee154_short_addr_t const *shrtAddrPtr);

    /**
     * Orders the radio to auto-acknowledge incoming frames.
     *
     * While in this mode, if any of the following conditions is not met the
     * frame will be dropped by the radio driver without notifying
     * RawFrameSender:
     * - The frame must be a correct Ieee154 data frame.
     * - The destination address in the frame must match the address configured
     *   with setDstAddrFilter().
     *
     * If additionally, the ACK Request bit is set in the frame, and auto
     * acknowledgment will be sent.
     *
     * WARNING: Always enable the filtering before startReceiving, otherwise
     * an unfiltered packet might be received!
     */
    command void enebaleDataFrameFilteringAndAutoACK();

    /**
     * Turns off filtering and autoack.
     */
    command void disableDataFrameFilteringAndAutoACK();
}
