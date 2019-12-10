/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <AudioFormat.h>

interface AudioFormatControl {
    /* Requests to set the given sample rate.
     *
     * Note that the actual rate set may differ if the exact one is
     * not available. The actual sample rate can be retrieved using
     * AudioFormat.getSampleRate(). */
    command void requestSampleRate(uint32_t sampleRate);
}
