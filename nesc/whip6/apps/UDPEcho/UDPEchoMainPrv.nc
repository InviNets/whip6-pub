/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucString.h>
#include <eui/ucEui64Types.h>
#include <ipv6/ucIpv6AddressManipulation.h>
#include <udp/ucUdpBasicTypes.h>
#include "UDPEcho.h"

#include <stdio.h>
#include <string.h>

#define app_local_printf(...) printf(__VA_ARGS__)


/**
 * The main module of the UDP echo application.
 *
 * @author Konrad Iwanicki
 */
module UDPEchoMainPrv
{
    uses
    {
        interface Boot;
        interface SynchronousStarter as IPv6StackStarter;
        interface UDPSocketController as ServerSocketController;
        interface UDPSimpleReceiver as ServerSocketReceiver;
        interface UDPSimpleSender as ServerSocketSender;
        interface UDPSocketController as ClientSocketController;
        interface UDPSimpleReceiver as ClientSocketReceiver;
        interface UDPSimpleSender as ClientSocketSender;
        interface Timer<TMilli, uint32_t> as ClientTimer;
        interface LocalIeeeEui64Provider;
        interface Led as ErrorLed;
        interface Led as ClientTxLed;
        interface Led as ServerRxLed;
    }
}
implementation
{

#define local_dbg(...) app_local_printf(__VA_ARGS__)
// #define local_dbg(...)

#define ASSERT_SUCCESS(st, op, msg) \
    (st) = (op); \
    if ((st) != SUCCESS) \
    { \
        local_dbg("[AppMain] ERROR (%u) " msg ".\r\n", (unsigned)(st)); \
        call ErrorLed.on(); \
        do \
        { \
            (st) = (op); \
        } \
        while ((st) != SUCCESS); \
        call ErrorLed.off(); \
        local_dbg("[AppMain] finally succeeded " msg ".\r\n"); \
    }


    whip6_udp_socket_addr_t   m_serverSockAddrBuf;
    whip6_udp_socket_addr_t   m_clientSockAddrBuf;
    uint8_t_xdata             m_serverDataBuf[APP_SERVER_BUF_SIZE];
    uint8_t_xdata             m_clientOutDataBuf[APP_CLIENT_BUF_SIZE];
    uint8_t_xdata             m_clientInDataBuf[APP_CLIENT_BUF_SIZE];
    uint8_t                   m_clientCounter;



    whip6_udp_socket_addr_t const * getServerSockAddr(
            whip6_udp_socket_addr_t * buf
    );
    whip6_udp_socket_addr_t const * getClientSockAddr(
            whip6_udp_socket_addr_t * buf
    );
    whip6_udp_socket_addr_t const * getPeerSockAddr(
            whip6_udp_socket_addr_t * buf
    );
    size_t createClientHelloMessage();
    task void sendClientHelloTask();


    event void Boot.booted()
    {
        error_t status;

        local_dbg("[AppMain] Booting.\r\n");

        m_clientCounter = 0;

        ASSERT_SUCCESS(
                status,
                call IPv6StackStarter.start(),
                "starting the IPv6 stack"
        );
        ASSERT_SUCCESS(
                status,
                call ServerSocketController.bind(getServerSockAddr(&m_serverSockAddrBuf)),
                "binding the server socket"
        );
        ASSERT_SUCCESS(
                status,
                call ClientSocketController.bind(getClientSockAddr(&m_clientSockAddrBuf)),
                "binding the client socket"
        );
        ASSERT_SUCCESS(
                status,
                call ClientSocketController.connect(getPeerSockAddr(&m_clientSockAddrBuf)),
                "connecting the client socket"
        );
        ASSERT_SUCCESS(
                status,
                call ServerSocketReceiver.startReceivingFrom(
                        &(m_serverDataBuf[0]),
                        sizeof(m_serverDataBuf) / sizeof(uint8_t_xdata),
                        &m_serverSockAddrBuf
                ),
                "receiving on the server socket"
        );
        ASSERT_SUCCESS(
                status,
                call ClientSocketReceiver.startReceiving(
                        &(m_clientInDataBuf[0]),
                        sizeof(m_clientInDataBuf) / sizeof(uint8_t_xdata)
                ),
                "receiving on the client socket"
        );

        call ClientTimer.startWithTimeoutFromNow(
                APP_HELLO_REQUEST_PERIOD_IN_MS
        );

        local_dbg("[AppMain] Booted.\r\n");
    }



    event void ClientTimer.fired()
    {
        local_dbg("[AppMain] The client timer has fired.\r\n");
        post sendClientHelloTask();
    }



    task void sendClientHelloTask()
    {
        size_t         numBytes;
        error_t        status;

        numBytes = createClientHelloMessage();
        if (numBytes == 0)
        {
            call ClientTimer.startWithTimeoutFromNow(
                    APP_HELLO_REQUEST_PERIOD_IN_MS
            );
            local_dbg("[AppMain] A client buffer is too small to hold a hello message.\r\n");
            return;
        }

        local_dbg("[AppMain] Sending the following client hello message: \"%s\".\r\n",
                &(m_clientOutDataBuf[0]));

        ASSERT_SUCCESS(
                status,
                call ClientSocketSender.startSending(
                        &(m_clientOutDataBuf[0]),
                        (size_t)numBytes
                ),
                "sending on the client socket"
        );
    }



    size_t createClientHelloMessage()
    {
        ieee_eui64_t      eui;
        size_t            res;
        uint8_t           i;
        uint8_t_xdata *   ptr;
        
        call LocalIeeeEui64Provider.read(&eui);
        strncpy(
                (char*) &(m_clientOutDataBuf[0]),
                "Hello world from node ",
                sizeof(m_clientOutDataBuf) / sizeof(uint8_t_xdata) - 1
        );
        m_clientOutDataBuf[sizeof(m_clientOutDataBuf) / sizeof(uint8_t_xdata) - 1] = '\0';
        res = strlen((char*) &(m_clientOutDataBuf[0]));
        if (res + (IEEE_EUI64_BYTE_LENGTH * 3 + 6) >= sizeof(m_clientOutDataBuf) / sizeof(uint8_t_xdata) - 1)
        {
            return 0;
        }
        // NOTICE iwanicki 2013-12-31:
        // For one-fragment packets, uncomment the line below.
        // res = 0;
        ptr = &(m_clientOutDataBuf[res]);
        for (i = 0; i < IEEE_EUI64_BYTE_LENGTH; ++i)
        {
            *ptr = whip6_hi4bitsToHexChar(eui.data[i]);
            ++ptr;
            *ptr = whip6_lo4bitsToHexChar(eui.data[i]);
            ++ptr;
            *ptr = '-';
            ++ptr;
            res += 3;
        }
        --ptr;
        *ptr = ' ';
        ++ptr;
        *ptr = '(';
        ++ptr;
        *ptr = '#';
        ++ptr;
        *ptr = whip6_hi4bitsToHexChar(m_clientCounter);
        ++ptr;
        *ptr = whip6_lo4bitsToHexChar(m_clientCounter);
        ++ptr;
        *ptr = ')';
        ++ptr;
        *ptr = '!';
        ++ptr;
        *ptr = '\0';
        ++ptr;
        ++m_clientCounter;
        return res + 7;
    }



    event void ClientSocketSender.finishSending(
            uint8_t_xdata const * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t const * sockAddr,
            error_t status
    )
    {
        local_dbg("[AppMain] Sending the client hello message has finished "
            "with status %u.\r\n", (unsigned)status);
        call ClientTimer.startWithTimeoutFromNow(
                APP_HELLO_REQUEST_PERIOD_IN_MS
        );
    }



    event void ClientSocketReceiver.finishReceiving(
            uint8_t_xdata * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t * sockAddrOrNull,
            error_t status
    )
    {
        local_dbg("[AppMain] Receiving the client hello message of %lu bytes "
            "has finished with status %u.\r\n", (long unsigned)bufLen, (unsigned)status);
        if (status == SUCCESS)
        {
            m_clientInDataBuf[sizeof(m_clientInDataBuf) / sizeof(uint8_t_xdata) - 1] = '\0';
            local_dbg("[AppMain] The received message: \"%s\".\r\n",
                    &(m_clientInDataBuf[0]));
        }
        ASSERT_SUCCESS(
                status,
                call ClientSocketReceiver.startReceiving(
                        &(m_clientInDataBuf[0]),
                        sizeof(m_clientInDataBuf) / sizeof(uint8_t_xdata)
                ),
                "receiving on the client socket"
        );
    }



    event void ServerSocketReceiver.finishReceiving(
            uint8_t_xdata * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t * sockAddrOrNull,
            error_t status
    )
    {
        local_dbg("[AppMain] Receiving a peer echo message of %lu bytes "
            "has finished with status %u.\r\n", (long unsigned)bufLen, (unsigned)status);

        if (status == SUCCESS && sockAddrOrNull != NULL)
        {
            m_serverDataBuf[sizeof(m_serverDataBuf) / sizeof(uint8_t_xdata) - 1] = '\0';
            local_dbg("[AppMain] The received message: \"%s\".\r\n",
                    &(m_serverDataBuf[0]));
            ASSERT_SUCCESS(
                    status,
                    call ServerSocketSender.startSendingTo(
                            &(m_serverDataBuf[0]),
                            (size_t)bufLen,
                            sockAddrOrNull
                    ),
                    "sending on the server socket"
            );
        }
        else
        {
            ASSERT_SUCCESS(
                    status,
                    call ServerSocketReceiver.startReceivingFrom(
                            &(m_serverDataBuf[0]),
                            sizeof(m_serverDataBuf) / sizeof(uint8_t_xdata),
                            &m_serverSockAddrBuf
                    ),
                    "receiving on the server socket"
            );
        }
    }



    event void ServerSocketSender.finishSending(
            uint8_t_xdata const * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t const * sockAddr,
            error_t status
    )
    {
        local_dbg("[AppMain] Replying the peer echo message has finished "
            "with status %u.\r\n", (unsigned)status);

        ASSERT_SUCCESS(
                status,
                call ServerSocketReceiver.startReceivingFrom(
                        &(m_serverDataBuf[0]),
                        sizeof(m_serverDataBuf) / sizeof(uint8_t_xdata),
                        &m_serverSockAddrBuf
                ),
                "receiving on the server socket"
        );
    }



    whip6_udp_socket_addr_t const * getServerSockAddr(
            whip6_udp_socket_addr_t * buf
    )
    {
        whip6_ipv6AddrSetUndefinedAddr(&buf->ipv6Addr);
        buf->udpPortNo = APP_NODE_PORT;
        return buf;
    }



    whip6_udp_socket_addr_t const * getClientSockAddr(
            whip6_udp_socket_addr_t * buf
    )
    {
        whip6_ipv6AddrSetUndefinedAddr(&buf->ipv6Addr);
        buf->udpPortNo = 0;
        return buf;
    }



    whip6_udp_socket_addr_t const * getPeerSockAddr(
            whip6_udp_socket_addr_t * buf
    )
    {
        buf->ipv6Addr.data8[0] = (uint8_t)((APP_PEER_ADDR1) >> 8);
        buf->ipv6Addr.data8[1] = (uint8_t)((APP_PEER_ADDR1));
        buf->ipv6Addr.data8[2] = (uint8_t)((APP_PEER_ADDR2) >> 8);
        buf->ipv6Addr.data8[3] = (uint8_t)((APP_PEER_ADDR2));
        buf->ipv6Addr.data8[4] = (uint8_t)((APP_PEER_ADDR3) >> 8);
        buf->ipv6Addr.data8[5] = (uint8_t)((APP_PEER_ADDR3));
        buf->ipv6Addr.data8[6] = (uint8_t)((APP_PEER_ADDR4) >> 8);
        buf->ipv6Addr.data8[7] = (uint8_t)((APP_PEER_ADDR4));
        buf->ipv6Addr.data8[8] = (uint8_t)((APP_PEER_ADDR5) >> 8);
        buf->ipv6Addr.data8[9] = (uint8_t)((APP_PEER_ADDR5));
        buf->ipv6Addr.data8[10] = (uint8_t)((APP_PEER_ADDR6) >> 8);
        buf->ipv6Addr.data8[11] = (uint8_t)((APP_PEER_ADDR6));
        buf->ipv6Addr.data8[12] = (uint8_t)((APP_PEER_ADDR7) >> 8);
        buf->ipv6Addr.data8[13] = (uint8_t)((APP_PEER_ADDR7));
        buf->ipv6Addr.data8[14] = (uint8_t)((APP_PEER_ADDR8) >> 8);
        buf->ipv6Addr.data8[15] = (uint8_t)((APP_PEER_ADDR8));
        buf->udpPortNo = APP_PEER_PORT;
        return buf;
    }



    default command inline void ErrorLed.on()
    {
    }



    default command inline void ErrorLed.off()
    {
    }



    default command inline void ErrorLed.toggle()
    {
    }



    default command inline void ClientTxLed.toggle()
    {
    }



    default command inline void ServerRxLed.toggle()
    {
    }


#undef local_dbg
#undef ASSERT_SUCCESS
}
