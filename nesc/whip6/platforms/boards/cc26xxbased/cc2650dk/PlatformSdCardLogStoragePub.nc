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

/* Sector size for SD Card is 512B */
generic configuration PlatformSdCardLogStoragePub(uint32_t startSector, uint32_t numSectors) {
    provides interface LogStorage<uint8_t_xdata>;
}

implementation {
    components new HalSdCardPub() as Hal;

    components SdCardConfigPub as FlashConfig;

    components new TwoResourcesArbiterPub() as Arbiter;
    Arbiter.FirstResource -> FlashConfig.SpiResource;
    Arbiter.SecondResource -> Hal.Resource;

    components new SdCardLogStoragePub(startSector, numSectors) as StoragePrv;
    StoragePrv.HalSdCard -> Hal.HalSdCard;
    StoragePrv.Resource -> Arbiter.Resource;
    LogStorage = StoragePrv.LogStorage;

    components BoardStartupPub;
    StoragePrv.Init <- BoardStartupPub.InitSequence[6];
}
