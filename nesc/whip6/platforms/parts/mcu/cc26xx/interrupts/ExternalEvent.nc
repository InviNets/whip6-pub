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
 * @author Przemyslaw <extremegf@gmail.com>
 * 
 * TODO(accek): Verify these assumptions.
 *
 * Provides an abstraction of an interrupt caused by some hardware condition.
 * When the external event occurs, its bit is asserted. Then if asynchronous
 * notifications are enabled, the triggered() event will fire. Otherwise the
 * bit will remain asserted until cleared or asynchronous events are enabled.
 * 
 * It is guaranteed that no other asynchronous event will occur until 
 * triggered() event handler returns.
 * 
 * The bit may be however reasserted at any time. It is the responsibility of
 * the user to ensure this doesn't case problems.
 * 
 * Note that the event handler is placed on top of current execution stack.
 * This increases the risk of overflow, therefore event handlers should defer
 * any complex processing to tasks.
 */
interface ExternalEvent {
    /**
     * Enables or disables asynchronous notifications about events.
     * 
     * When enabled, the triggered() will be fired each time the
     * event occurs. 
     * 
     * @param enable If TRUE then triggered() event will be signaled.
     */
    async command void asyncNotifications(bool enable);
    
    /**
     * Notifies the user about a new asynchronous event.
     */
    async event void triggered();
    
    /**
     * Clears the internal event bit. Often it is necessary to clear it
     * before enabling asynchronous notifications, to prevent old events
     * being triggered.
     */
    async command void clearPending();
}
