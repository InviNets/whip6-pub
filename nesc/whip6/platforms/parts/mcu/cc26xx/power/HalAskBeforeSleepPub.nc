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
 * Give out a single instance of the ask interface. All must
 * return TRUE for deep sleep to occur.
 */

generic configuration HalAskBeforeSleepPub() {
    provides interface AskBeforeSleep;
}
implementation{
    components HalCC26xxSleepPub;
    AskBeforeSleep = HalCC26xxSleepPub.AskBeforeSleep;
}
