/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <DimensionTypes.h>

/*
 * @author Szymon Acedanski
 * 
 */

generic configuration AnalogEdgeCounterPub(typedef units_tag,
        typedef val_t @integer(), typedef count_t @integer(),
        int threshold, int sampleTimeMs, int debounceSamples,
        bool countFallingEdges)
{
    uses interface DimensionalRead<units_tag, val_t> @exactlyonce();
    provides interface EventCount<count_t>;
    provides interface Event;
}
implementation
{
    components new AnalogEdgeCounterPrv(units_tag, val_t, count_t,
            threshold, sampleTimeMs, debounceSamples, countFallingEdges)
        as Impl;
    components new PlatformTimerMilliPub() as Timer;
    Impl.Timer -> Timer;
    DimensionalRead = Impl.DimensionalRead;
    EventCount = Impl.EventCount;
    Event = Impl.Event;
}
