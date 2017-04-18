/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <stdio.h>


/**
 * A printer of formatted text.
 *
 * @author Konrad Iwanicki
 */
interface CommonFormattedTextPrinter
{
    /**
     * Prints a formatted text.
     * @param fmt The formatting string.
     * @param args The arguments.
     */
    command void printFormattedText(const char * fmt, va_list args);

}
