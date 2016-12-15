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
#include <ipv6/ucIpv6Checksum.h>



/**
 * A generic virtualized Internet checksum computer
 * for I/O vectors.
 *
 * @param num_clients The number of the computer's clients.
 * @param max_bytes_iterated_in_task The maximal number of
 *   bytes checksummed in a single task.
 *
 * @author Konrad Iwanicki
 */
generic module GenericVirtualizedIPv6ChecksumComputerPub(
        uint8_t num_clients,
        size_t max_bytes_iterated_in_task
)
{
    provides
    {
        interface Init @exactlyonce();
        interface IPv6ChecksumComputer as Computer[uint8_t clientIdx];
    }
}
implementation
{
// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

    enum
    {
        NUM_CLIENTS = num_clients,
    };

    enum
    {
        MAX_BYTES_ITERATED_IN_TASK = max_bytes_iterated_in_task,
    };



    typedef struct client_state_s
    {
        size_t                          numBytes;
        size_t                          doneBytes;
        ipv6_checksum_computation_t *   comp;
        iov_blist_iter_t *              iovIter;
    } client_state_t;
    
    typedef client_state_t client_state_t_xdata; typedef client_state_t_xdata whip6_client_state_t;



    whip6_client_state_t   m_clientState[NUM_CLIENTS];
    uint8_t                m_clientIdx;



    void finishHandlingClient(
            whip6_client_state_t * clientState,
            uint8_t clientIdx
    );
    void continueHandlingClient(
            whip6_client_state_t * clientState,
            uint8_t clientIdx
    );

    task void doComputationTask();



    command error_t Init.init()
    {
        uint8_t   clientIdx;
        for (clientIdx = 0; clientIdx < NUM_CLIENTS; ++clientIdx)
        {
            m_clientState[clientIdx].numBytes = 0;
        }
        m_clientIdx = 0;
        return SUCCESS;
    }



    command error_t Computer.startChecksumming[uint8_t clientIdx](
            ipv6_checksum_computation_t * checksumPtr,
            iov_blist_iter_t * iovIter,
            size_t numBytes
    )
    {
        whip6_client_state_t *   clientState;

        local_dbg("[InetChecksum] Starting computing a checksum over %lu "
            "bytes for client %u.\r\n", (long unsigned)numBytes,
            (unsigned)clientIdx);

        if (numBytes == 0)
        {
            local_dbg("[InetChecksum] No bytes thus stopping the computation.\r\n");

            return EINVAL;
        }
        clientState = &(m_clientState[clientIdx]);
        if (clientState->numBytes != 0)
        {
            local_dbg("[InetChecksum] The client is busy thus stopping "
                "the computation.\r\n");

            return EBUSY;
        }
        clientState->numBytes = numBytes;
        clientState->doneBytes = 0;
        clientState->comp = checksumPtr;
        clientState->iovIter = iovIter;
        post doComputationTask();

        local_dbg("[InetChecksum] Started the computation.\r\n");

        return SUCCESS;
    }



    void finishHandlingClient(
            whip6_client_state_t * clientState,
            uint8_t clientIdx
    )
    {
        local_dbg("[InetChecksum] Finished computing a checksum over %lu "
            "bytes for client %u.\r\n", (long unsigned)clientState->numBytes,
            (unsigned)clientIdx);

        clientState->numBytes = 0;
        signal Computer.finishChecksumming[clientIdx](
                clientState->comp,
                clientState->iovIter,
                clientState->doneBytes
        );
    }



    void continueHandlingClient(
            whip6_client_state_t * clientState,
            uint8_t clientIdx
    )
    {
        size_t   tmpNumBytes;

        tmpNumBytes = clientState->numBytes - clientState->doneBytes;
        if (tmpNumBytes > MAX_BYTES_ITERATED_IN_TASK)
        {
            tmpNumBytes = MAX_BYTES_ITERATED_IN_TASK;
        }
        tmpNumBytes =
                whip6_ipv6ChecksumComputationProvideWithIovAndAdvanceIovIterator(
                        clientState->comp,
                        clientState->iovIter,
                        tmpNumBytes
                );
        if (tmpNumBytes == 0)
        {
            clientState->numBytes = clientState->doneBytes;
        }
        else
        {
            clientState->doneBytes += tmpNumBytes;
        }

        local_dbg("[InetChecksum] Continued computing a checksum over %lu "
            "bytes for client %u (%lu bytes summed). \r\n",
            (long unsigned)clientState->numBytes, (unsigned)clientIdx,
            (long unsigned)tmpNumBytes);
    }



    task void doComputationTask()
    {
        whip6_client_state_t *   clientState;
        uint8_t                  clientIdx;

        clientIdx = m_clientIdx;
        do
        {
            clientState = &(m_clientState[clientIdx]);
            if (clientState->numBytes > 0)
            {
                local_dbg("[InetChecksum] Handling client %u.\r\n",
                    (unsigned)clientIdx);
                if (clientState->doneBytes >= clientState->numBytes)
                {
                    finishHandlingClient(clientState, clientIdx);
                }
                else
                {
                    continueHandlingClient(clientState, clientIdx);
                }
                m_clientIdx = clientIdx + 1;
                if (m_clientIdx >= NUM_CLIENTS)
                {
                    m_clientIdx = 0;
                }
                post doComputationTask();
                return;
            }
            ++clientIdx;
            if (clientIdx >= NUM_CLIENTS)
            {
                clientIdx = 0;
            }
        }
        while (clientIdx != m_clientIdx);
        local_dbg("[InetChecksum] No clients to handle.\r\n");
    }



    default event inline void Computer.finishChecksumming[uint8_t clientIdx](
            ipv6_checksum_computation_t * checksumPtr,
            iov_blist_iter_t * iovIter,
            size_t checksummedBytes
    )
    {
        // Do nothing.
    }

#undef local_dbg
}

