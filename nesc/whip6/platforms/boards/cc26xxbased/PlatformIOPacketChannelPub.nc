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

generic configuration PlatformIOPacketChannelPub(int channel) {
    provides interface PacketRead;
    provides interface PacketWrite;
}
implementation {
    components new PlatformIOChannelPub(channel);
    components new IOVToPacketReaderAdapterPub() as ReaderAdapter;
    PacketRead = ReaderAdapter;
    ReaderAdapter.IOVRead -> PlatformIOChannelPub;
    components new IOVToPacketWriterAdapterPub() as WriterAdapter;
    PacketWrite = WriterAdapter;
    WriterAdapter.IOVWrite -> PlatformIOChannelPub;
}
