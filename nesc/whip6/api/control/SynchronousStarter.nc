/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
