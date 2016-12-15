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


/**
 * A generator of sequence numbers for
 * IEEE 802.15.4 frames.
 *
 * @author Konrad Iwanicki
 */
interface Ieee154FrameSequenceNumberGenerator
{

    /**
     * Generates a new sequence number.
     * @return The new sequence number.
     */
    command ieee154_frame_seq_no_t generateSeqNo();

}

