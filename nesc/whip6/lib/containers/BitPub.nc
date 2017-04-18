/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
