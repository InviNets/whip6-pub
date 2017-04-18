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

configuration HalSPI1PinsPub {
    uses interface CC2538Pin as MISO @exactlyonce();
    uses interface CC2538Pin as MOSI @exactlyonce();
    uses interface CC2538Pin as PCLK @exactlyonce();

    provides interface CC2538Pin as PMISO @exactlyonce();
    provides interface CC2538Pin as PMOSI @exactlyonce();
    provides interface CC2538Pin as PCLK @exactlyonce();
}

implementation {
    PMISO = MISO;
    PMOSI = MOSI;
    PCLK = CLK;
}
