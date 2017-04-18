/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 * @author Szymon Acedanski
 *
 * Makes the putchar() function available for the applications.
 *
 * This configuration is always available (referenced in CC26xxBasedPub.nc),
 * because it is needed by microc.
 */
configuration PutcharProviderPub {
}
implementation {
#ifdef PLATFORM_NO_PRINTF
    // -- no putchar
    components DummyPutcharProviderPub;
#elseif PLATFORM_PRINTF_OVER_UART0
    // -- putchar over UART0
    components BlockingWritePutcharProviderPub;
    components BlockingUART0Pub;
    BlockingWritePutcharProviderPub.BlockingWrite -> BlockingUART0Pub;
#else
    // -- putchar over Sensor Controller UART
    components NonBlockingWritePutcharProviderPub;
    components NonBlockingSCUARTPub;
    NonBlockingWritePutcharProviderPub.NonBlockingWrite -> NonBlockingSCUARTPub;
#endif
}
