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

#include <core_cm3.h>
#include <HalProcess.h>

extern void panic(const char* message);

/* Stack for exceptions */
#define EXC_STACK_WORDS 128
uint32_t exc_stack[EXC_STACK_WORDS]
    __attribute__((used, aligned(HAL_STACK_ALIGNMENT)));

/* Initial program status register */
#define INITIAL_xPSR    0x01000000

/* Stack frame structure */
struct stack_frame {
    uint32_t    r4;
    uint32_t    r5;
    uint32_t    r6;
    uint32_t    r7;
    uint32_t    r8;
    uint32_t    r9;
    uint32_t    r10;
    uint32_t    r11;
    uint32_t    r0;
    uint32_t    r1;
    uint32_t    r2;
    uint32_t    r3;
    uint32_t    r12;
    uint32_t    lr;
    uint32_t    pc;
    uint32_t    xpsr;
};

static void __attribute__((naked)) push_r4_to_r11(struct stack_frame *s)
{
    __asm("STMIA   R0,{R4-R11}\n"
          "BX      LR\n");
}

void hal_setup_context_switching() {
    // We will not use privilege separation, but we will use
    // separate stacks for interrupts.
    __asm volatile (
          "MOV     R0,SP\n"          /* Copy MSP to PSP */
          "MSR     PSP,R0\n"
          "MOV     R0,#2\n"          /* Switch SP to PSP */
          "MSR     CONTROL,R0\n"
          "ISB\n"
          "LDR     R0,=exc_stack\n"  /* Set MSP to exc_stack */
          "ADD     R0,%0\n"
          "MSR     MSP,R0\n"
          "B       1f\n"
          ".LTORG\n"
          "1:\n"
     : : "M" (EXC_STACK_WORDS * 4));
}

hal_stack_t* hal_stack_init(void (*func)(void*), void* arg,
        hal_stack_t *stack_top, size_t size) {
    int i;
    hal_stack_t *s;
    struct stack_frame *sf;

    /* Get stack frame pointer */
    s = (hal_stack_t *) ((uint8_t *) stack_top - sizeof(*sf));

    /* Zero out R1-R3, R12, LR */
    for (i = 9; i < 14; ++i) {
        s[i] = 0;
    }

    /* Set registers R4 - R11 on stack. */
    sf = (struct stack_frame *) s;
    push_r4_to_r11(sf);

    /* Set remaining portions of stack frame */
    sf->xpsr = INITIAL_xPSR;
    sf->pc = (uint32_t)func;
    sf->r0 = (uint32_t)arg;

    return (s);
}

bool hal_in_interrupt() {
    return !!__get_IPSR();
}

void hal_context_switch() {
    /* Set PendSV interrupt pending bit to force context switch */
    SCB->ICSR = SCB_ICSR_PENDSVSET_Msk;
}

__attribute__((naked)) void PendSVISR(void) {
    __asm volatile (
        "LDR     R3,=psched_run_list\n"        /* Get highest priority task ready to run */
        "LDR     R2,[R3]\n"                    /* Store in R2 */
        "LDR     R3,=psched_current_process\n" /* Get current task */
        "LDR     R1,[R3]\n"                    /* Current task in R1 */
        "CMP     R1,R2\n"
        "IT      EQ\n"
        "BXEQ    LR\n"                         /* RETI, no task switch */

        "MRS     R12,PSP\n"                    /* Read PSP */
        "STMDB   R12!,{R4-R11}\n"              /* Save Old context */
        "STR     R12,[R1,#0]\n"                /* Update stack pointer in current task */
        "STR     R2,[R3]\n"                    /* psched_current_task = highest ready */

        "LDR     R12,[R2,#0]\n"                /* get stack pointer of task we will start */
        "LDMIA   R12!,{R4-R11}\n"              /* Restore New Context */
        "MSR     PSP,R12\n"                    /* Write PSP */
        "BX      LR\n"                         /* Return to Thread Mode */
        ".LTORG\n"
    );
}
