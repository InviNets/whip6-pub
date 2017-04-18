#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Konrad Iwanicki
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#

SDCC_PP := sdcc
SDCC_CC := sdcc
SDCC_AS := sdas8051
SDCC_LD := sdld
SHELL_COPY := cp
SHELL_RM := rm -f

TARGET_NAME := cc253x-standard

INC_DIR := ../../include
SRC_DIR := ../../src
OBJ_DIR := ../../obj/$(TARGET_NAME)
BIN_DIR := ../../target/$(TARGET_NAME)
PKG_DIR := ./

SDCC_COMMON_FLAGS := \
	-mmcs51 --opt-code-size --std-c99 --model-large --stack-auto -I$(INC_DIR)
SDCC_CC_FLAGS := \
	-S $(SDCC_COMMON_FLAGS) \
	-DWHIP6_MICROC_EXTERN_DECL_PREFIX='extern' \
	-DWHIP6_MICROC_EXTERN_DECL_SUFFIX='__banked' \
	-DWHIP6_MICROC_EXTERN_DEF_PREFIX= \
	-DWHIP6_MICROC_EXTERN_DEF_SUFFIX='__banked' \
	-DWHIP6_MICROC_PRIVATE_DECL_PREFIX='static' \
	-DWHIP6_MICROC_PRIVATE_DECL_SUFFIX= \
	-DWHIP6_MICROC_PRIVATE_DEF_PREFIX='static' \
	-DWHIP6_MICROC_PRIVATE_DEF_SUFFIX= \
	-DWHIP6_MICROC_INLINE_DECL_PREFIX='static' \
	-DWHIP6_MICROC_INLINE_DECL_SUFFIX= \
	-DWHIP6_MICROC_INLINE_DEF_PREFIX='inline' \
	-DWHIP6_MICROC_INLINE_DEF_SUFFIX=

SDCC_AS_FLAGS := -posgwl

SDCC_LD_FLAGS :=

SRC_C_FILES_WITH_CODE := \
	$(SRC_DIR)/6lowpan/uc6LoWPANHeaderManipulation.c \
	$(SRC_DIR)/6lowpan/uc6LoWPANDefragmentation.c \
	$(SRC_DIR)/6lowpan/uc6LoWPANFragmentation.c \
	$(SRC_DIR)/6lowpan/uc6LoWPANIpv6AddressManipulation.c \
	$(SRC_DIR)/6lowpan/uc6LoWPANIpv6HeaderCompression.c \
	$(SRC_DIR)/6lowpan/uc6LoWPANMeshManipulation.c \
	$(SRC_DIR)/6lowpan/uc6LoWPANNalpExtensionSoftwareAcknowledgments.c \
	$(SRC_DIR)/6lowpan/uc6LoWPANPacketForwarding.c \
	$(SRC_DIR)/base/ucIoVec.c \
	$(SRC_DIR)/base/ucIoVecAllocation.c \
	$(SRC_DIR)/icmpv6/ucIcmpv6BasicMessageBuilders.c \
	$(SRC_DIR)/icmpv6/ucIcmpv6BasicMessageProcessing.c \
	$(SRC_DIR)/ieee154/ucIeee154AddressManipulation.c \
	$(SRC_DIR)/ieee154/ucIeee154FrameManipulation.c \
	$(SRC_DIR)/ieee154/ucIeee154Ipv6InterfaceStateManipulation.c \
	$(SRC_DIR)/ipv6/ucIpv6AddressHumanReadableIo.c \
	$(SRC_DIR)/ipv6/ucIpv6AddressManipulation.c \
	$(SRC_DIR)/ipv6/ucIpv6Checksum.c \
	$(SRC_DIR)/ipv6/ucIpv6ExtensionHeaderProcessing.c \
	$(SRC_DIR)/ipv6/ucIpv6GenericInterfaceStateManipulation.c \
	$(SRC_DIR)/rpl/ucRplMessageBuilders.c \
	$(SRC_DIR)/srcroute/ucSourceRouteExtensionHeaderProcessing.c \
	$(SRC_DIR)/udp/ucUdpHeaderManipulation.c
SRC_C_FILES_WITH_BANKS := \
	$(PKG_DIR)/ucBank2.c \
	$(PKG_DIR)/ucBank3.c \
	$(PKG_DIR)/ucBank4.c
