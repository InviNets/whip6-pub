#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Szymon Acedanski
# All rights reserved.
#
# Copyright (c) 2017 Uniwersytet Warszawski
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE
# files.
#
board: cherry-v1

dependencies:
  - platforms/boards/cc26xxbased
  - platforms/boards/cc26xxbased/cherry-v1/scif_uart
  - platforms/parts/sensor
  - lib/io/i2c
  - lib/io/leds
  - lib/io/buttons

make options:
  - PLATFORM_CC26XX_BOOTLOADER_DIO=8
