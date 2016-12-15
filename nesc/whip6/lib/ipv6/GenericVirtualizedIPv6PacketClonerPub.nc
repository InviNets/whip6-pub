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
#include <base/ucString.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6PacketAllocation.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * A generic virtualized cloner for IPv6 packets.
 *
 * @param num_clients The number of the cloner's clients.
 * @param max_bytes_copied_in_task The maximal number of
 *   bytes copied in a single task.
 *
 * @author Konrad Iwanicki
 */
generic module GenericVirtualizedIPv6PacketClonerPub(
        uint8_t num_clients,
        size_t max_bytes_copied_in_task
)
{
    provides
    {
        interface Init @exactlyonce();
        interface IPv6PacketCloner as Cloner[uint8_t clientId];
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
        MAX_BYTES_COPIED_IN_TASK = max_bytes_copied_in_task,
    };

    typedef struct client_state_s
    {
        whip6_ipv6_packet_t const *   orgPacket;
        whip6_ipv6_packet_t *         clonePacket;
        size_t                        remainingBytes;
        iov_blist_iter_t              orgIter;
        iov_blist_iter_t              cloneIter;
    } client_state_t;
    typedef client_state_t client_state_t_xdata; typedef client_state_t_xdata whip6_client_state_t;



    whip6_client_state_t   m_clientState[NUM_CLIENTS];
    uint8_t                m_clientIdx;



    void startHandlingClient(
            whip6_client_state_t * clientState,
            uint8_t clientIdx
    );
    void continueHandlingClient(
            whip6_client_state_t * clientState,
            uint8_t clientIdx
    );
    void finishHandlingClient(
            whip6_client_state_t * clientState,
            uint8_t clientIdx,
            error_t status
    );
    task void doClonePacketsTask();



    command error_t Init.init()
    {
        uint8_t   i;
        for (i = 0; i < NUM_CLIENTS; ++i)
        {
            m_clientState[i].orgPacket = NULL;
        }
        m_clientIdx = 0;
        return SUCCESS;
    }



    command error_t Cloner.startCloningIPv6Packet[uint8_t clientIdx](
            whip6_ipv6_packet_t const * orgPacket
    )
    {
        if (m_clientState[clientIdx].orgPacket != NULL)
        {
            return EBUSY;
        }
        m_clientState[clientIdx].orgPacket = orgPacket;
        m_clientState[clientIdx].clonePacket = NULL;
        post doClonePacketsTask();
        return SUCCESS;
    }



    task void doClonePacketsTask()
    {
        whip6_client_state_t *   clientState;
        uint8_t                  clientIdx;

        clientIdx = m_clientIdx;
        do
        {
            clientState = &(m_clientState[clientIdx]);
            if (clientState->orgPacket != NULL)
            {
                if (clientState->clonePacket == NULL)
                {
                    startHandlingClient(clientState, clientIdx);
                }
                else if (clientState->remainingBytes == 0)
                {
                    finishHandlingClient(clientState, clientIdx, SUCCESS);
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
                post doClonePacketsTask();
                return;
            }
            ++clientIdx;
            if (clientIdx >= NUM_CLIENTS)
            {
                clientIdx = 0;
            }
        }
        while (clientIdx != m_clientIdx);
    }



    void startHandlingClient(
            whip6_client_state_t * clientState,
            uint8_t clientIdx
    )
    {
        ipv6_payload_length_t         payloadLen;

        payloadLen =
                whip6_ipv6BasicHeaderGetPayloadLength(
                        &clientState->orgPacket->header
                );
        if ((size_t)payloadLen > whip6_iovGetTotalLength(clientState->orgPacket->firstPayloadIov))
        {
            goto FAILURE_ROLLBACK_0;
        }
        clientState->clonePacket = whip6_ipv6AllocatePacket(payloadLen);
        if (clientState->clonePacket == NULL)
        {
            goto FAILURE_ROLLBACK_0;
        }
        whip6_shortMemCpy(
                (uint8_t_xdata const *)&clientState->orgPacket->header,
                (uint8_t_xdata *)&clientState->clonePacket->header,
                sizeof(whip6_ipv6_basic_header_t)
        );
        clientState->remainingBytes = payloadLen;
        whip6_iovIteratorInitToBeginning(
                clientState->orgPacket->firstPayloadIov,
                &clientState->orgIter
        );
        whip6_iovIteratorInitToBeginning(
                clientState->clonePacket->firstPayloadIov,
                &clientState->cloneIter
        );
        return;

    FAILURE_ROLLBACK_0:
        finishHandlingClient(clientState, clientIdx, FAIL);
    }



    void continueHandlingClient(
            whip6_client_state_t * clientState,
            uint8_t clientIdx
    )
    {
        size_t   numCopied;

        numCopied =
                whip6_iovIteratorCopyBytesAndMoveForward(
                        &clientState->orgIter,
                        &clientState->cloneIter,
                        MAX_BYTES_COPIED_IN_TASK
                );
        clientState->remainingBytes -= numCopied;
        if (numCopied == 0)
        {
            finishHandlingClient(clientState, clientIdx, FAIL);
        }
    }



    void finishHandlingClient(
            whip6_client_state_t * clientState,
            uint8_t clientIdx,
            error_t status
    )
    {
        whip6_ipv6_packet_t const *   orgPacket;
        whip6_ipv6_packet_t *         clonePacket;

        orgPacket = clientState->orgPacket;
        clientState->orgPacket = NULL;
        clonePacket = clientState->clonePacket;
        clientState->clonePacket = NULL;
        if (status != SUCCESS && clonePacket != NULL)
        {
            whip6_ipv6FreePacket(clonePacket);
            clonePacket = NULL;
        }
        signal Cloner.finishCloningIPv6Packet[clientIdx](orgPacket, clonePacket);
    }



    default event inline void Cloner.finishCloningIPv6Packet[uint8_t clientIdx](
            whip6_ipv6_packet_t const * orgPacket,
            whip6_ipv6_packet_t * clonePacket
    )
    {
        // Should never happen.
    }



}

