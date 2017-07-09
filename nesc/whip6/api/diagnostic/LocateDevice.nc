/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

interface LocateDevice {
    /* Perform something to help the user find the device, for example
     * blink an LED or beep. */
    command void locateDevice();
}
