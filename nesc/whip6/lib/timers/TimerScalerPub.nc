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
 * Timer scaler.
 *
 * @author Szymon Acedanski
 */
generic module TimerScalerPub(typedef precision_tag_from,
        typedef precision_tag_to, typedef time_from_t @integer(),
        typedef time_to_t @integer(), int shift)
{
    provides interface Timer<precision_tag_to, time_to_t>;
    provides interface TimerOverflow;
    uses interface Timer<precision_tag_from, time_from_t> as TimerFrom;
    uses interface TimerOverflow as TimerOverflowFrom;
}
implementation {
    time_to_t m_overflowOffset;
    time_to_t m_t0, m_dt;
    time_to_t m_lastTrigger;

    enum
    {
        MAX_DELAY_LOG2 = 8 * sizeof(time_from_t) - 1 - shift,
        MAX_DELAY = ((time_to_t)1) << MAX_DELAY_LOG2,
    };

    inline time_to_t scaleForward(time_from_t t) {
        return t >> shift;
    }

    inline time_from_t scaleBack(time_to_t t) {
        return ((time_from_t)t) << shift;
    }

    void scheduleTimer() {
        time_to_t now = call Timer.getNow(), expires, remaining;

        /* m_t0 is assumed to be in the past. If it's > now, we assume
           that time has wrapped around */
        expires = m_t0 + m_dt;

        /* The cast is necessary to get correct wrap-around arithmetic */
        remaining = (time_to_t)(expires - now);

        /* if (expires <= now) remaining = 0; in wrap-around arithmetic */
        if (m_t0 <= now) {
            if (expires >= m_t0 && /* if it wraps, it's > now */ expires <= now) {
                remaining = 0;
            }
        } else {
            if (expires >= m_t0 || /* didn't wrap so < now */ expires <= now) {
                remaining = 0;
            }
        }
        if (remaining > MAX_DELAY) {
            m_t0 = now + MAX_DELAY;
            m_dt = remaining - MAX_DELAY;
            remaining = MAX_DELAY;
        } else {
            m_t0 += m_dt;
            m_dt = 0;
        }
        //printf("[Timer] Scheduling timer at %lu + %lu\r\n", (unsigned long)now, (unsigned long)remaining);
        
        call TimerFrom.startWithTimeoutFromTime(
            scaleBack(now), scaleBack(remaining));
    }

    command void Timer.startWithTimeoutFromNow(time_to_t dt) {
        m_t0 = call Timer.getNow();
        m_dt = dt;
        scheduleTimer();
    }

    command void Timer.startWithTimeoutFromLastTrigger(time_to_t dt) {
        m_t0 = m_lastTrigger;
        m_dt = dt;
        scheduleTimer();
    }

    command void Timer.startWithTimeoutFromTime(time_to_t t0, time_to_t dt) {
        m_t0 = t0;
        m_dt = dt;
        scheduleTimer();
    }

    command void Timer.stop() {
        call TimerFrom.stop();
    }

    command bool Timer.isRunning() {
        return call TimerFrom.isRunning();
    }

    command time_to_t Timer.getLastTrigger() {
        return m_lastTrigger;
    }

    command time_to_t Timer.getNow() {
        return scaleForward(call TimerFrom.getNow()) + m_overflowOffset;
    }

    command time_to_t Timer.getStartTime() {
        return m_t0;
    }

    command time_to_t Timer.getTimeoutFromStartTime() {
        return m_dt;
    }

    event void TimerOverflowFrom.overflow() {
        m_overflowOffset +=
            ((time_to_t)1) << (8 * sizeof(time_from_t) - shift);
        if (m_overflowOffset == 0) {
            signal TimerOverflow.overflow();
        }
    }

    event void TimerFrom.fired() {
        if (m_dt == 0) {
            m_lastTrigger = m_t0;
            //printf("[Timer] Fired at %lu and running\r\n", (unsigned long)now);
            signal Timer.fired();
        } else {
            scheduleTimer();
        }
    }

    default event void Timer.fired() { }
    default event void TimerOverflow.overflow() { }
}
