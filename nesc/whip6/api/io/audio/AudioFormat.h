/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef AUDIO_FORMAT_H_INCLUDED
#define AUDIO_FORMAT_H_INCLUDED

typedef enum {
    AUDIO_FORMAT_PDM,
    AUDIO_FORMAT_PCM16,
    AUDIO_FORMAT_ALAW,
    AUDIO_FORMAT_MULAW,
    AUDIO_FORMAT_IMA_ADPCM,
} audio_sample_format_t;

#endif
