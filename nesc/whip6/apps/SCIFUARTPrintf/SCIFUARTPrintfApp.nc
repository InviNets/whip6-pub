/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */
configuration SCIFUARTPrintfApp {

} implementation {
    components BoardStartupPub, SCIFUARTPrintfPrv;
    SCIFUARTPrintfPrv.Boot -> BoardStartupPub;

    components new PlatformTimerMilliPub();
    SCIFUARTPrintfPrv.Timer -> PlatformTimerMilliPub;
}
