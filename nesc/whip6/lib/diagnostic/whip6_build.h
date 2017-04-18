/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_BUILD__H__
#define __WHIP6_BUILD__H__

/* http://stackoverflow.com/questions/11697820/how-to-use-date-and-time-predefined-macros-in-as-two-integers-then-stri
   with some changes and improvements */

#define BUILD_DATE_YEAR ((__DATE__[ 7] - '0') * 1000 + (__DATE__[ 8] - '0') * 100 + (__DATE__[ 9] - '0') * 10 + (__DATE__[10] - '0'))

#define BUILD_DATE_MONTH ( \
    (__DATE__[0] == 'J' && __DATE__[1] == 'a' && __DATE__[2] == 'n')? 1 : \
    (__DATE__[0] == 'F' && __DATE__[1] == 'e' && __DATE__[2] == 'b')? 2 : \
    (__DATE__[0] == 'M' && __DATE__[1] == 'a' && __DATE__[2] == 'r')? 3 : \
    (__DATE__[0] == 'A' && __DATE__[1] == 'p' && __DATE__[2] == 'r')? 4 : \
    (__DATE__[0] == 'M' && __DATE__[1] == 'a' && __DATE__[2] == 'y')? 5 : \
    (__DATE__[0] == 'J' && __DATE__[1] == 'u' && __DATE__[2] == 'n')? 6 : \
    (__DATE__[0] == 'J' && __DATE__[1] == 'u' && __DATE__[2] == 'l')? 7 : \
    (__DATE__[0] == 'A' && __DATE__[1] == 'u' && __DATE__[2] == 'g')? 8 : \
    (__DATE__[0] == 'S' && __DATE__[1] == 'e' && __DATE__[2] == 'p')? 9 : \
    (__DATE__[0] == 'O' && __DATE__[1] == 'c' && __DATE__[2] == 't')? 10 : \
    (__DATE__[0] == 'N' && __DATE__[1] == 'o' && __DATE__[2] == 'v')? 11 : \
    (__DATE__[0] == 'D' && __DATE__[1] == 'e' && __DATE__[2] == 'c')? 12 : \
    -1 /* error */ \
)

#define BUILD_DATE_DAY (((__DATE__[4] >= '0')? (__DATE__[4] - '0') * 10 : 0) + (__DATE__[5] - '0'))

#define BUILD_TIME_HOUR ((__TIME__[0] - '0') * 10 + __TIME__[1] - '0')

#define BUILD_TIME_MINUTE ((__TIME__[3] - '0') * 10 + __TIME__[4] - '0')

#define BUILD_TIME_SECOND ((__TIME__[6] - '0') * 10 + __TIME__[7] - '0')

#define BUILD_DATE_AVAILABLE (__DATE__[0] != '?') /* you have to check this in your C code */

#define BUILD_TIME_AVAILABLE (__TIME__[0] != '?') /* you have to check this in your C code */

#endif /* __WHIP6_BUILD__H__ */
