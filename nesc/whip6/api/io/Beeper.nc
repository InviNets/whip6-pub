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
 * @author Szymon Acedanski
 */

/* Well... just an interface for beeping.
 *
 * It can beep some beeps or a Morse signal.
 *
 * Commands below initiate asynchronous beeping. No notification for completion
 * is provided, for simplicity.
 *
 * Beeping when another beep is in progress is ignored and returns EBUSY.
 *
 * This interface should be used for aural signals only, not for visual.
 *
 * Its implementation-dependent, how long a beep takes.
 */
interface Beeper {
    /* Beeps the specified number of times.
     */
    command error_t beep(uint8_t numBeeps);

    /* Beeps according to a sequence of characters ('0' to '9').
     * The actual character determines the duration of each beep.
     *
     * The passed pointer must be valid until the beeping is complete.
     * Well, in practice it should be a global constant...
     */
    command error_t beepSequence(const char_code* pattern);
}
