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


#define APP_OUTPUT_METHOD_NONE 0
#define APP_OUTPUT_METHOD_USB 1
#define APP_OUTPUT_METHOD_UART 2
#define APP_OUTPUT_METHOD_STDIO 3

#ifndef APP_DEFAULT_OUTPUT_METHOD
#define APP_DEFAULT_OUTPUT_METHOD APP_OUTPUT_METHOD_STD
#endif

#if ((APP_DEFAULT_OUTPUT_METHOD) == (APP_OUTPUT_METHOD_USB))
#include <usb_serial_stdio.h>
#define app_local_printf(...) usb_printf(__VA_ARGS__)
#warning Output method: USB
#elif ((APP_DEFAULT_OUTPUT_METHOD) == (APP_OUTPUT_METHOD_UART))
#include <uart_serial_stdio.h>
#define app_local_printf(...) uart_printf(__VA_ARGS__)
#warning Output method: UART
#elif ((APP_DEFAULT_OUTPUT_METHOD) == (APP_OUTPUT_METHOD_STDIO))
#include <stdio.h>
#define app_local_printf(...) printf(__VA_ARGS__)
#warning Output method: STDIO
#else
#define app_local_printf(...)
#endif

#include <eui/ucEui64Types.h>

/**
 * An application demonstrating the EUI-64
 * functionality.
 *
 * @author Konrad Iwanicki
 * @author Michal Marschall <m.marschall@invinets.com>
 */
module Eui64DemoAppPrv {
    uses interface Boot;
    uses interface Timer<TMilli, uint32_t>;
    uses interface LocalIeeeEui64Provider as Eui64Provider;
}

implementation {
    enum {
        DISPLAY_INTERVAL_MS = 1000,
    };

    event void Timer.fired() {
        ieee_eui64_t eui64;
        uint8_t i;

        call Eui64Provider.read(&eui64);
        app_local_printf("%02X", eui64.data[0]);
        for(i = 1; i < IEEE_EUI64_BYTE_LENGTH; ++i) {
            app_local_printf("-%02X", eui64.data[i]);
        }
        app_local_printf("\r\n");

        call Timer.startWithTimeoutFromLastTrigger(DISPLAY_INTERVAL_MS);
    }

    event void Boot.booted() {
        call Timer.startWithTimeoutFromNow(DISPLAY_INTERVAL_MS);
    }
}

#undef app_local_printf
