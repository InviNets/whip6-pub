/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucString.h>
#include <ipv6/ucIpv6AddressHumanReadableIo.h>


enum
{
    WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_NUMBER = 0,
    WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_SINGLE_COLON = 1,
    WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_FIRST_DOUBLE_COLON = 2,
    WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_SECOND_DOUBLE_COLON = 3,
    WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_STOP = 4,
};



/**
 * Returns the <tt>i</tt>-th hexadecimal digit of an
 * IPv6 address.
 * @param addr The address.
 * @param i The index of the digit.
 * @return The digit.
 */
WHIP6_MICROC_INLINE_DEF_PREFIX char whip6_ipv6AddrHumanReadableIoGetDigitForWriting(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr,
        uint8_t i
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const * addrPtr;
    uint8_t idx = i >> 1;
    uint8_t discr = i & 0x01;
    addrPtr = &(addr->data8[idx]);
    return discr != 0 ?
            whip6_lo4bitsToHexChar(*addrPtr) :
            whip6_hi4bitsToHexChar(*addrPtr);
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ipv6AddrHumanReadableIoInitializeWriting(
        ipv6_addr_human_readable_out_iter_t * iter,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   addrPtr;
    uint8_t                               maxZeroFirstIdx;
    uint8_t                               maxZeroNum;
    uint8_t                               currZeroNum;
    uint8_t                               idx;

    addrPtr = &(addr->data8[0]);
    maxZeroFirstIdx = IPV6_ADDRESS_LENGTH_IN_BYTES;
    maxZeroNum = 0;
    currZeroNum = 0;
    for (idx = 0; idx < IPV6_ADDRESS_LENGTH_IN_BYTES; idx += 2)
    {
        uint8_t first;
        uint8_t second;

        first = *addrPtr;
        ++addrPtr;
        second = *addrPtr;
        ++addrPtr;
        if (first == 0x00 && second == 0x00)
        {
            currZeroNum += 2;
        }
        else
        {
            if (currZeroNum > maxZeroNum)
            {
                maxZeroNum = currZeroNum;
                maxZeroFirstIdx = idx - currZeroNum;
            }
            currZeroNum = 0;
        }
    }
    if (currZeroNum > maxZeroNum)
    {
        maxZeroNum = currZeroNum;
        maxZeroFirstIdx = IPV6_ADDRESS_LENGTH_IN_BYTES - currZeroNum;
    }
    iter->addr = addr;
    iter->nextAction = WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_NUMBER;
    iter->nextIdx = 0;
    if (maxZeroNum > 2)
    {
        maxZeroNum = ((maxZeroFirstIdx + maxZeroNum) << 1);
        maxZeroFirstIdx = (maxZeroFirstIdx << 1);
        iter->firstZeroIdx = maxZeroFirstIdx;
        iter->nextNonzeroIdx = maxZeroNum;
        if (maxZeroFirstIdx == 0)
        {
            iter->nextAction = WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_FIRST_DOUBLE_COLON;
            iter->nextIdx = maxZeroNum;
        }
    }
    else
    {
        iter->firstZeroIdx = (IPV6_ADDRESS_LENGTH_IN_BYTES << 1);
        iter->nextNonzeroIdx = (IPV6_ADDRESS_LENGTH_IN_BYTES << 1) + 1;
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX char whip6_ipv6AddrHumanReadableIoContinueWriting(
        ipv6_addr_human_readable_out_iter_t * iter
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t   nextIdx = iter->nextIdx;
    char      res;

    switch (iter->nextAction)
    {
    case WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_NUMBER:
        res = whip6_ipv6AddrHumanReadableIoGetDigitForWriting(iter->addr, nextIdx);
        ++nextIdx;
        if ((nextIdx & 0x3) == 1 && res == '0')
        {
            do
            {
                res = whip6_ipv6AddrHumanReadableIoGetDigitForWriting(iter->addr, nextIdx);
                ++nextIdx;
            }
            while (res == '0' && (nextIdx & 0x3) != 0);
        }
        if (nextIdx >= (IPV6_ADDRESS_LENGTH_IN_BYTES << 1))
        {
            iter->nextAction = WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_STOP;
        }
        else if (nextIdx == iter->firstZeroIdx)
        {
            nextIdx = iter->nextNonzeroIdx;
            iter->nextAction = WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_FIRST_DOUBLE_COLON;
        }
        else if ((nextIdx & 0x03) == 0)
        {
            iter->nextAction = WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_SINGLE_COLON;
        }
        iter->nextIdx = nextIdx;
        return res;
    case WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_SINGLE_COLON:
        iter->nextAction = WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_NUMBER;
        return ':';
    case WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_FIRST_DOUBLE_COLON:
        iter->nextAction = WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_SECOND_DOUBLE_COLON;
        return ':';
    case WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_SECOND_DOUBLE_COLON:
        if (nextIdx >= (IPV6_ADDRESS_LENGTH_IN_BYTES << 1))
        {
            iter->nextAction = WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_STOP;
        }
        else
        {
            iter->nextAction = WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_NUMBER;
        }
        return ':';
    case WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_ACTION_STOP:
    default:
        return WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_EOS;
    }
}
