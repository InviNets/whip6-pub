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
#include <6lowpan/uc6LoWPANIpv6AddressManipulation.h>
#include <ieee154/ucIeee154AddressManipulation.h>
#include <ieee154/ucIeee154AddressTypes.h>
#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6IanaConstants.h>
#include <ipv6/ucIpv6PacketAllocation.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>


#define APP_OUTPUT_METHOD_NONE 0
#define APP_OUTPUT_METHOD_USB 1
#define APP_OUTPUT_METHOD_UART 2

#ifndef APP_DEFAULT_OUTPUT_METHOD
#define APP_DEFAULT_OUTPUT_METHOD APP_OUTPUT_METHOD_NONE
#endif

#if ((APP_DEFAULT_OUTPUT_METHOD) == (APP_OUTPUT_METHOD_USB))
#include <usb_serial_stdio.h>
#warning Output method: USB
#elif ((APP_DEFAULT_OUTPUT_METHOD) == (APP_OUTPUT_METHOD_UART))
#include <uart_serial_stdio.h>
#warning Output method: UART
#else
#include <stdio.h>
#warning Output method: NONE
#endif


/**
 * The main module of the application that forms
 * an IPv6 bridge between a one-hop radio network
 * and a serial interface.
 *
 * @author Konrad Iwanicki
 */
