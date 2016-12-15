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
 * @author Michal Marschall <m.marschall@invinets.com>
 * @author Szymon Acedanski
 * 
 * Component responsible for configuring SPI in master mode.
 */

#include "hw_ioc.h"
#include "gpio.h"
#include "ioc.h"
#include "ssi.h"
#include "prcm.h"
#include "sys_ctrl.h"
#include "hal_configure_spi.h"

generic module HalConfigureSPIMasterPrv(uint32_t ssiBase) {
    provides interface Init as ReInitRegisters @exactlyonce();

    provides interface OnOffSwitch @atleastonce();
    provides interface AsyncConfigure<spi_speed_t> as Speed;
    provides interface AsyncConfigure<spi_mode_t> as Mode;
    provides interface AsyncConfigure<spi_order_t> as BitOrder;

    uses interface CC26xxPin as MIPin @exactlyonce();
    uses interface CC26xxPin as MOPin @exactlyonce();
    uses interface CC26xxPin as CPin @exactlyonce();

    uses interface ShareableOnOff as PowerDomain @exactlyonce();
    uses interface ShareableOnOff as DMAPower @exactlyonce();
}

implementation {
    spi_speed_t cfgSpeed = SPI_SPEED_4MHZ;
    spi_mode_t cfgMode = SPI_MODE_0;
    spi_order_t cfgOrder = SPI_ORDER_MSB_FIRST;
    bool isOn = FALSE;

    inline void disableMIPin() {
        IOCPortConfigureSet(call MIPin.IOId(), IOC_PORT_GPIO,
            IOC_CURRENT_2MA | IOC_STRENGTH_AUTO |
            IOC_IOPULL_DOWN | IOC_SLEW_DISABLE |
            IOC_HYST_DISABLE | IOC_NO_EDGE |
            IOC_INT_DISABLE | IOC_IOMODE_NORMAL |
            IOC_NO_WAKE_UP | IOC_INPUT_DISABLE);
    }

    inline void disableMOPin() {
        IOCPortConfigureSet(call MOPin.IOId(), IOC_PORT_GPIO,
            IOC_CURRENT_2MA | IOC_STRENGTH_AUTO |
            IOC_IOPULL_DOWN | IOC_SLEW_DISABLE |
            IOC_HYST_DISABLE | IOC_NO_EDGE |
            IOC_INT_DISABLE | IOC_IOMODE_NORMAL |
            IOC_NO_WAKE_UP | IOC_INPUT_DISABLE);
    }

    inline void disableCPin() {
        IOCPortConfigureSet(call CPin.IOId(), IOC_PORT_GPIO,
            IOC_CURRENT_2MA | IOC_STRENGTH_AUTO |
            IOC_IOPULL_DOWN | IOC_SLEW_DISABLE |
            IOC_HYST_DISABLE | IOC_NO_EDGE |
            IOC_INT_DISABLE | IOC_IOMODE_NORMAL |
            IOC_NO_WAKE_UP | IOC_INPUT_DISABLE);
    }

    inline void enablePins() {
        IOCPinTypeSsiMaster(ssiBase, call MIPin.IOId(), call MOPin.IOId(),
                IOID_UNUSED, call CPin.IOId());
    }

    event void MIPin.configure() {
        disableMIPin();
    }

    event void MOPin.configure() {
        disableMOPin();
    }

    event void CPin.configure() {
        disableCPin();
    }

    error_t reconfigure();

    command error_t OnOffSwitch.on() {
        call PowerDomain.on();
        call DMAPower.on();

        PRCMPeripheralRunEnable(ssiBase == SSI0_BASE ?
                PRCM_PERIPH_SSI0 : PRCM_PERIPH_SSI1);
        PRCMPeripheralSleepEnable(ssiBase == SSI0_BASE ?
                PRCM_PERIPH_SSI0 : PRCM_PERIPH_SSI1);
        PRCMPeripheralDeepSleepEnable(ssiBase == SSI0_BASE ?
                PRCM_PERIPH_SSI0 : PRCM_PERIPH_SSI1);
        PRCMLoadSet();
        while (!PRCMLoadGet()) /* nop */;

        enablePins();

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
        uint32_t protocol;
        uint32_t bitrate;

        switch(cfgMode) {
            case SPI_MODE_0:
                protocol = SSI_FRF_MOTO_MODE_0;
                break;
            case SPI_MODE_1:
                protocol = SSI_FRF_MOTO_MODE_1;
                break;
            case SPI_MODE_2:
                protocol = SSI_FRF_MOTO_MODE_2;
                break;
            case SPI_MODE_3:
                protocol = SSI_FRF_MOTO_MODE_3;
                break;
            default:
                return EINVAL;
        }

        switch(cfgSpeed) {
            case SPI_SPEED_24MHZ:
                bitrate = 24000000;
                break;
            case SPI_SPEED_16MHZ:
                bitrate = 16000000;
                break;
            case SPI_SPEED_8MHZ:
                bitrate = 8000000;
                break;
            case SPI_SPEED_4MHZ:
                bitrate = 4000000;
                break;
            case SPI_SPEED_2MHZ:
                bitrate = 2000000;
                break;
            case SPI_SPEED_1MHZ:
                bitrate = 1000000;
                break;
            case SPI_SPEED_500KHZ:
                bitrate = 500000;
                break;
            case SPI_SPEED_250KHZ:
                bitrate = 250000;
                break;
            default:
                return EINVAL;
        }

        SSIDisable(ssiBase);
        SSIConfigSetExpClk(ssiBase, SysCtrlClockGet(), protocol,
                SSI_MODE_MASTER, bitrate, 8);
        SSIEnable(ssiBase);

        return SUCCESS;
    }

    command error_t OnOffSwitch.off() {
        SSIDisable(ssiBase);

        disableMIPin();
        disableMOPin();

        PRCMPeripheralRunDisable(ssiBase == SSI0_BASE ?
                PRCM_PERIPH_SSI0 : PRCM_PERIPH_SSI1);
        PRCMPeripheralSleepDisable(ssiBase == SSI0_BASE ?
                PRCM_PERIPH_SSI0 : PRCM_PERIPH_SSI1);
        PRCMPeripheralDeepSleepDisable(ssiBase == SSI0_BASE ?
                PRCM_PERIPH_SSI0 : PRCM_PERIPH_SSI1);
        PRCMLoadSet();

        call DMAPower.off();
        call PowerDomain.off();

        isOn = FALSE;

        return SUCCESS;
    }

    async command error_t Speed.configure(spi_speed_t speed) {
        if (speed != cfgSpeed) {
            cfgSpeed = speed;
            return reconfigure();
        } else {
            return SUCCESS;
        }
    }

    async command error_t Mode.configure(spi_mode_t mode) {
        if (mode != cfgMode) {
            cfgMode = mode;
            return reconfigure();
        } else {
            return SUCCESS;
        }
    }

    async command error_t BitOrder.configure(spi_order_t bitOrder) {
        if (bitOrder != SPI_ORDER_MSB_FIRST) {
            return ENOSYS;
        }
        return SUCCESS;
    }
}
