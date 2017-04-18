#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Konrad Iwanicki
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
dependencies:
  - lib/netstack/private
  - lib/ieee154
  - lib/ipv6
  - lib/lowpan
  - lib/icmpv6
  - lib/udp
  - lib/radio

define:
  - WHIP6_IPV6_6LOWPAN_MULTIHOP_DISABLE=1
