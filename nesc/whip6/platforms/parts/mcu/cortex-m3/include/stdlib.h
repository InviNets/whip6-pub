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
#ifndef STDLIB_H_INCLUDED
#define STDLIB_H_INCLUDED

#include <stddef.h>

int rand(void);

// TODO(accek): comment the implementation limitations
void* malloc(size_t size);
void free(void* ptr);


#endif
