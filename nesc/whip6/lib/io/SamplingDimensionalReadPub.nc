/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/*
 * @author Szymon Acedanski
 * 
 */

generic configuration SamplingDimensionalReadPub(typedef units_tag,
        typedef val_t @integer(), typedef accum_t @integer(),
        int sampleTimeMs, int numSamples)
{
    uses interface DimensionalRead<units_tag, val_t> as From;
    provides interface DimensionalRead<units_tag, val_t> as To;
}
implementation
{
    components new SamplingDimensionalReadPrv(units_tag, val_t, accum_t,
            sampleTimeMs, numSamples) as Impl;
    components new PlatformTimerMilliPub() as Timer;
    Impl.Timer -> Timer;
    From = Impl.From;
    To = Impl.To;
}
