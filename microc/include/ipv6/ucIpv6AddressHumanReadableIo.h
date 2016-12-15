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

#ifndef __WHIP6_MICROC_IPV6_IPV6_ADDRESS_HUMAN_READABLE_IO_H__
#define __WHIP6_MICROC_IPV6_IPV6_ADDRESS_HUMAN_READABLE_IO_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains functionality for reading and printing
 * IPv6 addresses in a human readable form.
 * For more information, refer to the wikipedia.
 */

#include <ipv6/ucIpv6AddressTypes.h>


enum
{
    WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_EOS = '\0',
};


/**
 * An iterator for writing an IPv6 address
 * as a string in a human-readable form.
 */
typedef struct ipv6_addr_human_readable_out_iter_s
{
    ipv6_addr_t MCS51_STORED_IN_RAM const *   addr;
    uint8_t                                   nextAction;
    uint8_t                                   nextIdx;
    uint8_t                                   firstZeroIdx;
    uint8_t                                   nextNonzeroIdx;
} ipv6_addr_human_readable_out_iter_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_addr_human_readable_out_iter_t)



/**
 * Initializes printing an IPv6 address
 * as a string in a human readable form.
 * @param iter A printing iterator.
 * @param addr The address to be printed.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6AddrHumanReadableIoInitializeWriting(
        ipv6_addr_human_readable_out_iter_t * iter,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns the next character to be printed
 * for an IPv6 address to be printed in
 * a human readable form.
 * @param iter A printing iterator.
 * @return The next character to be printed
 *   or <tt>WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_EOS</tt>
 *   if there are no more characters to print.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX char whip6_ipv6AddrHumanReadableIoContinueWriting(
        ipv6_addr_human_readable_out_iter_t * iter
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


#endif /* __WHIP6_MICROC_IPV6_IPV6_ADDRESS_HUMAN_READABLE_IO_H__ */
