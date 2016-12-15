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


#include "PlatformProcess.h"

module HalMainStackProviderPub {
    provides interface StackProvider;
}
implementation{
    extern uint8_t _stack @C();
    extern uint8_t _estack @C();

    command hal_stack_t* StackProvider.getBottomOfStack() {
        return (hal_stack_t*)&_stack;
    }

    command uint16_t StackProvider.getStackSizeInWords() {
        return (hal_stack_t*)&_estack - (hal_stack_t*)&_stack;
    }
}
