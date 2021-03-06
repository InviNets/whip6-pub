/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <AudioVAD.h>

/* Voice Activity Detector */
interface AudioVAD {
    /* Signaled to provide a new information about voice detection result.
     * It should be generated periodically, with every processed
     * (algorithm-defined) window, even if the result does not change. */
    event void ready(vad_result_t result);
}
