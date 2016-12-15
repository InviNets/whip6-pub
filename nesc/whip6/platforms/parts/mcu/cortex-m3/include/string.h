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
#ifndef _STRING_H_
#define	_STRING_H_

#define __need_size_t
#define __need_NULL
#include <stddef.h>

void* memset(void* m, int c, size_t n);
void* memcpy(void* dst0, const void* src0, size_t len0);
int memcmp(const void* m1, const void* m2, size_t n);
void* memmove(void* dst_void, const void* src_void, size_t length);
size_t strlen(const char *str);
char* strncpy(char* dst, const char* src, size_t count);
char* strcpy(char* dst, const char* src);

#endif /* _STRING_H_ */
