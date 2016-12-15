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


#ifndef GLOBAL_ADDRESS_PRINTING_H_
#define GLOBAL_ADDRESS_PRINTING_H_

#include "ieee154/ucIeee154AddressTypes.h"
#include "ipv6/ucIpv6AddressTypes.h"

void printf_ipv6(whip6_ipv6_addr_t const *ipv6Addr);
void printf_ieee154(whip6_ieee154_addr_t const *addr);

#endif  // GLOBAL_ADDRESS_PRINTING_H_

