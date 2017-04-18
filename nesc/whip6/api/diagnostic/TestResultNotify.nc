/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


interface TestResultNotify
{
    /**
     * Long blinks notify about success
     */
    command void testsPassed();

    /**
     * Short bursts notify which test nr. has failed.
     */
    command void testFailed(uint8_t testNr);
}
