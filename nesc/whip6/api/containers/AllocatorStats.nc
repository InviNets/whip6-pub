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
 * Helper interface for gathering allocator statistics.
 *
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */
interface AllocatorStats
{
    /**
     * Count all allocations done.
     * @return the number of successful allocations
     */
    command uint32_t getSuccessfulAllocationsCount();

    /**
     * Count failed allocations.
     * @return the number of failed allocations
     */
    command uint32_t getFailedAllocationsCount();

    /**
     * Count currently alive objects.
     * @return the number of failed allocations
     */
    command size_t getAliveObjectsCount();
}
