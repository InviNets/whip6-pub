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

#include "CoreRadioSniffer.h"

configuration CoreRadioSnifferApp {}
implementation {
  components CoreRadioSnifferPrv as AppPrv;

  components BoardStartupPub;
  AppPrv.Boot -> BoardStartupPub;

  components CoreRawRadioPub as RadioPrv;
  AppPrv.RadioInit -> RadioPrv;
  AppPrv.RawFrameReceiver -> RadioPrv;
  AppPrv.RawFrame -> RadioPrv;

  components CoreRadioTimestampingPub as TimestampingPrv;
  AppPrv.RawFrameTimestamp -> TimestampingPrv;

  components new PlatformIOChannelPub(IOMUX_SNIFFER_CHANNEL) as IO;
  AppPrv.IOVWrite -> IO;

  components new QueuePub(platform_frame_t*, uint8_t, 5);
  AppPrv.Queue -> QueuePub;

  components new GenericObjectPoolPub(platform_frame_t, 5) as Allocator;
  AppPrv.AllocatorInit -> Allocator;
  AppPrv.Allocator -> Allocator;

  components LedsPub;
  AppPrv.Led -> LedsPub.Red;

  components new PlatformTimerMilliPub() as LedTimer;
  AppPrv.LedTimer -> LedTimer;
}
