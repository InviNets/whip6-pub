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

#include "Ieee154.h"


/**
 * A synchronous starter for subsystems.
 *
 * @author Konrad Iwanicki
 */
interface SynchronousStarter
{
    /**
     * Starts the implementing subsystem synchronously.
     * @return SUCCESS if the subsystem has been started
     *   successfully; EALREADY if the subsystem is already
     *   runnig; EBUSY if the subsystem is busy at the
     *   moment, in which case another starting attempt
     *   can be made; ESTATE if the subsystem cannot be
     *   started at all.
     */
    command error_t start();
}

