/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

interface McuSleep {
    /** Called by the scheduler to put the MCU to sleep.

        Please not the required semantic of the implementation:

        Note that putting the microcontroller to sleep MUST have certain
        atomicity properties. The command is called from within an atomic
        section, and MUST atomically re-enable interrupts and go to sleep. An
        issue arises if the system handles an interrupt after it re-enables
        interrupts but before it sleeps: the interrupt may post a task, but
        the task will not be run until the microcontroller wakes up from sleep.

        Therefore sleep must not happen (or must be terminated ASAP) is an
        interrupt becomes pending while (or just before) this command runs.

        Microcontrollers generally have hardware mechanisms to support this
        requirement. For example, on the Atmega128, the ``sei`` instruction
        does not re-enable interrupts until two cycles after it is issued (so
        the sequence ``sei sleep`` runs atomically).

        See also: http://www.tinyos.net/tinyos-2.x/doc/txt/tep112.txt

        Even an empty implementation should enable the interrupts to avoid an
        infinite scheduling loop without interrupts enabled.
    */
    command void sleep();
}
