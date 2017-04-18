#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Szymon Acedanski
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
app name: BLEBeaconApp
boards:
 - cc2650dk
 - lpad2650
 - sensortag2
build dir: $(SPEC_DIR)/build/$(BOARD)
define:
 - APP_ADVERTISING_INTERVAL_MS=1000
dependencies:
 - lib/ble
