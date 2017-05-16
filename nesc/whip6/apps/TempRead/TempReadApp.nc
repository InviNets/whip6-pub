/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

/**
 * @author Przemyslaw Horban <extremegf@gmail.com>
 * @author Michal Marschall <m.marschall@invinets.com>
 *
 * Reads temperature every second and prints to the console.
 */

configuration TempReadApp {}

implementation {
   components BoardStartupPub, TempReadPrv;
   TempReadPrv.Boot -> BoardStartupPub;

   components new PlatformTimerMilliPub();
   TempReadPrv.Timer -> PlatformTimerMilliPub;

   components new TemperatureProviderPub();

   TempReadPrv.ReadTemp -> TemperatureProviderPub;
}
