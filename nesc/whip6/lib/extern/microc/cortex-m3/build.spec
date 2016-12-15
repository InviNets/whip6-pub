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
  I$(REPO_PATH)/microc/target/arm-gcc:

external objects:
  - $(REPO_PATH)/microc/target/arm-gcc/ucLibrary.o

run make at:
  - $(SPEC_DIR)
