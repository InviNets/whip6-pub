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
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */

#include <driverlib/sys_ctrl.h>
#include <driverlib/osc.h>
#include <driverlib/prcm.h>
#include <driverlib/ddi.h>
#include <driverlib/aon_rtc.h>

/**
 * @author Szymon Acedanski
 *
 * Power and clocks initialization.
 *
 * Uses code from tidrivers package, marked with the aforecited license.
 */
module HalPowerInitPrv {
    provides interface Init;
    uses interface ShareableOnOff as PeriphDomain;
    uses interface AskBeforeSleep;
    uses interface Timer<TMilli, uint32_t>;
}
implementation
{
    bool disabledLFClockQualifiers = FALSE;
    bool timeoutLFClockQualifiers = FALSE;

    enum {
        LF_CLOCK_QUALIFIERS_TIMEOUT_MS = 256,
    };

    command error_t Init.init() {
        // If something does not work and clock/power issues are suspected,
        // feel free to uncomment this for debugging:
        //SysCtrlPowerEverything();

        // For simplicity, we want the AUX and oscillator control always
        // powered, except sleep. This is what TI-RTOS does too, BTW.
        OSCInterfaceEnable();

        // For simplicity, we may have XOSC_HF running at all times, except
        // sleep. We don't know how much extra power it actually draws.
        //
        // Note: if you consider improving it, consider implementing RC
        // oscillators calibration, too, see TI's swra486.pdf, section 4.5.
        // See the reference implementation in tidrivers'
        // PowerCC26XX_calibrateRCOSC.c.
        //
        // Here we request the XOSC_HF, it's not being activated here yet.
#if CC26XX_XOSC_HF_ALWAYS_ON
        OSCHF_TurnOnXosc();
#endif

        // Enable LF clocking for MCU (watchdog) and AUX (sensor controller)
        // during sleep.
        AONWUCMcuPowerDownConfig(AONWUC_CLOCK_SRC_LF);
        AONWUCAuxPowerDownConfig(AONWUC_CLOCK_SRC_LF);

        // Enable AON RTC 16kHz internal clock. It's needed at least by the
        // radio, and the documentation says: "It is never necessary to reset
        // this bit to 0; it may be set permanently to 1 when the RTC is
        // started."
        HWREGBITW(AON_RTC_BASE + AON_RTC_O_CTL, AON_RTC_CTL_RTC_UPD_EN_BITN)
            = 1;

        call PeriphDomain.on();

        PRCMDomainEnable(PRCM_DOMAIN_VIMS);

        PRCMPeripheralRunEnable(PRCM_PERIPH_GPIO);
        PRCMPeripheralSleepEnable(PRCM_PERIPH_GPIO);
        PRCMPeripheralDeepSleepEnable(PRCM_PERIPH_GPIO);

        PRCMLoadSet();
        while(!PRCMLoadGet()) /* nop */;

        // The timer is needed to wake up the MCU from deep sleep if there is
        // no other event to do it in the near time.
        call Timer.startWithTimeoutFromNow(LF_CLOCK_QUALIFIERS_TIMEOUT_MS);

#if CC26XX_XOSC_HF_ALWAYS_ON
        // Actually switch to XOSC_HF.
        while (!OSCHF_AttemptToSwitchToXosc()) /* nop */;
#endif

        return SUCCESS;
    }

    event inline sleep_level_t AskBeforeSleep.maxSleepLevel() {
        uint32_t sourceLF;

        if (disabledLFClockQualifiers) {
            return SLEEP_LEVEL_DEEP;
        }

        /* query LF clock source */
        sourceLF = OSCClockSourceGet(OSC_SRC_CLK_LF);

        /* is LF source either RCOSC_LF or XOSC_LF yet? */
        if ((sourceLF == OSC_RCOSC_LF) || (sourceLF == OSC_XOSC_LF)) {

            /* yes, disable the LF clock qualifiers */
            DDI16BitfieldWrite(
                AUX_DDI0_OSC_BASE,
                DDI_0_OSC_O_CTL0,
                DDI_0_OSC_CTL0_BYPASS_XOSC_LF_CLK_QUAL_M|
                    DDI_0_OSC_CTL0_BYPASS_RCOSC_LF_CLK_QUAL_M,
                DDI_0_OSC_CTL0_BYPASS_RCOSC_LF_CLK_QUAL_S,
                0x3
            );

            /* enable clock loss detection */
            OSCClockLossEventEnable();

            disabledLFClockQualifiers = TRUE;
            call Timer.stop();
            return SLEEP_LEVEL_DEEP;
        } else {
            if (timeoutLFClockQualifiers) {
                panic("LF clock startup timed out");
            }
            return SLEEP_LEVEL_IDLE;
        }
    }

    event void Timer.fired() {
        // Now only mark that the timer fired, the actual check is performed
        // when going back to sleep.
        timeoutLFClockQualifiers = TRUE;
    }
}
