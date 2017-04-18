/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

configuration CC26xxPowerDomainsPub {
    provides interface ShareableOnOff as PeriphDomain;
    provides interface ShareableOnOff as SerialDomain;
    provides interface ShareableOnOff as RFCoreDomain;
}
implementation {
    components new CC26xxPowerDomainPub(PRCM_DOMAIN_PERIPH) as Periph;
    PeriphDomain = Periph;

    components new CC26xxPowerDomainPub(PRCM_DOMAIN_SERIAL) as Serial;
    SerialDomain = Serial;

    components new CC26xxPowerDomainPub(PRCM_DOMAIN_RFCORE) as RFCore;
    RFCoreDomain = RFCore;
}
