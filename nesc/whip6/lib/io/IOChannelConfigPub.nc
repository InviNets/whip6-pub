/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

generic module IOChannelConfigPub(int channel_num) {
    provides interface Init;
    uses interface IOChannelConfig;
}
implementation {
    command error_t Init.init(void) {
        call IOChannelConfig.setChannel(channel_num);
        return SUCCESS;
    }
}
