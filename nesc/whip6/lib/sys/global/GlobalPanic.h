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

#ifndef __GLOBAL_PANIC_H
#define __GLOBAL_PANIC_H

// This symbol will be replaced in *.c files
// with unique IDs. Each occurrence will get a
// different id.
extern uint16_t UINT16_ID_UNIQUE_IN_APPC;

void _panic(uint16_t panicId);

// TODO(accek): implement panic with messages on ARM or remove all this

#ifdef PANIC_NO_EXTENDED_MESSAGES
#define panic(message) _panic(UINT16_ID_UNIQUE_IN_APPC)
#else
void _panic_with_message(const char_code* message);
#define panic(message) _panic_with_message(message)
#endif

#endif /* __GLOBAL_PANIC_H */

