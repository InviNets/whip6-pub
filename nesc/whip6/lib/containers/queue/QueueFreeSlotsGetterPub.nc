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


#include "QueueMinSlots.h"

/**
 * @param qelem_t The type of a queue element.
 * @param qsize_t The type counting queue elements.
 *
 * @author Przemyslaw Horban
 */
generic module QueueFreeSlotsGetterPub(typedef qelem_t,
                                              typedef qsize_t @integer())
{
    uses interface Queue<qelem_t, qsize_t>;
    provides interface SimpleRead<uint8_t_min> as FreeSlotsInQueue;
}
implementation
{
    command uint8_t_min FreeSlotsInQueue.read() {
        return call Queue.getCapacity() - call Queue.getSize();
    }
}

