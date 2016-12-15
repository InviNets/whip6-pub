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

#include <base/ucIoVec.h>



/**
 * A generic I/O vector copier.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericIOVCopierPub()
{
    provides
    {
        interface IOVCopier;
    }
}
implementation
{
    enum
    {
        CLIENT_IDX = unique("GenericIOVCopierMuxPrv::Client"),
    };
    
    components GenericIOVCopierMuxPrv as MuxPrv;
    
    IOVCopier = MuxPrv.IOVCopier[CLIENT_IDX];
}

