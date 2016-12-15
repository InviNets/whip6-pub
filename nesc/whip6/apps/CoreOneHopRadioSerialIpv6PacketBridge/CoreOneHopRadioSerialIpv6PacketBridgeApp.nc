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

#include "CoreOneHopRadioSerialIpv6PacketBridge.h"
#include <IOChannels.h>



#ifndef WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE
#error No operating mode defined for the serial bridge!
#endif



/**
 * An application that forms an IPv6 bridge between
 * a one-hop radio network and a serial interface.
 *
 * The bridge operates at the level of IPv6 packets.
 * The node running it assumes that all nodes in the
 * network are witin one hop, that is, that the node
 * can reach them with a direct radio transmission.
 * Bridging boils down to transmitting over the radio
 * IPv6 packets received via the serial interface and
 * vice versa. Packets can be unicast or broadcast
 * depending on their destination IPv6 address. 
 * In addition, some user defined transformations
 * can be applied to the packets, which violates the
 * IPv6 design, but may come in handy in some
 * deployments.
 *
 * @author Konrad Iwanicki
 */
configuration CoreOneHopRadioSerialIpv6PacketBridgeApp
{
}
implementation
{
    components CoreOneHopRadioSerialIpv6PacketBridgeMainPrv as AppMainPrv;
    components new PlatformTimerMilliPub() as ErrorBlinkTimerPrv;
    components new QueuePub(
            whip6_ipv6_packet_t *,
            uint8_t,
            APP_IPV6_PACKET_QUEUE_SIZE
    ) as RadioToSerialPacketQueuePrv;
    components new QueuePub(
            whip6_ipv6_packet_t *,
            uint8_t,
            APP_IPV6_PACKET_QUEUE_SIZE
    ) as SerialToRadioPacketQueuePrv;

    components SleepDisablePub;
    AppMainPrv.SleepOnOff -> SleepDisablePub;

#if ((WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE) == \
    WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE_NULL)
#warning Bridge operating mode: NULL (all packets will be dropped).
    components NullPacketInterceptorPrv as InterceptorsPrv;
#elif ((WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE) == \
    WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE_CONTROLLER)
#warning Bridge operating mode: controller.
    components SingleControllerPacketInterceptorPrv as InterceptorsPrv;
#elif ((WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE) == \
    WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE_P2P)
#warning Bridge operating mode: point-to-point.
    components PointToPointPacketInterceptorPrv as InterceptorsPrv;
#elif ((WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE) == \
    WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE_NONREWRITING_UNICAST)
#warning Bridge operating mode: nonrewriting unicast.
    components NonrewritingUnicastPacketInterceptorPrv as InterceptorsPrv;
#elif ((WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE) == \
    WHIP6_CORE_ONE_HOP_RADIO_SERIAL_IPV6_PACKET_BRIDGE_MODE_NONREWRITING)
#warning Bridge operating mode: nonrewriting.
    components NonrewritingPacketInterceptorPrv as InterceptorsPrv;
#endif

    components CoreLoWPANStackPub as RadioStackPrv;
    components BoardStartupPub;

    AppMainPrv.Boot -> BoardStartupPub;
    AppMainPrv.RadioStackStarter -> RadioStackPrv;
    AppMainPrv.RadioPacketForwarder -> RadioStackPrv;
    AppMainPrv.RadioPacketAcceptor -> RadioStackPrv;

#ifndef WHIP6_IEEE154_OLD_STACK
    components CoreIeee154StackPub;
    AppMainPrv.RiMACPassiveReceive -> CoreIeee154StackPub;
#endif

    AppMainPrv.RadioToSerialPacketQueue -> RadioToSerialPacketQueuePrv;
    AppMainPrv.SerialToRadioPacketQueue -> SerialToRadioPacketQueuePrv;
    AppMainPrv.RadioToSerialPacketInterceptor -> InterceptorsPrv.RadioToSerialPacketInterceptor;
    AppMainPrv.SerialToRadioPacketInterceptor -> InterceptorsPrv.SerialToRadioPacketInterceptor;
    AppMainPrv.SerialToRadioIeee154AddressProvider -> InterceptorsPrv.SerialToRadioIeee154AddressProvider;

    components new PlatformIOChannelPub(IOMUX_IPV6_CHANNEL) as IPv6IOChannelPrv;
    components new IOVToDiscreteStreamReaderAdapterPub() as ReaderAdapterPrv;
    components new IOVToDiscreteStreamWriterAdapterPub() as WriterAdapterPrv;
    ReaderAdapterPrv.IOVRead -> IPv6IOChannelPrv;
    WriterAdapterPrv.IOVWrite -> IPv6IOChannelPrv;
    AppMainPrv.SerialStreamReader -> ReaderAdapterPrv;
    AppMainPrv.SerialStreamWriter -> WriterAdapterPrv;

    components new PlatformIOPacketChannelPub(IOMUX_EUI64_CHANNEL) as Eui64IOChannelPrv;
    components new IOMuxEui64ReporterPub() as Eui64ReporterPrv;
    components LocalIeeeEui64ProviderPub as Eui64ProviderPrv;
    Eui64ReporterPrv.PacketWrite -> Eui64IOChannelPrv;
    Eui64ReporterPrv.PacketRead -> Eui64IOChannelPrv;
    Eui64ReporterPrv.LocalIeeeEui64Provider -> Eui64ProviderPrv;
    BoardStartupPub.InitSequence[6] -> Eui64ReporterPrv;

    components new PlatformIOPacketChannelPub(IOMUX_VERSION_CHANNEL) as VersionChannelPrv;
    components new IOMuxVersionReporterPub() as VersionReporterPrv;
    VersionReporterPrv.PacketWrite -> VersionChannelPrv;
    VersionReporterPrv.PacketRead -> VersionChannelPrv;
    BoardStartupPub.InitSequence[6] -> VersionReporterPrv;

    AppMainPrv.Ieee154LocalAddressProvider -> RadioStackPrv;
    AppMainPrv.ErrorBlinkTimer -> ErrorBlinkTimerPrv;

    /** Will tell MAC to leave the radio in RX for this node */
    components new ThisIeee154ShortAddrAlwaysListensPub(WHIP6_IEEE154_ADDRESS_SHORT);

    InterceptorsPrv.Ieee154LocalAddressProvider -> RadioStackPrv;

    components LedsPub;
    AppMainPrv.ErrorLed -> LedsPub.Red;
    AppMainPrv.SerialToRadioTxLed -> LedsPub.Red;
    AppMainPrv.RadioToSerialTxLed -> LedsPub.Red;

    components new PlatformTimerMilliPub() as SimpleSerialToRadioWatchDogTimerPrv;
    components new PlatformTimerMilliPub() as SimpleRadioToSerialWatchDogTimerPrv;
    AppMainPrv.SimpleSerialToRadioWatchDogTimer -> SimpleSerialToRadioWatchDogTimerPrv;
    AppMainPrv.SimpleRadioToSerialWatchDogTimer -> SimpleRadioToSerialWatchDogTimerPrv;
}

