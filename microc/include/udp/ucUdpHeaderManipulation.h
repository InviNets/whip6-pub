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

#ifndef __WHIP6_MICROC_UDP_UDP_HEADER_MANIPULATION_H__
#define __WHIP6_MICROC_UDP_UDP_HEADER_MANIPULATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the functions for manipulating
 * the header of the User Datagram Protocol (UDP).
 */

#include <ipv6/ucIpv6BasicHeaderTypes.h>
#include <ipv6/ucIpv6Checksum.h>
#include <udp/ucUdpBasicTypes.h>
#include <udp/ucUdpHeaderTypes.h>


#define whip6_udpHeaderGetSrcPort(hdr) ((((udp_port_no_t)((hdr)->srcPort[0])) << 8) | ((hdr)->srcPort[1]))
#define whip6_udpHeaderGetDstPort(hdr) ((((udp_port_no_t)((hdr)->dstPort[0])) << 8) | ((hdr)->dstPort[1]))
#define whip6_udpHeaderGetLength(hdr) ((((ipv6_payload_length_t)((hdr)->length[0])) << 8) | ((hdr)->length[1]))
#define whip6_udpHeaderGetChecksum(hdr) ((((ipv6_checksum_t)((hdr)->checksum[0])) << 8) | ((hdr)->checksum[1]))

#define whip6_udpHeaderSetSrcPort(hdr, port) do { (hdr)->srcPort[0] = (uint8_t)((port) >> 8); (hdr)->srcPort[1] = (uint8_t)(port); } while (0)
#define whip6_udpHeaderSetDstPort(hdr, port) do { (hdr)->dstPort[0] = (uint8_t)((port) >> 8); (hdr)->dstPort[1] = (uint8_t)(port); } while (0)
#define whip6_udpHeaderSetLength(hdr, len) do { (hdr)->length[0] = (uint8_t)((len) >> 8); (hdr)->length[1] = (uint8_t)(len); } while (0)
#define whip6_udpHeaderSetChecksum(hdr, cs) do { (hdr)->checksum[0] = (uint8_t)((cs) >> 8); (hdr)->checksum[1] = (uint8_t)(cs); } while (0)


/**
 * Wraps an I/O vector into an IPv6 packet carrying
 * a UDP datagram.
 * @param payloadIov The I/O vector to be wrapped.
 * @param payloadLen The length of the I/O vector.
 * @param udpHdrIov The I/O vector element that will
 *   receive the UDP header. Its pointers will be overwritten.
 * @param srcSockAddr The address of the source socket.
 * @param dstSockAddr The address of the destination socket.
 * @return A pointer to the IPv6 packet with the
 *   I/O vector as a UDP payload or NULL in case of
 *   an error.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_udpWrapDataIntoOutgoingIpv6PacketCarryingUdpDatagram(
        iov_blist_t MCS51_STORED_IN_RAM * payloadIov,
        size_t payloadLen,
        iov_blist_t MCS51_STORED_IN_RAM * udpHdrIov,
        udp_socket_addr_t MCS51_STORED_IN_RAM const * srcSockAddr,
        udp_socket_addr_t MCS51_STORED_IN_RAM const * dstSockAddr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Unwraps an I/O vector with the data from an IPv6
 * packet carrying a UDP datagram.
 * @param packet The packet.
 * @param udpHdrIov The I/O vector element
 *   containing the UDP header.
 * @param payloadIovPtr A buffer that will receive
 *   the first element of the payload I/O vector.
 * @param payloadLenPtr A buffer that will receive
 *   the length of the payload I/O vector.
 * @return Zero if the I/O vector has been unwrapped correctly,
 *   or nonzero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_udpUnwrapDataFromOutgoingIpv6PacketCarryingUdpDatagram(
        ipv6_packet_t MCS51_STORED_IN_RAM * packet,
        iov_blist_t MCS51_STORED_IN_RAM * udpHdrIov,
        iov_blist_t MCS51_STORED_IN_RAM * * payloadIovPtr,
        size_t * payloadLenPtr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Unwraps an I/O vector with the data from an IPv6
 * packet carrying a UDP datagram.
 * @param iovIter An iterator pointing at the first
 *   byte of the UDP header in the datagram. The
 *   iterator will be modified as a result of this call.
 * @param iovSpare A spare I/O vector element
 * @param payloadLenPtr A buffer that will receive
 *   the length of the payload I/O vector.
 * @return Zero if the I/O vector has been unwrapped correctly,
 *   or nonzero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_udpStripeDataFromIncomingIpv6PacketCarryingUdpDatagram(
        iov_blist_iter_t MCS51_STORED_IN_RAM * iovIter,
        iov_blist_t MCS51_STORED_IN_RAM * iovSpare,
        iov_blist_t MCS51_STORED_IN_RAM * * payloadIovPtr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Restores an I/O vector data into an IPv6 packet
 * carrying a UDP datagram.
 * @param iovIter An iterator pointing at the first
 *   byte of the UDP header in the datagram. The
 *   iterator will be modified as a result of this call.
 * @param payloadIov The I/O vector to be restored.
 * @param iovSpare The spare I/O vector element used for
 *   striping.
 * @return Zero if the operation succeeded,
 *   or nonzero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_udpRestoreDataToIncomingIpv6PacketCarryingUdpDatagram(
        iov_blist_iter_t MCS51_STORED_IN_RAM * iovIter,
        iov_blist_t MCS51_STORED_IN_RAM * payloadIov,
        iov_blist_t MCS51_STORED_IN_RAM * iovSpare
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

#endif /* __WHIP6_MICROC_UDP_UDP_HEADER_MANIPULATION_H__ */
