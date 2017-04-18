/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_UDP_ECHO_H__
#define __WHIP6_UDP_ECHO_H__

// The IPv6 address of the PC server.
#define APP_PEER_ADDR1 0xfec0U
#define APP_PEER_ADDR2 0x0000U
#define APP_PEER_ADDR3 0x0000U
#define APP_PEER_ADDR4 0x0000U
#define APP_PEER_ADDR5 0x0000U
#define APP_PEER_ADDR6 0x0000U
#define APP_PEER_ADDR7 0x0000U
#define APP_PEER_ADDR8 0x0001U

// The UDP port of the PC server.
#define APP_PEER_PORT 10001

// The UDP port of the node server.
#define APP_NODE_PORT 9001

// The 64-bit prefix of the node network.
#define APP_NODE_PREF1 APP_PEER_ADDR1
#define APP_NODE_PREF2 APP_PEER_ADDR2
#define APP_NODE_PREF3 APP_PEER_ADDR3
#define APP_NODE_PREF4 APP_PEER_ADDR4

// The EUI-64 of the default gateway node.
#ifdef APP_USE_SHORT_ROUTER_ADDR
#define APP_GTW_SID 0x0001U
#else
#define APP_GTW_EUI1 0x00U
#define APP_GTW_EUI2 0x12U
#define APP_GTW_EUI3 0x4bU
#define APP_GTW_EUI4 0x00U
#define APP_GTW_EUI5 0x02U
#define APP_GTW_EUI6 0x49U
#define APP_GTW_EUI7 0x8cU
#define APP_GTW_EUI8 0x2cU
#endif // APP_USE_SHORT_ROUTER_ADDR

#define APP_HELLO_REQUEST_PERIOD_IN_MS 4096UL

#define APP_SERVER_BUF_SIZE 512
#define APP_CLIENT_BUF_SIZE 128

#endif /* __WHIP6_UDP_ECHO_H__ */
