include ../../../cortex-m3/Makefile.common

PLATFORM_CC26XX_BOOTLOADER_DIO ?= -1

OBJS := startup.o ccfg.o appversion.o
CFLAGS += -I../cc26xxware -I../cc26xxware/driverlib -DBOOTLOADER_DIO=$(PLATFORM_CC26XX_BOOTLOADER_DIO)

all: $(OBJS)

.PHONY: force
$(OBJS): force