module CoreOneHopRadioSerialIpv6PacketBridgeMainPrv
{
    uses
    {
        interface Boot;
        interface SynchronousStarter as RadioStackStarter;
        interface LoWPANIPv6PacketAcceptor as RadioPacketAcceptor;
        interface LoWPANIPv6PacketForwarder as RadioPacketForwarder;
        interface RiMACPassiveReceive;
        interface Queue<whip6_ipv6_packet_t *, uint8_t> as RadioToSerialPacketQueue;
        interface Queue<whip6_ipv6_packet_t *, uint8_t> as SerialToRadioPacketQueue;
        interface CoreOneHopRadioSerialIpv6PacketBridgePacketInterceptor as RadioToSerialPacketInterceptor;
        interface CoreOneHopRadioSerialIpv6PacketBridgePacketInterceptor as SerialToRadioPacketInterceptor;
        interface CoreOneHopRadioSerialIpv6PacketBridgeIeee154AddressProvider as SerialToRadioIeee154AddressProvider;
        interface DiscreteStreamWriter as SerialStreamWriter;
        interface DiscreteStreamReader as SerialStreamReader;
        interface Ieee154LocalAddressProvider;
        interface Led as ErrorLed;
        interface Led as RadioToSerialTxLed;
        interface Led as SerialToRadioTxLed;
        interface Timer<TMilli, uint32_t> as ErrorBlinkTimer;
        interface OnOffSwitch as SleepOnOff;
        interface Timer<TMilli, uint32_t> as SimpleSerialToRadioWatchDogTimer;
        interface Timer<TMilli, uint32_t> as SimpleRadioToSerialWatchDogTimer;
    }    
}
implementation
{
    whip6_iov_blist_t      m_outgoingIovHead;
    whip6_iov_blist_t      m_incomingIovHead;
    uint8_t                m_errorBlinksLeft = 0UL;
    bool                   m_serialToRadioPacketForwarded = FALSE;
    bool                   m_radioToSerialPacketForwarded = FALSE;

    whip6_ieee154_addr_t   m_outgoingIeee154Addr;


    static size_t packetToIov(
            whip6_iov_blist_t * iovHead,
            whip6_ipv6_packet_t * pkt
    );
    static whip6_ipv6_packet_t * iovToPacket(
            whip6_iov_blist_t * iovHead,
            whip6_iov_blist_t * iov
    );

    static void finishHandlingRadioToSerialPacket();
    static void finishHandlingSerialToRadioPacket();

    static void startErrorReportingOnLeds(uint8_t numBlinks);
    static void stopErrorReportingOnLeds();

    task void startProcessingRadioToSerialPacketTask();
    task void transmitRadioToSerialPacketTask();
    task void startProcessingSerialToRadioPacketTask();
    task void transmitSerialToRadioPacketTask();

#if ((APP_DEFAULT_OUTPUT_METHOD) == (APP_OUTPUT_METHOD_USB))
#define local_dbg(...) usb_printf(__VA_ARGS__)
#elif ((APP_DEFAULT_OUTPUT_METHOD) == (APP_OUTPUT_METHOD_UART))
#define local_dbg(...) uart_printf(__VA_ARGS__)
#else
#define local_dbg(...)
#endif


    // ---------------------------------------------------------------------
    // -                                                                   -
    // -                           Initialization                          -
    // -                                                                   -
    // ---------------------------------------------------------------------

    event void Boot.booted()
    {    
        call SleepOnOff.off();
        
        if (call SerialStreamReader.startReadingDataUnit(WHIP6_IPV6_MIN_MTU) != SUCCESS)
        {
            startErrorReportingOnLeds(0xff);
            return;
        }
        if (call RadioStackStarter.start() != SUCCESS)
        {
            startErrorReportingOnLeds(0xff);
            return;
        }

        call RiMACPassiveReceive.enablePassive();

#if ((APP_SERIAL_TO_RADIO_WATCHDOG_TIMER_IN_MILLIS) > 0)
        call SimpleSerialToRadioWatchDogTimer.startWithTimeoutFromNow(
                APP_SERIAL_TO_RADIO_WATCHDOG_TIMER_IN_MILLIS
        );
#endif
#if ((APP_RADIO_TO_SERIAL_WATCHDOG_TIMER_IN_MILLIS) > 0)
        call SimpleRadioToSerialWatchDogTimer.startWithTimeoutFromNow(
                APP_RADIO_TO_SERIAL_WATCHDOG_TIMER_IN_MILLIS
        );
#endif
    }



    static size_t packetToIov(
            whip6_iov_blist_t * iovHead,
            whip6_ipv6_packet_t * pkt
    )
    {
        iovHead->iov.ptr = (uint8_t_xdata *)(&pkt->header);
        iovHead->iov.len = sizeof(whip6_ipv6_basic_header_t);
        iovHead->next = pkt->firstPayloadIov;
        if (iovHead->next != NULL)
        {
            iovHead->next->prev = iovHead;
        }
        iovHead->prev = NULL;
        return (size_t)sizeof(whip6_ipv6_basic_header_t) +
                whip6_ipv6BasicHeaderGetPayloadLength(&pkt->header);
    }



    static whip6_ipv6_packet_t * iovToPacket(
            whip6_iov_blist_t * iovHead,
            whip6_iov_blist_t * iov
    )
    {
        whip6_ipv6_packet_t *   pkt;
        if (iov != iovHead)
        {
            return NULL;
        }
        if (iovHead->iov.len != sizeof(whip6_ipv6_basic_header_t))
        {
            return NULL;
        }
        pkt =
                (whip6_ipv6_packet_t *)(((uint8_t_xdata *)iovHead->iov.ptr) -
                        offsetof(whip6_ipv6_packet_t, header));
        if (pkt->firstPayloadIov != iovHead->next)
        {
            return NULL;
        }
        if (iovHead->next != NULL)
        {
            iovHead->next->prev = NULL;
        }
        return pkt;
    }



    // ---------------------------------------------------------------------
    // -                                                                   -
    // -                          Serial to Radio                          -
    // -                                                                   -
    // ---------------------------------------------------------------------

    event whip6_iov_blist_t * SerialStreamReader.provideIOVForDataUnit(
            size_t size
    )
    {
        whip6_ipv6_packet_t *   pkt;

        local_dbg("[Bridge] An I/O vector of size %lu requested for "
            "serial data.\r\n", (long unsigned)size);

        if (size < sizeof(whip6_ipv6_basic_header_t))
        {
            goto FAILURE_ROLLBACK_0;
        }
        pkt = whip6_ipv6AllocatePacket(size - sizeof(whip6_ipv6_basic_header_t));
        if (pkt == NULL)
        {
            startErrorReportingOnLeds(1);
            goto FAILURE_ROLLBACK_0;
        }
        packetToIov(&m_incomingIovHead, pkt);

        local_dbg("[Bridge] Returning an I/O vector, %lu, of size %lu, "
            "which corresponds to packet %lu.\r\n",
            (long unsigned)&m_incomingIovHead, (long unsigned)size,
            (long unsigned)pkt);

        return &m_incomingIovHead;

    FAILURE_ROLLBACK_0:
        return NULL;
    }



    event void SerialStreamReader.finishedReadingDataUnit(
            whip6_iov_blist_t * iov,
            size_t size,
            error_t status
    )
    {
        whip6_ipv6_packet_t *   pkt;

        local_dbg("[Bridge] %lu-byte serial data is available in an I/O "
            "vector %lu.\r\n", (long unsigned)size, (long unsigned)iov);

        pkt = iovToPacket(&m_incomingIovHead, iov);
        if (pkt == NULL)
        {
            local_dbg("[Bridge] ERROR: Bad packet.\r\n");

            startErrorReportingOnLeds(0xff);
            goto FAILURE_ROLLBACK_0;
        }
        if (call SerialToRadioPacketQueue.isFull() || status != SUCCESS)
        {
            startErrorReportingOnLeds(1);
            goto FAILURE_ROLLBACK_1;
        }
        if (call SerialToRadioPacketQueue.isEmpty())
        {
            call SerialToRadioTxLed.on();
            post startProcessingSerialToRadioPacketTask();
        }
        call SerialToRadioPacketQueue.enqueueLast(pkt);
        if (!call SerialToRadioPacketQueue.isFull())
        {
            if (call SerialStreamReader.startReadingDataUnit(WHIP6_IPV6_MIN_MTU) != SUCCESS)
            {
                startErrorReportingOnLeds(0xff);
            }
        }

        local_dbg("[Bridge] Started processing packet %lu from the serial.\r\n",
            (long unsigned)pkt);

        return;

    FAILURE_ROLLBACK_1:
        whip6_ipv6FreePacket(pkt);
    FAILURE_ROLLBACK_0:
    }



    task void startProcessingSerialToRadioPacketTask()
    {
        whip6_ipv6_packet_t *   pkt;
        if (call SerialToRadioPacketQueue.isEmpty())
        {
            startErrorReportingOnLeds(0xff);
            return;
        }
        pkt = call SerialToRadioPacketQueue.peekFirst();
        call SerialToRadioPacketInterceptor.startInterceptingPacket(pkt);
    }



    event void SerialToRadioPacketInterceptor.finishInterceptingPacket(
            whip6_ipv6_packet_t * pkt,
            bool drop
    )
    {
        if (call SerialToRadioPacketQueue.isEmpty() ||
                pkt != call SerialToRadioPacketQueue.peekFirst())
        {
            startErrorReportingOnLeds(0xff);
            return;
        }
        if (drop)
        {
            finishHandlingSerialToRadioPacket();
        }
        else
        {
            post transmitSerialToRadioPacketTask();
        }
    }



    task void transmitSerialToRadioPacketTask()
    {
        whip6_ipv6_packet_t * pkt;

        if (call SerialToRadioPacketQueue.isEmpty())
        {
            startErrorReportingOnLeds(0xff);
            return;
        }
        pkt = call SerialToRadioPacketQueue.peekFirst();

        // Compute the outgoing link-layer address.
        if (call SerialToRadioIeee154AddressProvider.computeIeee154AddressForOutgoingPacket(
                pkt, &m_outgoingIeee154Addr) != SUCCESS)
        {
            goto FAILURE_ROLLBACK_0;
        }

        // Transmit the packet over the radio.
        if (call RadioPacketForwarder.startForwardingIpv6Packet(pkt, &m_outgoingIeee154Addr) != SUCCESS)
        {
            goto FAILURE_ROLLBACK_0;
        }

        return;

    FAILURE_ROLLBACK_0:
        startErrorReportingOnLeds(1);
        finishHandlingSerialToRadioPacket();
    }



    event void RadioPacketForwarder.forwardingIpv6PacketFinished(
            whip6_ipv6_packet_t * pkt,
            whip6_ieee154_addr_t const * llAddr,
            error_t status
    )
    {
        if (call SerialToRadioPacketQueue.isEmpty() ||
                pkt != call SerialToRadioPacketQueue.peekFirst())
        {
            startErrorReportingOnLeds(0xff);
            return;
        }
        if (status != SUCCESS)
        {
            startErrorReportingOnLeds(1);
        }
        else
        {
            m_serialToRadioPacketForwarded = TRUE;
        }
        finishHandlingSerialToRadioPacket();
    }



    static void finishHandlingSerialToRadioPacket()
    {
        whip6_ipv6_packet_t *   pkt;
        bool                    wasFull;
        pkt = call SerialToRadioPacketQueue.peekFirst();
        wasFull = call SerialToRadioPacketQueue.isFull();
        call SerialToRadioPacketQueue.dequeueFirst();
        whip6_ipv6FreePacket(pkt);
        if (call SerialToRadioPacketQueue.isEmpty())
        {
            call SerialToRadioTxLed.off();
        }
        else
        {
            post startProcessingSerialToRadioPacketTask();
        }
        if (wasFull)
        {
            if (call SerialStreamReader.startReadingDataUnit(WHIP6_IPV6_MIN_MTU) != SUCCESS)
            {
                startErrorReportingOnLeds(0xff);
            }
        }
        local_dbg("[Bridge] Finished processing packet %lu from the serial.\r\n",
            (long unsigned)pkt);

    }



    // ---------------------------------------------------------------------
    // -                                                                   -
    // -                          Radio to Serial                          -
    // -                                                                   -
    // ---------------------------------------------------------------------

    event void RadioPacketAcceptor.acceptedIpv6PacketForProcessing(
            whip6_ipv6_packet_t * pkt,
            whip6_ieee154_addr_t const * llAddr
    )
    {
        local_dbg("[Bridge] Started processing packet %lu from the radio.\r\n",
            (long unsigned)pkt);
        if (call RadioToSerialPacketQueue.isFull())
        {
            startErrorReportingOnLeds(1);
            goto FAILURE_ROLLBACK_0;
        }
        if (call RadioToSerialPacketQueue.isEmpty())
        {
            post startProcessingRadioToSerialPacketTask();
            call RadioToSerialTxLed.on();
        }
        call RadioToSerialPacketQueue.enqueueLast(pkt);
        return;

    FAILURE_ROLLBACK_0:
        whip6_ipv6FreePacket(pkt);
    }



    task void startProcessingRadioToSerialPacketTask()
    {
        whip6_ipv6_packet_t *   pkt;
        if (call RadioToSerialPacketQueue.isEmpty())
        {
            startErrorReportingOnLeds(0xff);
            return;
        }
        pkt = call RadioToSerialPacketQueue.peekFirst();
        call RadioToSerialPacketInterceptor.startInterceptingPacket(pkt);
    }



    event void RadioToSerialPacketInterceptor.finishInterceptingPacket(
            whip6_ipv6_packet_t * pkt,
            bool drop
    )
    {
        if (call RadioToSerialPacketQueue.isEmpty() ||
                pkt != call RadioToSerialPacketQueue.peekFirst())
        {
            startErrorReportingOnLeds(0xff);
            return;
        }
        if (drop)
        {
            finishHandlingRadioToSerialPacket();
        }
        else
        {
            post transmitRadioToSerialPacketTask();
        }
    }



    task void transmitRadioToSerialPacketTask()
    {
        whip6_ipv6_packet_t *   pkt;
        size_t                  len;

        if (call RadioToSerialPacketQueue.isEmpty())
        {
            startErrorReportingOnLeds(0xff);
            return;
        }
        pkt = call RadioToSerialPacketQueue.peekFirst();
        len = packetToIov(&m_outgoingIovHead, pkt);
        if (call SerialStreamWriter.startWritingDataUnit(&m_outgoingIovHead, len) != SUCCESS)
        {
            startErrorReportingOnLeds(1);
            finishHandlingRadioToSerialPacket();
        }
    }



    event void SerialStreamWriter.finishedWritingDataUnit(
            whip6_iov_blist_t * iov,
            size_t size,
            error_t status
    )
    {
        whip6_ipv6_packet_t *   pkt;
        pkt = iovToPacket(&m_outgoingIovHead, iov);
        if (call RadioToSerialPacketQueue.isEmpty() ||
                pkt == NULL ||
                pkt != call RadioToSerialPacketQueue.peekFirst())
        {
            startErrorReportingOnLeds(0xff);
            return;
        }
        if (status != SUCCESS)
        {
            startErrorReportingOnLeds(1);
        }
        else
        {
            m_radioToSerialPacketForwarded = TRUE;
        }
        finishHandlingRadioToSerialPacket();
    }



    static void finishHandlingRadioToSerialPacket()
    {
        whip6_ipv6_packet_t *   pkt;
        pkt = call RadioToSerialPacketQueue.peekFirst();
        call RadioToSerialPacketQueue.dequeueFirst();
        whip6_ipv6FreePacket(pkt);
        if (call RadioToSerialPacketQueue.isEmpty())
        {
            call RadioToSerialTxLed.off();
        }
        else
        {
            post startProcessingRadioToSerialPacketTask();
        }
        local_dbg("[Bridge] Finished processing packet %lu from the radio.\r\n",
            (long unsigned)pkt);
    }



    // ---------------------------------------------------------------------
    // -                                                                   -
    // -                          Error reporting                          -
    // -                                                                   -
    // ---------------------------------------------------------------------

    static void startErrorReportingOnLeds(uint8_t numBlinks)
    {
        if (m_errorBlinksLeft == 0xff || numBlinks == 0x00)
        {
            return;
        }
        if (numBlinks == 0xff)
        {
            m_errorBlinksLeft = numBlinks;
        }
        else
        {
            numBlinks = numBlinks << 1;
            m_errorBlinksLeft += numBlinks;
            if (m_errorBlinksLeft < numBlinks || m_errorBlinksLeft == 0xff)
            {
                m_errorBlinksLeft = 0xfe;
            }
        }
        if (! call ErrorBlinkTimer.isRunning())
        {
            call ErrorLed.toggle();
            call ErrorBlinkTimer.startWithTimeoutFromNow(
                    APP_ERROR_BLINK_PERIOD_IN_MILLIS
            );
        }
    }



    static void stopErrorReportingOnLeds()
    {
        m_errorBlinksLeft = 0;
        call ErrorBlinkTimer.stop();
        call ErrorLed.off();
    }



    event void ErrorBlinkTimer.fired()
    {
        if (m_errorBlinksLeft == 0)
        {
            stopErrorReportingOnLeds();
        }
        else
        {
            if (m_errorBlinksLeft < 0xff)
            {
                --m_errorBlinksLeft;
            }
            call ErrorLed.toggle();
            call ErrorBlinkTimer.startWithTimeoutFromNow(
                    APP_ERROR_BLINK_PERIOD_IN_MILLIS
            );
        }
    }



    event void SimpleSerialToRadioWatchDogTimer.fired()
    {
#if ((APP_SERIAL_TO_RADIO_WATCHDOG_TIMER_IN_MILLIS) > 0)
        if (m_serialToRadioPacketForwarded)
        {
            m_serialToRadioPacketForwarded = FALSE;
            call SimpleSerialToRadioWatchDogTimer.startWithTimeoutFromNow(
                    APP_SERIAL_TO_RADIO_WATCHDOG_TIMER_IN_MILLIS
            );
        }
        else
        {
            whip6_crashNode();
        }
#endif
    }
    
    
    
    
    event void SimpleRadioToSerialWatchDogTimer.fired()
    {
#if ((APP_RADIO_TO_SERIAL_WATCHDOG_TIMER_IN_MILLIS) > 0)
        if (m_radioToSerialPacketForwarded)
        {
            m_radioToSerialPacketForwarded = FALSE;
            call SimpleRadioToSerialWatchDogTimer.startWithTimeoutFromNow(
                    APP_RADIO_TO_SERIAL_WATCHDOG_TIMER_IN_MILLIS
            );
        }
        else
        {
            whip6_crashNode();
        }
#endif
    }



    // ---------------------------------------------------------------------
    // -                                                                   -
    // -                             Defaults                              -
    // -                                                                   -
    // ---------------------------------------------------------------------

    whip6_ipv6_packet_t *   m_defaultRadioToSerialInterceptorPkt = NULL;
    whip6_ipv6_packet_t *   m_defaultSerialToRadioInterceptorPkt = NULL;

    task void defaultRadioToSerialInterceptorTask()
    {
        whip6_ipv6_packet_t *   pkt;
        pkt = m_defaultRadioToSerialInterceptorPkt;
        m_defaultRadioToSerialInterceptorPkt = NULL;
        signal RadioToSerialPacketInterceptor.finishInterceptingPacket(pkt, FALSE);
    }

    task void defaultSerialToRadioInterceptorTask()
    {
        whip6_ipv6_packet_t *   pkt;
        pkt = m_defaultSerialToRadioInterceptorPkt;
        m_defaultSerialToRadioInterceptorPkt = NULL;
        signal SerialToRadioPacketInterceptor.finishInterceptingPacket(pkt, FALSE);
    }

    default command inline void RadioToSerialPacketInterceptor.startInterceptingPacket(
            whip6_ipv6_packet_t * pkt
    )
    {
        m_defaultRadioToSerialInterceptorPkt = pkt;
        post defaultRadioToSerialInterceptorTask();
    }

    default command inline void SerialToRadioPacketInterceptor.startInterceptingPacket(
            whip6_ipv6_packet_t * pkt
    )
    {
        m_defaultSerialToRadioInterceptorPkt = pkt;
        post defaultSerialToRadioInterceptorTask();
    }

    default command inline void ErrorLed.toggle()
    {
    }

    default command inline void ErrorLed.off()
    {
    }

    default command inline void RadioToSerialTxLed.on()
    {
    }

    default command inline void RadioToSerialTxLed.off()
    {
    }

    default command inline void SerialToRadioTxLed.on()
    {
    }

    default command inline void SerialToRadioTxLed.off()
    {
    }

    default command inline void RiMACPassiveReceive.enablePassive()
    {
    }

#undef local_dbg

}

