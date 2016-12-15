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
