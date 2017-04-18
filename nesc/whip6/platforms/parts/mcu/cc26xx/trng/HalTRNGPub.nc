/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
