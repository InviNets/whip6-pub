/* Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * TimerMuxPub uses a single Timer to create up to 255 virtual timers.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

#include <Assert.h>

generic module TimerMuxPub(typedef precision_tag,
        typedef time_type_t @integer(), int max_timers) @safe()
{
    provides interface Timer<precision_tag, time_type_t> as Timer[uint8_t num];
    uses interface Timer<precision_tag, time_type_t> as TimerFrom;
}
implementation
{
    enum {
      NUM_TIMERS = max_timers,
      END_OF_LIST = 255,
    };

    struct timer_s;
    typedef struct timer_s _timer_t;
    typedef _timer_t _timer_t_xdata;
    typedef _timer_t_xdata timer_t;

    struct timer_s {
        time_type_t t0;
        time_type_t dt;
        time_type_t last_trigger;
        struct {
            unsigned running : 1;
            unsigned fire_queued : 1;
        };
    };

    timer_t timers[NUM_TIMERS];

    task void updateFromTimer();

    task void fireTimers() {
        uint8_t num;
        for (num = 0; num < NUM_TIMERS; num++) {
            timer_t* timer = &timers[num];
            if (timer->fire_queued) {
                timer->fire_queued = FALSE;
                timer->running = FALSE;
                timer->last_trigger = timer->t0 + timer->dt;
                signal Timer.fired[num]();
            }
        }
        post updateFromTimer();
    }
    
    task void updateFromTimer() {
        time_type_t now = call TimerFrom.getNow();
        time_type_t min_remaining = (time_type_t)-1;
        bool min_remaining_isset = FALSE;
        uint8_t num;

        CHECK(min_remaining > 0);

        call TimerFrom.stop();

        for (num = 0; num < NUM_TIMERS; num++) {
            timer_t* timer = &timers[num];
            time_type_t elapsed, remaining;
            if (!timer->running) {
                continue;
            }
            elapsed = now - timer->t0;
            remaining = timer->dt - elapsed;
            if (timer->dt <= elapsed) {
                remaining = 0;
                timer->fire_queued = TRUE;
            }
            if (remaining < min_remaining) {
                min_remaining = remaining;
                min_remaining_isset = TRUE;
            }
        }

        if (min_remaining_isset) {
            if (min_remaining == 0)
                post fireTimers();
            else
                call TimerFrom.startWithTimeoutFromTime(now, min_remaining);
        }
    }
    
    event void TimerFrom.fired() {
        post fireTimers();
    }

    void startTimer(uint8_t num, time_type_t t0, time_type_t dt) {
        timer_t* timer = &timers[num];
        timer->t0 = t0;
        timer->dt = dt;
        timer->running = TRUE;
        timer->fire_queued = FALSE;
        post updateFromTimer();
    }

    command void Timer.startWithTimeoutFromNow[uint8_t num](time_type_t dt) {
        timer_t* timer = &timers[num];
        timer->t0 = call TimerFrom.getNow();
        timer->dt = dt;
        timer->running = TRUE;
        timer->fire_queued = FALSE;
        post updateFromTimer();
    }

    command void Timer.startWithTimeoutFromLastTrigger[uint8_t num](time_type_t dt) {
        timer_t* timer = &timers[num];
        timer->t0 = timer->last_trigger;
        timer->dt = dt;
        timer->running = TRUE;
        timer->fire_queued = FALSE;
        post updateFromTimer();
    }

    command void Timer.startWithTimeoutFromTime[uint8_t num](time_type_t t0,
            time_type_t dt) {
        timer_t* timer = &timers[num];
        timer->t0 = t0;
        timer->dt = dt;
        timer->running = TRUE;
        timer->fire_queued = FALSE;
        post updateFromTimer();
    }

    command void Timer.stop[uint8_t num]() {
        timer_t* timer = &timers[num];
        timer->running = FALSE;
        timer->fire_queued = FALSE;
        post updateFromTimer();
    }

    command bool Timer.isRunning[uint8_t num]() {
        return timers[num].running;
    }

    command time_type_t Timer.getLastTrigger[uint8_t num]() {
        return timers[num].last_trigger;
    }

    command time_type_t Timer.getNow[uint8_t num]() {
        return call TimerFrom.getNow();
    }

    command time_type_t Timer.getStartTime[uint8_t num]() {
        return timers[num].t0;
    }

    command time_type_t Timer.getTimeoutFromStartTime[uint8_t num]() {
        return timers[num].dt;
    }

    default event void Timer.fired[uint8_t num]() { }
}
