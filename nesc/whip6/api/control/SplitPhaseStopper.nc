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
 * A split-phase stopper for subsystems.
 *
 * @author Konrad Iwanicki
 */
interface SplitPhaseStopper
{
    /**
     * Stops the implementing subsystem.
     * @return SUCCESS if stopping the subsystem has been started
     *   successfully; EALREADY if the subsystem is already
     *   stopped; EBUSY if the subsystem is busy at the
     *   moment, in which case another starting attempt
     *   can be made; ESTATE if the subsystem cannot be
     *   stopped at all.
     */
    command error_t stop();
    
    /**
     * Signaled when stopping the subsystem has been
     * finished. Note that it does not mean that the
     * subsystem has stopped.
     * @param status SUCCESS if the subsystem has been stopped,
     *   or an error code otherwise, in which case the subsystem
     *   is working normally.
     */
    event void stopped(error_t status);
}

