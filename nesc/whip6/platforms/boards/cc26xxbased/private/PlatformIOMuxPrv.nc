/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "PlatformIOMuxPrv.h"
#include <IOChannels.h>

configuration PlatformIOMuxPrv {
    provides interface IOVRead[uint8_t];
    provides interface IOVWrite[uint8_t];
    provides interface IOChannelConfig as ReadConfig[uint8_t];
    provides interface IOChannelConfig as WriteConfig[uint8_t];
}
implementation {
    components BoardStartupPub;
    components PlatformBufferedIOPub as IO;

    components new BufferedReaderMuxPub(uniqueCount(UQ_IO_CHANNEL));
    IOVRead = BufferedReaderMuxPub;
    ReadConfig = BufferedReaderMuxPub;
    BufferedReaderMuxPub.In -> IO;
    BoardStartupPub.InitSequence[4] -> BufferedReaderMuxPub;

    components new BufferedWriterMuxPub(uniqueCount(UQ_IO_CHANNEL));
    IOVWrite = BufferedWriterMuxPub;
    WriteConfig = BufferedWriterMuxPub;
    BufferedWriterMuxPub.Out -> IO;
    BoardStartupPub.InitSequence[4] -> BufferedWriterMuxPub;

    components new IOMuxFlowControlPub(uniqueCount(UQ_IO_CHANNEL));
    components new PlatformIOPacketChannelPub(IOMUX_FLOW_CONTROL_CHANNEL)
        as FlowControlChannel;
    IOMuxFlowControlPub.IOFlowControlHelper -> BufferedReaderMuxPub;
    IOMuxFlowControlPub.PacketWrite -> FlowControlChannel;
}
