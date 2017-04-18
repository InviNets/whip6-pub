/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include "TimerTypes.h"

interface TimeSynchronizationSource<precision_tag, time_type_t>
{
    /* Signalled by the time synchronization provider to pass the
     * current time read from an external source.
     *
     * This simple interface does not provide any means to specify
     * when exactly the passed value has been read, so it will
     * naturally have some uncertainty.
     */
    event void newTimeReference(time_type_t time);
}