SRC_H_FILES_WITH_HEADERS := \
	$(INC_DIR)/6lowpan/uc6LoWPANDefragmentation.h \
	$(INC_DIR)/6lowpan/uc6LoWPANFragmentation.h \
	$(INC_DIR)/6lowpan/uc6LoWPANHeaderManipulation.h \
	$(INC_DIR)/6lowpan/uc6LoWPANHeaderTypes.h \
	$(INC_DIR)/6lowpan/uc6LoWPANIpv6AddressManipulation.h \
	$(INC_DIR)/6lowpan/uc6LoWPANIpv6HeaderCompression.h \
	$(INC_DIR)/6lowpan/uc6LoWPANMeshManipulation.h \
	$(INC_DIR)/6lowpan/uc6LoWPANMeshTypes.h \
	$(INC_DIR)/6lowpan/uc6LoWPANNalpExtensionConstants.h \
	$(INC_DIR)/6lowpan/uc6LoWPANNalpExtensionSoftwareAcknowledgments.h \
	$(INC_DIR)/6lowpan/uc6LoWPANPacketForwarding.h \
	$(INC_DIR)/base/ucError.h \
	$(INC_DIR)/base/ucEtx.h \
	$(INC_DIR)/base/ucIoVec.h \
	$(INC_DIR)/base/ucIoVecAllocation.h \
	$(INC_DIR)/base/ucString.h \
	$(INC_DIR)/base/ucTypes.h \
	$(INC_DIR)/eui/ucEui64Types.h \
	$(INC_DIR)/external/ucExternal6LoWPANAllocators.h \
	$(INC_DIR)/external/ucExternalBaseAllocators.h \
	$(INC_DIR)/external/ucExternalIpv6Allocators.h \
	$(INC_DIR)/external/ucExternalIpv6InterfaceAccessors.h \
	$(INC_DIR)/icmpv6/ucIcmpv6BasicMessageBuilders.h \
	$(INC_DIR)/icmpv6/ucIcmpv6BasicMessageProcessing.h \
	$(INC_DIR)/icmpv6/ucIcmpv6BasicTypes.h \
	$(INC_DIR)/icmpv6/ucIcmpv6Constants.h \
	$(INC_DIR)/ieee154/ucIeee154AddressManipulation.h \
	$(INC_DIR)/ieee154/ucIeee154AddressTypes.h \
	$(INC_DIR)/ieee154/ucIeee154FrameManipulation.h \
	$(INC_DIR)/ieee154/ucIeee154FrameTypes.h \
	$(INC_DIR)/ieee154/ucIeee154Ipv6InterfaceStateManipulation.h \
	$(INC_DIR)/ieee154/ucIeee154Ipv6InterfaceStateTypes.h \
	$(INC_DIR)/ipv6/ucIpv6AddressHumanReadableIo.h \
	$(INC_DIR)/ipv6/ucIpv6AddressManipulation.h \
	$(INC_DIR)/ipv6/ucIpv6AddressTypes.h \
	$(INC_DIR)/ipv6/ucIpv6BasicHeaderManipulation.h \
	$(INC_DIR)/ipv6/ucIpv6BasicHeaderTypes.h \
	$(INC_DIR)/ipv6/ucIpv6Checksum.h \
	$(INC_DIR)/ipv6/ucIpv6ExtensionHeaderProcessing.h \
	$(INC_DIR)/ipv6/ucIpv6ExtensionHeaderTypes.h \
	$(INC_DIR)/ipv6/ucIpv6HeaderProcessorTypes.h \
	$(INC_DIR)/ipv6/ucIpv6IanaConstants.h \
	$(INC_DIR)/ipv6/ucIpv6GenericInterfaceStateManipulation.h \
	$(INC_DIR)/ipv6/ucIpv6GenericInterfaceStateTypes.h \
	$(INC_DIR)/ipv6/ucIpv6PacketAllocation.h \
	$(INC_DIR)/ipv6/ucIpv6PacketTypes.h \
	$(INC_DIR)/rpl/ucRplBase.h \
	$(INC_DIR)/rpl/ucRplLollipop.h \
	$(INC_DIR)/rpl/ucRplMessageBuilders.h \
	$(INC_DIR)/rpl/ucRplMessageTypes.h \
	$(INC_DIR)/srcroute/ucSourceRouteExtensionHeaderManipulation.h \
	$(INC_DIR)/srcroute/ucSourceRouteExtensionHeaderTypes.h \
	$(INC_DIR)/udp/ucUdpBasicTypes.h \
	$(INC_DIR)/udp/ucUdpHeaderManipulation.h \
	$(INC_DIR)/udp/ucUdpHeaderTypes.h
SRC_H_FILES_WITH_INLINES := \
	$(INC_DIR)/6lowpan/detail/uc6LoWPANHeaderManipulationImpl.h \
	$(INC_DIR)/6lowpan/detail/uc6LoWPANMeshManipulationImpl.h \
	$(INC_DIR)/6lowpan/detail/uc6LoWPANPacketForwardingImpl.h \
	$(INC_DIR)/base/detail/ucEtxImpl.h \
	$(INC_DIR)/base/detail/ucIoVecImpl.h \
	$(INC_DIR)/base/detail/ucStringImpl.h \
	$(INC_DIR)/icmpv6/detail/ucIcmpv6BasicMessageBuildersImpl.h \
	$(INC_DIR)/ieee154/detail/ucIeee154AddressManipulationImpl.h \
	$(INC_DIR)/ieee154/detail/ucIeee154FrameManipulationImpl.h \
	$(INC_DIR)/ieee154/detail/ucIeee154Ipv6InterfaceStateManipulationImpl.h \
	$(INC_DIR)/ipv6/detail/ucIpv6AddressManipulationImpl.h \
	$(INC_DIR)/ipv6/detail/ucIpv6BasicHeaderManipulationImpl.h \
	$(INC_DIR)/ipv6/detail/ucIpv6ChecksumImpl.h \
	$(INC_DIR)/ipv6/detail/ucIpv6GenericInterfaceStateManipulationImpl.h \
	$(INC_DIR)/ipv6/detail/ucIpv6PacketAllocationImpl.h \
	$(INC_DIR)/rpl/detail/ucRplLollipopImpl.h \
	$(INC_DIR)/srcroute/detail/ucSourceRouteExtensionHeaderManipulationImpl.h
