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

generic module SamplingDimensionalReadPrv(typedef units_tag,
        typedef val_t @integer(), typedef accum_t @integer(),
        int sampleTimeMs, int numSamples)
{
    uses interface DimensionalRead<units_tag, val_t> as From;
    uses interface Timer<TMilli, uint32_t>;
    provides interface DimensionalRead<units_tag, val_t> as To;
}
implementation
{
    bool isReadingFrom;
    int numSamplesRead;
    int numSamplesRemaining;
    accum_t accumulator;

    command inline error_t To.read() {
        numSamplesRemaining = numSamples;
        numSamplesRead = 0;
        accumulator = 0;
        call Timer.startWithTimeoutFromNow(0);
        return SUCCESS;
    }

    event inline void Timer.fired() {
        if (numSamplesRemaining == 0) {
            signal To.readDone(SUCCESS, accumulator / numSamplesRead);
            return;
        }
        numSamplesRemaining--;
        if (!isReadingFrom) {
            error_t err = call From.read();
            if (err != SUCCESS) {
                signal To.readDone(err, 0);
                return;
            } else {
                isReadingFrom = TRUE;
            }
        }
        call Timer.startWithTimeoutFromLastTrigger(sampleTimeMs);
    }

    event inline void From.readDone(error_t result, val_t val) {
        isReadingFrom = FALSE;
        if (result != SUCCESS) {
            call Timer.stop();
            signal To.readDone(result, val);
            return;
        }
        accumulator += val;
        numSamplesRead++;
    }
}
