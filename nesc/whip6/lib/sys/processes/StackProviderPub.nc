/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include "PlatformProcess.h"

generic module StackProviderPub(size_t stack_words) {
    provides interface StackProvider;
}
implementation
{
    hal_stack_t stack[HAL_STACK_ALIGN(stack_words)];

    inline command hal_stack_t* StackProvider.getBottomOfStack() {
        return stack;
    }

    inline command uint16_t StackProvider.getStackSizeInWords() {
        return stack_words;
    }
}