OBJ_ASM_FILES_WITH_BANKS := $(subst .c,.asm,$(SRC_C_FILES_WITH_BANKS))
OBJ_ASM_FILES_WITH_BANKS := $(subst $(PKG_DIR),$(OBJ_DIR),$(OBJ_ASM_FILES_WITH_BANKS))
OBJ_REL_FILES_WITH_BANKS := $(subst .asm,.rel,$(OBJ_ASM_FILES_WITH_BANKS))
OBJ_SYM_FILES_WITH_BANKS := $(subst .asm,.sym,$(OBJ_ASM_FILES_WITH_BANKS))
OBJ_LST_FILES_WITH_BANKS := $(subst .asm,.lst,$(OBJ_ASM_FILES_WITH_BANKS))
BIN_REL_FILES_WITH_BANKS := $(subst $(OBJ_DIR),$(BIN_DIR),$(OBJ_REL_FILES_WITH_BANKS))
BIN_LST_FILES_WITH_BANKS := $(subst $(OBJ_DIR),$(BIN_DIR),$(OBJ_LST_FILES_WITH_BANKS))
BIN_LIBRARY_MAIN_HEADER_FILE := $(BIN_DIR)/nesc_whip6lib.h
BIN_LIBRARY_OTHER_HEADER_FILES := $(SRC_H_FILES_WITH_HEADERS) $(SRC_H_FILES_WITH_INLINES)
BIN_LIBRARY_OTHER_HEADER_FILES := $(subst $(INC_DIR),$(BIN_DIR),$(BIN_LIBRARY_OTHER_HEADER_FILES))

TARGET_OBJS := \
	$(BIN_REL_FILES_WITH_BANKS) \
	$(BIN_LST_FILES_WITH_BANKS) \
	$(BIN_LIBRARY_OTHER_HEADER_FILES) # \
	$(BIN_LIBRARY_MAIN_HEADER_FILE)

.PRECIOUS: $(OBJ_ASM_FILES_WITH_BANKS) $(OBJ_REL_FILES_WITH_BANKS) $(OBJ_SYM_FILES_WITH_BANKS) $(OBJ_LST_FILES_WITH_BANKS)


.PHONY: all

all: $(TARGET_OBJS)
	  @true # Suppress 'Nothing to be done for all'


$(BIN_DIR)/%.rel: $(OBJ_DIR)/%.rel
	$(SHELL_COPY) $^ $@

$(BIN_DIR)/%.lst: $(OBJ_DIR)/%.lst
	$(SHELL_COPY) $^ $@

$(BIN_DIR)/%.h: $(INC_DIR)/%.h
	perl -w mangleHeader.pl $< $@

$(BIN_LIBRARY_MAIN_HEADER_FILE): $(BIN_LIBRARY_OTHER_HEADER_FILES)
	perl -w createMainHeader.pl $^ >$@ || $(SHELL_RM) $@

$(OBJ_DIR)/%.rel $(OBJ_DIR)/%.sym $(OBJ_DIR)/%.lst: $(OBJ_DIR)/%.asm
	$(SDCC_AS) $(SDCC_AS_FLAGS) $<

$(OBJ_DIR)/%.asm: $(PKG_DIR)/%.c $(SRC_H_FILES_WITH_HEADERS) $(SRC_H_FILES_WITH_INLINES) $(SRC_C_FILES_WITH_CODE)
	$(SDCC_CC) $(SDCC_CC_FLAGS) -o $@ $<

clean:
#	$(SHELL_RM) $(BIN_LIBRARY_MAIN_HEADER_FILE)
	$(SHELL_RM) $(BIN_LIBRARY_OTHER_HEADER_FILES)
	$(SHELL_RM) $(BIN_REL_FILES_WITH_BANKS)
	$(SHELL_RM) $(BIN_LST_FILES_WITH_BANKS)
	$(SHELL_RM) $(OBJ_LST_FILES_WITH_BANKS)
	$(SHELL_RM) $(OBJ_SYM_FILES_WITH_BANKS)
	$(SHELL_RM) $(OBJ_REL_FILES_WITH_BANKS)
	$(SHELL_RM) $(OBJ_ASM_FILES_WITH_BANKS)
	
