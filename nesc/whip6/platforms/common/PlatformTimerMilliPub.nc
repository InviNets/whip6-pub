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

#include <PlatformTimerPrv.h>

generic configuration PlatformTimerMilliPub() {
  provides interface Timer<TMilli, uint32_t> @exactlyonce();
  provides interface TimerOverflow;
}
implementation {
  components PlatformTimerMilliPrv;
  Timer = PlatformTimerMilliPrv.TimerMilli[unique(UQ_TIMER_MILLI)];
  TimerOverflow = PlatformTimerMilliPrv;
}

