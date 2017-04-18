/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */



/**
 * An implementation of a FIFO queue.
 *
 * @param qelem_t The type of a queue element.
 * @param qsize_t The type counting queue elements.
 * @param max_size The maximal size of the queue.
 *
 * @author Konrad Iwanicki
 */
generic module QueuePub(typedef qelem_t, typedef qsize_t @integer(), size_t max_size)
{
    provides interface Queue<qelem_t, qsize_t>;
}
implementation
{

    enum
    {
        NUM_ELEMENTS = max_size,
    };

    qelem_t   m_elems[NUM_ELEMENTS];
    qsize_t   m_firstIdx = 0;
    qsize_t   m_numElems = 0;

    command inline bool Queue.isEmpty()
    {
        return m_numElems == 0;
    }

    command inline bool Queue.isFull()
    {
#ifdef QUEUE_OR_POOL_PRINTF_IF_FULL
        if (m_numElems == NUM_ELEMENTS)
            printf("[QueuePub] isFull returns TRUE\n");
#endif  // QUEUE_OR_POOL_PRINTF_IF_FULL
        return m_numElems == NUM_ELEMENTS;
    }

    command inline qelem_t Queue.peekFirst()
    {
        return m_elems[m_firstIdx];
    }

    command void Queue.dequeueFirst()
    {
        ++m_firstIdx;
        if (m_firstIdx >= NUM_ELEMENTS)
        {
            m_firstIdx = 0;
        }
        --m_numElems;
    }

    command void Queue.enqueueLast(qelem_t elem)
    {
        qsize_t lastIdx = m_firstIdx + m_numElems;
        if (lastIdx >= NUM_ELEMENTS)
        {
            lastIdx -= NUM_ELEMENTS;
        }
        m_elems[lastIdx] = elem;
        ++m_numElems;
#ifdef QUEUE_OR_POOL_PRINTF_IF_FULL
        if (m_numElems > NUM_ELEMENTS)
            printf("[QueuePub] m_numElems > NUM_ELEMENTS (!)\n");
#endif  // QUEUE_OR_POOL_PRINTF_IF_FULL
    }

    command inline qsize_t Queue.getSize()
    {
#ifdef QUEUE_OR_POOL_PRINTF_IF_FULL
        if (m_numElems == NUM_ELEMENTS)
            printf("[QueuePub] getSize == getCapacity\n");
#endif  // QUEUE_OR_POOL_PRINTF_IF_FULL
        return m_numElems;
    }

    command inline qsize_t Queue.getCapacity()
    {
        return NUM_ELEMENTS;
    }

    command qelem_t Queue.peekIth(qsize_t i)
    {
        i += m_firstIdx;
        i %= NUM_ELEMENTS;
        return m_elems[i];
    }

    command void Queue.dequeueIth(qsize_t i)
    {
        qsize_t  j, k;
        if (i < m_numElems)
        {
            j = (m_firstIdx + i) % NUM_ELEMENTS;
            ++i;
            k = (m_firstIdx + i) % NUM_ELEMENTS;
            i = m_numElems - i;
            while (i > 0)
            {
                m_elems[j] = m_elems[k];
                j = k;
                ++k;
                if (k >= NUM_ELEMENTS)
                {
                    k = 0;
                }
                --i;
            }
            --m_numElems;
        }
    }

    command void Queue.clear()
    {
        m_numElems = 0;
        m_firstIdx = 0;
    }
}
