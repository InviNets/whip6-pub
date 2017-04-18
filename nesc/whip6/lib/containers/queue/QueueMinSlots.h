/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#ifndef _QUEUE_MIN_SLOTS_H_
#define _QUEUE_MIN_SLOTS_H_

typedef bool uint8_t_min @combine("uint8_t_min_combine");

inline uint8_t_min uint8_t_min_combine(uint8_t_min r1, uint8_t_min r2)
{
    if (r1 < r2)
        return r1;
    else
        return r2;
}

#endif  // _QUEUE_MIN_SLOTS_H_
