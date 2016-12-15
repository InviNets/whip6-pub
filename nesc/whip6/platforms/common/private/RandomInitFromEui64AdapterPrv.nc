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




/**
 * An adapter for a pseudo random number generator
 * seed initialization that makes use of the local
 * EUI-64.
 *
 * @author Konrad Iwanicki
 */
module RandomInitFromEui64AdapterPrv
{
    provides interface Init;
    uses interface ParameterInit<uint16_t> as SubSeedInit;
    uses interface LocalIeeeEui64Provider;
}
implementation
{
    command error_t Init.init()
    {
        ieee_eui64_t   eui64;
        uint16_t       seed;

        call LocalIeeeEui64Provider.read(&eui64);
        seed = ((uint16_t)(eui64.data[6]) << 8) | eui64.data[7];
        return call SubSeedInit.init(seed);
    }
}

