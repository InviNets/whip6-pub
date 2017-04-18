/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * Used to keep the resource powered while anyone is using it and
 * power it down when everyone stops.
 */

interface ShareableOnOff
{
    /**
     * Will keep the resource active until stopped.
     * 
     */
    command void on();

    /**
     * Symmetric.
     */
    command void off();
}

