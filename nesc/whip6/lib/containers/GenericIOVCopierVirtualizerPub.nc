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

#include <base/ucIoVec.h>



/**
 * The generic module virtualizing I/O vector copying.
 *
 * @param num_clients The number of clients. Must be
 *   at least 1.
 * @param max_bytes_copied_per_task The maximal number
 *   of bytes copied in a single task. Must be at least 1.
 *
 * @author Konrad Iwanicki
 */
generic module GenericIOVCopierVirtualizerPub(
        uint8_t num_clients,
        size_t max_bytes_copied_per_task
)
{
    provides
    {
        interface Init @exactlyonce();
        interface IOVCopier[uint8_t clientId];
    }
}
implementation
{
    enum
    {
        NUM_CLIENTS = num_clients,
    };
    
    enum
    {
        MAX_BYTES_COPIED_PER_TASK = max_bytes_copied_per_task,
    };
    
    typedef struct client_state_s
    {
        whip6_iov_blist_iter_t *   srcIovIter;
        whip6_iov_blist_iter_t *   dstIovIter;
        size_t                     numRequestedBytes;
        size_t                     numCopiedBytes;
    } client_state_t;

    typedef client_state_t client_state_t_xdata; typedef client_state_t_xdata whip6_client_state_t;

    
    whip6_client_state_t   m_clientData[NUM_CLIENTS];
    uint8_t                m_clientIdx = 0;


    task void doCopyTask();


    command error_t Init.init()
    {
        whip6_client_state_t *   clientState;
        uint8_t                  clientId;
        
        for (clientId = 0; clientId < NUM_CLIENTS; ++clientId)
        {
            clientState = &(m_clientData[clientId]);
            clientState->srcIovIter = NULL;
            clientState->dstIovIter = NULL;
        }
        return SUCCESS;
    }



    command error_t IOVCopier.startCopying[uint8_t clientId](
            whip6_iov_blist_iter_t * srcIovIter,
            whip6_iov_blist_iter_t * dstIovIter,
            size_t numBytes
    )
    {
        whip6_client_state_t *   clientState;

        if (clientId >= NUM_CLIENTS)
        {
            return EINVAL;
        }
        clientState = &(m_clientData[clientId]);
        if (clientState->srcIovIter != NULL)
        {
            return EBUSY;
        }
        clientState->srcIovIter = srcIovIter;
        clientState->dstIovIter = dstIovIter;
        clientState->numRequestedBytes = numBytes;
        clientState->numCopiedBytes = 0;
        post doCopyTask();
        return SUCCESS;
    }
    


    command error_t IOVCopier.stopCopying[uint8_t clientId](
            whip6_iov_blist_iter_t * iovIter
    )
    {
        whip6_client_state_t *   clientState;

        if (clientId >= NUM_CLIENTS)
        {
            return EINVAL;
        }
        clientState = &(m_clientData[clientId]);
        if (clientState->srcIovIter != iovIter &&
                clientState->dstIovIter != iovIter)
        {
            return EINVAL;
        }
        clientState->srcIovIter = NULL;
        clientState->dstIovIter = NULL;
        return SUCCESS;
    }


    
    task void doCopyTask()
    {
        whip6_client_state_t *   clientState;
        size_t                   numBytesToCopy;
        uint8_t                  currClientId;
        uint8_t                  nextClientId;

        currClientId = m_clientIdx;
        do
        {
            nextClientId = currClientId + 1;
            if (nextClientId >= NUM_CLIENTS)
            {
                nextClientId = 0;
            }
            clientState = &(m_clientData[currClientId]);
            if (clientState->srcIovIter != NULL)
            {
                numBytesToCopy =
                        clientState->numRequestedBytes -
                                clientState->numCopiedBytes;
                if (numBytesToCopy == 0)
                {
                    whip6_iov_blist_iter_t * srcIovIter;
                    whip6_iov_blist_iter_t * dstIovIter;
                    
                    srcIovIter = clientState->srcIovIter;
                    clientState->srcIovIter = NULL;
                    dstIovIter = clientState->dstIovIter;
                    clientState->dstIovIter = NULL;
                    signal IOVCopier.finishCopying[currClientId](
                            srcIovIter,
                            dstIovIter,
                            clientState->numCopiedBytes
                    );
                }
                else
                {
                    size_t   numCopiedBytes;
                    
                    if (numBytesToCopy > MAX_BYTES_COPIED_PER_TASK)
                    {
                        numBytesToCopy = MAX_BYTES_COPIED_PER_TASK;
                    }
                    numCopiedBytes =
                            whip6_iovIteratorCopyBytesAndMoveForward(
                                    clientState->srcIovIter,
                                    clientState->dstIovIter,
                                    numBytesToCopy
                            );
                    clientState->numCopiedBytes += numCopiedBytes;
                    if (numCopiedBytes < numBytesToCopy)
                    {
                        clientState->numRequestedBytes =
                                clientState->numCopiedBytes;
                    }
                }
                m_clientIdx = nextClientId;
                post doCopyTask();
            }
            currClientId = nextClientId;
        }
        while (currClientId != m_clientIdx);
    }
    
    
    
    default event inline void IOVCopier.finishCopying[uint8_t clientId](
            whip6_iov_blist_iter_t * srcIovIter,
            whip6_iov_blist_iter_t * dstIovIter,
            size_t numCopiedBytes
    )
    {
        // Do nothing.
    }
}

