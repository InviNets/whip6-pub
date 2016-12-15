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
 * Synchronous enable and disable of a hardware/software component.
 * 
 * @author Przemyslaw Horban <extremegf@gmail.com>
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

