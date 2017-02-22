/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */

/**
 * @author Przemyslaw Horban <extremegf@gmail.com>
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
#else
    // -- putchar over Sensor Controller UART
    components NonBlockingWritePutcharProviderPub;
    components NonBlockingSCUARTPub;
    NonBlockingWritePutcharProviderPub.NonBlockingWrite -> NonBlockingSCUARTPub;
#endif
}
