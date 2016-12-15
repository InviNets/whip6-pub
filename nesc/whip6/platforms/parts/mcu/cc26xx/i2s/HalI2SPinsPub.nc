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
 * @author Szymon Acedanski
 */

configuration HalI2SPinsPub {
    uses interface CC26xxPin as BCLK @atmostonce();
    uses interface CC26xxPin as WCLK @atmostonce();
    uses interface CC26xxPin as AD @atmostonce();

    provides interface CC26xxPin as PBCLK @atmostonce();
    provides interface CC26xxPin as PWCLK @atmostonce();
    provides interface CC26xxPin as PAD @atmostonce();
}

implementation {
    PBCLK = BCLK;
    PWCLK = WCLK;
    PAD = AD;
}
