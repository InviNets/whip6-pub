/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2018 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

#include <stdbool.h>

/**
 * Enables/disables production mode.
 *
 * In production mode:
 *  - JTAG is disabled
 *  - any low-level bootloader which allows flash access is disabled
 *
 * @author Szymon Acedanski
 */
interface ProductionModeControl
{
    /**
     * Determines if the device is in production mode.
     */
    command bool isInProductionMode();

    /**
     * Enables/disables production mode.
     *
     * @return SUCCESS, if the mode has been set,
     *         EALREADY, if the device was in the given mode already,
     *         appropriate error value otherwise.
     */
    command error_t setProductionMode(bool flag);
}
