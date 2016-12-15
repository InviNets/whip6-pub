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


configuration CC26xxTimersPrv {
    provides interface CC26xxTimer[uint8_t num];
}
implementation {
    components new CC26xxTimerPrv(GPT0_BASE, 0) as GPT0;
    CC26xxTimer[0] = GPT0.CC26xxTimer;
    components new CC26xxTimerPrv(GPT1_BASE, 1) as GPT1;
    CC26xxTimer[1] = GPT1.CC26xxTimer;
    components new CC26xxTimerPrv(GPT2_BASE, 2) as GPT2;
    CC26xxTimer[2] = GPT2.CC26xxTimer;
    components new CC26xxTimerPrv(GPT3_BASE, 3) as GPT3;
    CC26xxTimer[3] = GPT3.CC26xxTimer;
}
