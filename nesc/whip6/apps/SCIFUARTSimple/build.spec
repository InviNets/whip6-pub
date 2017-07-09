#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2017 University of Warsaw
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE
# files.
#
app name: SCIFUARTSimpleApp
boards:
 - cherry-v1
 - cherry-v2
build dir: $(SPEC_DIR)/build/$(BOARD)
dependencies:
 - platforms/boards/cc26xxbased/cherry-v1/scif_uart
