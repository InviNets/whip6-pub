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
#include <stdint.h>
#include <stdbool.h>
#include <fault_handler.h>

extern void printf(const char *fmt, ...);
extern void _panic(uint16_t panicId);

static bool in_fault_handler;

// Default implementation; may be overridden by non-weak symbol
// in MCU-specific code.
__attribute__((weak))
void mcu_fault_handler_hook(struct trap_frame *tf) {
    /* do nothing */
}

__attribute__((used))
void cortex_m3_fault_handler(struct trap_frame *tf) {
    if (in_fault_handler) {
        /* This should never happen on ARM, as double fault results
         * in a lockup state
         * (http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dui0552a/BGBFCHGC.html) */
        printf("Fault handler re-entered.\n");
    } else {
        in_fault_handler = true;

        printf("Unhandled interrupt (%ld), exception sp 0x%08lx\n",
          SCB->ICSR & SCB_ICSR_VECTACTIVE_Msk, (uint32_t)tf->ef);
        printf(" r0:0x%08lx  r1:0x%08lx  r2:0x%08lx  r3:0x%08lx\n",
          tf->ef->r0, tf->ef->r1, tf->ef->r2, tf->ef->r3);
        printf(" r4:0x%08lx  r5:0x%08lx  r6:0x%08lx  r7:0x%08lx\n",
          tf->r4, tf->r5, tf->r6, tf->r7);
        printf(" r8:0x%08lx  r9:0x%08lx r10:0x%08lx r11:0x%08lx\n",
          tf->r8, tf->r9, tf->r10, tf->r11);
        printf("r12:0x%08lx  lr:0x%08lx  pc:0x%08lx psr:0x%08lx\n",
          tf->ef->r12, tf->ef->lr, tf->ef->pc, tf->ef->psr);
        printf("ICSR:0x%08lx HFSR:0x%08lx CFSR:0x%08lx\n",
          SCB->ICSR, SCB->HFSR, SCB->CFSR);
        printf("BFAR:0x%08lx MMFAR:0x%08lx\n", SCB->BFAR, SCB->MMFAR);

        mcu_fault_handler_hook(tf);
    }

    //__asm volatile ("bkpt #0");

    _panic(ARM_HARD_FAULT_PANIC_ID);
}

__attribute__((naked)) void HardFaultISR() {
    __asm volatile (
        "TST     LR,#4\n"
        "ITE     EQ\n"
        "MRSEQ   R3,MSP\n"
        "MRSNE   R3,PSP\n"
        "PUSH    {R3-R11,LR}\n"
        "MOV     R0, SP\n"
        "BL      cortex_m3_fault_handler\n"
        "POP     {R3-R11,LR}\n"
        "BX      LR\n"
    );
}
