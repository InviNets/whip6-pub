/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
