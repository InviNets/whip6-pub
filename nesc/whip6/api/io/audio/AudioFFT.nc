/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


interface AudioFFT {
    /* Signaled to provide a new audio FFT result.sound level as a fraction of the full
     * scale value. Max is 65535.
     */
    event void ready(int16_t* coefficients, int windowSize);
}
