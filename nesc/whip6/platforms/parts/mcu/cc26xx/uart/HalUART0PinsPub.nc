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

    provides interface CC26xxPin as PRX @atmostonce();
    provides interface CC26xxPin as PTX @atmostonce();
}

implementation {
    PRX = RX;
    PTX = TX;
}
