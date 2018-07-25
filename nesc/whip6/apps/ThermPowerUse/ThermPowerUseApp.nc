/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

configuration ThermPowerUseApp {}

implementation {
   components BoardStartupPub, ThermPowerUsePrv;
   ThermPowerUsePrv.Boot -> BoardStartupPub;

   components new PlatformTimerMilliPub();
   ThermPowerUsePrv.Timer -> PlatformTimerMilliPub;

   components new ICountPub();
   ThermPowerUsePrv.ICount -> ICountPub.EventCount;

   components new TemperatureProviderPub();
   ThermPowerUsePrv.ReadTemp -> TemperatureProviderPub;
}
