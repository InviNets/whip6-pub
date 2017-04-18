#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Konrad Iwanicki
# Copyright (c) 2012-2017 InviNets Sp. z o.o.
# Copyright (c) 2012-2017 Przemyslaw Horban
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
app name: CoreIeee154StackDemoApp
boards:
  - bboard
  - climboard
  - corebox
  - fedo
  - hyboard
  - mr3020
  - cc2650dk
define:
  - WHIP6_IEEE154_OLD_STACK
build dir: $(SPEC_DIR)/build/$(BOARD)
