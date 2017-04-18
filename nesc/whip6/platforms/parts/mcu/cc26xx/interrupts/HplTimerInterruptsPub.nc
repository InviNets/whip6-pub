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
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

configuration HplTimerInterruptsPub {
    provides interface ExternalEvent as ChannelAInterrupt[uint8_t timer];
    provides interface ExternalEvent as ChannelBInterrupt[uint8_t timer];
}
implementation{
    components HplCC26xxIntSrcPub as Sources;

    components new HplSimpleInterruptEventPrv() as GPT0AEvent;
    GPT0AEvent.InterruptSource -> Sources.Timer0A;
    ChannelAInterrupt[0] = GPT0AEvent;
    components new HplSimpleInterruptEventPrv() as GPT0BEvent;
    GPT0BEvent.InterruptSource -> Sources.Timer0B;
    ChannelBInterrupt[0] = GPT0BEvent;

    components new HplSimpleInterruptEventPrv() as GPT1AEvent;
    GPT1AEvent.InterruptSource -> Sources.Timer1A;
    ChannelAInterrupt[1] = GPT1AEvent;
    components new HplSimpleInterruptEventPrv() as GPT1BEvent;
    GPT1BEvent.InterruptSource -> Sources.Timer1B;
    ChannelBInterrupt[1] = GPT1BEvent;

    components new HplSimpleInterruptEventPrv() as GPT2AEvent;
    GPT2AEvent.InterruptSource -> Sources.Timer2A;
    ChannelAInterrupt[2] = GPT2AEvent;
    components new HplSimpleInterruptEventPrv() as GPT2BEvent;
    GPT2BEvent.InterruptSource -> Sources.Timer2B;
    ChannelBInterrupt[2] = GPT2BEvent;

    components new HplSimpleInterruptEventPrv() as GPT3AEvent;
    GPT3AEvent.InterruptSource -> Sources.Timer3A;
    ChannelAInterrupt[3] = GPT3AEvent;
    components new HplSimpleInterruptEventPrv() as GPT3BEvent;
    GPT3BEvent.InterruptSource -> Sources.Timer3B;
    ChannelBInterrupt[3] = GPT3BEvent;
}
