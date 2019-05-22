#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Przemyslaw Horban
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
app name: BlinkIfSeeEachOtherApp

boards:
 - bboard
 - cooja
 - climboard
 - corebox
 - fedo
 - hyboard
 - cc2650dk
 - cherry-v4

build dir: $(SPEC_DIR)/build/$(BOARD)
