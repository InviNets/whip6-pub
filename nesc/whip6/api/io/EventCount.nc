/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

interface EventCount<cnt_type_t> {
    /**
     * Initialize all necessary hardware and start counting events.
     */
    command error_t start();
    /* Disable all hardware and stop counting events.
     */
    command error_t stop();
    /**
     * Read the absolute number of events since the beginning of time.
     * This means that the value returned will count events before the start
     * (if the start wasn't the first one).
     * The recommended way of using this is to look at differences between the
     * number of events in 2 points in time. There's no oveflow problem with
     * this aproach.
     * Reads can be done in arbitrary moment in time (regardless of start and
     * stop).
     * @param value Address of variable to store the result.
     * @return SUCCESS or FAILURE
     */
    command error_t read(cnt_type_t *value);
}
