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


#include <stddef.h>
#include "PlatformProcess.h"

/* A cooperative (non-preemtive) process scheduler.
 *
 * The scheduler maintains two process lists: the run list, which contains
 * the processes which are ready to run, and the sleep list, which contains
 * sleeping processes.
 *
 * The scheduling policy is that the run list is sorted according to priority
 * (lower value of priority means that the process is more important, as
 * in Linux) and the first process from the run list is scheduled.
 */
interface ProcessScheduler {
    /* Returns the currently running process. */
    async command process_t* getCurrentProcess();

    /* Switches to the first process on the run list.
     *
     * Must not be called from interrupt context.
     *
     * May be called with interrupts disabled, in which case the context
     * switch is performed when the interrupts are re-enabled.
     */
    async command void schedule();

    /* Removes the process from the run list and puts it on the sleep list.
     *
     * This does not actually causes a context switch, and therefore should
     * usually be followed by a call to ProcessScheduler.schedule().
     */
    async command void suspend(process_t* p);

    /* Called to wake up a process. Waking up a process consists of setting
     * its state to READY and moving it from the sleep list to the run list.
     *
     * This does not actually causes a context switch, and therefore should
     * usually be followed by a call to ProcessScheduler.schedule().
     */
    async command void resume(process_t* p);

    /* Sets the priority of the given process.
     *
     * It does not actually call ProcessScheduler.schedule().
     */
    async command void setPriority(process_t* p, uint8_t prio);

    /* Returns if a call to schedule would do a context switch
     * (it won't if the current process is the first on the run list).
     */
    async command bool isContextSwitchPending();


    /* Initializes a new process.
     *
     * After the call the process is set as ready to run, but need to
     * be added to the run list using ProcessScheduler.addProcess().
     *
     * The new process is set up to execute func(arg) when scheduled.
     * This function should never exit.
     *
     * We do not support destroying or otherwise ending the processes.
     *
     * The normal way of creating processes is by instantiating a new
     * ProcessPub component.
     */
    command void initProcess(process_t* p, const char* name,
            void (*func)(void*),
            void* arg, uint8_t prio, hal_stack_t* stack_bottom,
            size_t stack_size);

    /* Inserts the process into the scheduler list. This causes the process to
     * be evaluated for running when ProcessScheduler.schedule() is called. */
    command void addProcess(process_t* p);

    /* This should be called by the init code, from the context of
     * the main process:
     *
     *  call ProcessScheduler.initProcess(&process, "main", NULL, NULL, ...);
     *  call ProcessScheduler.addProcess(&process);
     *  call ProcessScheduler.setMainProcess(&process);
     *
     * This must be done exactly once and before the first call to
     * ProcessScheduler.schedule().
     */
    command void setMainProcess(process_t* p);
}
