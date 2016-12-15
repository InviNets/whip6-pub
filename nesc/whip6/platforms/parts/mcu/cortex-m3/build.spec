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
include paths:
  - $(SPEC_DIR)/include

dependencies:
  - platforms/parts/mcu/cortex-m3/native/tfp_printf_glue

gdbinit:
  - platforms/parts/mcu/cortex-m3/gdbinit

nesc args:
  - -fnostdinc
  - -nostdinc
