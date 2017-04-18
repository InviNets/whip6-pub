/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

generic module OutputPWMConfigPub(bool highWhenStopped) {
    provides interface OutputPWMConfig;
}
implementation {
    command bool OutputPWMConfig.shouldBeHighWhenStopped() {
        return highWhenStopped;
    }
}
