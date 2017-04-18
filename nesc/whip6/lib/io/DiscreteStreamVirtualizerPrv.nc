/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVec.h>
#include <ipv6/ucIpv6Checksum.h>
#include "soft_reset.h"
#include "DiscreteStreamConfig.h"



/**
 * A virtualizer for a discrete stream.
 *
 * @param num_clients The number of clients. Must be
 *   at least 1.
 *
 * @author Konrad Iwanicki
 */
generic module DiscreteStreamVirtualizerPrv(
        uint8_t num_clients
)
{
    provides
    {
        interface Init @exactlyonce();
        interface SynchronousStarter;
        interface SplitPhaseStopper;
        interface DiscreteStreamReader as Reader[uint8_t channel, uint8_t clientId];
        interface DiscreteStreamWriter as Writer[uint8_t channel, uint8_t clientId];
    }
    uses
    {
        interface InternalDiscreteStreamReader as InternalReader @exactlyonce();
        interface InternalDiscreteStreamWriter as InternalWriter @exactlyonce();
        interface Bit as IsActiveBit @exactlyonce();
        interface Bit as ChangingStateBit @exactlyonce();
        interface Bit as WritingActiveBit @exactlyonce();
        interface Bit as WritingCanceledBit @exactlyonce();
    }
}
implementation
{
    enum
    {
        NUM_CLIENTS = num_clients,
    };
    
    typedef struct client_state_s
    {
        whip6_iov_blist_t *   iovWrPtr;
        size_t                iovRdMaxLen;
        size_t                iovWrLen;
        uint8_t               iovRdChannel;
        uint8_t               iovWrChannel;
    } client_state_t;

    typedef client_state_t client_state_t_xdata; typedef client_state_t_xdata whip6_client_state_t;

    whip6_client_state_t                m_clientData[NUM_CLIENTS];
    uint8_t                             m_wrClientIdx = 0;
    uint8_t                             m_rdClientIdx = NUM_CLIENTS;


#define local_fatal_failure whip6_crashNode()
// #define local_fatal_failure
#define local_passert(cond) if (!(cond)) { local_fatal_failure; }
// #define local_passert(cond)


    static void finishHandlingWriteClient(uint8_t clientId, error_t status);
    task void handleClientsTask();


    command error_t Init.init()
    {
        whip6_client_state_t *   clientPtr;
        uint8_t                  clientId;
        
        clientPtr = &(m_clientData[0]);
        for (clientId = NUM_CLIENTS; clientId > 0; --clientId)
        {
            clientPtr->iovWrPtr = NULL;
            clientPtr->iovRdMaxLen = 0;
            ++clientPtr;
        }
        m_wrClientIdx = 0;
        m_rdClientIdx = NUM_CLIENTS;
        return SUCCESS;
    }



    command error_t SynchronousStarter.start()
    {
        if (call ChangingStateBit.isSet())
        {
            return EBUSY;
        }
        if (call IsActiveBit.isSet())
        {
            return EALREADY;
        }
        if (call InternalReader.startReading() != SUCCESS)
        {
            return FAIL;
        }
        call IsActiveBit.set();
        call WritingActiveBit.clear();
        call WritingCanceledBit.clear();
        return SUCCESS;
    }



    command error_t SplitPhaseStopper.stop()
    {
        if (call ChangingStateBit.isSet())
        {
            return EBUSY;
        }
        if (call IsActiveBit.isClear())
        {
            return EALREADY;
        }
        if (call InternalReader.stopReading() != SUCCESS)
        {
            return FAIL;
        }
        call ChangingStateBit.set();
        post handleClientsTask();
        return SUCCESS;
    }



    default event inline void SplitPhaseStopper.stopped(error_t status)
    {
        // Do nothing.
    }



    command error_t Reader.startReadingDataUnit[uint8_t channel, uint8_t clientId](
            size_t maxSize
    )
    {
        whip6_client_state_t *   clientPtr;
        
        // ASSUMPTION clientId < NUM_CLIENTS
        
        if (call IsActiveBit.isClear() || call ChangingStateBit.isSet())
        {
            return EOFF;
        }
        if (maxSize == 0)
        {
            return EINVAL;
        }
        clientPtr = &(m_clientData[clientId]);
        if (clientPtr->iovRdMaxLen > 0)
        {
            return EBUSY;
        }
        clientPtr->iovRdMaxLen = maxSize;
        clientPtr->iovRdChannel = channel;
        return SUCCESS;
    }



    event whip6_iov_blist_t * InternalReader.readyToRead(
            uint16_t size,
            uint8_t channel
    )
    {
        whip6_client_state_t *   clientPtr;
        whip6_iov_blist_t *      iov;
        uint8_t                  clientId;

        local_passert(m_rdClientIdx >= NUM_CLIENTS);
        if (call IsActiveBit.isClear() || call ChangingStateBit.isSet())
        {
            return NULL;
        }
        clientPtr = &(m_clientData[0]);
        for (clientId = 0; clientId < NUM_CLIENTS; ++clientId)
        {
            if (clientPtr->iovRdChannel == channel &&
                    clientPtr->iovRdMaxLen >= size)
            {
                break;
            }
            ++clientPtr;
        }
        if (clientId >= NUM_CLIENTS)
        {
            return NULL;
        }
        iov = signal Reader.provideIOVForDataUnit[channel, clientId](size);
        if (iov != NULL)
        {
            if (call ChangingStateBit.isSet())
            {
                clientPtr->iovRdMaxLen = 0;
                signal Reader.finishedReadingDataUnit[channel, clientId](iov, 0, EOFF);
                iov = NULL;
            }
            else
            {
                m_rdClientIdx = clientId;
            }
        }
        return iov;
    }



    event void InternalReader.doneReading(
            whip6_iov_blist_t * iov,
            uint16_t size,
            uint8_t channel,
            error_t status
    )
    {
        whip6_client_state_t *   clientPtr;
        uint8_t                  clientId;

        local_passert(m_rdClientIdx < NUM_CLIENTS);
        clientId = m_rdClientIdx;
        m_rdClientIdx = NUM_CLIENTS;
        clientPtr = &(m_clientData[clientId]);
        clientPtr->iovRdMaxLen = 0;
        if (call ChangingStateBit.isSet())
        {
            post handleClientsTask();
        }
        signal Reader.finishedReadingDataUnit[channel, clientId](iov, size, status);
    }



    command error_t Writer.startWritingDataUnit[uint8_t channel, uint8_t clientId](
            whip6_iov_blist_t * iov,
            size_t size
    )
    {
        whip6_client_state_t *   clientPtr;
        
        // ASSUMPTION clientId < NUM_CLIENTS
        
        if (call IsActiveBit.isClear() || call ChangingStateBit.isSet())
        {
            return EOFF;
        }
        if (size == 0)
        {
            return EINVAL;
        }
        if (size > 0x7fffU)
        {
            return ESIZE;
        }
        clientPtr = &(m_clientData[clientId]);
        if (clientPtr->iovWrPtr != NULL)
        {
            return EBUSY;
        }
        clientPtr->iovWrPtr = iov;
        clientPtr->iovWrLen = size;
        clientPtr->iovWrChannel = channel;
        post handleClientsTask();
        return SUCCESS;
    }
    
    
    
    /*command error_t Writer.stopWritingDataUnit[uint8_t channel, uint8_t clientId](
            whip6_iov_blist_t * iov
    )
    {
        whip6_client_state_t *   clientPtr;
        
        // ASSUMPTION clientId < NUM_CLIENTS
        clientPtr = &(m_clientData[clientId]);
        if (clientPtr->iovWrPtr != iov || clientPtr->iovWrChannel != channel)
        {
            return EINVAL;
        }
        if (call WritingActiveBit.isClear() || clientId != m_wrClientIdx)
        {
            clientPtr->iovWrPtr = NULL;
            return SUCCESS;
        }
        return EBUSY;
    }*/



    task void handleClientsTask()
    {
        whip6_client_state_t *   clientPtr;
        uint8_t                  clientId;
        uint8_t                  nextClientId;
        
        if (call IsActiveBit.isClear())
        {
            return;
        }
        if (call ChangingStateBit.isSet())
        {
            if (call WritingActiveBit.isSet())
            {
                if (call WritingCanceledBit.isClear())
                {
                    clientId = m_wrClientIdx;
                    clientPtr = &(m_clientData[clientId]);
                    call InternalWriter.cancelWriting(
                            clientPtr->iovWrPtr,
                            clientPtr->iovWrChannel
                    );
                    call WritingCanceledBit.set();
                }
            }
            else if (m_rdClientIdx == NUM_CLIENTS)
            {
                clientPtr = &(m_clientData[0]);
                for (clientId = NUM_CLIENTS; clientId > 0; --clientId)
                {
                    if (clientPtr->iovWrPtr != NULL)
                    {
                        finishHandlingWriteClient(clientId, ECANCEL);
                        return;
                    }
                    ++clientPtr;
                }
                call WritingCanceledBit.clear();
                call ChangingStateBit.clear();
                call IsActiveBit.clear();
                signal SplitPhaseStopper.stopped(SUCCESS);
            }
        }
        else
        {
            if (call WritingActiveBit.isSet())
            {
                return;
            }
            clientId = m_wrClientIdx;
            do
            {
                nextClientId = clientId + 1;
                if (nextClientId >= NUM_CLIENTS)
                {
                    nextClientId = 0;
                }
                clientPtr = &(m_clientData[clientId]);
                if (clientPtr->iovWrPtr != NULL)
                {
                    error_t status;
                    
                    status =
                            call InternalWriter.initiateWriting(
                                    clientPtr->iovWrPtr,
                                    (uint16_t)clientPtr->iovWrLen,
                                    clientPtr->iovWrChannel
                            );
                    if (status == SUCCESS)
                    {
                        call WritingActiveBit.set();
                        m_wrClientIdx = clientId;
                        return;
                    }
                    else
                    {
                        finishHandlingWriteClient(clientId, status);
                        m_wrClientIdx = nextClientId;
                    }
                }
                clientId = nextClientId;
            }
            while (clientId != m_wrClientIdx);
        }
    }



    static void finishHandlingWriteClient(uint8_t clientId, error_t status)
    {
        whip6_client_state_t *   clientPtr;
        whip6_iov_blist_t *      iov;
        
        clientPtr = &(m_clientData[clientId]);
        iov = clientPtr->iovWrPtr;
        clientPtr->iovWrPtr = NULL;
        post handleClientsTask();
        signal Writer.finishedWritingDataUnit[clientPtr->iovWrChannel, clientId](
            iov,
            clientPtr->iovWrLen,
            status
        );
    }
    
    
    
    event void InternalWriter.doneWriting(
            whip6_iov_blist_t * iov,
            uint16_t size,
            uint8_t channel,
            error_t status
    )
    {
        whip6_client_state_t *   clientPtr;

        clientPtr = &(m_clientData[m_wrClientIdx]);
        if (call WritingActiveBit.isClear() || iov != clientPtr->iovWrPtr)
        {
            return;
        }
        call WritingActiveBit.clear();
        finishHandlingWriteClient(m_wrClientIdx, status);
        ++m_wrClientIdx;
        if (m_wrClientIdx >= NUM_CLIENTS)
        {
            m_wrClientIdx = 0;
        }
    }



    default event inline whip6_iov_blist_t * Reader.provideIOVForDataUnit[uint8_t channel, uint8_t clientId](
            size_t size
    )
    {
        return NULL;
    }



    default event inline void Reader.finishedReadingDataUnit[uint8_t channel, uint8_t clientId](
            whip6_iov_blist_t * iov,
            size_t size,
            error_t status
    )
    {
        // Do nothing.
    }
    
    
    
    default event inline void Writer.finishedWritingDataUnit[uint8_t channel, uint8_t clientId](
            whip6_iov_blist_t * iov,
            size_t size,
            error_t status
    )
    {
        // Do nothing.
    }

#undef local_passert
#undef local_fatal_failure
}
