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
  I$(REPO_PATH)/microc/target/cc253x-standard:

wnesc arguments:
  I: $(REPO_PATH)/microc/target/cc253x-standard
  include:
    - $(REPO_PATH)/microc/include/base/ucTypes.h
    - $(REPO_PATH)/microc/packages/cc253x-standard/ucBank2.c
    - $(REPO_PATH)/microc/packages/cc253x-standard/ucBank3.c
    - $(REPO_PATH)/microc/packages/cc253x-standard/ucBank4.c

run make at:
  - $(SPEC_DIR)

define:
  - WHIP6_MICROC_EXTERN_DECL_PREFIX=extern
  - WHIP6_MICROC_EXTERN_DECL_SUFFIX=__attribute__((banked))
  - 'WHIP6_MICROC_EXTERN_DEF_PREFIX= '
  - WHIP6_MICROC_EXTERN_DEF_SUFFIX=__attribute__((banked))
  - WHIP6_MICROC_PRIVATE_DECL_PREFIX=static
  - 'WHIP6_MICROC_PRIVATE_DECL_SUFFIX= '
  - WHIP6_MICROC_PRIVATE_DEF_PREFIX=static
  - 'WHIP6_MICROC_PRIVATE_DEF_SUFFIX= '
  - WHIP6_MICROC_INLINE_DECL_PREFIX=static
  - 'WHIP6_MICROC_INLINE_DECL_SUFFIX= '
  - WHIP6_MICROC_INLINE_DEF_PREFIX=inline
  - 'WHIP6_MICROC_INLINE_DEF_SUFFIX= '
  - MCS51_STORED_IN_RAM=__xdata
