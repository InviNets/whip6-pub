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
 * A FIFO queue.
 *
 * @param qelem_t The type of a queue element.
 * @param qsize_t The type counting queue elements.
 *
 * @author Konrad Iwanicki
 */
interface Queue<qelem_t, qsize_t>
{
    /**
     * Checks if the queue is empty.
     * @return TRUE if the queue is empty.
     */
    command bool isEmpty();

    /**
     * Checks if the queue is full.
     * @return TRUE if the queue is full.
     */
    command bool isFull();

    /**
     * Peeks the first element in the queue.
     * The queue must not be empty.
     * @return The first element in the queue.
     */
    command qelem_t peekFirst();

    /**
     * Dequeues the first element from the queue.
     * The queue must not be empty.
     */
    command void dequeueFirst();

    /**
     * Enqueues a given element as the last one
     * in the queue. The queue must not be full.
     * @param elem The element to be enqueued.
     */
    command void enqueueLast(qelem_t elem);

    /**
     * Returns the number of elements in the queue.
     * @return The number of elements in the queue.
     */
    command qsize_t getSize();

    /**
     * Returns the maximal number of elements in the queue.
     * @return The maximal number of elements in the queue.
     */
    command qsize_t getCapacity();

    /**
     * Returns the <tt>i</tt>-th element in the queue.
     * @param i The index of the element.
     * @return The element under the given index. If
     *   the index is greater than or equal to the
     *   number of elements in the queue, the result
     *   is undefined (such a call is thus an error).
     */
    command qelem_t peekIth(qsize_t i);

    /**
     * Removes the <tt>i</tt>-th element from the queue.
     * @param i The index of the element. If the index
     *   is greater than or equal to the number of
     *   elements in the queue, the result is undefined
     *   (such a call is thus an error).
     */
    command void dequeueIth(qsize_t i);

    /**
     * Removes all elements from the queue.
     */
    command void clear();
}

