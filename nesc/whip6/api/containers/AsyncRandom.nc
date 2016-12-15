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

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 *
 * Interface definition for asynchronous generation of random bytes sequences.
 */
interface AsyncRandom {
    command error_t generateRandom(uint8_t_xdata *buffer, uint16_t length);

    event void generateRandomDone(error_t error, uint8_t_xdata *buffer, uint16_t length);
}
