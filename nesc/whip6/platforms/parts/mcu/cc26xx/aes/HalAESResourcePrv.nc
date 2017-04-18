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
 * Resource interface for AES readers and writers. You must request a Resource and keep it
 * for the whole encryption/decryption operation. Each client must bind to different instance
 * (different user_id).
 */
configuration HalAESResourcePrv {
    provides interface Resource[uint8_t user_id];
}

implementation {
    components new SimpleFcfsArbiterPub("HalAESResourcePub") as Arbiter;
    Resource = Arbiter;
}
