/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "PlatformIOMuxPrv.h"

generic configuration PlatformIOChannelPub(int channel) {
    provides interface IOVRead;
    provides interface IOVWrite;
}
implementation {
    components new PlatformIOChannelPrv(unique(UQ_IO_CHANNEL), channel);
    IOVRead = PlatformIOChannelPrv;
    IOVWrite = PlatformIOChannelPrv;
}
