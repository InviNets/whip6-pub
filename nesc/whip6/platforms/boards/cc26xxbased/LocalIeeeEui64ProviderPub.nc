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
 * The default IEEE EUI-64 provider.
 *
 * @author Konrad Iwanicki
 */
configuration LocalIeeeEui64ProviderPub
{
    provides interface LocalIeeeEui64Provider;
}
implementation {
    components HalEui64ProviderPub as Impl;
    LocalIeeeEui64Provider = Impl;
}
