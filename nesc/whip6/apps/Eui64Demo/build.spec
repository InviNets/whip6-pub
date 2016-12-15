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
app name: Eui64DemoApp
boards:
  - bboard
  - cooja
  - bdisp
  - corebox
  - climboard
  - fedo
  - hyboard
  - lpad2650
  - cc2650dk
define:
  - APP_DEFAULT_OUTPUT_METHOD=APP_OUTPUT_METHOD_STDIO
build dir: $(SPEC_DIR)/build/$(BOARD)
