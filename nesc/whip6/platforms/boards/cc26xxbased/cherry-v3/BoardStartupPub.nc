/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 *
 * This component is responsible for board specific initializations,
 * that were not inherited from BoardStartupPrv.
 *
 * There are 16 initialization steps in the sequence. They are ran staring
 * at 0 and ending at 15. These can be used to set the order of component
 * initialization.
 *
 * Besides that, an enum in InitOrder.h defines additional levels that can
 * be ran before or after those defined above. In order to use this, modify
 * InitOrder.h and InitOrderPrv.nc.
 */
configuration BoardStartupPub {
    uses interface Init as InitSequence[uint8_t level];
    provides interface Boot;
}
implementation {
    components InitOrderPrv, MainPub, CC26xxBasedPub;
    InitOrderPrv.SystemInitEntry <- MainPub.SystemInitEntry;
    InitSequence = InitOrderPrv;
    Boot = MainPub;

    components BoardPinsPrv;
}
