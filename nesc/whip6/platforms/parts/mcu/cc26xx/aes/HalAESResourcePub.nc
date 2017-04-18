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
 * for the whole encryption/decryption operation. Each user must instantiate a new instance
 * of this configuration.
 */
generic configuration HalAESResourcePub() {
    provides interface Resource;
}

implementation {
    components HalAESResourcePrv as ResourcePrv;
    Resource = ResourcePrv.Resource[unique("HalAESResourcePub")];
}
