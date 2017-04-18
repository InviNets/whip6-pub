/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * Synchronous enable and disable of a hardware/software component.
 * 
 * @author Przemyslaw <extremegf@gmail.com>
 */

#include "GlobalError.h"

interface OnOffSwitch
{
    /**
     * Turns the functionality on. 
     * 
     * @return Unless SUCCESS is returned, assume functionality is off.
     */
    command error_t on();

    /**
     * Symmetric to on().
     */
    command error_t off();
}
