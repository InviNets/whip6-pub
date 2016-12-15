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

// wNesC makes the codeseg pragmas obsolete
// #pragma codeseg BANK2

/* base */
#include "../../src/base/ucIoVec.c"
#include "../../src/base/ucIoVecAllocation.c"

/* ieee154 */
#include "../../src/ieee154/ucIeee154AddressManipulation.c"
#include "../../src/ieee154/ucIeee154FrameManipulation.c"
#include "../../src/ieee154/ucIeee154Ipv6InterfaceStateManipulation.c"

/** ipv6 */
#include "../../src/ipv6/ucIpv6AddressHumanReadableIo.c"
#include "../../src/ipv6/ucIpv6AddressManipulation.c"
#include "../../src/ipv6/ucIpv6Checksum.c"
//#include "../../src/ipv6/ucIpv6ExtensionHeaderProcessing.c"
#include "../../src/ipv6/ucIpv6GenericInterfaceStateManipulation.c"

/** udp */
#include "../../src/udp/ucUdpHeaderManipulation.c"
