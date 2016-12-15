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

generic configuration HalTRNGPub(bool secure) {
    provides interface Random;
}
implementation {
    components new HalTRNGPrv(secure) as Prv;
    Random = Prv;

    components CC26xxPowerDomainsPub as PowerDomains;
    Prv.PeriphDomain -> PowerDomains.PeriphDomain;
}
