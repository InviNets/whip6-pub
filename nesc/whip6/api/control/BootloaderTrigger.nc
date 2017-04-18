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
 * Bootloader trigger.
 *
 * @author Szymon Acedanski
 */
interface BootloaderTrigger
{
    /**
     * User requested to enter the bootloader.
     */
    event void bootloaderRequested();
}
