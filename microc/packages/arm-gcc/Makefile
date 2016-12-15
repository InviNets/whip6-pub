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

ARMCC ?= arm-none-eabi-gcc
CC := $(ARMCC)
CP ?= cp
RM ?= rm -f

TARGET_NAME := arm-gcc

INC_DIR := ../../include
SRC_DIR := ../../src
OBJ_DIR := ../../obj/$(TARGET_NAME)
BIN_DIR := ../../target/$(TARGET_NAME)
PKG_DIR := ./

CFLAGS ?= -O3

EXTRA_CFLAGS := \
	-c -std=c99 -I$(INC_DIR) \
	-Wno-unused-function \
	-DWHIP6_MICROC_EXTERN_DECL_PREFIX='extern' \
	-DWHIP6_MICROC_EXTERN_DECL_SUFFIX= \
	-DWHIP6_MICROC_EXTERN_DEF_PREFIX= \
	-DWHIP6_MICROC_EXTERN_DEF_SUFFIX= \
	-DWHIP6_MICROC_PRIVATE_DECL_PREFIX='static' \
	-DWHIP6_MICROC_PRIVATE_DECL_SUFFIX= \
	-DWHIP6_MICROC_PRIVATE_DEF_PREFIX='static' \
	-DWHIP6_MICROC_PRIVATE_DEF_SUFFIX= \
	-DWHIP6_MICROC_INLINE_DECL_PREFIX='static inline' \
	-DWHIP6_MICROC_INLINE_DECL_SUFFIX= \
	-DWHIP6_MICROC_INLINE_DEF_PREFIX='static inline' \
	-DWHIP6_MICROC_INLINE_DEF_SUFFIX=

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
SRC_C_FILES_WITH_ENTIRE_LIB := \
	$(PKG_DIR)/ucLibrary.c
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
OBJ_FILES_WITH_ENTIRE_LIB := $(subst .c,.o,$(SRC_C_FILES_WITH_ENTIRE_LIB))
OBJ_FILES_WITH_ENTIRE_LIB := $(subst $(PKG_DIR),$(OBJ_DIR),$(OBJ_FILES_WITH_ENTIRE_LIB))
BIN_FILES_WITH_ENTIRE_LIB := $(subst $(OBJ_DIR),$(BIN_DIR),$(OBJ_FILES_WITH_ENTIRE_LIB))
BIN_LIBRARY_OTHER_HEADER_FILES := $(SRC_H_FILES_WITH_HEADERS) $(SRC_H_FILES_WITH_INLINES)
BIN_LIBRARY_OTHER_HEADER_FILES := $(subst $(INC_DIR),$(BIN_DIR),$(BIN_LIBRARY_OTHER_HEADER_FILES))

TARGET_OBJS := \
	$(BIN_FILES_WITH_ENTIRE_LIB) \
	$(BIN_LIBRARY_OTHER_HEADER_FILES)

.PRECIOUS: $(OBJ_FILES_WITH_ENTIRE_LIB)



all: $(TARGET_OBJS)


$(BIN_DIR)/%.o: $(OBJ_DIR)/%.o
	$(CP) $^ $@

$(BIN_DIR)/%.h: $(INC_DIR)/%.h
	perl -w mangleHeader.pl $< $@

$(OBJ_DIR)/%.o: $(PKG_DIR)/%.c $(SRC_H_FILES_WITH_HEADERS) $(SRC_H_FILES_WITH_INLINES) $(SRC_C_FILES_WITH_CODE)
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

clean:
	$(RM) $(BIN_LIBRARY_OTHER_HEADER_FILES)
	$(RM) $(BIN_FILES_WITH_ENTIRE_LIB)
	$(RM) $(OBJ_FILES_WITH_ENTIRE_LIB)
	
