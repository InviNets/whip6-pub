/*
 * Copyright (c) 2000-2003 The Regents of the University  of California.
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
 * - Neither the name of the copyright holders nor the names of
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 *
 *
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */ 

/**
 * MainC is the system interface the TinyOS boot sequence. It wires the
 * boot sequence implementation to the scheduler and hardware resources.
 * 
 * There are 16 initialization steps in the sequence. They are ran staring
 * at 0 and ending at 15. Levels 0-7 should be devoted to hardware and
 * 8-15 should take care of the software components.
 * 
 * The Bootstrap interface is the earliest entry point to the system. Any time
 * critical operations should be done there, but note that the scheduler does
 * not operate at that time.
 *
 * @author Przemyslaw Horban
 */ 

module MainPub @safe() {
    provides interface Boot;
    uses interface Scheduler;

    uses interface Bootstrap; // Atomic. No task scheduler!
    
    // Instead of SystemInitEntry, use BoardStartupPub.
    uses interface Init as SystemInitEntry; // Atomic.
}

implementation {
    int main() @C() @spontaneous() {
        // System starts with interrupts disabled.  

        call Bootstrap.bootstrap();
        call Scheduler.init();
        call SystemInitEntry.init();
        while(call Scheduler.runNextTask());

        /* Trim VIMS to be set to either GPRAM or CACHE mode depending on flag */
        trimVIMSMode();

        /* Enable interrupts now that system is ready. */
        __nesc_enable_interrupt();

        signal Boot.booted();

        /* Spin in the Scheduler */
        call Scheduler.taskLoop();

        /* We should never reach this point, but some versions of
         * gcc don't realize that and issue a warning if we return
         * void from a non-void function. So include this. */
        return -1;
    }

    default command void Bootstrap.bootstrap() {
    }
    default event void Boot.booted() {
    }
}
