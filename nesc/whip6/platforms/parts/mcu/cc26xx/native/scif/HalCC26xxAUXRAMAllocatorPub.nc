/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

configuration HalCC26xxAUXRAMAllocatorPub {
    provides interface ChunkAllocator;
}

implementation {
    components HalCC26xxAUXRAMAllocatorPrv as Prv;

    components new HalAskBeforeSleepPub();
    Prv.AskBeforeSleep -> HalAskBeforeSleepPub;

    ChunkAllocator = Prv;
}
