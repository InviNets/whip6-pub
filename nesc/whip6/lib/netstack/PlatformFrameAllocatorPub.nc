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

#include <NetStackCompileTimeConfig.h>

configuration PlatformFrameAllocatorPub {
    provides interface ObjectAllocator<platform_frame_t> as FrameAllocator;
}
implementation {
    components BoardStartupPub;
    components new PoolPub(platform_frame_t, WHIP6_IEEE154_MAX_CONCURRENT_FRAMES);
    BoardStartupPub.InitSequence[0] -> PoolPub;
    FrameAllocator = PoolPub;
}
