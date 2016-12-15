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
 * Bootloader entry point.
 *
 * @author Szymon Acedanski
 */
interface Bootloader
{
    /**
     * Enters the bootloader. May return an error, but otherwise
     * never returns.
     */
    command error_t enterBootloader();
}

