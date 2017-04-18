/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */




/**
 * A platform-dependent implementation of
 * a computer of Internet checksums.
 *
 * @author Konrad Iwanicki
 */
generic configuration PlatformIPv6ChecksumComputerPub()
{
    provides
    {
        interface IPv6ChecksumComputer;
    }
}
implementation
{
    components new GenericIPv6ChecksumComputerPub() as Generic;
    IPv6ChecksumComputer = Generic;
}
