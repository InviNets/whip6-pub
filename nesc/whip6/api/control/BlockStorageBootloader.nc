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
 * Bootloader entry point for programming from the external flash.
 *
 * It is assumed that the bootloader can somehow communicate with
 * PlatformBootloaderBlockStoragePub()-provided storage. This
 * interface is used to initiate programming, once the image has
 * been stored in the block storage.
 *
 * @author Szymon Acedanski
 */
interface BlockStorageBootloader
{
    /**
     * Programs the image already saved in the bootloader BlockStorage.
     * May return an error, but otherwise never returns.
     */
    command error_t programBlockStorageImage(uint32_t offset, uint32_t len);
}

