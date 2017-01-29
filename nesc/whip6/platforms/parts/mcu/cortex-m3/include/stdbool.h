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
#ifndef STDBOOL_H
#define STDBOOL_H

#ifdef NESC
// Well, nescc does not really understand _Bool...
typedef uint8_t bool;
#else
#define bool	_Bool
#endif

#define true	1
#define false	0

#endif
