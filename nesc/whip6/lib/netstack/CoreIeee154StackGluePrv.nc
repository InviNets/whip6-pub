/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "Ieee154.h"



/**
 * Glue code for the IEEE 802.15.4 radio
 * stack on WhisperCore-based platforms.
 *
 * @author Konrad Iwanicki
 */
module CoreIeee154StackGluePrv
{
    provides
    {
        interface SynchronousStarter;
    }
    uses
    {
        // FIXME iwanicki 2013-09-10:
        // This interface should also be
        // changed to SynchronousStarter.
        interface Init as RadioInit;
        interface XMACControl;
    }
}
implementation
{
    command error_t SynchronousStarter.start()
    {
        error_t   status;
        status = call RadioInit.init();
        if (status != SUCCESS)
        {
            return status;
        }
        #ifdef WHIP6_USE_XMAC
        call XMACControl.enableXMAC();
        #endif
        return SUCCESS;
    }
}
