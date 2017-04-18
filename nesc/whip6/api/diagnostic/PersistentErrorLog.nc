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
 * @author Szymon Acedanski
 */

interface PersistentErrorLog {
    /* Dumps the content of the persistent error log
     * using the given putc-like function.
     * Does not clear the log. */
    command void dump(void (*putc)(char c));

    /* As above, but passes the given arg to putc and returns early
     * if putc returns false. Returns the last value reutned by putc,
     * or true if the log is empty. */
    command bool dumpWithArg(bool (*putc)(char c, void* arg), void* arg);

    /* Clears the log. */
    command void clear();

    /* Checks if it's empty. */
    command bool isEmpty();
}
