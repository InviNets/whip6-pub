/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <stdio.h>

module PersistentErrorLogDumperPrv {
    provides interface Init @exactlyonce();
    uses interface PersistentErrorLog as ErrorLog @exactlyonce();
}
implementation {
    command error_t Init.init() {
        if (!call ErrorLog.isEmpty()) {
            printf("[PersistentErrorLogDumperPrv] Last recorded error:\n");
            printf("[PersistentErrorLogDumperPrv] -- ELOG START --\n");
            call ErrorLog.dump(whip6_putchar);
            printf("[PersistentErrorLogDumperPrv] -- ELOG END --\n");
        }
        return SUCCESS;
    }
}
