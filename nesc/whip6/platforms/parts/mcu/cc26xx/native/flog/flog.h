/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @file
 * @author Szymon Acedanski
 */

#ifndef FLOG_H
#define FLOG_H

void flog_clear(void);
void flog_dump(void (*putc)(char c));
bool flog_dumparg(bool (*putc)(char c, void* arg), void* arg);
bool flog_is_empty(void);

#endif
