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


/**
 * @param name The human readable name of the queue.
 *
 * @author Przemyslaw Horban
 */
generic module QueuePrinterPub(typedef qelem_t,
                               typedef qsize_t @integer(),
                               char name[])
{
    uses interface Queue<qelem_t, qsize_t>;
    provides interface Init as PrintStates;
}
implementation
{
    command error_t PrintStates.init() {
        printf("Queue %s: %d / %d\n",
                name, (int)call Queue.getSize(), (int)call Queue.getCapacity());
        return SUCCESS;
    }
}

