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
