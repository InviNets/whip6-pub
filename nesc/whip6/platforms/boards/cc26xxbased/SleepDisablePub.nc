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
 * @author Przemyslaw Horban <extremegf@gmail.com>
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
