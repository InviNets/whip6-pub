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

configuration HalI2CPinsPub {
    uses interface CC26xxPin as SDA @exactlyonce();
    uses interface CC26xxPin as SCL @exactlyonce();

    provides interface CC26xxPin as PSDA @atmostonce();
    provides interface CC26xxPin as PSCL @atmostonce();
}

implementation {
    PSDA = SDA;
    PSCL = SCL;
}
