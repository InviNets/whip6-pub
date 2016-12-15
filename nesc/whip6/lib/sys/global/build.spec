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
nesc arguments:
  fnesc-include:
    - GlobalHeaders
    - GlobalTypes
    - GlobalError
    - GlobalPanic
    - GlobalAddressPrinting

wnesc arguments:
  include:
    - $(REPO_PATH)/nesc/whip6/lib/sys/global/GlobalHeaders.h
    - $(REPO_PATH)/nesc/whip6/lib/sys/global/GlobalTypes.h
    - $(REPO_PATH)/nesc/whip6/lib/sys/global/GlobalError.h
    - $(REPO_PATH)/nesc/whip6/lib/sys/global/GlobalPanic.h
    - $(REPO_PATH)/nesc/whip6/lib/sys/global/GlobalAddressPrinting.h
