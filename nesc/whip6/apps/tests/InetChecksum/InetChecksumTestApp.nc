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

