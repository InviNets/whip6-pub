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
// #include <uart_serial_stdio.h>


/**
 * An implementation of a discrete stream writer that
 * is not virtualized.
 *
 * @param buffer_size_t The type describing the size of
 *   an internal buffer.
 * @param buffer_size_val The size of an internal buffer.
 *   Must be at least 1 and at most the maximal value
 *   of <tt>buffer_size_t</tt> plus 1.
 *
 * @author Konrad Iwanicki
 */
generic module NonvirtualizedDiscreteStreamReaderPrv(
    typedef buffer_size_t @integer(),
    size_t buffer_size_val
)
{
    provides
    {
        interface InternalDiscreteStreamReader as InternalReader @exactlyonce();
    }
    uses
    {
        interface ReadNow<uint8_t> as AsyncReader @exactlyonce();
        interface Bit as CanceledBit @exactlyonce();
        interface Timer<TMilli, uint32_t> as PerformanceTimer;
    }
}
implementation
{
    enum
    {
        BUFFER_SIZE =
            buffer_size_val <= 16 ? 16 :
                (buffer_size_val <= 32 ? 32 :
                    (buffer_size_val <= 64 ? 64 :
                        (buffer_size_val <= 128 ? 128 :
                            (buffer_size_val <= 256 ? 256 :
                                (buffer_size_val <= 512 ? 512 :
                                    (buffer_size_val <= 1024 ? 1024 :
                                        (buffer_size_val <= 2048 ? 2048 :
                                            (buffer_size_val <= 4096 ? 4096 : 8192)))))))),
    };
    
    enum
    {
        BUFFER_UPDATE_CHUNK = 64,
    };
    
    enum
    {
        /** The reader is off. */
        STATE_OFF = 0,
        /** The reader is accepting bytes. */
        STATE_ACCEPTING = 1,
        /** The reader is waiting for a SOF byte. */
        STATE_WAITING = 2,
        /** The reader is ignoring all bytes. */
        STATE_IGNORING = 3,
    };
    
    enum
    {
        /** The parser detected a frame. */
        PARSER_START_LENGTH = 0,
        /** The parser has read the first length byte. */
        PARSER_MIDDLE_LENGTH = 1,
        /** The parser has read the entire length field. */
        PARSER_TYPE = 2,
        /** The parser has read the type field and is now reading the payload. */
        PARSER_PAYLOAD = 3,
        /** The parser is about to read the first byte of the CRC. */
        PARSER_CRC_START = 4,
        /** The parser is about to read the last byte of the CRC. */
        PARSER_CRC_END = 5,
        /** The parser is idle. */
        PARSER_IDLE = 6,
    };

#define local_fatal_failure whip6_crashNode()
// #define local_fatal_failure
#define local_passert(cond) if (!(cond)) { local_fatal_failure; }
// #define local_passert(cond)
// #define local_dbg(...) uart_printf(__VA_ARGS__)
#define local_dbg(...)
// #define local_dbg_detail(...) uart_printf(__VA_ARGS__)
#define local_dbg_detail(...)
// #define local_dbg_detail_extreme(...) uart_printf(__VA_ARGS__)
#define local_dbg_detail_extreme(...)

    norace uint8_t                m_bufData[BUFFER_SIZE];
    buffer_size_t                 m_bufExistingIdx = 0;      // the index of the first existing element
    buffer_size_t                 m_bufNonexistingIdx = 0;   // the index of the first nonexisting element
    buffer_size_t                 m_bufUncommittedIdx = 0;   // the index of the first uncommitted element
    uint8_t                       m_bufState = STATE_OFF;

    uint8_t                       m_parserState = PARSER_IDLE;
    uint8_t                       m_parsedType;
    uint16_t                      m_parsedLength;
    ipv6_checksum_t               m_parsedCrc;
    whip6_iov_blist_t *           m_iovPtr = NULL;
    uint16_t                      m_iovRemaining;
    whip6_iov_blist_iter_t        m_iovIter;
    ipv6_checksum_computation_t   m_iovChecksum;


    static bool finishHandlingDataUnitIfNecessary(
            error_t status,
            buffer_size_t parserCurrIdx
    );
    task void processReceivedDataTask();
    
    

    command error_t InternalReader.startReading()
    {
        error_t res;
        atomic
        {
            if (m_bufState != STATE_OFF)
            {
                return EALREADY;
            }
            if (m_iovPtr != NULL)
            {
                return EBUSY;
            }
            res = call AsyncReader.read();
            if (res != SUCCESS)
            {
                return res;
            }
            m_bufExistingIdx = 0;
            m_bufNonexistingIdx = 0;
            m_bufUncommittedIdx = 0;
            m_bufState = STATE_WAITING;
        }
        m_parserState = PARSER_IDLE;
        call CanceledBit.clear();
        return SUCCESS;
    }
    
    
    
    command error_t InternalReader.stopReading()
    {
        atomic
        {
            if (m_bufState == STATE_OFF)
            {
                return EALREADY;
            }
            m_bufState = STATE_OFF;
            post processReceivedDataTask();
        }
        call CanceledBit.set();
        return SUCCESS;
    }


    
#define isBufferEmpty() (m_bufExistingIdx == m_bufNonexistingIdx)

#define isBufferFull() (((m_bufNonexistingIdx + 1) % BUFFER_SIZE) == m_bufExistingIdx)

    static inline void addDataToBuf(uint8_t val)
    {
        m_bufData[m_bufNonexistingIdx] = val;
        m_bufNonexistingIdx = (m_bufNonexistingIdx + 1) % BUFFER_SIZE;
    }
    
    
    /*task void dbgTask()
    {
        buffer_size_t si;
        buffer_size_t ei;
        
        atomic
        {
            si = m_bufExistingIdx;
            ei = m_bufNonexistingIdx;
        }
        local_dbg_detail_extreme("B:");
        for (; si != ei; si = (si + 1) % BUFFER_SIZE)
        {
            local_dbg_detail_extreme(" %02x", m_bufData[si]);
        }
        local_dbg_detail_extreme("\r\n");
        atomic
        {
            m_bufExistingIdx = 0;
            m_bufNonexistingIdx = 0;
        }
    }*/
    
    
    async event void AsyncReader.readDone(error_t status, uint8_t val)
    {
        // NOTICE iwanicki 2015-02-09:
        // It is extremely important that this function
        // be short. In particular, posting a task is
        // extremely long, so we must be sure that when
        // it is done nothing more will be received
        // for a while.
        bool postProcessingTask = FALSE;
        /*atomic
        {
            if (! isBufferFull())
            {
                addDataToBuf(val);
            }
            if (isBufferFull() || val == DISCRETE_STREAM_EOF)
                post dbgTask();
            local_passert(call AsyncReader.read() == SUCCESS);
        }*/
        atomic
        {
            switch (m_bufState)
            {
            case STATE_OFF:
                return;
            case STATE_ACCEPTING:
                if (status != SUCCESS || isBufferFull())
                {
                    m_bufNonexistingIdx = m_bufUncommittedIdx;
                    m_bufState = STATE_IGNORING;
                    postProcessingTask = TRUE;
                }
                else
                {
                    if (val != DISCRETE_STREAM_EOF)
                    {
                        addDataToBuf(val);
                        if (isBufferFull())
                        {
                            m_bufUncommittedIdx = m_bufNonexistingIdx;
                            postProcessingTask = TRUE;
                        }
                    }
                    else
                    {
                        // NOTICE iwanicki 2015-02-09:
                        // Ignore the EOF delimeter to simplify
                        // the parsing code.
                        m_bufUncommittedIdx = m_bufNonexistingIdx;
                        postProcessingTask = TRUE;
                    }
                }
                break;
            case STATE_WAITING:
                if (status == SUCCESS && val == DISCRETE_STREAM_SOF)
                {
                    // NOTICE iwanicki 2014-04-02:
                    // The space is guaranteed by the waiting
                    // state itself.
                    addDataToBuf(val);
                    m_bufState = STATE_ACCEPTING;
                }
                break;
            case STATE_IGNORING:
            default:
                break;
            }
            local_passert(call AsyncReader.read() == SUCCESS);
            if (postProcessingTask)
            {
                local_dbg_detail("post %u\r\n",
                    (unsigned)((uint8_t)(
                        (uint8_t)m_bufNonexistingIdx -
                            (uint8_t)m_bufExistingIdx)));
                post processReceivedDataTask();
            }
        }
    }



    command inline bool InternalReader.isReading()
    {
        return m_iovPtr != NULL;
    }



    task void processReceivedDataTask()
    {
        buffer_size_t   parserCurrIdx = 0;
        buffer_size_t   parserLastIdx = 0;
        buffer_size_t   parserByteCount;
        uint8_t         val;

        local_dbg_detail("timeS %lu\r\n", call PerformanceTimer.getNow());
        atomic
        {
            if (m_bufState == STATE_OFF)
            {
                // m_bufExistingIdx = 0;
                // m_bufNonexistingIdx = 0;
                // m_bufUncommittedIdx = 0;
                val = 1;
            }
            else
            {
                m_bufUncommittedIdx = m_bufNonexistingIdx;
                parserCurrIdx = m_bufExistingIdx;
                parserLastIdx = m_bufNonexistingIdx;
                val = 0;
            }
        }
        if (val)
        {
            if (call CanceledBit.isSet())
            {
                call CanceledBit.clear();
                local_dbg("[Serial] The reception into the I/O vector has "
                    "been canceled by a user.\r\n");
                finishHandlingDataUnitIfNecessary(ECANCEL, parserCurrIdx);
                // NOTICE iwanicki 2014-12-16:
                // If we had a split-phase stopper, this
                // would be the place to signal that
                // stopping this component has finished.
            }
            return;
        }
        local_dbg_detail_extreme(
                "ci=%u;li=%u;s=%u\r\n",
                (unsigned)parserCurrIdx,
                (unsigned)parserLastIdx,
                (unsigned)m_parserState
        );
        parserByteCount = BUFFER_UPDATE_CHUNK;
        while (parserCurrIdx != parserLastIdx && parserByteCount > 0)
        {
            --parserByteCount;
            if (m_bufData[parserCurrIdx] == DISCRETE_STREAM_SOF)
            {
    START_OF_FRAME_ENCOUNTERED:
                local_dbg_detail_extreme("SOF\r\n");
                m_parserState = PARSER_START_LENGTH;
                parserCurrIdx = (parserCurrIdx + 1) % BUFFER_SIZE;
                local_dbg("[Serial] The reception into the I/O vector has "
                    "been canceled due to a congestion.\r\n");
                if (finishHandlingDataUnitIfNecessary(ECANCEL, parserCurrIdx))
                {
                    goto FINISH_PARSING_IN_TASK;
                }
                else
                {
                    local_dbg("[Serial] But the parsing task is continued.\r\n");
                    continue;
                }
            }
            // NOTICE iwanicki 2015-02-09:
            // We do not need to consider the EOF byte,
            // because it is never added to the buffer.
            if (m_bufData[parserCurrIdx] == DISCRETE_STREAM_ESC)
            {
                uint8_t nextIdx = (parserCurrIdx + 1) % BUFFER_SIZE;
                if (nextIdx == parserLastIdx)
                {
                    goto FINISH_PARSING_IN_TASK;
                }
                parserCurrIdx = nextIdx;
                val = m_bufData[parserCurrIdx];
                if (val == DISCRETE_STREAM_SOF)
                {
                    goto START_OF_FRAME_ENCOUNTERED;
                }
                // NOTICE iwanicki 2014-12-16:
                // We could also check whether the value is
                // not the escape sequence, but let's ignore
                // this.
                val ^= DISCRETE_STREAM_EXM;
            }
            else
            {
                val = m_bufData[parserCurrIdx];
            }
            parserCurrIdx = (parserCurrIdx + 1) % BUFFER_SIZE;
            // NOTICE iwanicki 2014-04-06:
            // At this point, val contains the current byte.
            switch (m_parserState)
            {
            case PARSER_START_LENGTH:
                local_dbg_detail_extreme("PSL(%u)\r\n", (unsigned)val);
                whip6_ipv6ChecksumComputationInit(&m_iovChecksum);
                whip6_ipv6ChecksumComputationProvideWithOneByte(
                        &m_iovChecksum,
                        val
                );
                m_parsedLength = (val & 0x7f);
                if ((val & 0x80) != 0)
                {
                    m_parsedLength = (m_parsedLength << 8);
                    m_parserState = PARSER_MIDDLE_LENGTH;
                }
                else
                {
                    m_parserState = PARSER_TYPE;
                }
                break;
            case PARSER_MIDDLE_LENGTH:
                local_dbg_detail_extreme("PML\r\n");
                whip6_ipv6ChecksumComputationProvideWithOneByte(
                        &m_iovChecksum,
                        val
                );
                m_parsedLength |= val;
                m_parserState = PARSER_TYPE;
                break;
            case PARSER_TYPE:
                local_dbg_detail_extreme("PT\r\n");
                if (m_parsedLength == 0)
                {
                    m_parserState = PARSER_IDLE;
                    break;
                }
                whip6_ipv6ChecksumComputationProvideWithOneByte(
                        &m_iovChecksum,
                        val
                );
                m_parsedType = val;
                // NOTICE 2015-06-10:
                // Synchronize because signaling may last
                // a while so we do not want to keep
                // the buffer occupied.
                atomic m_bufExistingIdx = parserCurrIdx;
                local_dbg_detail_extreme("L=%u;T=%u\r\n", (unsigned)m_parsedLength, (unsigned)m_parsedType);
                local_dbg_detail("provide %u\r\n", (unsigned)m_parsedLength);
                m_iovPtr =
                        signal InternalReader.readyToRead(
                                m_parsedLength,
                                m_parsedType
                        );
                if (m_iovPtr == NULL)
                {
                    local_dbg_detail("nothing\r\n");
                    m_parserState = PARSER_IDLE;
                }
                else if (m_iovPtr->iov.len == 0)
                {
                    m_parserState = PARSER_IDLE;
                    local_dbg("[Serial] The reception into the I/O vector has "
                        "been terminated due to vector being invalid.\r\n");
                    finishHandlingDataUnitIfNecessary(EINVAL, parserCurrIdx);
                }
                else
                {
                    m_parserState = PARSER_PAYLOAD;
                    m_iovRemaining = m_parsedLength;
                    m_iovIter.currElem = m_iovPtr;
                    m_iovIter.offset = 0;
                }
                goto FINISH_PARSING_IN_TASK;
            case PARSER_PAYLOAD:
                local_dbg_detail_extreme("PP\r\n");
                whip6_ipv6ChecksumComputationProvideWithOneByte(
                        &m_iovChecksum,
                        val
                );
                *(m_iovIter.currElem->iov.ptr + m_iovIter.offset) = val;
                --m_iovRemaining;
                ++m_iovIter.offset;
                if (m_iovRemaining == 0)
                {
                    m_parserState = PARSER_CRC_START;
                }
                else if (m_iovIter.offset >= m_iovIter.currElem->iov.len)
                {
                    m_iovIter.offset = 0;
                    m_iovIter.currElem = m_iovIter.currElem->next;
                    if (m_iovIter.currElem == NULL)
                    {
                        m_parserState = PARSER_IDLE;
                        local_dbg("[Serial] The reception into the I/O vector has "
                            "been canceled due to an overflow.\r\n");
                        finishHandlingDataUnitIfNecessary(ESIZE, parserCurrIdx);
                        goto FINISH_PARSING_IN_TASK;
                    }
                }
                break;
            case PARSER_CRC_START:
                local_dbg_detail_extreme("PCS\r\n");
                m_parsedCrc = (((ipv6_checksum_t)val) << 8);
                m_parserState = PARSER_CRC_END;
                break;
            case PARSER_CRC_END:
                local_dbg_detail_extreme("PCE\r\n");
                m_parsedCrc |= val;
                m_parserState = PARSER_IDLE;
                m_parsedCrc -=
                        whip6_ipv6ChecksumComputationFinalize(
                                &m_iovChecksum
                        );
                local_dbg("[Serial] The reception into the I/O vector has "
                    "been finished %s (error: %u; size: %u).\r\n",
                    (m_parsedCrc ? "with a wrong CRC" : "successfully"),
                    (unsigned)m_parsedCrc, (unsigned)m_parsedLength);
                finishHandlingDataUnitIfNecessary(
                        m_parsedCrc == 0 ? SUCCESS : FAIL, parserCurrIdx
                );
                goto FINISH_PARSING_IN_TASK;
            case PARSER_IDLE:
            default:
                break;
            }
        } // while
    FINISH_PARSING_IN_TASK:
        atomic
        {
            m_bufExistingIdx = parserCurrIdx;
            if (m_bufState == STATE_OFF)
            {
                local_dbg_detail("repost1 %u\r\n", (unsigned)(
                    (uint8_t)((uint8_t)m_bufNonexistingIdx -
                        (uint8_t)m_bufExistingIdx)));
                post processReceivedDataTask();
            }
            else 
            {
                if (m_bufState == STATE_IGNORING && ! isBufferFull())
                {
                    m_bufState = STATE_WAITING;
                }
                if (! isBufferEmpty())
                {
                    local_dbg_detail("repost2 %u\r\n", (unsigned)(
                        (uint8_t)((uint8_t)m_bufNonexistingIdx -
                            (uint8_t)m_bufExistingIdx)));
                    post processReceivedDataTask();
                }
            }
            local_dbg_detail("rem %u %u %u %u\r\n", (unsigned)(
                (uint8_t)((uint8_t)m_bufNonexistingIdx -
                    (uint8_t)m_bufExistingIdx)),
                (unsigned)m_bufState,
                (unsigned)m_parserState,
                (unsigned)m_iovRemaining);
        }
        local_dbg_detail("timeE %lu\r\n", call PerformanceTimer.getNow());
    }
    


    static bool finishHandlingDataUnitIfNecessary(
            error_t status,
            buffer_size_t parserCurrIdx
    )
    {
        whip6_iov_blist_t *   iovPtr;

        if (m_iovPtr == NULL)
        {
            return FALSE;
        }
        iovPtr = m_iovPtr;
        m_iovPtr = NULL;
        // NOTICE 2015-06-10:
        // Synchronize because signaling may last
        // a while so we do not want to keep
        // the buffer occupied.
        atomic m_bufExistingIdx = parserCurrIdx;
        signal InternalReader.doneReading(
                iovPtr,
                m_parsedLength,
                m_parsedType,
                status
        );
        return TRUE;
    }
    
    
    
    default command inline uint32_t PerformanceTimer.getNow()
    {
        return 0UL;
    }
    
    
    
    event inline void PerformanceTimer.fired()
    {
        // Never invoked.
    }

#undef local_dbg_detail_extreme
#undef local_dbg_detail
#undef local_dbg
#undef local_passert
#undef local_fatal_failure
}

