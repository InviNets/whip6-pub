/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

configuration BlockingWriteDemoApp {
}

implementation {
   components BoardStartupPub, BlockingWriteDemoPrv;
   BlockingWriteDemoPrv.Boot -> BoardStartupPub;

   components LedsPub;
   BlockingWriteDemoPrv.Yellow -> LedsPub.Yellow;
   BlockingWriteDemoPrv.Green -> LedsPub.Green;
   BlockingWriteDemoPrv.Orange -> LedsPub.Orange;
   BlockingWriteDemoPrv.Red -> LedsPub.Red;

   components new PlatformTimerMilliPub() as Timer1;
   components new PlatformTimerMilliPub() as Timer2;
   BlockingWriteDemoPrv.Timer1 -> Timer1;
   BlockingWriteDemoPrv.Timer2 -> Timer2;

   components BlockingUART0Pub;
   BlockingWriteDemoPrv.BlockingWrite -> BlockingUART0Pub;
}
