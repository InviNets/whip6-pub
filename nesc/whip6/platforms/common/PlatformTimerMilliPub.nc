/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
