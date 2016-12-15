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
 * An object allocator.
 *
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */
interface ObjectAllocator<obj_t>
{
    /**
     * Allocates an object.
     * @return pointer to the allocated data or NULL if there's no memory left.
     */
    command obj_t * allocate();

    /**
     * Frees the previously allocated object.
     */
    command void free(obj_t * object);
}
