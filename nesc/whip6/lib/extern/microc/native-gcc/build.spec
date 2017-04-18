#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Konrad Iwanicki
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
nesc arguments:
  I$(REPO_PATH)/microc/target/native-gcc:

external objects:
  - $(REPO_PATH)/microc/target/native-gcc/ucLibrary.o

run make at:
  - $(SPEC_DIR)
