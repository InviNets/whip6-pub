/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <stdio.h>
#include "tfp_printf.h"

void snprintf(char* s, size_t n, const char *fmt, ...) {
	va_list va;
	va_start(va,fmt);
	tfp_vsprintf(s,fmt,va);
	va_end(va);
}

void sprintf(char* s,const char *fmt, ...) {
	va_list va;
	va_start(va,fmt);
	tfp_vsprintf(s,fmt,va);
	va_end(va);
}

void vprintf(const char *fmt, va_list ap) {
	tfp_vprintf(fmt,ap);
}

void printf(const char *fmt, ...) {
	va_list va;
	va_start(va,fmt);
	tfp_vprintf(fmt,va);
	va_end(va);
}
