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
#ifndef STDIO_H_INCLUDED
#define STDIO_H_INCLUDED

#include <stddef.h>
#include <stdarg.h>

void snprintf(char* s,size_t n,const char *fmt, ...);
void sprintf(char* s,const char *fmt, ...);
void vprintf(const char *fmt, va_list ap);
void printf(const char *fmt, ...);

#endif
