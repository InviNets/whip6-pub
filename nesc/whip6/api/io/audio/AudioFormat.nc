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


#include <AudioFormat.h>

interface AudioFormat {
    command uint32_t getSampleRate();
    command audio_sample_format_t getSampleFormat();
    command uint8_t getNumChannels();
}
