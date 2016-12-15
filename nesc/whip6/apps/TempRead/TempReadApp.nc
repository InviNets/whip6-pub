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
 * @author Przemyslaw Horban <extremegf@gmail.com>
 * @author Michal Marschall <m.marschall@invinets.com>
 * 
 * Reads temperature every second and prints to the console.
 */

configuration TempReadApp {}

implementation {
   components BoardStartupPub, TempReadPrv;
   TempReadPrv.Boot -> BoardStartupPub;

   components LedsPub;
   TempReadPrv.Led -> LedsPub.Red;

   components new PlatformTimerMilliPub();
   TempReadPrv.Timer -> PlatformTimerMilliPub;

   components new TemperatureProviderPub();
   //components LB718TemperatureProviderPub as TemperatureProviderPub;

   TempReadPrv.ReadTemp -> TemperatureProviderPub;
}
