/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


interface AudioInput {
    /* Start capturing audio data.
     *
     * The audio driver fills an internal buffer and when a chunk of data is
     * ready (the size of the chunk is driver-dependent), the chunkReady event
     * is signalled.
     *
     * The audio data format is not specified by this interface.
     *
     * If during the capture an error is detected (including buffer overflow),
     * stopped() with appropriate error is signalled and the capture stops.
     * Capture can be restarted from within stopped() handler.
     */
    command error_t start();

    // TODO: consider removing the buffer from start(), so that the low level
    // driver prepares the buffer according to its (possibly complex)
    // requirements. It needed, bufferring may be done by the application
    // anyway.

    /* Request stopping the capture.
     *
     * The capture process does not stop immediately. Depending on the hardware,
     * it may need some time and the buffer passed to start() may be used during
     * that time.
     *
     * chunkReady() events are not signalled between requestStop() and
     * stopped().
     */
    command error_t requestStop();

    /* Signals a new portion of data.
     *
     * The chunk pointer points to a fragment of the buffer passed to
     * start() and does not cross chunk boundaries, but may be a smaller
     * fragment than chunkSize passed to the start() command.
     */
    event void chunkReady(uint8_t_xdata* chunk, uint16_t chunkSize);

    /* Signals that the capture stopped.
     *
     * It may have stopped as a result of requestStop() called, in which case
     * error is SUCCESS, or due to an error.
     */
    event void stopped(error_t error);
}
