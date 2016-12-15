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
 * A bit with synchronous interface.
 *
 * @author Konrad Iwanicki
 */
generic configuration BitPub()
{
    provides interface Bit;
}
implementation
{
    enum
    {
        MY_IDX = unique("GlobalBitVectorPub"),
    };

    components GlobalBitVectorPub as BitVectorPrv;
    Bit = BitVectorPrv.Bit[MY_IDX];
}

