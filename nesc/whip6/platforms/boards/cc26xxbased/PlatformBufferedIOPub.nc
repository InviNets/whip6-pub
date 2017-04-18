/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

configuration PlatformBufferedIOPub {
    provides interface BufferedRead;
    provides interface BufferedWrite;
}
implementation {
    components BufferedUART0ProviderPub;
    BufferedRead = BufferedUART0ProviderPub;
    BufferedWrite = BufferedUART0ProviderPub;
}
