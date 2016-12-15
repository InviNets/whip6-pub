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

configuration XMACRadioPub {
    provides interface Init;
    provides interface RawFrameSender;
    provides interface RawFrameReceiver;
    provides interface XMACControl;

    uses interface Init as LowInit;
    uses interface RawFrame;
    uses interface XMACFrame;
    uses interface RawFrameSender as LowFrameSender;
    uses interface RawFrameReceiver as LowFrameReceiver;
    uses interface Timer<T32khz, uint32_t>;
}
implementation {
    components XMACRadioPrv;
    XMACRadioPrv.RawFrame = RawFrame;
    XMACRadioPrv.XMACFrame = XMACFrame;
    XMACRadioPrv.LowFrameSender = LowFrameSender;
    XMACRadioPrv.LowFrameReceiver = LowFrameReceiver;
    XMACRadioPrv.Timer = Timer;
    XMACRadioPrv.Init = Init;
    XMACRadioPrv.LowInit = LowInit;
    RawFrameSender = XMACRadioPrv;
    RawFrameReceiver = XMACRadioPrv;
    Init = XMACRadioPrv;
    XMACControl = XMACRadioPrv;
}
