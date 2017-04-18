/*
 * Copyright (c) 2015, Texas Instruments Incorporated
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * *  Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * *  Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * *  Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQueueNTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */
#include <driverlib/sys_ctrl.h>
#include <driverlib/prcm.h>
#include <driverlib/osc.h>
#include <driverlib/aon_ioc.h>
#include <driverlib/aon_rtc.h>
#include <driverlib/vims.h>



/**
 * @author Szymon Acedanski
 *
 * Totally based on the following document from TI:
 *
 * CC26xx/CC13xx Power Management Software Developer's Reference Guide
 * (swra486.pdf)
 *
 * Uses code from tidrivers package, marked with the aforecited
 * license.
 */
module HalCC26xxSleepPub {
    provides interface McuSleep;
    provides interface AskBeforeSleep;
    provides interface OnOffSwitch;

    uses interface Init as AtomicAfterSleepInit;
    uses interface Init as AtomicAfterDeepSleepInit;

    uses interface Led as NoDeepSleepLed;
    uses interface Led as NoIdleSleepLed;

    uses interface AsyncCounter<T32khz, uint32_t> as StatsCounter;
    uses interface StatsIncrementer<uint32_t> as IdleSleepTime;
    uses interface StatsIncrementer<uint32_t> as DeepSleepTime;
}
implementation {
    bool sleepEnabled = TRUE;

    enum {
        // Determines if the flash cache is retained in deep sleep.
        // We say NO, as we suppose it makes sense to retain it when
        // it's used as GPRAM, which is not the case AFAIK.
        SLEEP_RETAIN_CACHE = 0,
    };

    void enter_sleep() {
        bool xosc_hf_active;
        uint32_t poweredDomains = PRCM_DOMAIN_CPU;
        uint32_t modeVIMS;

        /* 1. Freeze the IOs on the boundary between MCU and AON */
        AONIOCFreezeEnable();

        /* 2. If XOSC_HF is active, force it off */
        if(OSCClockSourceGet(OSC_SRC_CLK_HF) == OSC_XOSC_HF) {
            xosc_hf_active = TRUE;
            OSCHF_SwitchToRcOscTurnOffXosc();
        }

        /* 3. Allow AUX to power down */
        AONWUCAuxWakeupEvent(AONWUC_AUX_ALLOW_SLEEP);

        /* 4. Make sure writes take effect */
        SysCtrlAonSync();

        /* now proceed to transition to Power_STANDBY ... */

        /* 5. Query and save domain states before powering them off */
        if (PRCMPowerDomainStatus(PRCM_DOMAIN_RFCORE) == PRCM_DOMAIN_POWER_ON) {
            poweredDomains |= PRCM_DOMAIN_RFCORE;
        }
        if (PRCMPowerDomainStatus(PRCM_DOMAIN_SERIAL) == PRCM_DOMAIN_POWER_ON) {
            poweredDomains |= PRCM_DOMAIN_SERIAL;
        }
        if (PRCMPowerDomainStatus(PRCM_DOMAIN_PERIPH) == PRCM_DOMAIN_POWER_ON) {
            poweredDomains |= PRCM_DOMAIN_PERIPH;
        }

        /* 8. Request power off of domains in the MCU voltage domain */
        PRCMPowerDomainOff(poweredDomains);

        /* 9. Request uLDO during standby */
        PRCMMcuUldoConfigure(true);

        /* 10. If don't want VIMS retention in standby, disable it now... */
        if (!SLEEP_RETAIN_CACHE) {

            /* 10.1 Get the current VIMS mode */
            do {
                modeVIMS = VIMSModeGet(VIMS_BASE);
            } while (modeVIMS == VIMS_MODE_CHANGING);

            /* 10.2 If in a cache mode, turn VIMS off */
            if (modeVIMS == VIMS_MODE_ENABLED) {

                /* 10.3 Now turn off the VIMS */
                VIMSModeSet(VIMS_BASE, VIMS_MODE_OFF);
            }

            /* 10.4 Now disable retention */
            PRCMCacheRetentionDisable();
        }

        /* 11. Setup recharge parameters */
        SysCtrlSetRechargeBeforePowerDown(XOSC_IN_HIGH_POWER_MODE);

        /* 12. Make sure all writes have taken effect */
        SysCtrlAonSync();

        /* 13. Invoke deep sleep to go to STANDBY */
        PRCMDeepSleep();

        /* 14. If didn't retain VIMS in standby, re-enable retention now */
        if (!SLEEP_RETAIN_CACHE) {

            /* 14.1 If previously in a cache mode, restore the mode now */
            if (modeVIMS == VIMS_MODE_ENABLED) {
                VIMSModeSet(VIMS_BASE, modeVIMS);
            }

            /* 14.2 Re-enable retention */
            PRCMCacheRetentionEnable();
        }

        /* 15. Start forcing on power to AUX */
        AONWUCAuxWakeupEvent(AONWUC_AUX_WAKEUP);

        /* 16. Start re-powering power domains */
        PRCMPowerDomainOn(poweredDomains);

        /* 19. Release request for uLDO */
        PRCMMcuUldoConfigure(false);

        /* 21. Wait until all power domains are back on */
        while (PRCMPowerDomainStatus(poweredDomains) !=
               PRCM_DOMAIN_POWER_ON) /* nop */;

        /* 23. Disable IO freeze and ensure RTC shadow value is updated */
        AONIOCFreezeDisable();
        SysCtrlAonSync();

        /* 24. Wait for AUX to power up */
        while (!(AONWUCPowerStatusGet() & AONWUC_AUX_POWER_ON)) /* nop */;

        /* 25. If XOSC_HF was forced off above, initiate switch back */
        if (xosc_hf_active) {
            OSCHF_TurnOnXosc();
        }

        /* 26. Signal HAL */
        call AtomicAfterDeepSleepInit.init();

        /* 27. Finalize XOSC_HF switch */
        if (xosc_hf_active) {
            while (!OSCHF_AttemptToSwitchToXosc()) /* nop */;
        }

        /* 30. Adjust recharge parameters */
        SysCtrlAdjustRechargeAfterPowerDown();
    }

    void enter_idle() {
        /* 1. Configure flash to remain on in IDLE */
        HWREG(PRCM_BASE + PRCM_O_PDCTL1VIMS) |= PRCM_PDCTL1VIMS_ON;
        /* 2. Always keep cache retention ON in IDLE  */
        PRCMCacheRetentionEnable();
        /* 3. Turn off the CPU power domain */
        PRCMPowerDomainOff(PRCM_DOMAIN_CPU);
        /* 4. Ensure any possible outstanding AON writes complete */
        SysCtrlAonSync();

        /* 5. Enter IDLE */
        PRCMDeepSleep();

        /* 6. Make sure MCU and AON are in sync after wakeup */
        SysCtrlAonUpdate();
    }

    command void McuSleep.sleep() {
        uint32_t sleepTime;
        // Called from within an atomic secion.

        if(sleepEnabled) {
            sleep_level_t maxSleepLevel = signal AskBeforeSleep.maxSleepLevel();

            sleepTime = call StatsCounter.getNow();
            switch (maxSleepLevel) {
                case SLEEP_LEVEL_DEEP:
                    call NoIdleSleepLed.off();
                    call NoDeepSleepLed.off();
                    enter_sleep();
                    call NoDeepSleepLed.on();
                    call NoIdleSleepLed.on();
                    break;
                case SLEEP_LEVEL_IDLE:
                    call NoIdleSleepLed.off();
                    enter_idle();
                    call NoIdleSleepLed.on();
                    break;
                case SLEEP_LEVEL_NONE:
                    // This actually calls CPUwfi() and it works like no sleep,
                    // assuming all peripherals are PRCMPeripheralSleepEnable'd.
                    PRCMSleep();
                    break;
            }
            sleepTime = call StatsCounter.getNow() - sleepTime;

            SysCtrl_DCDC_VoltageConditionalControl();

            call AtomicAfterSleepInit.init();

            switch (maxSleepLevel) {
                case SLEEP_LEVEL_DEEP:
                    call DeepSleepTime.increment(sleepTime);
                    break;
                case SLEEP_LEVEL_IDLE:
                    call IdleSleepTime.increment(sleepTime);
                    break;
                default:
                    // Do nothing.
            }
        }
    }

    command inline error_t OnOffSwitch.off() {
        sleepEnabled = FALSE;
        return SUCCESS;
    }

    command inline error_t OnOffSwitch.on() {
        sleepEnabled = TRUE;
        return SUCCESS;
    }

    default event inline sleep_level_t AskBeforeSleep.maxSleepLevel() {
        return SLEEP_LEVEL_DEEP;
    }

    default command inline error_t AtomicAfterSleepInit.init() {
        return SUCCESS;
    }

    default command inline error_t AtomicAfterDeepSleepInit.init() {
        return SUCCESS;
    }

    default async command inline uint32_t StatsCounter.getNow() { return 0; }
    default command inline void IdleSleepTime.increment(uint32_t value) { }
    default command inline void DeepSleepTime.increment(uint32_t value) { }
    default command inline void NoIdleSleepLed.on() { }
    default command inline void NoIdleSleepLed.off() { }
    default command inline void NoDeepSleepLed.on() { }
    default command inline void NoDeepSleepLed.off() { }
}
