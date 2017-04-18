/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


interface RadioClockFrequency
{
  /**
   * Returns the frequency of the radio clock, used with timers of time
   * TRadio.
   *
   * The returned value is constant in time, can be read once and remembered
   * or requested at every use. Implementations should just return a constant
   * value.
   */
  command uint32_t getRadioClockFrequencyInHz();
}
