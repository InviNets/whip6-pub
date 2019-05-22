#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Szymon Acedański
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
include paths:
  - $(SPEC_DIR)/inc
  - $(SPEC_DIR)/driverlib

external objects:
  - $(SPEC_DIR)/driverlib/adi.o
  - $(SPEC_DIR)/driverlib/aon_batmon.o
  - $(SPEC_DIR)/driverlib/aon_event.o
  - $(SPEC_DIR)/driverlib/aon_ioc.o
  - $(SPEC_DIR)/driverlib/aon_rtc.o
  - $(SPEC_DIR)/driverlib/aon_wuc.o
  - $(SPEC_DIR)/driverlib/aux_adc.o
  - $(SPEC_DIR)/driverlib/aux_smph.o
  - $(SPEC_DIR)/driverlib/aux_tdc.o
  - $(SPEC_DIR)/driverlib/aux_timer.o
  - $(SPEC_DIR)/driverlib/aux_wuc.o
  - $(SPEC_DIR)/driverlib/ccfgread.o
  - $(SPEC_DIR)/driverlib/chipinfo.o
  - $(SPEC_DIR)/driverlib/cpu.o
  - $(SPEC_DIR)/driverlib/crypto.o
  - $(SPEC_DIR)/driverlib/ddi.o
  - $(SPEC_DIR)/driverlib/debug.o
  - $(SPEC_DIR)/driverlib/driverlib_release.o
  - $(SPEC_DIR)/driverlib/event.o
  - $(SPEC_DIR)/driverlib/flash.o
  - $(SPEC_DIR)/driverlib/gpio.o
  - $(SPEC_DIR)/driverlib/i2c.o
  - $(SPEC_DIR)/driverlib/i2s.o
  - $(SPEC_DIR)/driverlib/interrupt.o
  - $(SPEC_DIR)/driverlib/ioc.o
  - $(SPEC_DIR)/driverlib/osc.o
  - $(SPEC_DIR)/driverlib/prcm.o
  - $(SPEC_DIR)/driverlib/pwr_ctrl.o
  - $(SPEC_DIR)/driverlib/rfc.o
  - $(SPEC_DIR)/driverlib/rom_crypto.o
  - $(SPEC_DIR)/driverlib/setup.o
  - $(SPEC_DIR)/driverlib/setup_rom.o
  - $(SPEC_DIR)/driverlib/smph.o
  - $(SPEC_DIR)/driverlib/ssi.o
  - $(SPEC_DIR)/driverlib/sys_ctrl.o
  - $(SPEC_DIR)/driverlib/systick.o
  - $(SPEC_DIR)/driverlib/timer.o
  - $(SPEC_DIR)/driverlib/trng.o
  - $(SPEC_DIR)/driverlib/uart.o
  - $(SPEC_DIR)/driverlib/udma.o
  - $(SPEC_DIR)/driverlib/vims.o
  - $(SPEC_DIR)/driverlib/watchdog.o

run make at:
  - $(SPEC_DIR)
