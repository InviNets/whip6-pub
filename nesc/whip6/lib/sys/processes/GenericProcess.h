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
 */

#ifndef GENERIC_PROCESS_H_INCLUDED
#define GENERIC_PROCESS_H_INCLUDED

#include "Lists.h"
#include "HalProcess.h"

enum {
    // Only the idle process should run with this priority.
    // Otherwise, MCU sleep would break.
    _PROCESS_PRIO_IDLE = 255,

    PROCESS_PRIO_LOWEST = 254,
    PROCESS_PRIO_DEFAULT = 128,
    PROCESS_PRIO_HIGHEST = 0,
};

typedef enum {
    PROCESS_STATE_READY,
    PROCESS_STATE_SLEEPING,
} process_state_t;

typedef struct process_s {
    // HAL assumes that the first field is the saved stack pointer.
    // Do not change this.
    hal_stack_t* stackptr;

    hal_stack_t* stackbot;  // Bottom of the stack
    uint16_t stacksize;

    uint8_t prio;
    process_state_t state;

    const char* name;

    /* Used to chain task to either the run or sleep list */
    WHIP6_LIST_TAILQ_ENTRY(struct process_s) run_list;
} process_t;

#endif
