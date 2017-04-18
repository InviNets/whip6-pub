/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_NETSTACK_COMPILE_TIME_CONFIG_H__
#define __WHIP6_NETSTACK_COMPILE_TIME_CONFIG_H__

/** The maximal number of IEEE 802.15.4 frames concurrently processed in the system. */
#ifndef WHIP6_IEEE154_MAX_CONCURRENT_FRAMES
#define WHIP6_IEEE154_MAX_CONCURRENT_FRAMES 6
#endif /* WHIP6_IEEE154_MAX_CONCURRENT_FRAMES */

/** The IEEE 802.15.4 PAN identifier. */
#ifndef WHIP6_IEEE154_PAN_ID
#define WHIP6_IEEE154_PAN_ID 0xc0deU
#endif /* WHIP6_IEEE154_PAN_ID */

/** The maximal number of entries in the 6LoWPAN link table. */
#ifndef WHIP6_LOWPAN_MAX_NUM_LINK_TABLE_ENTRIES
#define WHIP6_LOWPAN_MAX_NUM_LINK_TABLE_ENTRIES 32
#endif /* WHIP6_LOWPAN_MAX_NUM_LINK_TABLE_ENTRIES */

/**
 * The number of buckets in the hash table indexing the 6LoWPAN link
 * table by extended IEEE 802.15.4 addresses.
 */
#ifndef WHIP6_LOWPAN_NUM_LINK_TABLE_EXT_ADDR_HASH_BUCKETS
#define WHIP6_LOWPAN_NUM_LINK_TABLE_EXT_ADDR_HASH_BUCKETS 32
#endif /* WHIP6_LOWPAN_NUM_LINK_TABLE_EXT_ADDR_HASH_BUCKETS */

/**
 * The number of buckets in the hash table indexing the 6LoWPAN link
 * table by short IEEE 802.15.4 addresses.
 */
#ifndef WHIP6_LOWPAN_NUM_LINK_TABLE_SHORT_ADDR_HASH_BUCKETS
#define WHIP6_LOWPAN_NUM_LINK_TABLE_SHORT_ADDR_HASH_BUCKETS 1
#endif /* WHIP6_LOWPAN_NUM_LINK_TABLE_SHORT_ADDR_HASH_BUCKETS */

/** The maximal number of custom unicast IPv6 addresses associated with a 6LoWPAN interface. */
#ifndef WHIP6_LOWPAN_MAX_UNICAST_IFACE_ADDRS
#define WHIP6_LOWPAN_MAX_UNICAST_IFACE_ADDRS 1
// NOTICE iwanicki 2013-10-29:
// - an autoconfigured address for a single prefix
#endif /* WHIP6_LOWPAN_MAX_MULTICAST_IFACE_ADDRS */

/** The maximal number of custom multicast IPv6 addresses associated with a 6LoWPAN interface. */
#ifndef WHIP6_LOWPAN_MAX_MULTICAST_IFACE_ADDRS
#define WHIP6_LOWPAN_MAX_MULTICAST_IFACE_ADDRS 1
// NOTICE iwanicki 2013-10-29:
// - an address for all RPL nodes
#endif /* WHIP6_LOWPAN_MAX_MULTICAST_IFACE_ADDRS */

/** The maximal number of IPv6 packets concurrently processed in the system. */
#ifndef WHIP6_IPV6_MAX_CONCURRENT_PACKETS
#define WHIP6_IPV6_MAX_CONCURRENT_PACKETS 7
#endif /* WHIP6_IPV6_MAX_CONCURRENT_PACKETS */

/** The maximal number of ICMPv6 messages concurrently processed in the system. */
#ifndef WHIP6_ICMPV6_MAX_CONCURRENT_PACKETS
#define WHIP6_ICMPV6_MAX_CONCURRENT_PACKETS 1
#endif /* WHIP6_ICMPV6_MAX_CONCURRENT_PACKETS */

#endif /* __WHIP6_NETSTACK_COMPILE_TIME_CONFIG_H__ */
