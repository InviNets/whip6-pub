/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 * 
 * Trivial interface for byte transfer.
 */
interface ByteInput {
    /**
     * It will block until a byte is available.
     */
    command uint8_t readByte();
}
