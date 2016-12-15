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

#include "flog.h"

module HalFLogPub {
    provides interface PersistentErrorLog;
}
implementation {
    command bool PersistentErrorLog.dumpWithArg(bool (*putc)(char c, void* arg),
            void* arg) {
        return flog_dumparg(putc, arg);
    }

    command void PersistentErrorLog.dump(void (*putc)(char c)) {
        flog_dump(putc);
    }

    command void PersistentErrorLog.clear() {
        flog_clear();
    }

    command bool PersistentErrorLog.isEmpty() {
        return flog_is_empty();
    }
}
