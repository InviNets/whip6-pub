/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
