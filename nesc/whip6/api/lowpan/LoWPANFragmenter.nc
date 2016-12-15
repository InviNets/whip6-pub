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

#include <6lowpan/uc6LoWPANHeaderTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * A fragmenter of 6LoWPAN frames.
 *
 * @author Konrad Iwanicki
 */
interface LoWPANFragmenter
{
    /**
     * Starts fragmenting an IPv6 packet, possibly
     * with some additional 6LoWPAN headers that will
     * be added to each frame generated for the packet.
     * @param packet The packet to be fragmented.
     * @param loWPANHdrs Additional 6LoWPAN headers
     *   that will be added to each frame created for
     *   the packet. A NULL value indicates that no
     *   additional 6LoWPAN headers will precede
     *   fragmentation headers.
     * @return If the fragmenter has been unable to start
     *   fragmentation, zero is returned. Otherwise,
     *   a token is returned that is bound to the packet.
     *   In the latter case, the <tt>ipv6PacketFragmented</tt>
     *   event is guaranteed to be signaled later. The
     *   token value is from 1 to the maximal number of
     *   concurrently fragmented packets (inclusive).
     */
    command uint8_t startFragmentingIpv6Packet(
        whip6_ipv6_packet_t * packet,
        whip6_lowpan_unpacked_frame_headers_t * loWPANHdrs
    );

    /**
     * Signaled when the fragmenter needs a frame into
     * which a subsequent fragment of the packet
     * will be embedded.
     * @param token The token corresponding to the packet.
     * @return A pointer to a frame, the ownership of
     *   which is passed to the fragmenter; or NULL
     *   indicating that the fragmenter should ask for
     *   a frame later. However, in the latter case,
     *   the handler should guarantee that the fragmenter
     *   will always have at least one frame for each
     *   fragmented packet. Otherwise, the packet will
     *   never be fragmented.
     */
    event whip6_ieee154_dframe_info_t * frameForFragmentedPacketRequested(
        uint8_t token
    );

    /**
     * Signaled when the fragmenter no longer needs a frame
     * returned by the earlier invocation of handler
     * <tt>frameNeeded</tt> to fragment a packet.
     * @param token The token corresponding to the packet.
     * @param frame A pointer to the frame.
     */
    event void frameForFragmentedPacketReleased(
        uint8_t token,
        whip6_ieee154_dframe_info_t * frame
    );

    /**
     * Stops fragmenting an IPv6 packet.
     * @param token The token associated with the packet.
     * @return SUCCESS if the fragmentation of the packet
     *   has been canceled successfully, or an error code
     *   otherwise. In any case, the <tt>ipv6PacketFragmented</tt>
     *   is still guaranteed to be invoked.
     */
    command error_t stopFragmentingIpv6Packet(uint8_t token);

    /**
     * Signaled when fragmentation of a packet has finished.
     * Note that it does not mean that the packet has been
     * successfully fragmented, and all the resulting frames
     * have been sent successfully. The status of fragmentation
     * sending and is provided in a dedicated variable. When the
     * event is signaled, the fragmenter releases the ownership
     * of the packet and the optional additional 6LoWPAN headers.
     * @param packet The original fragmented packet.
     * @param token The token representing the packet.
     * @param status The status of packet sending. SUCCESS denotes
     *   that the packet has been fragmented and sent successfully.
     */
    event void fragmentingIpv6PacketFinished(
        whip6_ipv6_packet_t * packet,
        uint8_t token,
        error_t status
    );
}

