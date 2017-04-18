/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

 
interface IOPin {
  command void makeOutput();
  command bool isOutput();
  command void setHigh();
  command void setLow();
  command void toggle();

  command void makeInput();
  command bool isInput();
  command bool get();
}
