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
 * @author Michal Marschall <m.marschall@invinets.com>
 * @author Szymon Acedanski
 */

interface OutputPWM {
    /* Start generating PWM output.
     *
     * May be called multiple times with different arguments, it which case it
     * updates the parameters of an active PWM signal.
     *
     * If possible, the hardware should change the parameters glitch-free, not
     * by stopping and restarting the PWM.
     *
     * If the hardware cannot generate the requested frequency, a nearest
     * available one should be used.
     */
    command error_t start(uint8_t percent, uint16_t hz);

    /* Stops the PWM output.
     */
    command error_t stop();
}
