/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 */

#include <CC26xxPinConfig.h>

configuration SdCardPinsConfigPrv {
    provides interface IOPin as SS;
}

implementation {
    components new HalIOPinPub(OUTPUT_HIGH) as Pin;
    components CC26xxPinsPub;
    Pin.CC26xxPin -> CC26xxPinsPub.DIO30;
    SS = Pin;
}
