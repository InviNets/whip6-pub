/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 *
 */
#ifndef HAL_PROCESS_H_INCLUDED
#define HAL_PROCESS_H_INCLUDED

#include <stdbool.h>
#include <stddef.h>

#ifndef ALIGN
#define ALIGN(__n, __a) (                                \
        (((__n) & ((__a) - 1)) == 0)                   ? \
            (__n)                                      : \
            ((__n) + ((__a) - ((__n) & ((__a) - 1))))    \
        )
#endif

typedef uint32_t hal_stack_t;

#define HAL_STACK_ALIGNMENT  (8)
#define HAL_STACK_ALIGN(__nmemb) \
        (ALIGN((__nmemb), HAL_STACK_ALIGNMENT))

#define HAL_STACK_PATTERN 0xdeadbeef

bool hal_in_interrupt();
void hal_setup_context_switching();
hal_stack_t* hal_stack_init(void (*func)(void*), void* arg,
        hal_stack_t *stack_top, size_t size);

/* Takes the first process from the psched_run_list and switches
 * to it. */
void hal_context_switch();

#endif
