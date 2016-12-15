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

generic configuration CC26xxPowerDomainPub(uint32_t domain) {
    provides interface ShareableOnOff;
}
implementation {
    components new OnOffSwitchToShareableOnOffAdapterPub() as Adapter;
    components new CC26xxPowerDomainPrv(domain) as Impl;
    Adapter.OnOffSwitch -> Impl;
    ShareableOnOff = Adapter;
}
