/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucEtx.h>
#include <base/ucIoVec.h>
#include <ieee154/ucIeee154AddressTypes.h>
#include <ieee154/ucIeee154FrameTypes.h>
#include <ipv6/ucIpv6AddressTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * A printer of common objects used in
 * the whip6 code base.
 *
 * @author Konrad Iwanicki
 */
interface CommonObjectPrinter
{
    /**
     * Prints a byte array.
     * @param arrPtr A pointer to the array elements.
     * @param arrLen The length of the array.
     */
    command void printByteArray(
            uint8_t_xdata const * arrPtr,
            size_t arrLen
    );

    /**
     * Prints only the contents of the byte array.
     * @param arrPtr A pointer to the array elements.
     * @param arrLen The length of the array.
     * @param separator The separator of the array
     *   elements or '\0' if there is no separator.
     */
    command void printByteArrayContents(
            uint8_t_xdata const * arrPtr,
            size_t arrLen,
            char separator
    );

    /**
     * Prints a fragment of an I/O vector.
     * @param iovElem A pointer to the I/O vector element.
     * @param iovOffset An offset within the element.
     * @param numToPrint The maxima number of bytes to print.
     * @param separator The separator of the array
     *   elements or '\0' if there is no separator.
     */
    command void printIovFragmentContents(
            whip6_iov_blist_t const * iovElem,
            size_t iovOffset,
            size_t numToPrint,
            char separator
    );

    /**
     * Prints a raw IEEE 802.15.4 address.
     * @param mode The mode of the address.
     * @param dataPtr A pointer to the address
     *   contents.
     */
    command void printIeee154AddrRaw(
            uint8_t mode,
            uint8_t_xdata const * dataPtr
    );

    /**
     * Prints an IEEE 802.15.4 address.
     * @param addr The address to print.
     */
    command void printIeee154AddrAny(
            whip6_ieee154_addr_t const * addr
    );

    /**
     * Prints a raw IEEE 802.15.4 PAN ID.
     * @param dataPtr A pointer to the PAN ID
     *   contents.
     */
    command void printIeee154PanIdRaw(
            uint8_t_xdata const * dataPtr
    );

    /**
     * Prints an IEEE 802.15.4 PAN ID.
     * @param panId The PAN ID to print.
     */
    command void printIeee154PanId(
            whip6_ieee154_pan_id_t const * panId
    );

    /**
     * Prints an IEEE 802.15.4 data frame.
     * @param frame The frame to be printed.
     */
    command void printIeee154DFrameInfo(
            whip6_ieee154_dframe_info_t * frame
    );

    /**
     * Prints an IPv6 address.
     * @param addr The address to be printed.
     */
    command void printIpv6Addr(
            whip6_ipv6_addr_t const * addr
    );

    /**
     * Prints the basic header of an IPv6 packet.
     * @param hdr The basic header to be printed.
     */
    command void printIpv6PacketBasicHeader(
            whip6_ipv6_basic_header_t const * hdr
    );

    /**
     * Prints a basic IPv6 packet  header with a few
     * initial and terminal packet payload bytes.
     * @param pkt The packet to be printed.
     * @param len The length of the payload to print.
     */
    command void printIpv6PacketBounds(
            whip6_ipv6_packet_t * pkt,
            uint8_t len
    );

    /**
     * Prints an ETX value.
     * @param etx The ETX value to be printed.
     */
    command void printEtx(
            etx_metric_host_t etx
    );
}
