#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) University of Warsaw
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
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
