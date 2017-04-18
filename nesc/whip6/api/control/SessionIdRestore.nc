/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

interface SessionIdRestore {
    /* May be called once with a session id which was valid before
     * a reboot. */
    command error_t restoreSessionId(uint32_t sessionId);
}
