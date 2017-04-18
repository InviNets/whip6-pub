/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 *
 * Shared counter used for secure generation of random numbers with AES-128.
 */
configuration SharedRandomAESCounterPrv {
    provides interface SharedCounter;
}

implementation {
    components new SharedCounterPub(128 / 8);
    SharedCounter = SharedCounterPub;
}
