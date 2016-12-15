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
app name: SCIFPowerTestApp
boards:
 - cc2650dk
build dir: $(SPEC_DIR)/build/$(BOARD)
dependencies:
 - platforms/boards/cc26xxbased/cc2650dk/scif_pwrtest
define:
 - PLATFORM_NO_PRINTF
