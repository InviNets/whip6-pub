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
 * Bootloader updater.
 *
 * @author Szymon Acedanski
 */
interface BootloaderUpdater
{
    /**
     * Updates the bootloader.
     */
    command error_t updateBootloader();
}

