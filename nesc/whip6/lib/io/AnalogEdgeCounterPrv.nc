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

generic module AnalogEdgeCounterPrv(typedef units_tag,
        typedef val_t @integer(), typedef count_t @integer(),
        int threshold, int sampleTimeMs, int debounceSamples,
        bool countFallingEdges)
{
    uses interface DimensionalRead<units_tag, val_t> @exactlyonce();
    uses interface Timer<TMilli, uint32_t>;
    provides interface EventCount<count_t>;
    provides interface Event;
}
implementation
{
    bool isActive;
    bool discreteState;
    int debounceCounter;
    count_t eventsCounter;
    val_t lastValue;

    command error_t EventCount.start() {
        if (isActive) {
            return EBUSY;
        }
        isActive = TRUE;
        call Timer.startWithTimeoutFromNow(0);
        return SUCCESS;
    }

    command error_t EventCount.stop() {
        if (!isActive) {
            return EOFF;
        }
        call Timer.stop();
        isActive = FALSE;
    }

    event inline void Timer.fired() {
        bool d = lastValue >= threshold;
        if (countFallingEdges) {
            d = !d;
        }
        if (d == discreteState) {
            debounceCounter = 0;
        } else if (debounceCounter >= debounceSamples) {
            discreteState = d;
            if (d) {
                // This is the debounced rising edge, we count it as a pulse.
                eventsCounter++;
                signal Event.eventObserved();
            }
        } else {
            debounceCounter++;
        }

        call DimensionalRead.read();
        // If an error happens, we do nothing and use the previous
        // measurement.

        call Timer.startWithTimeoutFromLastTrigger(sampleTimeMs);
    }

    event inline void DimensionalRead.readDone(error_t result, val_t val) {
        if (result == SUCCESS) {
            lastValue = val;
        }
    }

    command error_t EventCount.read(count_t *value) {
        *value = eventsCounter;
        return SUCCESS;
    }

    default event void Event.eventObserved() { }
}
