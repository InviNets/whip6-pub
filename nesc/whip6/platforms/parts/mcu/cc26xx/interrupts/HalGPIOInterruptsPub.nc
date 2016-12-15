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
 * @author Przemyslaw Horban <extremegf@gmail.com>
 * @author Szymon Acedanski
 *
 * Gives access to GPIO rising/falling edge interrupt.
 *
 * Note that the ExternalEvent interfaces of particular pins will only be
 * active if you configure them through GPIOEventConfig interface.
 */

#include "aon_event.h"

configuration HalGPIOInterruptsPub {
    provides interface ExternalEvent[uint32_t IOId];
    provides interface GPIOEventConfig[uint32_t IOId];
}
implementation {
    components HalGPIOInterruptsPrv as Impl;
    ExternalEvent = Impl;
    GPIOEventConfig = Impl;

    components HplCC26xxIntSrcPub as Ints;
    Impl.GPIOInterrupt -> Ints.GPIO;

    components new CC26xxWakeUpSourcePub(AON_EVENT_IO) as WakeUp;
    Impl.WakeUpSource -> WakeUp;
}
