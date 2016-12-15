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

configuration SdCardConfigPub {
    provides interface Resource as SpiResource;
}

implementation {
    components HalSdCardWirePub as SdCard;

    components new PlatformSPIPub() as Spi;
    SdCard.SpiByte -> Spi;
    SdCard.SpiPacket -> Spi;
    SpiResource = Spi;

    components SdCardSpiConfigPrv as SpiConfig;
    SpiConfig.Mode -> Spi.Mode;
    SpiConfig.Speed -> Spi.Speed;
    SpiConfig.BitOrder -> Spi.BitOrder;
    Spi.ResourceConfigure -> SpiConfig.ResourceConfigure;

    components SdCardPinsConfigPrv as PinsConfig;
    SdCard.SS -> PinsConfig.SS;

    components HVDomainOnOffSwitchPub;
    SdCard.SubPowerSwitch -> HVDomainOnOffSwitchPub;
}
