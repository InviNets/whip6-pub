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
 * Notifies about a physical button press.
 */
interface ButtonPress {
    /**
     * Enables press notification.
     * Disabled by default.
     */
    command void enable();

    /**
     * Disables press notification.
     * Disabled by default.
     */
    command void disable();

    /**
     * Notifies when a button was pressed.
     */
    event void buttonPressed();

    /**
     * Notifies when a button was released.
     *
     * This must also be fired from disable() if buttonPressed() was
     * called without corresponding buttonReleased().
     *
     * In short, buttonPressed() and buttonReleased() events must be
     * balanced.
     */
    event void buttonReleased();
}
