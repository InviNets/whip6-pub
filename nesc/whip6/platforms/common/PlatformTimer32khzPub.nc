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

#include "PlatformTimerPrv.h"

generic configuration PlatformTimer32khzPub() {
  provides interface Timer<T32khz, uint32_t> @exactlyonce();
  provides interface TimerOverflow;
}
implementation {
  components PlatformTimer32khzPrv;
  Timer = PlatformTimer32khzPrv.Timer32khz[unique(UQ_TIMER_32KHZ)];
  TimerOverflow = PlatformTimer32khzPrv;
}

