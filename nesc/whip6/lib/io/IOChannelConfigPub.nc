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
