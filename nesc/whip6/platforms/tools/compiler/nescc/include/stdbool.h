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

#ifndef STDBOOL_H
#define STDBOOL_H

// Well, nescc does not really understand _Bool...
typedef uint8_t bool;

#define true	1
#define false	0

#endif
