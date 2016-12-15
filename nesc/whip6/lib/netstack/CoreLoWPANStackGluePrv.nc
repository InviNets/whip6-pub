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
 * Glue code for the 6LoWPAN radio
 * stack on WhisperCore-based platforms.
 *
 * @author Konrad Iwanicki
 */
module CoreLoWPANStackGluePrv
{
    provides
    {
        interface SynchronousStarter;
    }
    uses
    {
        interface SynchronousStarter as Ieee154StackSynchronousStarter;
        interface SynchronousStarter as GenericLoWPANStackSynchronousStarter;
    }
}
implementation
{
    command error_t SynchronousStarter.start()
    {
        error_t   status;
        status = call Ieee154StackSynchronousStarter.start();
        if (status != SUCCESS && status != EALREADY)
        {
            return status;
        }
        return call GenericLoWPANStackSynchronousStarter.start();
    }
}

