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

configuration HalSPI0PinsPub {
    uses interface CC26xxPin as MISO @exactlyonce();
    uses interface CC26xxPin as MOSI @exactlyonce();
    uses interface CC26xxPin as CLK @exactlyonce();

    provides interface CC26xxPin as PMISO @atmostonce();
    provides interface CC26xxPin as PMOSI @atmostonce();
    provides interface CC26xxPin as PCLK @atmostonce();
}

implementation {
    PMISO = MISO;
    PMOSI = MOSI;
    PCLK = CLK;
}
