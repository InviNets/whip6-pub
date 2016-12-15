/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
 *
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */

#include <stdio.h>

#include "PlatformProcess.h"
#include "Lists.h"

#define SCHEDULER_WARNPRINTF(...) printf(__VA_ARGS__)
//#define SCHEDULER_DBGPRINTF(...) printf(__VA_ARGS__)
#define SCHEDULER_DBGPRINTF(...)

/* The generic, non-preemptive process scheduler.
 *
 * To work, requires the following functions defined by the HAL:
 *
 * - hal_setup_context_switching()
 *
 *   Initializes CPU for context switching. It may assume that the
 *   current process is psched_current_process and it's on the
 *   psched_run_list.
 *
 * - hal_context_switch()
 *
 *   Saves the current stack to the psched_current_process, then
 *   takes the first element from the psched_run_list and switches
 *   to this process.
 *
 *   This is never called from interrupt context and HAL need not
 *   check it.
 *
 * - hal_in_interrupt()
 *
 *   Returns if it was called from an interrupt context.
 *
 * - hal_stack_init(func, arg, stack_top, size)
 *
 *   Setup stack of a new process, such that when the context switch
 *   to this process is performed, func will be called with the
 *   given (void*) arg.
 *
 * HAL must also provide HalProcess.h with the following definitions:
 *
 * - typedef hal_stack_t
 *
 *   Type of the element of the stack, for example uint32_t on ARM.
 *
 * - HAL_STACK_ALIGNMENT, HAL_STACK_ALIGN
 *
 *   see platforms/parts/mcu/cortex-m3/HalProcess.h
 *
 * - HAL_STACK_PATTERN
 *
 *   A value used to fill the stack when the process is initialized
 *   (done for all processees except the main one). It is also used
 *   to check for stack overflows (if the bottom of the stack
 *   contains a different value on context switch).
 *
 * HAL may assume that:
 *
 * - there are the following symbols provided:
 *   - psched_run_list
 *   - psched_sleep_list
 *   - psched_current_process
 *   (see below)
 *
 * - the first field in process_t is the stack pointer
 */
module GenericProcessSchedulerPub {
    provides interface ProcessScheduler;
}
implementation
{
    /* See the big comment above for the information about how
     * HAL may use these symbols. */
    WHIP6_LIST_TAILQ_HEAD(, process_t) psched_run_list @C()
        __attribute__((used))
            = WHIP6_LIST_TAILQ_HEAD_INITIALIZER(psched_run_list);
    WHIP6_LIST_TAILQ_HEAD(, process_t) psched_sleep_list @C()
        __attribute__((used))
            = WHIP6_LIST_TAILQ_HEAD_INITIALIZER(psched_sleep_list);
    process_t* psched_current_process @C() __attribute__((used));


    static process_t* next_process(void) {
        return WHIP6_LIST_TAILQ_FIRST(&psched_run_list);
    }

    async command process_t* ProcessScheduler.getCurrentProcess() {
        return psched_current_process;
    }

    command void ProcessScheduler.setMainProcess(process_t* p) {
        if (psched_current_process != NULL) {
            panic("More than one call to ProcessScheduler.setMainProcess()");
        }
        psched_current_process = p;
        hal_setup_context_switching();
    }

    static void check_stack_overflow(process_t* p) {
        if (p->stackbot[0] != HAL_STACK_PATTERN) {
            SCHEDULER_WARNPRINTF("[GenericProcessSchedulerPub] Stack marker "
                    "at 0x%08x corrupted (process: %s at 0x%08x). Stack "
                    "overflow?\r\n", p->stackbot, p->name, p);
            panic("Stack marker corrupted.");
        }
    }

    async command void ProcessScheduler.schedule() {
        if (hal_in_interrupt()) {
            // Well, technically it would work, except that all the code outside
            // the scheduler is not preemption-ready.
            panic("ProcessScheduler.schedule() called from interrupt.");
        }
        atomic {
            process_t* p = next_process();
            if (p != psched_current_process) {
                SCHEDULER_DBGPRINTF("[GenericProcessSchedulerPub] Switching "
                    "to process: %s (0x%08x)\r\n", p->name, p);
                check_stack_overflow(psched_current_process);
                hal_context_switch();
            }
        }
    }

    async command bool ProcessScheduler.isContextSwitchPending() {
        atomic {
            return next_process() != psched_current_process;
        }
    }

    static void clear_stack(hal_stack_t *stack_bottom, uint16_t size) {
        uint16_t i;
        for (i = 0; i < size; i++) {
            stack_bottom[i] = HAL_STACK_PATTERN;
        }
    }

    command void ProcessScheduler.initProcess(process_t* p, const char* name,
            void (*func)(void*),
            void* arg, uint8_t prio, hal_stack_t* stack_bottom,
            size_t stack_size) {
        memset(p, 0, sizeof(*p));

        p->state = PROCESS_STATE_READY;
        p->name = name;
        p->prio = prio;

        if (func != NULL) {
            // If func == NULL, then we are initializing the process structure
            // for the main process, which is currently being executed, already
            // has stack etc.
            clear_stack(stack_bottom, stack_size);
            p->stackptr = hal_stack_init(func, arg, &stack_bottom[stack_size],
                    stack_size);
        } else {
            stack_bottom[0] = HAL_STACK_PATTERN;
        }
        p->stackbot = stack_bottom;
        p->stacksize = stack_size;
    }

    command void ProcessScheduler.addProcess(process_t* p) {
        process_t* entry;

        if (p->state != PROCESS_STATE_READY) {
            return;
        }

        entry = NULL;
        atomic {
            WHIP6_LIST_TAILQ_FOREACH(entry, &psched_run_list, run_list) {
                if (p->prio < entry->prio) {
                    break;
                }
            }
            if (entry) {
                WHIP6_LIST_TAILQ_INSERT_BEFORE(entry, p, run_list);
            } else {
                WHIP6_LIST_TAILQ_INSERT_TAIL(&psched_run_list, p, run_list);
            }
        }
    }

    async command void ProcessScheduler.suspend(process_t* p) {
        atomic {
            if (p->state != PROCESS_STATE_SLEEPING) {
                WHIP6_LIST_TAILQ_REMOVE(&psched_run_list, p, run_list);
                WHIP6_LIST_TAILQ_INSERT_TAIL(&psched_sleep_list, p, run_list);
                p->state = PROCESS_STATE_SLEEPING;
            }
        }
    }

    async command void ProcessScheduler.resume(process_t* p) {
        atomic {
            if (p->state != PROCESS_STATE_READY) {
                p->state = PROCESS_STATE_READY;
                WHIP6_LIST_TAILQ_REMOVE(&psched_sleep_list, p, run_list);
                call ProcessScheduler.addProcess(p);
            }
        }
    }

    async command void ProcessScheduler.setPriority(process_t* p, uint8_t prio) {
        atomic {
            p->prio = prio;
            if (p->state == PROCESS_STATE_READY) {
                WHIP6_LIST_TAILQ_REMOVE(&psched_run_list, p, run_list);
                call ProcessScheduler.addProcess(p);
            }
        }
    }
}

#undef SCHEDULER_WARNPRINTF
#undef SCHEDULER_DBGPRINTF
