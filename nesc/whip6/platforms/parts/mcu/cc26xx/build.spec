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
  - platforms/parts/mcu/cortex-m3
  - platforms/parts/mcu/cortex-m3/native/fault_handler
  - platforms/parts/mcu/cortex-m3/native/utils
  - platforms/parts/mcu/cc26xx/native/startup
  - platforms/parts/mcu/cc26xx/native/cc26xxware
  - platforms/parts/mcu/cc26xx/native/flog
  - platforms/parts/mcu/cc26xx/include
  - platforms/parts/mcu/cc26xx/adc
  - platforms/parts/mcu/cc26xx/aes
  - platforms/parts/mcu/cc26xx/batmon
  - platforms/parts/mcu/cc26xx/dma
  - platforms/parts/mcu/cc26xx/i2c
  - platforms/parts/mcu/cc26xx/i2s
  - platforms/parts/mcu/cc26xx/interrupts
  - platforms/parts/mcu/cc26xx/ioports
  - platforms/parts/mcu/cc26xx/power
  - platforms/parts/mcu/cc26xx/rfcore
  - platforms/parts/mcu/cc26xx/rtc
  - platforms/parts/mcu/cc26xx/spi
  - platforms/parts/mcu/cc26xx/timers
  - platforms/parts/mcu/cc26xx/trng
  - platforms/parts/mcu/cc26xx/uart
  - api/ble
  - api/radio
  - api/timers
  - api/watchdog
  - api/sys/hwid
  - api/cipher
  - api/control

define:
  - ARMGCC
#  - DRIVERLIB_NOROM
  - CC26XX_XOSC_HF_ALWAYS_ON=0

gcc prefix: arm-none-eabi-

main makefile: $(SPEC_DIR)/Makefile.main

make options: []
# - -B

direct targets:
  - flashsize
  - ramsize
