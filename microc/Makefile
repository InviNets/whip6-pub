#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Konrad Iwanicki
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#

PACKAGE_DIRS=packages

.PHONY: all

all:
	@echo "" >&2
	@echo "whip6: Warsaw High-performance IPv6" >&2
	@echo "Embedded C libraries make system" >&2
	@echo "" >&2
	@echo "No target selected. Please, select one of the following targets:" >&2
	@echo "    cc253x-standard native-gcc" >&2
	@echo "" >&2

cc253x-standard:
	@echo "Compiling the cc253x-standard package."
	$(MAKE) --directory=$(PACKAGE_DIRS)/$@

native-gcc:
	@echo "Compiling the native-gcc package."
	$(MAKE) --directory=$(PACKAGE_DIRS)/$@

arm-gcc:
	@echo "Compiling the arm-gcc package."
	$(MAKE) --directory=$(PACKAGE_DIRS)/$@

clean:
	@echo "Cleaning all the packages."
	$(MAKE) --directory=$(PACKAGE_DIRS)/cc253x-standard clean
	$(MAKE) --directory=$(PACKAGE_DIRS)/native-gcc clean
