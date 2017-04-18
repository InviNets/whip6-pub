/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <stdio.h>

/**
 * The configuration for the
 * application the functionality related
 * to computing Internet checksums
 * by the microc library.
 *
 * @author Konrad Iwanicki 
 */
configuration InetChecksumTestApp
{
}
implementation
{
    components InetChecksumTestPrv as AppPrv;
    components BoardStartupPub;  
    AppPrv.Boot -> BoardStartupPub;
}
