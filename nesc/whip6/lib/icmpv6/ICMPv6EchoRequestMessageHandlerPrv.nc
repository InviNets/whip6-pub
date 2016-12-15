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
#include <base/ucIoVecAllocation.h>
#include <icmpv6/ucIcmpv6BasicTypes.h>
#include <ipv6/ucIpv6AddressManipulation.h>



/**
 * The main module for handling ICMPv6
 * Echo Request messages.
 *
 * @author Konrad Iwanicki
 */
generic module ICMPv6EchoRequestMessageHandlerPrv(
)
{
    uses
    {
        interface ICMPv6MessageReceiver as EchoRequestReceiver @exactlyonce();
        interface ICMPv6MessageSender as EchoReplySender @exactlyonce();
        interface StatsIncrementer<uint8_t> as NumEchoRequestsHandledStat;
        interface ConfigValue<bool> as ShouldReplyToRequestsToMulticastAddresses;
        interface IOVCopier as DedicatedIOVCopier @exactlyonce();
    }
}
implementation
{
    enum
    {
        MIN_ECHO_REQUEST_PAYLOAD_LENGTH = 4,
    };


    whip6_iov_blist_iter_t *    m_sourcePayloadIterPtr = NULL;
    size_t                      m_sourcePayloadLen;
    whip6_iov_blist_t *         m_targetPayloadIov = NULL;
    whip6_ipv6_addr_t const *   m_targetSrcAddr;
    whip6_ipv6_addr_t const *   m_targetDstAddr;
    whip6_iov_blist_iter_t      m_targetPayloadIter;


    static void finishHandlingMessage(error_t status);

// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

    event inline bool EchoRequestReceiver.isCodeSupported(
            icmpv6_message_code_t msgCode
    )
    {
        return msgCode == 0;
    }



    event error_t EchoRequestReceiver.startReceivingMessage(
            icmpv6_message_code_t msgCode,
            whip6_iov_blist_iter_t * payloadIter,
            size_t payloadLen,
            whip6_ipv6_addr_t const * srcAddr,
            whip6_ipv6_addr_t const * dstAddr
    )
    {
        whip6_iov_blist_t *   newIovPtr;
        
        local_dbg("[ICMPv6] Received an echo message.\r\n");
        if (payloadLen < MIN_ECHO_REQUEST_PAYLOAD_LENGTH)
        {
            local_dbg("[ICMPv6] The received echo message is too short.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        if (m_sourcePayloadIterPtr != NULL)
        {
            local_dbg("[ICMPv6] Unable to iterate over the received echo message.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        if (whip6_ipv6AddrIsMulticast(srcAddr))
        {
            local_dbg("[ICMPv6] The received echo message is sourced at "
                "a multicast address.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        m_targetDstAddr = srcAddr;
        if (whip6_ipv6AddrIsMulticast(dstAddr))
        {
            if (call ShouldReplyToRequestsToMulticastAddresses.get())
            {
                m_targetSrcAddr = NULL;
            }
            else
            {
                local_dbg("[ICMPv6] The received echo message is destined at "
                    "a multicast address on which we do not reply.\r\n");
                goto FAILURE_ROLLBACK_0;
            }
        }
        else
        {
            m_targetSrcAddr = dstAddr;
        }
        newIovPtr = whip6_iovAllocateChain(payloadLen, NULL);
        if (newIovPtr == NULL)
        {
            local_dbg("[ICMPv6] Failed to create a reply to the received "
                "echo message.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        whip6_iovIteratorInitToBeginning(
                newIovPtr,
                &m_targetPayloadIter
        );
        if (call DedicatedIOVCopier.startCopying(
                    payloadIter,
                    &m_targetPayloadIter,
                    payloadLen) != SUCCESS)
        {
            local_dbg("[ICMPv6] Failed to start copying data to a reply "
                "to the received echo message.\r\n");
            goto FAILURE_ROLLBACK_1;
        }
        m_sourcePayloadIterPtr = payloadIter;
        m_sourcePayloadLen = payloadLen;
        m_targetPayloadIov = newIovPtr;
        local_dbg("[ICMPv6] Successfully started copying data to a reply "
            "to the received echo message.\r\n");
        return SUCCESS;

    FAILURE_ROLLBACK_1:
        local_dbg("[ICMPv6] Dropping the received echo message.\r\n");
        whip6_iovFreeChain(newIovPtr);
    FAILURE_ROLLBACK_0:
        return FAIL;
    }    



    event void DedicatedIOVCopier.finishCopying(
            whip6_iov_blist_iter_t * srcIovIter,
            whip6_iov_blist_iter_t * dstIovIter,
            size_t numCopiedBytes
    )
    {
        local_dbg("[ICMPv6] Finished copying data to a reply "
            "to the received echo message.\r\n");
        if (numCopiedBytes != m_sourcePayloadLen)
        {
            local_dbg("[ICMPv6] The number of copied bytes, %u, "
                "does not match the expected number, %u.\r\n",
                (unsigned)numCopiedBytes, (unsigned)m_sourcePayloadLen);
            goto FAILURE_ROLLBACK_0;
        }
        whip6_iovIteratorInitToBeginning(
                m_targetPayloadIov,
                &m_targetPayloadIter
        );
        if (call EchoReplySender.startSendingMessage(
                    0,
                    &m_targetPayloadIter,
                    m_sourcePayloadLen,
                    m_targetSrcAddr,
                    m_targetDstAddr) != SUCCESS)
        {
            local_dbg("[ICMPv6] Failed to start sending a reply "
                "to the received echo message.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        local_dbg("[ICMPv6] Successfully started sending a reply "
            "to the received echo message.\r\n");
        return;
        
    FAILURE_ROLLBACK_0:
        local_dbg("[ICMPv6] Dropping the received echo message.\r\n");
        finishHandlingMessage(FAIL);
    }
    
    
    
    event inline void EchoReplySender.finishSendingMessage(
            whip6_iov_blist_iter_t * payloadIter,
            error_t status
    )
    {
        local_dbg("[ICMPv6] Finished sending a reply "
            "to the received echo message with %s. Finishing handling "
            "the message\r\n", status == SUCCESS ? "success" : "a failure");
        if (payloadIter == &m_targetPayloadIter)
        {
            finishHandlingMessage(status);
        }
    }



    static void finishHandlingMessage(error_t status)
    {
        whip6_iov_blist_iter_t *   payloadIter;
        
        payloadIter = m_sourcePayloadIterPtr;
        m_sourcePayloadIterPtr = NULL;
        whip6_iovFreeChain(m_targetPayloadIov);
        call EchoRequestReceiver.finishReceivingMessage(payloadIter, status);
    }
    
    
    
    default command inline bool ShouldReplyToRequestsToMulticastAddresses.get()
    {
        return TRUE;
    }



    default command inline void NumEchoRequestsHandledStat.increment(uint8_t val)
    {
        // Do nothing.
    }

#undef local_dbg
}

