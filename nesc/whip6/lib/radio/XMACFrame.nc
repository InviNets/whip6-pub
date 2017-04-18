/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


interface XMACFrame
{
    command bool isXMACFrame(platform_frame_t * frame);
    command void generateAck(platform_frame_t * strobe,
            platform_frame_t * ack);
    command bool isMatchingAck(platform_frame_t * frameToSend,
            platform_frame_t * potentialAck);
    command void generateStrobe(platform_frame_t * toSend,
            platform_frame_t * strobe);
    command bool isStrobeForMe(platform_frame_t * frame);
}
