/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef GLOBAL_TYPES_H
#define GLOBAL_TYPES_H

#include <stdbool.h>

enum {
    FALSE = 0,
    TRUE = 1
};

/**
 * The following should be seen only by the nescc compiler.
 */
#ifdef NESC

struct @atleastonce { };
struct @atmostonce { };
struct @exactlyonce { };

typedef nx_int8_t nx_bool;

#endif // NESC

/*
 * NOTICE iwanicki 2012-12-06:
 * The types below have to be defined for SDCC for 8051.
 * Otherwise, the mangling of data access specifiers
 * does not work correctly.
 */
typedef uint8_t    uint8_t_xdata;
typedef uint16_t   uint16_t_xdata;
typedef uint32_t   uint32_t_xdata;
typedef int8_t     int8_t_xdata;
typedef int16_t    int16_t_xdata;
typedef int32_t    int32_t_xdata;
typedef void       void_xdata;
typedef char       char_xdata;

typedef uint8_t    uint8_t_code;
typedef uint16_t   uint16_t_code;
typedef uint32_t   uint32_t_code;
typedef int8_t     int8_t_code;
typedef int16_t    int16_t_code;
typedef int32_t    int32_t_code;
typedef void       void_code;
typedef char       char_code;

typedef uint8_t    uint8_t_data;
typedef uint16_t   uint16_t_data;
typedef uint32_t   uint32_t_data;
typedef int8_t     int8_t_data;
typedef int16_t    int16_t_data;
typedef int32_t    int32_t_data;
typedef void       void_data;
typedef char       char_data;

#endif /* GLOBAL_TYPES_H */
