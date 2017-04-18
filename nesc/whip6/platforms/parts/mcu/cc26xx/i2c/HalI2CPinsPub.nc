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
