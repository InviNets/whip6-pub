/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ipv6/ucIpv6AddressManipulation.h>
#include <udp/ucUdpBasicTypes.h>



/**
 * A controller for a User Datagram Protocol (UDP)
 * socket.
 *
 * The interface contains only the socket control
 * functionality. The interfaces for communicating
 * through the socket are separate.
 *
 * @author Konrad Iwanicki
 */
interface UDPSocketController
{

    /**
     * Binds the socket to a given address.
     * @param sockAddr A UDP socket address to which the
     *   socket should be bound. If the IPv6 address is
     *   undefined (see <tt>whip6_ipv6AddrSetUndefinedAddr</tt>),
     *   the socket will be bound to all addresses of the
     *   node. If the port number is zero, the underlying
     *   system will select the best port. The pointed
     *   address may be deallocated as soon as the command returns.
     * @return SUCCESS if the socket has been successfully
     *   bound to the given address, or an error code otherwise.
     *   Possible error codes:
     *   - EALREADY if the socket is already bound to some address.
     *   - ENOMEM if there is no memory to bind the socket.
     *   - EBUSY if the given port is busy.
     *   - EINVAL if the given IPv6 address is invalid.
     */
    command error_t bind(whip6_udp_socket_addr_t const * sockAddr);

    /**
     * Binds the socket to a given pair (IPv6 address, port number).
     * It is a convenience wrapper over <tt>bind</tt> with the same
     * remarks and error values.
     */
    command error_t bindToAddrAndPort(
            whip6_ipv6_addr_t const * ipv6Addr,
            udp_port_no_t udpPortNo
    );

    /**
     * Connects the socket to a given remote address and port.
     * No messages are sent. Instead, each outgoing packet
     * is assumed to be destined to the given address.
     * After a successful connect, the socket will receive
     * datagrams only from the given remote address.
     * It is possible to reconnect to another address.
     * @param sockAddr A remote UDP address to which the socket
     *   should be connected. Neither is the IPv6 address
     *   allowed to be undefined, nor is the port allowed to
     *   be zero.
     * @return SUCCESS if the socket has been successfully
     *   connected to the given address, or an error code otherwise.
     *   Possible error codes:
     *   - ESTATE if the socket is not bound.
     *   - EINVAL if the given address is invalid.
     */
    command error_t connect(whip6_udp_socket_addr_t const * sockAddr);

    /**
     * Connects the socket to a given pair (remote IPv6
     * address, remote port number). It is a convenience wrapper
     * over <tt>connect</tt> with the same remarks and error values.
     */
    command error_t connectToAddrAndPort(
            whip6_ipv6_addr_t const * ipv6Addr,
            udp_port_no_t udpPortNo
    );

    /**
     * Returns a pointer to the UDP socket address to
     * which the socket is bound.
     * @return A pointer to the UDP socket address to
     *   which the socket is bound. If the socket is not
     *   bound, the port number is zero. If the socket is
     *   bound to multiple addresses, the IPv6 address
     *   is undefined.
     */
    command whip6_udp_socket_addr_t const * getLocalAddr();

    /**
     * Returns a pointer to the remote UDP socket address to
     * which the socket is connected.
     * @return A pointer to the UDP socket address to
     *   which the socket is connected. If the socket is not
     *   connected, the IPv6 address is undefined and the port
     *   number is zero.
     */
    command whip6_udp_socket_addr_t const * getRemoteAddr();

    /**
     * A convenience command for checking if the is bound.
     * @return TRUE if the socket is bound or FALSE otherwise.
     */
    command bool isBound();

    /**
     * A convenience command for checking if the is connected.
     * @return TRUE if the socket is connected or FALSE otherwise.
     */
    command bool isConnected();

}
