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
 * An implementation of a generator of sequence
 * numbers for IEEE 802.15.4 frames.
 *
 * @author Konrad Iwanicki
 */
module Ieee154FrameSequenceNumberGeneratorPub
{
    provides interface Ieee154FrameSequenceNumberGenerator;
}
implementation
{

    ieee154_frame_seq_no_t   m_prevSeqNo = 0;

    command inline ieee154_frame_seq_no_t Ieee154FrameSequenceNumberGenerator.generateSeqNo()
    {
        return ++m_prevSeqNo;
    }
    
}

