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

#include <ieee154/ucIeee154AddressManipulation.h>
#include <ieee154/ucIeee154FrameManipulation.h>

module PlatformFrameToXMACFrameAdapterPrv {
    provides interface XMACFrame;
    uses interface RawFrame;
    uses interface Ieee154LocalAddressProvider as AddressProvider;
}
implementation {
    // These are non-standard, reserved codes, per IEEE 802.15.4.
    const uint8_t XMAC_STROBE_TYPE = 6;
    const uint8_t XMAC_ACK_TYPE = 7;

    const uint8_t XMAC_PKT_LEN = 3;

    static inline whip6_ieee154_dframe_info_t * platformFrameToDFrameInfo(
            platform_frame_t * platformFramePtr) {
        return &platformFramePtr->dframe_info;
    }

    static inline uint16_t frameToCode(platform_frame_t * frame) {
        whip6_ieee154_dframe_info_t * dframe
                = platformFrameToDFrameInfo(frame);
        static ieee154_addr_t_xdata dstAddr;
        whip6_ieee154DFrameGetDstAddr(dframe, &dstAddr);
        if (dstAddr.mode == IEEE154_ADDR_MODE_EXT) {
            return dstAddr.vars.ext.data[1] << 8 |
                    dstAddr.vars.ext.data[0];
        } else if (dstAddr.mode == IEEE154_ADDR_MODE_SHORT) {
            return dstAddr.vars.shrt.data[1] << 8 |
                    dstAddr.vars.shrt.data[0];
        } else {
            return 0;
        }
    }

    command bool XMACFrame.isXMACFrame(platform_frame_t * frame) {
        uint8_t_xdata* payload;
        if (call RawFrame.getLength(frame) != XMAC_PKT_LEN)
            return FALSE;
        payload = call RawFrame.getData(frame);
        return payload[0] == XMAC_STROBE_TYPE || payload[0] == XMAC_ACK_TYPE;
    }

    command void XMACFrame.generateAck(platform_frame_t * strobe,
            platform_frame_t * ack) {
        uint8_t_xdata* strobePayload = call RawFrame.getData(strobe);
        uint8_t_xdata* ackPayload = call RawFrame.getData(ack);
        ackPayload[0] = XMAC_ACK_TYPE;
        ackPayload[1] = strobePayload[1];
        ackPayload[2] = strobePayload[2];
        call RawFrame.setLength(ack, XMAC_PKT_LEN);
    }

    command bool XMACFrame.isMatchingAck(platform_frame_t * frameToSend,
            platform_frame_t * potentialAck) {
        uint16_t xmacCode = frameToCode(frameToSend);
        uint8_t_xdata* ackPayload = call RawFrame.getData(potentialAck);
        return ackPayload[0] == XMAC_ACK_TYPE &&
               ackPayload[1] == (xmacCode & 0xff) &&
               ackPayload[2] == (xmacCode >> 8);
    }

    command void XMACFrame.generateStrobe(platform_frame_t * toSend,
            platform_frame_t * strobe) {
        uint16_t xmacCode = frameToCode(toSend);
        uint8_t_xdata* strobePayload = call RawFrame.getData(strobe);
        strobePayload[0] = XMAC_STROBE_TYPE;
        strobePayload[1] = (xmacCode & 0xff);
        strobePayload[2] = (xmacCode >> 8);
        call RawFrame.setLength(strobe, XMAC_PKT_LEN);
    }

    command bool XMACFrame.isStrobeForMe(platform_frame_t * frame) {
        uint8_t_xdata* payload = call RawFrame.getData(frame);
        whip6_ieee154_short_addr_t const * saddr;
        whip6_ieee154_ext_addr_t const * laddr;

        if (payload[0] != XMAC_STROBE_TYPE)
            return FALSE;

        if (call AddressProvider.hasShortAddr()) {
            saddr = call AddressProvider.getShortAddrPtr();
            if (payload[1] == saddr->data[0] &&
                    payload[2] == saddr->data[1])
                return TRUE;
        }

        laddr = call AddressProvider.getExtAddrPtr();
        return payload[1] == laddr->data[0] &&
                payload[2] == laddr->data[1];
    }
}
