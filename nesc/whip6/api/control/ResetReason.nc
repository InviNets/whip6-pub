/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


// Feel free to add your own when some new MCU supports it.
// All users should be aware that this enum may expand.
typedef enum {
    RESET_REASON_POWERON,
    RESET_REASON_EXTERNAL,
    RESET_REASON_WATCHDOG,
    RESET_REASON_CLOCK_LOSS,
    RESET_REASON_SOFTWARE,
    RESET_REASON_BROWNOUT,
    RESET_REASON_UNKNOWN = 255,
} reset_reason_t;

interface ResetReason
{
    command reset_reason_t getLastResetReason();
}
