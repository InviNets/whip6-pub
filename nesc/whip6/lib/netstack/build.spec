#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2016 InviNets Sp z o.o.
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files. If you do not find these files, copies can be found by writing
# to technology@invinets.com.
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
