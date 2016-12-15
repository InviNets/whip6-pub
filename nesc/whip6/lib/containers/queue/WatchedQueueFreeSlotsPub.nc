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


#include "DimensionTypes.h"
#include "QueueMinSlots.h"

module WatchedQueueFreeSlotsPub
{
    provides interface SimpleRead<uint8_t> as QueueMinFreeSlots;

    // Connected to all queues. Combiner will find minimum.
    uses interface SimpleRead<uint8_t_min> as FreeSlotsInQueue;
}
implementation
{
    command uint8_t QueueMinFreeSlots.read() {
        return call FreeSlotsInQueue.read();
    }
}

