/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_ADDRESSING_FOR_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_APP_H__
#define __WHIP6_ADDRESSING_FOR_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_APP_H__


#ifndef APP_ADDRESSING_MODE
#error APP_ADDRESSING_MODE must be defined, see AddressingForCoreOneHopRadioSerialIpv6PacketBridge.h
#endif

#define APP_ADDRESSING_MODE_DEPLOYMENT    1
#define APP_ADDRESSING_MODE_DEVELOPMENT   2
#define APP_ADDRESSING_MODE_ACCEK_PRIVATE 3

# if APP_ADDRESSING_MODE == APP_ADDRESSING_MODE_DEPLOYMENT

// NOTICE iwanicki 2013-11-08:
// At deployment, these should be modified to the
// IPv6 unicast prefix of our nodes.
#define APP_SNODE_PRF1 0x2001U
#define APP_SNODE_PRF2 0x0470U
#define APP_SNODE_PRF3 0x6b6fU
#define APP_SNODE_PRF4 0x0006U

// NOTICE iwanicki 2013-11-08:
// At deployment, these should be modified to the
// IPv6 multicast prefix of our nodes.
#define APP_ANODE_PRF1 0xff02U
#define APP_ANODE_PRF2 0x4567U
#define APP_ANODE_PRF3 0x89abU
#define APP_ANODE_PRF4 0xcdefU

// NOTICE iwanicki 2013-11-08:
// At deployment, these should be modified to the
// IPv6 multicast suffix of our nodes.
#define APP_ANODE_SUF1 0x0123U
#define APP_ANODE_SUF2 0x4567U
#define APP_ANODE_SUF3 0x89abU
#define APP_ANODE_SUF4 0xcdefU

// NOTICE iwanicki 2013-11-08:
// At deployment, these should be modified to the
// IPv6 prefix of our sink/controller node.
#define APP_CTRL_PRF1 0x2001U
#define APP_CTRL_PRF2 0x0470U
#define APP_CTRL_PRF3 0x6b6fU
#define APP_CTRL_PRF4 0x0006U

// NOTICE iwanicki 2013-11-08:
// At deployment, these should be modified to the
// IPv6 suffix of our sink/controller node.
#define APP_CTRL_SUF1 0x0000U
#define APP_CTRL_SUF2 0x0000U
#define APP_CTRL_SUF3 0x0000U
#define APP_CTRL_SUF4 0x0001U

// NOTICE accek 2013-11-11:
// At deployment, these should be modified to the
// link-layer address of the peer (if MODE_P2P
// is defined in CoreOneHopRadioSerialIpv6PacketBridgeApp.nc)
//#define APP_PEER_LLADDR1 0x0012U
//#define APP_PEER_LLADDR2 0x4b00U
//#define APP_PEER_LLADDR3 0x02d3U
//#define APP_PEER_LLADDR4 0x2975U

#elif APP_ADDRESSING_MODE == APP_ADDRESSING_MODE_DEVELOPMENT

// NOTICE iwanicki 2013-11-08:
// At deployment, these should be modified to the
// IPv6 unicast prefix of our nodes.
#define APP_SNODE_PRF1 0xfec0U
#define APP_SNODE_PRF2 0x0000U
#define APP_SNODE_PRF3 0x0000U
#define APP_SNODE_PRF4 0x0000U

// NOTICE iwanicki 2013-11-08:
// At deployment, these should be modified to the
// IPv6 multicast prefix of our nodes.
#define APP_ANODE_PRF1 0xff02U
#define APP_ANODE_PRF2 0x4567U
#define APP_ANODE_PRF3 0x89abU
#define APP_ANODE_PRF4 0xcdefU

// NOTICE iwanicki 2013-11-08:
// At deployment, these should be modified to the
// IPv6 multicast suffix of our nodes.
#define APP_ANODE_SUF1 0x0123U
#define APP_ANODE_SUF2 0x4567U
#define APP_ANODE_SUF3 0x89abU
#define APP_ANODE_SUF4 0xcdefU

// NOTICE iwanicki 2013-11-08:
// At deployment, these should be modified to the
// IPv6 prefix of our sink/controller node.
#define APP_CTRL_PRF1 0xfec0U
#define APP_CTRL_PRF2 0x0000U
#define APP_CTRL_PRF3 0x0000U
#define APP_CTRL_PRF4 0x0000U

// NOTICE iwanicki 2013-11-08:
// At deployment, these should be modified to the
// IPv6 suffix of our sink/controller node.
#define APP_CTRL_SUF1 0x0000U
#define APP_CTRL_SUF2 0x0000U
#define APP_CTRL_SUF3 0x0000U
#define APP_CTRL_SUF4 0x0001U

#elif APP_ADDRESSING_MODE == APP_ADDRESSING_MODE_ACCEK_PRIVATE

#define APP_SNODE_PRF1 0x2001U
#define APP_SNODE_PRF2 0x0470U
#define APP_SNODE_PRF3 0x61b9U
#define APP_SNODE_PRF4 0x0001U

#define APP_ANODE_PRF1 0xff02U
#define APP_ANODE_PRF2 0x4567U
#define APP_ANODE_PRF3 0x89abU
#define APP_ANODE_PRF4 0xcdefU

#define APP_ANODE_SUF1 0x0123U
#define APP_ANODE_SUF2 0x4567U
#define APP_ANODE_SUF3 0x89abU
#define APP_ANODE_SUF4 0xcdefU

#define APP_CTRL_PRF1 0x2001U
#define APP_CTRL_PRF2 0x0470U
#define APP_CTRL_PRF3 0x0071U
#define APP_CTRL_PRF4 0x00c7U

#define APP_CTRL_SUF1 0x0000U
#define APP_CTRL_SUF2 0x0000U
#define APP_CTRL_SUF3 0x0000U
#define APP_CTRL_SUF4 0x0003U

#else

#error Invalid APP_ADDRESSING_MODE

#endif


#endif /* __WHIP6_ADDRESSING_FOR_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_APP_H__ */
