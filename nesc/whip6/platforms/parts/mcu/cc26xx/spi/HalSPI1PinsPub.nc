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
