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

#ifndef GLOBAL_PUTCHAR_H
#define GLOBAL_PUTCHAR_H

// This function must be implemented for the platform-specific printf to work.
// Each platform has its own way of ensuring that this function is somewhere
// actually defined.
void whip6_putchar(char c);

#endif
