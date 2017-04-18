/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
