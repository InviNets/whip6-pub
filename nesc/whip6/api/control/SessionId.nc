/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

interface SessionId {
    /* Returns an unique value at every reset (or in some other way
     * specified session boundary). */
    command uint32_t getSessionId();
}
