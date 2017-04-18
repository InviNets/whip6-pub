/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 *
 * @author Michal Marschall <m.marschall@invinets.com>
 */

generic module PowerManagerPub() {
    uses interface OnOffSwitch;
    uses interface ResourceDefaultOwner;
}

implementation {
    task void startTask() {
        call OnOffSwitch.on();
        call ResourceDefaultOwner.release();
    }

    task void stopTask() {
        call OnOffSwitch.off();
    }

    async event void ResourceDefaultOwner.requested() {
        post startTask();
    }

    async event void ResourceDefaultOwner.granted() {
        post stopTask();
    }

    async event void ResourceDefaultOwner.immediateRequested() {}
  
    default command error_t OnOffSwitch.on() {
        return SUCCESS;
    }
  
    default command error_t OnOffSwitch.off() {
        return SUCCESS;
    }
}
