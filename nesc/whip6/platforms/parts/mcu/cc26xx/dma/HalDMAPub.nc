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
 * @author Szymon Acedanski
 */
 
configuration HalDMAPub {
    provides interface DMAChannel[uint8_t channel];
    provides interface ShareableOnOff;
}
implementation {
    components HalDMAPrv as Impl;
    DMAChannel = Impl;

    components new OnOffSwitchToShareableOnOffAdapterPub() as OnOffAdapter;
    OnOffAdapter.OnOffSwitch -> Impl;
    ShareableOnOff = OnOffAdapter;

    components new HalAskBeforeSleepPub();
    Impl.AskBeforeSleep -> HalAskBeforeSleepPub;
 
    components HplDMAInterruptsPub;
    Impl.DMASwInt -> HplDMAInterruptsPub.SwInt;
    Impl.DMAErrInt -> HplDMAInterruptsPub.ErrInt;
}
