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
 * A platform-dependent implementation of
 * a cloner for IPv6 packets.
 *
 * @author Szymon Acedanski
 */
generic configuration PlatformIPv6PacketClonerPub()
{
    provides
    {
        interface IPv6PacketCloner;
    }
}
implementation
{
    components new GenericIPv6PacketClonerPub() as Generic;
    IPv6PacketCloner = Generic;
}
