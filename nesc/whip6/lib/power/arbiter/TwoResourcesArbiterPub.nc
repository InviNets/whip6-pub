/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 *
 * @author Michal Marschall <m.marschall@invinets.com>
 *
 * When a request is made, this module reserves two subresources in a specified
 * order. When the resource is released, subresources are released in an opposite
 * order.
 */

generic module TwoResourcesArbiterPub() {
    provides interface Resource;

    uses interface Resource as FirstResource @exactlyonce();
    uses interface Resource as SecondResource @exactlyonce();
}

implementation {
    bool reqFirst = FALSE, reqSecond = FALSE;

    async command error_t Resource.request() {
        error_t error = call FirstResource.request();
        if(error == SUCCESS) {
            reqFirst = TRUE;
        }
        return error;
    }

    async command error_t Resource.immediateRequest() {
        error_t error;

        error = call FirstResource.immediateRequest();
        if(error == SUCCESS) {
            error = call SecondResource.immediateRequest();
            if(error != SUCCESS) {
                call FirstResource.release();
            }
        }
        return error;
    }

    event void FirstResource.granted() {
        if(reqFirst) {
            error_t error = call SecondResource.request();
            reqFirst = FALSE;
            if(error == SUCCESS) {
                reqSecond = TRUE;
            } else {
                /* Very big fail: we will never signal granted and we cannot do anything. */
                call FirstResource.release();
            }
        }
    }

    event void SecondResource.granted() {
        if(reqSecond) {
            reqSecond = FALSE;
            signal Resource.granted();
        }
    }

    async command error_t Resource.release() {
        error_t error1, error2;

        error1 = call SecondResource.release();
        error2 = call FirstResource.release();

        return error1 == SUCCESS? error2 : error1;
    }

    async command bool Resource.isOwner() {
        return call FirstResource.isOwner() && call SecondResource.isOwner();
    }
}
