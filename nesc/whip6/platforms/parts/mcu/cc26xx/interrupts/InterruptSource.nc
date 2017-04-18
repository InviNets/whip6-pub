/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 * @author Szymon Acedanski
 *
 * TODO(accek): document the interface
 * 
 * Interface providing direct entry into an interrupt handler.
 */

interface InterruptSource {
    async command void enable();
    async command void disable();
    async command void clearPending();

    /**
     * Notifies about occurrence of a low level interrupt.
     */
    async event void interruptFired();
}
