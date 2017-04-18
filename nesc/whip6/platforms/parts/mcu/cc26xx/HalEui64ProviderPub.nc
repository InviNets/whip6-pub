/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <eui/ucEui64Types.h>
#include <inc/hw_types.h>
#include <inc/hw_memmap.h>
#include <inc/hw_fcfg1.h>


/**
 * The primary provider of a local IEEE EUI-64
 * for CC26xx MCUs. It returns the primary
 * (factory-generated) EUI-64 stored in
 * the FCFG memory area.
 *
 * @author Konrad Iwanicki
 * @author Szymon Acedanski
 */
module HalEui64ProviderPub
{
    provides
    {
        interface LocalIeeeEui64Provider;
    }
}
implementation
{

    // ====================== LocalIeeeEui64Provider ======================

    command inline void LocalIeeeEui64Provider.read(ieee_eui64_t * eui)
    {
        uint32_t part1 = HWREG(FCFG1_BASE + FCFG1_O_MAC_15_4_0);
        uint32_t part2 = HWREG(FCFG1_BASE + FCFG1_O_MAC_15_4_1);
        eui->data[7] = part1 & 0xff;
        part1 >>= 8;
        eui->data[6] = part1 & 0xff;
        part1 >>= 8;
        eui->data[5] = part1 & 0xff;
        part1 >>= 8;
        eui->data[4] = part1 & 0xff;
        eui->data[3] = part2 & 0xff;
        part2 >>= 8;
        eui->data[2] = part2 & 0xff;
        part2 >>= 8;
        eui->data[1] = part2 & 0xff;
        part2 >>= 8;
        eui->data[0] = part2 & 0xff;
    }
}
