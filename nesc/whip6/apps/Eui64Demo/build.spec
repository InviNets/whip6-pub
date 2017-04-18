#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Konrad Iwanicki
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
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
