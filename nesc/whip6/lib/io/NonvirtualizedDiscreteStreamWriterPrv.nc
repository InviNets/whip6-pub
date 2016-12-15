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
#include "soft_reset.h"
#include "DiscreteStreamConfig.h"



/**
 * An implementation of a discrete stream writer that
 * is not virtualized.
 *
 * @author Konrad Iwanicki
 */
generic module NonvirtualizedDiscreteStreamWriterPrv()
{
    provides
    {
        interface InternalDiscreteStreamWriter as InternalWriter @exactlyonce();
    }
    uses
    {
        interface AsyncWrite<uint8_t> as AsyncWriter @exactlyonce();
        interface IPv6ChecksumComputer as ChecksumComputer @exactlyonce();
    }
}
implementation
{
    enum
    {
        // NOTICE iwanicki 2014-04-18:
        // The buffer has to be at least 7 in the
        // current version of the serial protocol.
        BUFFER_SIZE = 8,
    };
    
    enum
    {
        STATE_VALUE_IDLE = 0x00,
        STATE_VALUE_CHECKSUMMING = 0x01,
        STATE_VALUE_TRANSMITTING = 0x02,
        STATE_VALUE_WRAPPING_UP = 0x03,
        STATE_FLAG_CANCELED = 0x80,
        STATE_MASK_FLAGS = STATE_FLAG_CANCELED,
        STATE_MASK_VALUES = ~(uint8_t)STATE_MASK_FLAGS,
    };
    
    whip6_iov_blist_t *           m_iovPtr = NULL;
    uint16_t                      m_iovRemaining;
    uint16_t                      m_iovTotal;
    uint8_t                       m_iovChannel;
    error_t                       m_iovResult;
    uint8_t                       m_state = STATE_VALUE_IDLE;
    whip6_iov_blist_iter_t        m_iovIter;
    ipv6_checksum_computation_t   m_iovChecksumComp;
    uint8_t                       m_iovBuffer[BUFFER_SIZE];
    uint8_t                       m_iovBufferLen = 0;
    uint8_t                       m_iovBufferFirst = 0;
    
    
    task void completeWritingTask();
    


    command error_t InternalWriter.initiateWriting(
            whip6_iov_blist_t * iov,
            uint16_t size,
            uint8_t channel
    )
    {
        if (iov == NULL || size == 0)
        {
            return EINVAL;
        }
        if (size > 0x7fffU)
        {
            return ESIZE;
        }
        atomic
        {
            if (m_iovPtr != NULL)
            {
                return EBUSY;
            }
            m_iovPtr = iov;
            m_iovRemaining = size;
            m_iovTotal = size;
            m_iovChannel = channel;
            m_iovIter.currElem = m_iovPtr;
            m_iovIter.offset = 0;
            m_state = STATE_VALUE_CHECKSUMMING;
        }
        whip6_ipv6ChecksumComputationInit(&m_iovChecksumComp);
        if (size >= 0x80)
        {
            uint8_t tmp = ((uint8_t)(size >> 8) | 0x80);
            whip6_ipv6ChecksumComputationProvideWithOneByte(
                    &m_iovChecksumComp,
                    tmp
            );
        }
        whip6_ipv6ChecksumComputationProvideWithOneByte(
                &m_iovChecksumComp,
                (uint8_t)size
        );
        whip6_ipv6ChecksumComputationProvideWithOneByte(
                &m_iovChecksumComp,
                channel
        );
        if (call ChecksumComputer.startChecksumming(
                            &m_iovChecksumComp,
                            &m_iovIter,
                            (size_t)size) != SUCCESS)
        {
            atomic
            {
                m_iovPtr = NULL;
                m_state = STATE_VALUE_IDLE;
            }
            return FAIL;
        }
        return SUCCESS;
    }



    static void serializeByte(uint8_t val)
    {
        if (val == DISCRETE_STREAM_SOF ||
                val == DISCRETE_STREAM_EOF ||
                val == DISCRETE_STREAM_ESC)
        {
            m_iovBuffer[m_iovBufferLen++] = DISCRETE_STREAM_ESC;
            m_iovBuffer[m_iovBufferLen++] = (val ^ DISCRETE_STREAM_EXM);
        }
        else
        {
            m_iovBuffer[m_iovBufferLen++] = val;
        }
    }


    
    event void ChecksumComputer.finishChecksumming(
            ipv6_checksum_computation_t * checksumPtr,
            iov_blist_iter_t * iovIter,
            size_t checksummedBytes
    )
    {
        whip6_iov_blist_t *   iov;
        uint8_t               channel;
        error_t               status = SUCCESS;
        
        atomic
        {
            if ((m_state & STATE_FLAG_CANCELED) != 0)
            {
                status = ECANCEL;
            }
            else if (checksummedBytes != (size_t)m_iovRemaining)
            {
                status = FAIL;
            }
            else
            {
                m_iovIter.currElem = m_iovPtr;
                m_iovIter.offset = 0;
                m_iovBufferFirst = 0;
                m_iovBufferLen = 0;
                m_iovBuffer[m_iovBufferLen++] = DISCRETE_STREAM_SOF;
                if (m_iovRemaining >= 0x80)
                {
                    serializeByte((uint8_t)(m_iovRemaining >> 8) | 0x80);
                }
                serializeByte((uint8_t)m_iovRemaining);
                serializeByte(m_iovChannel);
                if (call AsyncWriter.startWrite(m_iovBuffer[m_iovBufferFirst]) == SUCCESS)
                {
                    ++m_iovBufferFirst;
                    --m_iovBufferLen;
                    m_state = STATE_VALUE_TRANSMITTING;
                    return;
                }
            }
            iov = m_iovPtr;
            m_iovPtr = NULL;
            m_state = STATE_VALUE_IDLE;
            channel = m_iovChannel;
        }
        signal InternalWriter.doneWriting(iov, 0, channel, status);
    }



    async event void AsyncWriter.writeDone(error_t result)
    {
        error_t status = SUCCESS;
        atomic
        {
            if (m_state != STATE_VALUE_TRANSMITTING)
            {
                if ((m_state & STATE_MASK_VALUES) != STATE_VALUE_TRANSMITTING)
                {
                    // Ignore.
                    return;
                }
                else if ((m_state & STATE_FLAG_CANCELED) != 0)
                {
                    status = ECANCEL;
                }
                else
                {
                    // NOTICE iwanicki 2014-04-24:
                    // Something really bad happened.
                    status = ESTATE;
                }
            }
            else if (result != SUCCESS)
            {
                status = FAIL;
            }
            else
            {
                if (m_iovBufferLen == 0)
                {
                    // No more data in the buffer to write.
                    if (m_iovRemaining == 0)
                    {
                        // We are done.
                    }
                    else if (m_iovIter.currElem == NULL)
                    {
                        status = EINVAL;
                    }
                    else
                    {
                        m_iovBufferFirst = 0;
                        serializeByte(
                                *(m_iovIter.currElem->iov.ptr + m_iovIter.offset)
                        );
                        ++m_iovIter.offset;
                        if (m_iovIter.offset >= m_iovIter.currElem->iov.len)
                        {
                            m_iovIter.currElem = m_iovIter.currElem->next;
                            m_iovIter.offset = 0;
                        }
                        --m_iovRemaining;
                        if (m_iovRemaining == 0)
                        {
                            ipv6_checksum_t   checksum;
                            
                            checksum =
                                    whip6_ipv6ChecksumComputationFinalize(
                                            &m_iovChecksumComp
                                    );
                            serializeByte((uint8_t)(checksum >> 8));
                            serializeByte((uint8_t)checksum);
                            // NOTICE iwanicki 2015-02-09:
                            // We have space here, because the buffer
                            // is long enough to store the header.
                            m_iovBuffer[m_iovBufferLen++] = DISCRETE_STREAM_EOF;
                        }
                    }
                }
                if (m_iovBufferLen > 0)
                {
                    if (call AsyncWriter.startWrite(m_iovBuffer[m_iovBufferFirst]) == SUCCESS)
                    {
                        ++m_iovBufferFirst;
                        --m_iovBufferLen;
                        return;
                    }
                    status = FAIL;
                }
            }
            m_state = STATE_VALUE_WRAPPING_UP;
            m_iovResult = status;
            post completeWritingTask();
        }
    }
    
    
    
    task void completeWritingTask()
    {
        whip6_iov_blist_t *   iov;
        uint16_t              size;
        uint8_t               channel;
        error_t               status;

        atomic
        {
            if ((m_state & STATE_MASK_VALUES) != STATE_VALUE_WRAPPING_UP)
            {
                // Ignore.
                return;
            }
            else if ((m_state & STATE_FLAG_CANCELED) != 0)
            {
                status = ECANCEL;
            }
            else
            {
                status = m_iovResult;
            }
            m_state = STATE_VALUE_IDLE;
            iov = m_iovPtr;
            m_iovPtr = NULL;
            channel = m_iovChannel;
            size = m_iovTotal - m_iovRemaining;
        }
        signal InternalWriter.doneWriting(iov, size, channel, status);
    }
    
    
    
    command error_t InternalWriter.cancelWriting(
            whip6_iov_blist_t * iov,
            uint8_t channel
    )
    {
        atomic
        {
            if (m_iovPtr != iov || m_iovChannel != channel)
            {
                return EINVAL;
            }
            m_state |= STATE_FLAG_CANCELED;
        }
        return SUCCESS;
    }

}

