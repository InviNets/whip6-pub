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


#include <AudioVAD.h>

/* Voice Activity Detector */
interface AudioVAD {
    /* Signaled to provide a new information about voice detection result.
     * It should be generated periodically, with every processed
     * (algorithm-defined) window, even if the result does not change. */
    event void ready(vad_result_t result);
}
