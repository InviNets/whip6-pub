/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

configuration SoftResetApp {
}

implementation {
   components BoardStartupPub, SoftResetPrv;
   SoftResetPrv.Boot -> BoardStartupPub;
   
   components LedsPub;
   SoftResetPrv.Led -> LedsPub.Orange;

   components new PlatformTimerMilliPub();
   SoftResetPrv.Timer -> PlatformTimerMilliPub;
   
   components SoftwareResetPub;
   SoftResetPrv.Reset -> SoftwareResetPub;
}
