/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

interface RFCoreClaim {
    command error_t claim();
    command void release();

    async event void onLastCommandDone();
    async event void onRXDone();
    async event void onTXDone();
    async event void onTXPkt();
}
