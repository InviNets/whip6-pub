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
app name: UDPEchoApp
boards:
  - corebox
  - climboard
  - fedo
  - cc2650dk
build dir: $(SPEC_DIR)/build/$(BOARD)
define:
  - APP_USE_SHORT_ROUTER_ADDR=1
  - WHIP6_IEEE154_OLD_STACK
#  - WHIP6_USE_XMAC=1
#  - WHIP6_IPV6_LOOPBACK_DISABLE=1
#  - WHIP6_IPV6_ICMPV6_DISABLE=1
