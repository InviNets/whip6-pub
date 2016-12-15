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
  * Interface for getting and setting the internal 32bit state of
  * a random number generator.
  */
interface RandomState
{
    /**
     * @return Returns the 32-bit generator internal state.
     */
    command uint32_t getState();

    /**
     * Sets the random generator internal state.
     */
    command void setState(uint32_t state);
}


