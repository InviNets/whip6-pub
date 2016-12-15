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

#include <stdint.h>
#include <stdlib.h>
#include <driverlib/flash.h>
#include <fault_handler.h>
#include <core_cm3.h>
#include <tfp_printf.h>

#include "flog.h"

/**
 * @file
 * @author Szymon Acedanski
 *
 * This code saves faults and panics to a dedicated flash sector.
 */

/* These must be defined in a linker script and point to a sector-aligned flash
 * region. */
extern uint8_t _flog;
extern uint8_t _eflog;

/* This must be defined in a linker script and point to the end of SRAM. */
extern uint8_t _sram;
extern uint8_t _esram;


static uint8_t* flog_cursor;

static void flog_init(void) {
    uint32_t sector_size = FlashSectorSizeGet();
    uint8_t* ptr;

    for (ptr = &_flog; ptr < &_eflog; ptr += sector_size) {
        FlashSectorErase((uint32_t)ptr);
    }

    flog_cursor = &_flog;
}

static void flog_putc(char c) {
    if (c == '\xff' || flog_cursor < &_flog || flog_cursor >= &_eflog) {
        return;
    }
    FlashProgram((uint8_t*)&c, (uint32_t)flog_cursor, 1);
    flog_cursor++;
}

static void flog_tfp_putc(void* arg, char c) {
    flog_putc(c);
}

static void flog_printf(const char *fmt, ...) {
    va_list va;
    va_start(va, fmt);
    tfp_format(NULL, flog_tfp_putc, fmt, va);
    va_end(va);
}

void flog_dump(void (*putc)(char c)) {
    uint8_t* ptr;
    for (ptr = &_flog; ptr < &_eflog; ptr++) {
        if (*ptr == '\xff') {
            break;
        }
        putc(*ptr);
    }
}

bool flog_dumparg(bool (*putc)(char c, void* arg), void* arg) {
    uint8_t* ptr;
    for (ptr = &_flog; ptr < &_eflog; ptr++) {
        if (*ptr == '\xff') {
            break;
        }
        if (!putc(*ptr, arg)) {
            return false;
        }
    }
    return true;
}

void flog_clear(void) {
    flog_init();
}

bool flog_is_empty(void) {
    return _flog == 0xff;
}

static void flog_stack(uint32_t* sp) {
    int i;
    uint32_t* start_of_ram = (uint32_t*)&_sram;
    uint32_t* end_of_ram = (uint32_t*)&_esram;
    if (sp < start_of_ram || sp >= end_of_ram) {
        flog_printf(" Invalid stack pointer (0x%08x).\n", sp);
        return;
    }
    for (i = 0; i < 32; i++) {
        if (sp + i >= end_of_ram) {
            break;
        }
        flog_printf(" 0x%08x: 0x%08x\n", sp + i, *(sp + i));
    }
}

static uint32_t* get_stack_pointer(void) {
    uint32_t* sp;
    __asm volatile (
            "MOV %[sp],SP"
            : [sp] "=r" (sp));
    return sp;
}

static uint32_t* get_main_stack_pointer(void) {
    uint32_t* sp;
    __asm volatile (
            "MRS %[sp],MSP"
            : [sp] "=r" (sp));
    return sp;
}

static uint32_t* get_process_stack_pointer(void) {
    uint32_t* sp;
    __asm volatile (
            "MRS %[sp],PSP"
            : [sp] "=r" (sp));
    return sp;
}

static void flog_halt_for_debugger(void) {
    /* Halt if a debugger is connected. */
    if (CoreDebug->DHCSR & CoreDebug_DHCSR_C_DEBUGEN_Msk) {
        __asm volatile ("BKPT");
    }
}

void mcu_fault_handler_hook(struct trap_frame* tf) {
    /* Saves the fault in the given section of the flash, to be
     * made available after reboot. */

    flog_init();

    flog_printf("Unhandled interrupt (%ld), exception sp 0x%08lx\n",
      SCB->ICSR & SCB_ICSR_VECTACTIVE_Msk, (uint32_t)tf->ef);
    flog_printf(" r0:0x%08lx  r1:0x%08lx  r2:0x%08lx  r3:0x%08lx\n",
      tf->ef->r0, tf->ef->r1, tf->ef->r2, tf->ef->r3);
    flog_printf(" r4:0x%08lx  r5:0x%08lx  r6:0x%08lx  r7:0x%08lx\n",
      tf->r4, tf->r5, tf->r6, tf->r7);
    flog_printf(" r8:0x%08lx  r9:0x%08lx r10:0x%08lx r11:0x%08lx\n",
      tf->r8, tf->r9, tf->r10, tf->r11);
    flog_printf("r12:0x%08lx  lr:0x%08lx  pc:0x%08lx psr:0x%08lx\n",
      tf->ef->r12, tf->ef->lr, tf->ef->pc, tf->ef->psr);
    flog_printf("ICSR:0x%08lx HFSR:0x%08lx CFSR:0x%08lx\n",
      SCB->ICSR, SCB->HFSR, SCB->CFSR);
    flog_printf("BFAR:0x%08lx MMFAR:0x%08lx\n", SCB->BFAR, SCB->MMFAR);

    flog_printf("Process Stack:\n");
    flog_stack(get_process_stack_pointer());
    flog_printf("Main Stack:\n");
    flog_stack(get_main_stack_pointer());

    flog_halt_for_debugger();
}

void mcu_panic_hook(uint16_t panic_id) {
    if (panic_id == ARM_HARD_FAULT_PANIC_ID) {
        /* In this case the above mcu_fault_handler_hook already handled
         * the logging. */
        return;
    }

    flog_init();
    flog_printf("Panic #%d\n", (int)panic_id);
    flog_stack(get_stack_pointer());

    flog_halt_for_debugger();
}
