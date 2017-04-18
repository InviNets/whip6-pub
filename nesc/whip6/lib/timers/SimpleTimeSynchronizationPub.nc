/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */



/**
 * This simple time synchronizer either jumps the clock forward or stops the
 * clock until synchronized, unless the discrepancy is larger than
 * max_discrepancy, in which case the clock jumps back.
 *
 * @author Szymon Acedanski
 */
generic module SimpleTimeSynchronizationPub(typedef precision_tag,
        typedef time_type_t @integer(), long long max_discrepancy) {
    provides interface AsyncCounter<precision_tag, time_type_t>;
    provides interface TimeSynchronizationStatus as Status;
    uses interface AsyncCounter<precision_tag, time_type_t> as SourceCounter;
    uses interface TimeSynchronizationSource<precision_tag, time_type_t>;
}
implementation {
    time_type_t delta;  // Signedness does not matter for arithmetic.
    time_type_t lastNow;
    bool synchronized;

    async command time_type_t AsyncCounter.getNow() {
        time_type_t new_now = call SourceCounter.getNow() + delta;
        if (new_now < lastNow && lastNow - new_now < max_discrepancy) {
            return lastNow;
        } else {
            lastNow = new_now;
            return lastNow;
        }
    }

    event void TimeSynchronizationSource.newTimeReference(time_type_t time) {
        atomic {
            delta = time - call SourceCounter.getNow();
        }
        if (!synchronized) {
            synchronized = TRUE;
            signal Status.synchronizationStatusChanged();
        }
    }

    command bool Status.isTimeValid() {
        return synchronized;
    }
}
