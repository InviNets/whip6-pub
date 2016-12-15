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

/**
 * Allows to incject external packets to the ipv6 stack, by
 * pretending that they've came from the LoWPAN layer.
 *
 * Also allows interception of packets sent to LoWPAN layer and
 * their external processing.
 *
 * Basically allows to inject and intercept packets via serial.
 */
module LoWPANPacketJunctionPub {
    provides interface LoWPANIPv6PacketAcceptor
            as UpperStackAcceptor @exactlyonce();
    provides interface LoWPANIPv6PacketForwarder
            as UpperStackForwarder @exactlyonce();

    uses interface LoWPANIPv6PacketAcceptor
            as LoWPANRadioAcceptor @exactlyonce();
    uses interface LoWPANIPv6PacketForwarder
            as LoWPANRadioForwarder @exactlyonce();

    uses interface LoWPANIPv6PacketAcceptor
            as ExternalAcceptor @exactlyonce();
    uses interface LoWPANIPv6PacketForwarder
            as ExternalForwarder @exactlyonce();
}
implementation
{
    // ---------------------------- Forwarder ------------------------------

    command error_t UpperStackForwarder.startForwardingIpv6Packet(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * llAddr)
    {
        error_t err = call ExternalForwarder.startForwardingIpv6Packet(
                packet, llAddr);

        if (err == ENOROUTE) {
            err = call LoWPANRadioForwarder.startForwardingIpv6Packet(
                    packet, llAddr);
        }

        return err;
    }

    command error_t UpperStackForwarder.stopForwardingIpv6Packet(
            whip6_ipv6_packet_t * packet)
    {
        error_t err = call LoWPANRadioForwarder.stopForwardingIpv6Packet(packet);

        if (err == EINVAL) {
            err = call ExternalForwarder.stopForwardingIpv6Packet(packet);
        }

        return err;
    }

    event void LoWPANRadioForwarder.forwardingIpv6PacketFinished(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * llAddr,
            error_t status)
    {
        signal UpperStackForwarder.forwardingIpv6PacketFinished(
                packet, llAddr, status);
    }

    event void ExternalForwarder.forwardingIpv6PacketFinished(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * llAddr,
            error_t status)
    {
        signal UpperStackForwarder.forwardingIpv6PacketFinished(
                packet, llAddr, status);
    }

    // ---------------------------- Acceptor ------------------------------

    event void LoWPANRadioAcceptor.acceptedIpv6PacketForProcessing(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * lastLinkAddr)
    {
        signal UpperStackAcceptor.acceptedIpv6PacketForProcessing(
                packet, lastLinkAddr);
    }

    event void ExternalAcceptor.acceptedIpv6PacketForProcessing(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * lastLinkAddr) 
    {
        signal UpperStackAcceptor.acceptedIpv6PacketForProcessing(
                packet, lastLinkAddr);
    }
}

