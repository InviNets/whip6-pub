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

configuration PlatformTimerMilliPrv {
  provides interface Timer<TMilli, uint32_t> as TimerMilli[uint8_t id];
  provides interface TimerOverflow;
}
implementation {
  components new PlatformTimer32khzPub() as Timer32khz;
  components new TimerScalerPub(T32khz, TMilli, uint32_t, uint32_t, 5) as Timer32khzScaled;
  Timer32khzScaled.TimerFrom -> Timer32khz;
  Timer32khzScaled.TimerOverflowFrom -> Timer32khz;
  TimerOverflow = Timer32khzScaled;
  components new TimerMuxPub(TMilli, uint32_t, uniqueCount(UQ_TIMER_MILLI));
  TimerMuxPub.TimerFrom -> Timer32khzScaled;
  TimerMilli = TimerMuxPub;
}
