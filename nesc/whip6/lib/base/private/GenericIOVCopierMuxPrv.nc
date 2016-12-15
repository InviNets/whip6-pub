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

#include "BaseCompileTimeConfig.h"
#include <base/ucIoVec.h>



/**
 * A component virtualizing I/O vector copying.
 *
 * @author Konrad Iwanicki
 */
configuration GenericIOVCopierMuxPrv
{
    provides
    {
        interface IOVCopier[uint8_t clientId];
    }
}
implementation
{
    enum
    {
        NUM_CLIENTS = uniqueCount("GenericIOVCopierMuxPrv::Client"),
    };
    enum
    {
        BYTES_PER_TASK = WHIP6_BASE_MAX_BYTES_PROCESSED_PER_TASK,
    };
    
    components BoardStartupPub as StartupPrv;
    components new GenericIOVCopierVirtualizerPub(
            NUM_CLIENTS,
            BYTES_PER_TASK
    ) as ImplPrv;
    
    StartupPrv.InitSequence[0] -> ImplPrv;
    IOVCopier = ImplPrv;
}

