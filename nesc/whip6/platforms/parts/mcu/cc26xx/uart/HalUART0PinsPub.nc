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
 * @author Szymon Acedanski
 */

configuration HalUART0PinsPub {
    uses interface CC26xxPin as RX @atmostonce();
    uses interface CC26xxPin as TX @atmostonce();
    uses interface CC26xxPin as CTS @atmostonce();
    uses interface CC26xxPin as RTS @atmostonce();

    provides interface CC26xxPin as PRX @atmostonce();
    provides interface CC26xxPin as PTX @atmostonce();
    provides interface CC26xxPin as PCTS @atmostonce();
    provides interface CC26xxPin as PRTS @atmostonce();
}

implementation {
    PRX = RX;
    PTX = TX;
    PCTS = CTS;
    PRTS = RTS;
}
