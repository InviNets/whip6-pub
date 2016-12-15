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

#ifndef __WHIP6_BASE_COMPILE_TIME_CONFIG_H__
#define __WHIP6_BASE_COMPILE_TIME_CONFIG_H__

/** The maximal number of bytes processed per task. */
#ifndef WHIP6_BASE_MAX_BYTES_PROCESSED_PER_TASK
#define WHIP6_BASE_MAX_BYTES_PROCESSED_PER_TASK 512
#endif /* WHIP6_BASE_MAX_BYTES_PROCESSED_PER_TASK */

/** The maximal number of concurrently processed I/O vector elements. */
#ifndef WHIP6_BASE_IOV_MAX_CONCURRENT_ELEMENTS
#define WHIP6_BASE_IOV_MAX_CONCURRENT_ELEMENTS 16
#endif /* WHIP6_BASE_IOV_MAX_CONCURRENT_ELEMENTS */

/** The maximal size of an I/O vector element. */
#ifndef WHIP6_BASE_IOV_MAX_ELEMENT_SIZE
#define WHIP6_BASE_IOV_MAX_ELEMENT_SIZE 120
#endif /* WHIP6_BASE_IOV_MAX_ELEMENT_SIZE */

#endif /* __WHIP6_BASE_COMPILE_TIME_CONFIG_H__ */

