/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVec.h>
#include "DiscreteStreamConfig.h"



/**
 * A multiplexer for discrete streams on top of
 * asynchronous reading and writing interfaces.
 *
 * @param num_clients The number of clients. Must be
 *   at least 1.
 * @param buffer_size_t The type describing the size of
 *   an internal buffer.
 * @param buffer_size_val The size of an internal buffer.
 *   Must be at least 1 and at most the maximal value
 *   of <tt>buffer_size_t</tt> plus 1.
 *
 * @author Konrad Iwanicki
 */
generic configuration DiscreteStreamMuxPub(
    uint8_t num_clients,
    typedef buffer_size_t @integer(),
    size_t buffer_size_val    
)
{
    provides
    {
        interface Init @exactlyonce();
        interface SynchronousStarter;
        interface SplitPhaseStopper;
        interface DiscreteStreamReader as Reader[uint8_t channel, uint8_t clientId];
        interface DiscreteStreamWriter as Writer[uint8_t channel, uint8_t clientId];
    }
    uses
    {
        interface ReadNow<uint8_t> as AsyncReader @exactlyonce();
        interface AsyncWrite<uint8_t> as AsyncWriter @exactlyonce();
    }
}
implementation
{

    enum
    {
        NUM_CLIENTS = num_clients,
    };
    
    enum
    {
        READ_BUFFER_SIZE = buffer_size_val,
    };
    
    components new DiscreteStreamVirtualizerPrv(
            NUM_CLIENTS
    ) as VirtualizerPrv;
    components new NonvirtualizedDiscreteStreamReaderPrv(
            buffer_size_t,
            READ_BUFFER_SIZE
    ) as ReaderImplPrv;
    components new NonvirtualizedDiscreteStreamWriterPrv(
    ) as WriterImplPrv;
    components new PlatformIPv6ChecksumComputerPub() as WriterChecksumComputerPrv;
    components new BitPub() as IsActiveBitPrv;
    components new BitPub() as ChangingStateBitPrv;
    components new BitPub() as ReadingCanceledBitPrv;
    components new BitPub() as WritingActiveBitPrv;
    components new BitPub() as WritingCanceledBitPrv;

    Init = VirtualizerPrv;
    SynchronousStarter = VirtualizerPrv;
    SplitPhaseStopper = VirtualizerPrv;
    Reader = VirtualizerPrv;
    Writer = VirtualizerPrv;
    
    VirtualizerPrv.InternalReader -> ReaderImplPrv;
    VirtualizerPrv.InternalWriter -> WriterImplPrv;
    VirtualizerPrv.IsActiveBit -> IsActiveBitPrv;
    VirtualizerPrv.ChangingStateBit -> ChangingStateBitPrv;
    VirtualizerPrv.WritingActiveBit -> WritingActiveBitPrv;
    VirtualizerPrv.WritingCanceledBit -> WritingCanceledBitPrv;

    ReaderImplPrv.AsyncReader = AsyncReader;
    ReaderImplPrv.CanceledBit -> ReadingCanceledBitPrv;

    WriterImplPrv.AsyncWriter = AsyncWriter;
    WriterImplPrv.ChecksumComputer -> WriterChecksumComputerPrv;

    // NOTICE iwanicki 2015-06-10:
    // This is to measure the performance.
    // It is not needed in production, as
    // it degrades the performance.
    // components new PlatformTimerMilliPub() as PerformanceTimerPrv;
    // ReaderImplPrv.PerformanceTimer -> PerformanceTimerPrv;
}
