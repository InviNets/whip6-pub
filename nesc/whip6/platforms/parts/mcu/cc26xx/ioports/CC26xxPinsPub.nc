/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

configuration CC26xxPinsPub {
#define PIN(n) \
    provides interface CC26xxPin as DIO##n @atmostonce()
#include "CC26xxPins.h"
#undef PIN

    provides interface Init @exactlyonce();
    uses interface CC26xxPinsDefaultConfig as DefaultConfig @atmostonce();
}
implementation {
    components CC26xxPinsPrv as Impl;
#define PIN(n) \
    DIO##n = Impl.DIO[n]
#include "CC26xxPins.h"
#undef PIN

    Init = Impl.Init;
    DefaultConfig = Impl.DefaultConfig;
}
