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
app name: CoreOneHopRadioSerialIpv6PacketBridgeApp
boards:
  - bboard
  - corebox
  - climboard
  - fedo
  - hyboard
  - mr3020
  - cc2538dk
  - cc2650dk

dependencies:
  - api/mac

build dir: $(SPEC_DIR)/build/$(BOARD)
define:
  - WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE=WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE_NONREWRITING
  - WHIP6_IEEE154_ADDRESS_SHORT=0x0001U
  - APP_ADDRESSING_MODE=APP_ADDRESSING_MODE_DEPLOYMENT
  - WHIP6_IPV6_MAX_CONCURRENT_PACKETS=16
  - WHIP6_LOWPAN_DEFAULT_FRAGMENT_REASSEMBLY_TIMEOUT_IN_MILLIS=256UL
  - WHIP6_IEEE154_OLD_STACK
#  - WHIP6_SOFTWARE_VERSION="20150826"
#  - APP_RADIO_TO_SERIAL_WATCHDOG_TIMER_IN_MILLIS=307200UL
#  - APP_SERIAL_TO_RADIO_WATCHDOG_TIMER_IN_MILLIS=307200UL
#  - WHIP6_USE_XMAC=1
#  - APP_DEFAULT_OUTPUT_METHOD=APP_OUTPUT_METHOD_UART
