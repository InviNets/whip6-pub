/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */
#include <string.h>
#include <stdint.h>
#include <stdio.h>

// Needed e.g. by the math library.
static int errno_var;
int* __errno() {
    return &errno_var;
}

/**
 * @file
 * @author Szymon Acedanski
 *
 * C-only code should only use regular asserts. As we don't have the magic
 * panic number assignments for C code, we steal the 666 constant. It may
 * be slightly confusing for some to see the blinks and not have _panic(666)
 * anywhere in app.workingcopy.c, but maybe evetually someone would search
 * the entire code... I don't have a better idea. --accek
 */
void _panic(uint16_t panicId);
void __assert_func(const char* file, size_t line, const char* msg) {
    _panic(666);
}

/* The following functions are derived from newlib, see
 * COPYING.NEWLIB for licensing information.
 *
 * No copyright notices were present in the sources these
 * functions were derived from.
 */

inline void* memset(void* m, int c, size_t n) {
    char *s = (char *) m;
    while (n--)
        *s++ = (char) c;
    return m;
}

inline void* memcpy(void* dst0, const void* src0, size_t len0) {
    char *dst = (char *) dst0;
    char *src = (char *) src0;
    void *save = dst0;
    while (len0--) {
        *dst++ = *src++;
    }
    return save;
}

inline int memcmp(const void* m1, const void* m2, size_t n) {
    unsigned char *s1 = (unsigned char *) m1;
    unsigned char *s2 = (unsigned char *) m2;
    while (n--) {
        if (*s1 != *s2) {
            return *s1 - *s2;
        }
        s1++;
        s2++;
    }
    return 0;
}

inline void* memmove(void* dst_void, const void* src_void, size_t length) {
    char *dst = dst_void;
    const char *src = src_void;
    if (src < dst && dst < src + length) {
        /* Have to copy backwards */
        src += length;
        dst += length;
        while (length--) {
            *--dst = *--src;
        }
    } else {
        while (length--) {
            *dst++ = *src++;
        }
    }
    return dst_void;
}

size_t strlen(const char *str) {
    const char *start = str;
    while (*str)
        str++;
    return str - start;
}

char* strncpy(char* dst, const char* src, size_t count) {
    char *dscan;
    const char *sscan;

    dscan = dst;
    sscan = src;
    while (count > 0)
    {
        --count;
        if ((*dscan++ = *sscan++) == '\0')
            break;
    }
    while (count-- > 0)
        *dscan++ = '\0';

    return dst;
}

char* strcpy(char* dst, const char* src) {
    char *s = dst;

    while ((*dst++ = *src++))
        /* do nothing */;

    return s;
}

// malloc & free

/* To ease the porting of plain-C code, here's a stub implementation of
 * malloc(). It uses a segment of memory between _heap and _eheap symbols
 * to allocate memory from. No free() is supported.
 *
 * nesC glue code must instantiate HalHeapReservationPub() component
 * to reserve heap memory for use with malloc(). */

/* These symbols must be provided by the actual MCU HAL. */
extern uint8_t _heap;
extern uint8_t _eheap;

static uint8_t* alloc_ptr = &_heap;

void* malloc(size_t n) {
    void* ret = alloc_ptr;
    if (alloc_ptr + n > &_eheap) {
        _panic(667);
    }
    alloc_ptr += n;
    printf("[malloc] Allocated %luB, still %luB free\n",
            (unsigned long)n, (unsigned long)(&_eheap - alloc_ptr));
    return ret;
}

void free(void* ptr) {
    if (ptr == NULL) {
        return;
    }
    _panic(668);  // Free is not supported in this dummy implementation.
}

// rand

static uint64_t rand_state;

void srand(unsigned int seed) {
    rand_state = seed;
}

int rand(void) {
    rand_state = rand_state * __extension__ 6364136223846793005LL + 1;
    return (int)(rand_state >> 32);
}
