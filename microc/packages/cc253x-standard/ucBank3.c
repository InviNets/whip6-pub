/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

// wNesC makes the codeseg pragmas obsolete
// #pragma codeseg BANK2

/** 6lowpan */
#include "../../src/6lowpan/uc6LoWPANDefragmentation.c"
#include "../../src/6lowpan/uc6LoWPANFragmentation.c"
#include "../../src/6lowpan/uc6LoWPANHeaderManipulation.c"
#include "../../src/6lowpan/uc6LoWPANIpv6AddressManipulation.c"
#include "../../src/6lowpan/uc6LoWPANIpv6HeaderCompression.c"
#include "../../src/6lowpan/uc6LoWPANMeshManipulation.c"
#include "../../src/6lowpan/uc6LoWPANNalpExtensionSoftwareAcknowledgments.c"
#include "../../src/6lowpan/uc6LoWPANPacketForwarding.c"
