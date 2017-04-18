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
