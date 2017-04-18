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
 * Component responsible for configuring I2S in input mode,
 * mono. Output is not supported in this driver.
 */

#include <inc/hw_ioc.h>
#include <driverlib/ioc.h>
#include <driverlib/i2s.h>
#include <driverlib/prcm.h>
#include <driverlib/sys_ctrl.h>

#include "hal_configure_i2s.h"

generic module HalConfigureI2SPrv(uint32_t i2sBase,
        i2s_word_size_t wordSize, uint32_t preferredRate,
        i2s_clock_pol_t clockPol, audio_sample_format_t sampleFormat) {
    provides interface OnOffSwitch @atleastonce();
    provides interface HalI2SSampleSize;
    provides interface AudioFormat;

    uses interface CC26xxPin as BCLKPin;
    uses interface CC26xxPin as WCLKPin;
    uses interface CC26xxPin as ADPin;

    uses interface ShareableOnOff as PowerDomain @exactlyonce();
    uses interface ShareableOnOff as DMAEngineOnOff @exactlyonce();
}

implementation {
    I2SControlTable controlTable;

    bool isOn = FALSE;

    event void BCLKPin.configure() {
        IOCPortConfigureSet(call BCLKPin.IOId(), IOC_PORT_MCU_I2S_BCLK,
                IOC_STD_OUTPUT);
    }

    default async command uint32_t BCLKPin.IOId() {
        return IOID_UNUSED;
    }

    event void WCLKPin.configure() {
        IOCPortConfigureSet(call WCLKPin.IOId(), IOC_PORT_MCU_I2S_WCLK,
                IOC_STD_OUTPUT);
    }

    default async command uint32_t WCLKPin.IOId() {
        return IOID_UNUSED;
    }

    event void ADPin.configure() {
        IOCPortConfigureSet(call ADPin.IOId(), IOC_PORT_MCU_I2S_AD0,
                IOC_STD_INPUT);
    }

    default async command uint32_t ADPin.IOId() {
        return IOID_UNUSED;
    }

    uint32_t computeDivisor() {
        return (SysCtrlClockGet() + (preferredRate / 2)) / preferredRate;
    }

    command error_t OnOffSwitch.on() {
        int bits = wordSize == I2S_WORD_16BIT ? 16 : 24;
        uint32_t clkDiv = computeDivisor();

        call PowerDomain.on();

        g_pControlTable = &controlTable;

        /* Apparently, UDMA clock is needed by I2S, but only in sleep,
         * even though this is undocumented. Maybe this is a silicon bug,
         * when some iternal clock dependency is not preserved in sleep
         * mode.
         *
         * For simplicity, we just turn on the UDMA engine.
         */

        call DMAEngineOnOff.on();

        PRCMPeripheralRunEnable(PRCM_PERIPH_I2S);
        PRCMPeripheralSleepEnable(PRCM_PERIPH_I2S);
        PRCMPeripheralDeepSleepEnable(PRCM_PERIPH_I2S);
        PRCMAudioClockConfigSetOverride(PRCM_WCLK_SINGLE_PHASE |
                PRCM_WCLK_POS_EDGE, clkDiv, clkDiv, bits - 1);
        HWREG(PRCM_BASE + PRCM_O_I2SBCLKSEL) = PRCM_I2SBCLKSEL_SRC;
        PRCMLoadSet();
        while (!PRCMLoadGet()) /* nop */;

        I2SDisable(i2sBase);

        I2SClockConfigure(i2sBase, I2S_INT_WCLK | I2S_NORMAL_WCLK);
        I2SChannelConfigure(i2sBase, I2S_LINE_INPUT | I2S_CHAN0_ACT,
                I2S_LINE_UNUSED, I2S_LINE_UNUSED);
        I2SAudioFormatConfigure(i2sBase, (wordSize == I2S_WORD_16BIT ?
                I2S_MEM_LENGTH_16 : I2S_MEM_LENGTH_24)
                | (clockPol == I2S_CLOCK_POL_NORMAL ?
                    I2S_NEG_EDGE : I2S_POS_EDGE)
                | I2S_SINGLE_PHASE_FMT
                | (wordSize == I2S_WORD_16BIT ?
                    I2S_WORD_LENGTH_16 : I2S_WORD_LENGTH_24),
                0);

        PRCMAudioClockEnable();
        PRCMLoadSet();
        while (!PRCMLoadGet()) /* nop */;

        isOn = TRUE;

        return SUCCESS;
    }

    command error_t OnOffSwitch.off() {
        PRCMAudioClockDisable();
        PRCMPeripheralRunDisable(PRCM_PERIPH_I2S);
        PRCMPeripheralSleepDisable(PRCM_PERIPH_I2S);
        PRCMPeripheralDeepSleepDisable(PRCM_PERIPH_I2S);
        PRCMLoadSet();

        call DMAEngineOnOff.off();
        call PowerDomain.off();

        isOn = FALSE;

        return SUCCESS;
    }

    command uint8_t HalI2SSampleSize.getSampleSizeInBytes() {
        return wordSize == I2S_WORD_16BIT ? 2 : 3;
    }

    command uint32_t AudioFormat.getSampleRate() {
        uint32_t clkDiv = computeDivisor();
        switch (sampleFormat) {
            case AUDIO_FORMAT_PDM:
                return SysCtrlClockGet() / clkDiv;
            case AUDIO_FORMAT_PCM16:
                return SysCtrlClockGet() / clkDiv / 16;
            default:
                panic();
        }
    }

    command uint8_t AudioFormat.getNumChannels() {
        return 1;
    }

    command audio_sample_format_t AudioFormat.getSampleFormat() {
        return sampleFormat;
    }
}
