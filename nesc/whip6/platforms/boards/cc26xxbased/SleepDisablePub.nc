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
 * @author Przemyslaw <extremegf@gmail.com>
 * 
 * Use this to globally disable MCU sleep.
 */

configuration SleepDisablePub {
    provides interface OnOffSwitch;
}
implementation {
    components HalCC26xxSleepPub;    
    OnOffSwitch = HalCC26xxSleepPub;
}
