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
