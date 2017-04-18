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
 * Allows to configure IO Pin interrups
 */
interface GPIOEventConfig {
    /**
     * Commands set the edge at which the interrupt will be triggered.
     */
    command void triggerOnRisingEdge();
    command void triggerOnFallingEdge();
    command void triggerOnBothEdges();

    /**
     * Configures the given pin to detect signal change events. Related
     * ExternalEvent interface can only be used after this command was
     * called.
     *
     * The pin should not be used for anything else afterwards.
     */
    command void setupExternalEvent();
}
