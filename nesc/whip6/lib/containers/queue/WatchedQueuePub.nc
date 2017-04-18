/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */



/**
 * Wrapper for the FIFO queue which gives control over it's capcity.
 *
 * @param qelem_t The type of a queue element.
 * @param qsize_t The type counting queue elements.
 * @param max_size The maximal size of the queue.
 * @param name The human readable name of the queue.
 *
 * @author Przemyslaw Horban
 */
generic configuration WatchedQueuePub(typedef qelem_t, typedef qsize_t @integer(),
                                      size_t max_size, char name[])
{
    provides interface Queue<qelem_t, qsize_t>;
}
implementation
{
    components new QueuePub(
            qelem_t,
            qsize_t,
            max_size) as Q;

    Queue = Q;

    components new QueueFreeSlotsGetterPub(qelem_t, qsize_t) as SG;
    SG.Queue -> Q;

    components WatchedQueueFreeSlotsPub;
    WatchedQueueFreeSlotsPub.FreeSlotsInQueue -> SG.FreeSlotsInQueue;

#ifdef PRINTF_IPV6_STACK_QUEUE_OCCUPANCY
    components new QueuePrinterPub(
            qelem_t,
            qsize_t,
            name) as QP;
    QP.Queue -> Q;

    components QueuePrintControllerPub;
    QueuePrintControllerPub.PrintStates -> QP.PrintStates;
#endif  // PRINTF_IPV6_STACK_QUEUE_OCCUPANCY
}
