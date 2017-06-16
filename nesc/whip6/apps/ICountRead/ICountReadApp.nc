/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

configuration ICountReadApp {}

implementation {
   components BoardStartupPub, ICountReadPrv;
   ICountReadPrv.Boot -> BoardStartupPub;

   components new PlatformTimerMilliPub();
   ICountReadPrv.Timer -> PlatformTimerMilliPub;

   components new ICountPub();

   ICountReadPrv.ICount -> ICountPub.EventCount;
}
