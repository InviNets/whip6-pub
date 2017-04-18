/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <eui/ucEui64Types.h>


/**
 * An IEEE EUI-64 provider.
 *
 * @author Konrad Iwanicki
 */
interface LocalIeeeEui64Provider
{
    /**
     * Reads a local IEEE EUI-64 into
     * a given buffer.
     *
     * Note that this command may
     * perform some I/O, for example,
     * if the EUI-64 is stored by an
     * external chip. Nevertheless,
     * the command is always synchronous.
     *
     * @param eui A pointer to the buffer
     *   that will receive the EUI-64.
     */
    command void read(ieee_eui64_t * eui);

}
