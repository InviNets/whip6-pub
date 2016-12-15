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

#ifndef __WHIP6_MICROC_BASE_DEBUG_H__
#define __WHIP6_MICROC_BASE_DEBUG_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains basic debugging functionality.
 */

#if defined(WHIP6_MICROC_DEBUG)

#include <base/ucPrintf.h>
#define dbg(fmt, ...) whip6_printf(fmt, __VA_ARGS__)
#define dbg_char(c) whip6_putchar(c)

#else

#define dbg(fmt, ...)
#define dbg_char(c)

#endif


#endif /* __WHIP6_MICROC_BASE_DEBUG_H__ */
