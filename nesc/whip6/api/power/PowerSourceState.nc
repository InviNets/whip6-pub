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
 * An interface for reporting power source availability.
 *
 * @author Szymon Acedanski
 */
interface PowerSourceState
{
    /**
     * Event signaled when the state of the power source changed.
     *
     * This event must also be generated after the power source
     * monitoring obtains the first measurement after reset.
     *
     * This event may be generated before all inits have been
     * called.
     */
    event void powerStateChanged(bool available);
}

