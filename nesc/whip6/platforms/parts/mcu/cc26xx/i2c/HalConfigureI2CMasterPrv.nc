/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 * @author Szymon Acedanski
 * 
 * Component responsible for configuring SPI in master mode.
 */

#include <inc/hw_ioc.h>
#include <driverlib/gpio.h>
#include <driverlib/ioc.h>
#include <driverlib/i2c.h>
#include <driverlib/prcm.h>
#include <driverlib/sys_ctrl.h>

generic module HalConfigureI2CMasterPrv(uint32_t i2cBase) {
    provides interface Init as ReInitRegisters @exactlyonce();

    provides interface OnOffSwitch @atleastonce();

    uses interface CC26xxPin as SDAPin @exactlyonce();
    uses interface CC26xxPin as SCLPin @exactlyonce();

    uses interface ShareableOnOff as PowerDomain;
}

implementation {
    bool isOn = FALSE;

    event void SDAPin.configure() {
        IOCPinTypeI2c(i2cBase, call SDAPin.IOId(), IOID_UNUSED);
    }

    event void SCLPin.configure() {
        IOCPinTypeI2c(i2cBase, IOID_UNUSED, call SCLPin.IOId());
    }

    error_t reconfigure();

    command error_t OnOffSwitch.on() {
        call PowerDomain.on();

        PRCMPeripheralRunEnable(PRCM_PERIPH_I2C0);
        PRCMPeripheralSleepEnable(PRCM_PERIPH_I2C0);
        PRCMPeripheralDeepSleepEnable(PRCM_PERIPH_I2C0);
        PRCMLoadSet();
        while (!PRCMLoadGet()) /* nop */;

        isOn = TRUE;

        return reconfigure();
    }

    command error_t ReInitRegisters.init() {
        if (isOn) {
            return reconfigure();
        } else {
            return SUCCESS;
        }
    }

    error_t reconfigure() {
        I2CMasterDisable(i2cBase);
        I2CMasterInitExpClk(i2cBase, SysCtrlClockGet(), true);
        I2CMasterEnable(i2cBase);
        return SUCCESS;
    }

    command error_t OnOffSwitch.off() {
        I2CMasterDisable(i2cBase);

        PRCMPeripheralRunDisable(PRCM_PERIPH_I2C0);
        PRCMPeripheralSleepDisable(PRCM_PERIPH_I2C0);
        PRCMPeripheralDeepSleepDisable(PRCM_PERIPH_I2C0);
        PRCMLoadSet();

        call PowerDomain.off();

        isOn = FALSE;

        return SUCCESS;
    }
}
