/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */

/**
 * @author Szymon Acedanski
 */

#include "GlobalPutchar.h"
#include "tfp_printf.h"

module HalPutcharToTFPPrintfAdapterPub {
    provides interface Init @exactlyonce();
}
implementation{
	void tfp_putc(void* ununsed, char c) __attribute__ ((spontaneous)) @C() {
        whip6_putchar(c);
	}

    command error_t Init.init(){
        init_printf(NULL, tfp_putc);
        return SUCCESS;
    }
}
