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

generic module DummyShareableOnOff() {
    provides interface ShareableOnOff;
}

implementation {
    command void ShareableOnOff.on() {
    }

    command void ShareableOnOff.off() {
    }
}
