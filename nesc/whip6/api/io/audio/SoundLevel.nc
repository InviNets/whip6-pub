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


interface SoundLevel {
    /* Returns the average sound level from samples received via the
     * AudioInput interface and resets the internal counters.
     *
     * The returned value is proportional to the total energy as a
     * fraction of the full scale energy (max is 2^30 if the input
     * is constantly 2^15 and ignoring the DC filtering). */
    command uint32_t getAccumulatedSoundLevel();
}
