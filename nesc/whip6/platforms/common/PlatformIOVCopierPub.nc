/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVec.h>



generic configuration PlatformIOVCopierPub() {
    provides interface IOVCopier;
}
implementation
{
    components new GenericIOVCopierPub();
    IOVCopier = GenericIOVCopierPub;
}
