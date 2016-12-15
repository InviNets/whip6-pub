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


#include "sys_ctrl.h"

module HalResetReasonPub
{
    provides interface ResetReason;
}
implementation {
    command reset_reason_t ResetReason.getLastResetReason() {
        switch (SysCtrlResetSourceGet()) {
            case RSTSRC_PWR_ON:
                return RESET_REASON_POWERON;
            case RSTSRC_PIN_RESET:
                return RESET_REASON_EXTERNAL;
            case RSTSRC_CLK_LOSS:
                return RESET_REASON_CLOCK_LOSS;
            case RSTSRC_VDD_LOSS:
            case RSTSRC_VDDR_LOSS:
            case RSTSRC_VDDS_LOSS:
                return RESET_REASON_BROWNOUT;
            case RSTSRC_SYSRESET:
            case RSTSRC_WARMRESET:
            case RSTSRC_WAKEUP_FROM_SHUTDOWN:
                return RESET_REASON_SOFTWARE;
            default:
                panic();
                return RESET_REASON_UNKNOWN;

        }
    }
}

