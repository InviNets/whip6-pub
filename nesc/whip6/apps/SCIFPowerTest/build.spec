#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Szymon Acedanski
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
app name: SCIFPowerTestApp
boards:
 - cc2650dk
build dir: $(SPEC_DIR)/build/$(BOARD)
dependencies:
 - platforms/boards/cc26xxbased/cc2650dk/scif_pwrtest
define:
 - PLATFORM_NO_PRINTF
