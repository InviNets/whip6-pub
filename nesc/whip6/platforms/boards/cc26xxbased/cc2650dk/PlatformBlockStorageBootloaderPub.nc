/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

configuration PlatformBlockStorageBootloaderPub {
    provides interface BlockStorageBootloader;
}
implementation {
    components DummyBootloaderPub as Impl;
    BlockStorageBootloader = Impl;
}
