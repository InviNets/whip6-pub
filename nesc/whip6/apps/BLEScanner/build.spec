#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Szymon Acedanski
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
app name: BLEScannerApp
boards:
 - lpad2650
 - sensortag2
 - cc2650dk
build dir: $(SPEC_DIR)/build/$(BOARD)
dependencies:
 - lib/ble
