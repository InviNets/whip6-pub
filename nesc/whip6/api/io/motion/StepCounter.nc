/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


/* Represents an algorithm for counting steps based on sensor data.
 * "Sensor data" for now means "accelerometer readings".
 *
 * It is assumed that the sensor data is a sequence of data_type_t
 * elements, and their meaning is implementation-dependent.
 */
interface StepCounter<data_type_t> {
    /* Resets the internal algorithm state. This should be called
     * before the first use and when data continuity is lost.
     */
    command void resetState();

    /* This command should be used to feed data to the detection
     * algorithm. It should be called periodically, as the data
     * come from the sensors.
     */
    command void feedData(data_type_t* data, size_t numItems);

    /* Event generated, from inside feedData(), to notify about
     * the found steps.
     *
     * The detector reports the number of new steps detected.
     * It may delay the reporting of some steps from previous
     * data chunks, for example after making sure that some
     * predefined number of step events has been detected,
     * to avoid too many false positives.
     */
    event void stepsDetected(size_t numSteps);
}
