/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


generic module IOPinLedPub(bool litOnHigh) {
  provides interface Init @exactlyonce();
  provides interface Led;
  
  uses interface IOPin @exactlyonce();
}

implementation {
  command error_t Init.init() {
    call IOPin.makeOutput();
    call Led.off();
    return SUCCESS;
  }

  command void Led.on() {
    if(litOnHigh)
      call IOPin.setHigh();
    else
      call IOPin.setLow();
  }

  command void Led.off() {
    if(litOnHigh)
      call IOPin.setLow();
    else
      call IOPin.setHigh();
  }

  command void Led.set(bool on) {
    if(on)
      call Led.on();
    else
      call Led.off();
  }

  command bool Led.isOn() {
    return litOnHigh && call IOPin.get();
  }

  command void Led.toggle() {
    call IOPin.toggle();
  }
}
