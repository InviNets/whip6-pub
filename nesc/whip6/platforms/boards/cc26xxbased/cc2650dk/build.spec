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
board: cc2650dk

dependencies:
  - platforms/boards/cc26xxbased
  - platforms/boards/cc26xxbased/cc2650dk/private
  - platforms/parts/memory/sdcard
  - lib/io/leds
  - lib/io/buttons

make options:
  - PLATFORM_CC26XX_BOOTLOADER_DIO=11
  - PLATFORM_BOOTLOADER_LED_DIO=25

uniflash config file:
  platforms/boards/cc26xxbased/cc2650dk/cc2650dk.ccxml
