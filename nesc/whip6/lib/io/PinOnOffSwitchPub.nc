/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 */

generic module PinOnOffSwitchPub(bool pinHighMeansOn) {
    uses interface IOPin as Pin;

    provides interface Init @exactlyonce();
    provides interface OnOffSwitch as OnOff;
}
implementation{
    command error_t Init.init(){
        call Pin.makeOutput();
        if (pinHighMeansOn) {
            call Pin.setLow();
        }
        else {
            call Pin.setHigh();
        }
        return SUCCESS;
    }

    command error_t OnOff.on(){
        if (pinHighMeansOn) {
            call Pin.setHigh();
        }
        else {
            call Pin.setLow();
        }
        return SUCCESS;
    }

    command error_t OnOff.off(){
        if (pinHighMeansOn) {
            call Pin.setLow();
        }
        else {
            call Pin.setHigh();
        }
        return SUCCESS;
    }
}
