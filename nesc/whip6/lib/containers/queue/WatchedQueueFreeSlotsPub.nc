/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
