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
 * @author Szymon Acedanski
 */

#include "prcm.h"

generic module CC26xxPowerDomainPrv(uint32_t domain) {
    provides interface OnOffSwitch @atmostonce();
}
implementation
{
    command error_t OnOffSwitch.on() {
        PRCMPowerDomainOn(domain);
        while (PRCMPowerDomainStatus(domain) != PRCM_DOMAIN_POWER_ON) /* nop */;
        return SUCCESS;
    }

    command error_t OnOffSwitch.off() {
        PRCMPowerDomainOff(domain);
        while (PRCMPowerDomainStatus(domain) != PRCM_DOMAIN_POWER_OFF) /* nop */;
        return SUCCESS;
    }
}
