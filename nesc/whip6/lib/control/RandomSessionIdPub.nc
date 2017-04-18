/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

generic module RandomSessionIdPub() {
    provides interface SessionId;
    uses interface Random;
}
implementation {
    bool initialized;
    uint32_t session_id;

    command uint32_t SessionId.getSessionId() {
        if (!initialized) {
            initialized = TRUE;
            session_id = call Random.rand32();
        }
        return session_id;
    }
}
