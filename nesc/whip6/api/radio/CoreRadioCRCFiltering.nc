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


interface CoreRadioCRCFiltering
{
    /**
     * Enables CRC filtering. After enabling, frames with incorrect CRC
     * will be discarded.
     *
     * This is the default.
     */
    command void enableCRCFiltering();

    /**
     * Disables CRC filtering.
     */
    command void disableCRCFiltering();
}
