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

