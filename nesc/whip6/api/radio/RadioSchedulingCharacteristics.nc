/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


interface RadioSchedulingCharacteristics
{
  /**
   * Returns the minimum delay required to successfully call scheduleSending,
   * in ticks of the PlatformRadioTimerPub.
   *
   * Please note that it is theoretically not possible to 100% ensure that
   * scheduled radio operations never return EINVAL because of a too small
   * a delay, because a very long interrupt may happen between the calculation
   * of the delay and the call to RadioComplexOperations.startComplexOp().
   *
   * This command returns a constant value which does not change at runtime.
   */
  command uint32_t minSchedulingDelay();
}
