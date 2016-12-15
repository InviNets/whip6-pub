include ../../../cortex-m3/Makefile.common

OBJS := flog.o
CFLAGS += -I../cc26xxware -I../cc26xxware/driverlib -I../../../cortex-m3/include -I../../../../../../lib/extern/tfp_printf/cortex-m3

all: $(OBJS)

.PHONY: force
$(OBJS): force
