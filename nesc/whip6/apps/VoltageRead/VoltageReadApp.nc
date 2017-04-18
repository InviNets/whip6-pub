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
 * @author Michal Marschall <m.marschall@invinets.com
 */

configuration VoltageReadApp {}

implementation {
   components BoardStartupPub, VoltageReadPrv;
   VoltageReadPrv.Boot -> BoardStartupPub;

   components LedsPub;
   VoltageReadPrv.Led -> LedsPub.Red;

   components new PlatformTimerMilliPub();
   VoltageReadPrv.Timer -> PlatformTimerMilliPub;

   components new VDDDividedBy3ProviderPub();
   VoltageReadPrv.ReadVoltage -> VDDDividedBy3ProviderPub;
}
