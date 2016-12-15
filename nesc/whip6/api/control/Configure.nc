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
 * @author Michal Marschall <m.marschall@invinets.com>
 */
interface Configure {
    /**
     * Configures a resource. Configuring the same resource multiple times should have no
     * (bad) effect.
     */
    command void configure();

    /**
     * Unconfigures a resource if it has been configured. Otherwise, this command has no
     * effect.
     */
    command void unconfigure();
}

