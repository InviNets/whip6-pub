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
#ifndef HALATOMIC_H_INCLUDED
#define HALATOMIC_H_INCLUDED

#include <stdint.h>

typedef uint32_t __nesc_atomic_t;

__attribute__((always_inline))
static inline void __nesc_enable_interrupt()
{
    __nesc_atomic_t newState = 0;
    __asm volatile (
        "msr primask, %0"
        :
        : "r" (newState)
    );
}

__attribute__((always_inline))
static inline void __nesc_disable_interrupt()
{
    __nesc_atomic_t newState = 1;
    __asm volatile (
        "msr primask, %0"
        :
        : "r" (newState)
    );
}

__attribute__((always_inline))
static inline __nesc_atomic_t __nesc_atomic_start()
{
    __nesc_atomic_t oldState = 0;
    __nesc_atomic_t newState = 1;
    __asm volatile(
        "mrs %[old], primask\n"
        "msr primask, %[new]\n"
        : [old] "=&r" (oldState)
        : [new] "r"  (newState)
        : "memory", "cc"
    );
    return oldState;
}

__attribute__((always_inline))
static inline void __nesc_atomic_end(__nesc_atomic_t oldState)
{
    __asm volatile ("" : : : "memory");
    __asm volatile (
        "msr primask, %[old]"
        :
        : [old] "r" (oldState)
    );
}

#endif
