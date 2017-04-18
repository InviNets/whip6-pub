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
 * @author Szymon Acedanski
 */

generic configuration CC26xxPowerDomainPub(uint32_t domain) {
    provides interface ShareableOnOff;
}
implementation {
    components new OnOffSwitchToShareableOnOffAdapterPub() as Adapter;
    components new CC26xxPowerDomainPrv(domain) as Impl;
    Adapter.OnOffSwitch -> Impl;
    ShareableOnOff = Adapter;
}
