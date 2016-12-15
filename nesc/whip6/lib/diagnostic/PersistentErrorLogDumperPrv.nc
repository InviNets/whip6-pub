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

