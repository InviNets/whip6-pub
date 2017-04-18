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
 * Adapter will simply pass calls from start() to init()
 */
generic module InitToSynchronousStarterPub() {
    uses interface Init;
    provides interface SynchronousStarter;
}
implementation {
    command error_t SynchronousStarter.start() {
        if (call Init.init() == SUCCESS)
            return SUCCESS;
        else
            return ESTATE;
    }
}
