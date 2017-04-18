/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

 
interface Led {
  command void on();
  command void off();
  command void set(bool on);
  command bool isOn();
  command void toggle();
}
