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
#include <ipv6/ucIpv6HeaderProcessorTypes.h>


/**
 * A module for skipping common-format extension
 * headers when processing incoming IPv6 packets.
 *
 * @author Konrad Iwanicki 
 */
module IPv6ExtensionHeaderSkipperForIncomingPacketProcessorPrv
{
    uses
    {
        interface IPv6PacketReceiver[ipv6_next_header_field_t nxtHdrId];
    }
}
implementation
{
    whip6_ipv6_extension_header_generic_t       m_hdrBuf;
    whip6_ipv6_in_packet_processing_state_t *   m_inPacketPtr = NULL;


    task void skipHeaderIfPossibleTask();

#define local_assert(cond) do { if (!(cond)) { uint8_t ___XXX_Assert = 5; printf("Assertion " #cond " failed in file \"%s\", line %u!", __FILE__, __LINE__); while (TRUE) { --___XXX_Assert; }; } } while (0);
//#define local_assert(cond)



    event error_t IPv6PacketReceiver.startReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        local_assert(inPacket->nextHeaderId == nxtHdrId);
        local_assert((inPacket->flags & WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_BEING_PROCESSED) != 0);
        local_assert((inPacket->flags & WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_PROCESSING_DONE) == 0);

        if (m_inPacketPtr != NULL)
        {
            return EBUSY;
        }
        m_inPacketPtr = inPacket;
        post skipHeaderIfPossibleTask();
        return SUCCESS;
    }



    task void skipHeaderIfPossibleTask()
    {
        whip6_ipv6_in_packet_processing_state_t *   inPacket;
        size_t                                      numBytes;
        ipv6_payload_length_t                       hdrLen;
        ipv6_next_header_field_t                    nxtHdrId;
        error_t                                     status;

        local_assert(m_inPacketPtr != NULL);
        local_assert((m_inPacketPtr->flags & WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_BEING_PROCESSED) != 0);
        local_assert((m_inPacketPtr->flags & WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_PROCESSING_DONE) == 0);

        inPacket = m_inPacketPtr;
        m_inPacketPtr = NULL;
        nxtHdrId = inPacket->nextHeaderId;
        status = SUCCESS;

        numBytes =
                whip6_iovIteratorReadAndMoveForward(
                        &inPacket->payloadIter,
                        (uint8_t_xdata *)&m_hdrBuf,
                        sizeof(whip6_ipv6_extension_header_generic_t)
                );
        if (numBytes != sizeof(ipv6_extension_header_generic_t) ||
                ! whip6_iovIteratorIsValid(&inPacket->payloadIter))
        {
            // NOTICE iwanicki 2013-12-10:
            // In theory, we could send an ICMPv6 parameter
            // problem message with code 0 (erroneous header
            // field encountered), but let's suppress it.
            goto FAILURE_ROLLBACK_0;
        }
        hdrLen = m_hdrBuf.hdrExtLen << 3;
        hdrLen += (sizeof(ipv6_extension_header_generic_t) + 7) & ~(ipv6_payload_length_t)0x7;
        numBytes = (size_t)hdrLen - sizeof(ipv6_extension_header_generic_t);
        if (numBytes != whip6_iovIteratorMoveForward(&inPacket->payloadIter, numBytes))
        {
            // NOTICE iwanicki 2013-12-10:
            // In theory, we could send an ICMPv6 parameter
            // problem message with code 0 (erroneous header
            // field encountered), but let's suppress it.
            goto FAILURE_ROLLBACK_0;
        }
        inPacket->nextHeaderId = m_hdrBuf.nextHdr;
        inPacket->payloadOffset += hdrLen;
        goto PROCESSING_FINISH;

    FAILURE_ROLLBACK_0:
        inPacket->flags |= WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_PROCESSING_DONE;
        inPacket->nextHeaderId = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
        status = EINVAL;

    PROCESSING_FINISH:
        call IPv6PacketReceiver.finishReceivingIPv6Packet[nxtHdrId](inPacket, status);
    }


    default command inline void IPv6PacketReceiver.finishReceivingIPv6Packet[ipv6_net_iface_id_t ifaceId](
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
        local_assert(FALSE);
    }

#undef local_assert
}
