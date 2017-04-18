/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

configuration ButtonsTestApp {
}

implementation {
   components BoardStartupPub, ButtonsTestPrv as Prv;
   Prv.Boot -> BoardStartupPub;

   components LedsPub;
   Prv.Led -> LedsPub.Led[0];

   components ButtonsPub;
   Prv.ButtonPress -> ButtonsPub.Buttons;
}
