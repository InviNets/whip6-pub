/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ipv6/ucIpv6AddressHumanReadableIo.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>



/**
 * A generic implementation of a printer of
 * common objects used in the whip6 code base.
 *
 * @author Konrad Iwanicki
 */
generic module GenericCommonObjectPrinterPub()
{
    provides
    {
        interface CommonObjectPrinter;
    }
    uses
    {
        interface CommonFormattedTextPrinter;
    }
}
implementation
{

    static void printFmt(const char * fmt, ...)
    {
        va_list args;
        va_start(args, fmt);
        call CommonFormattedTextPrinter.printFormattedText(fmt, args);
        va_end(args);
    }



    command void CommonObjectPrinter.printByteArray(
            uint8_t_xdata const * arrPtr,
            size_t arrLen
    )
    {
        printFmt("[BYTES::len=%u;data={", (unsigned)arrLen);
        call CommonObjectPrinter.printByteArrayContents(arrPtr, arrLen, ' ');
        printFmt("}]");
    }



    command void CommonObjectPrinter.printByteArrayContents(
            uint8_t_xdata const * arrPtr,
            size_t arrLen,
            char separator
    )
    {
        if (arrLen > 0)
        {
            printFmt("%02x", (unsigned)*arrPtr);
            ++arrPtr;
            --arrLen;
            if (separator == '\0')
            {
                for (; arrLen > 0; --arrLen)
                {
                    printFmt("%02x", (unsigned)*arrPtr);
                    ++arrPtr;
                }
            }
            else
            {
                for (; arrLen > 0; --arrLen)
                {
                    printFmt("%c%02x", separator, (unsigned)*arrPtr);
                    ++arrPtr;
                }
            }
        }
    }



    command void CommonObjectPrinter.printIovFragmentContents(
            whip6_iov_blist_t const * iovElem,
            size_t iovOffset,
            size_t numToPrint,
            char separator
    )
    {
        uint8_t_xdata const *   ptr;
        
        if (iovElem != NULL && numToPrint > 0)
        {
            if (iovOffset >= iovElem->iov.len)
            {
                iovOffset = 0;
                iovElem = iovElem->next;
                if (iovElem == NULL)
                {
                    return;
                }
                ptr = iovElem->iov.ptr;
            }
            else
            {
                ptr = iovElem->iov.ptr + iovOffset;
            }
            printFmt("%02x", (unsigned)*ptr);
            ++ptr;
            --numToPrint;
            ++iovOffset;
            while (numToPrint > 0)
            {
                if (iovOffset >= iovElem->iov.len)
                {
                    iovOffset = 0;
                    iovElem = iovElem->next;
                    if (iovElem == NULL)
                    {
                        return;
                    }
                    ptr = iovElem->iov.ptr;
                }
                if (separator != '\0')
                {
                    printFmt("%c", separator);
                }
                printFmt("%02x", (unsigned)*ptr);
                ++ptr;
                --numToPrint;
                ++iovOffset;
            }
        }
    }



    command void CommonObjectPrinter.printIeee154AddrRaw(
            uint8_t mode,
            uint8_t_xdata const * dataPtr
    )
    {
        uint8_t                 cnt;
        switch (mode)
        {
        case IEEE154_ADDR_MODE_NONE:
            printFmt("NONE");
            break;
        case IEEE154_ADDR_MODE_SHORT:
            dataPtr += IEEE154_SHORT_ADDR_BYTE_LENGTH - 1;
            for (cnt = IEEE154_SHORT_ADDR_BYTE_LENGTH; cnt > 0; --cnt)
            {
                printFmt("%02x", (unsigned)*dataPtr);
                --dataPtr;
            }
            break;
        case IEEE154_ADDR_MODE_EXT:
            dataPtr += IEEE154_EXT_ADDR_BYTE_LENGTH - 1;
            printFmt("%02x", (unsigned)*dataPtr);
            --dataPtr;
            for (cnt = IEEE154_EXT_ADDR_BYTE_LENGTH - 1; cnt > 0; --cnt)
            {
                printFmt("-%02x", (unsigned)*dataPtr);
                --dataPtr;
            }
            break;
        default:
            printFmt("ERROR");
        }
    }



    command inline void CommonObjectPrinter.printIeee154AddrAny(
            whip6_ieee154_addr_t const * addr
    )
    {
        call CommonObjectPrinter.printIeee154AddrRaw(
                addr->mode,
                (uint8_t_xdata const *)(&(addr->vars))
        );
    }



    command void CommonObjectPrinter.printIeee154PanIdRaw(
            uint8_t_xdata const * dataPtr
    )
    {
        uint8_t   cnt;
        dataPtr += IEEE154_PAN_ID_BYTE_LENGTH - 1;
        for (cnt = IEEE154_PAN_ID_BYTE_LENGTH; cnt > 0; --cnt)
        {
            printFmt("%02x", (unsigned)*dataPtr);
            --dataPtr;
        }
    }



    command inline void CommonObjectPrinter.printIeee154PanId(
            whip6_ieee154_pan_id_t const * panId
    )
    {
        call CommonObjectPrinter.printIeee154PanIdRaw(
                &(panId->data[0])
        );
    }



    command void CommonObjectPrinter.printIeee154DFrameInfo(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        printFmt(
                "[IEEE154::fptr=%p;bptr=%p;len=%u;seqNo=%u;dstPanId=",
                framePtr, framePtr->bufferPtr,
                (unsigned)whip6_ieee154DFrameGetMacDataLen(framePtr),
                (unsigned)whip6_ieee154DFrameGetSeqNo(framePtr)
        );
        call CommonObjectPrinter.printIeee154PanIdRaw(
                &(framePtr->bufferPtr[whip6_ieee154DFrameGetOffsetDstPanId(framePtr)])
        );
        printFmt(";dstAddr=");
        call CommonObjectPrinter.printIeee154AddrRaw(
                whip6_ieee154DFrameGetModeDstAddr(framePtr),
                &(framePtr->bufferPtr[whip6_ieee154DFrameGetOffsetDstAddr(framePtr)])
        );
        if (whip6_ieee154DFrameIsInterPan(framePtr))
        {
            printFmt(";srcPanId=");
            call CommonObjectPrinter.printIeee154PanIdRaw(
                    &(framePtr->bufferPtr[whip6_ieee154DFrameGetOffsetSrcPanId(framePtr)])
            );
        }
        printFmt(";srcAddr=");
        call CommonObjectPrinter.printIeee154AddrRaw(
                whip6_ieee154DFrameGetModeSrcAddr(framePtr),
                &(framePtr->bufferPtr[whip6_ieee154DFrameGetOffsetSrcAddr(framePtr)])
        );
        printFmt(";payload=");
        call CommonObjectPrinter.printByteArray(
                whip6_ieee154DFrameUnsafeGetPayloadPtr(framePtr),
                whip6_ieee154DFrameGetPayloadLen(framePtr)
        );
        printFmt("]");
    }



    command void CommonObjectPrinter.printIpv6Addr(
            whip6_ipv6_addr_t const * addr
    )
    {
        ipv6_addr_human_readable_out_iter_t   iter;
        char                                  c;
        whip6_ipv6AddrHumanReadableIoInitializeWriting(&iter, addr);
        c = whip6_ipv6AddrHumanReadableIoContinueWriting(&iter);
        while (c != WHIP6_IPV6_ADDR_HUMAN_READABLE_OUT_EOS)
        {
            printFmt("%c", c);
            c = whip6_ipv6AddrHumanReadableIoContinueWriting(&iter);
        }
    }



    command void CommonObjectPrinter.printIpv6PacketBasicHeader(
            whip6_ipv6_basic_header_t const * hdr
    )
    {
        printFmt(
                "[IPv6HDR::ver=%u;tc=%u;fl=%lu;plen=%u;nhdr=%u;hlim=%u;saddr=",
                (unsigned)whip6_ipv6BasicHeaderGetVersion(hdr),
                (unsigned)whip6_ipv6BasicHeaderGetTrafficClass(hdr),
                (long unsigned)whip6_ipv6BasicHeaderGetFlowLabel(hdr),
                (unsigned)whip6_ipv6BasicHeaderGetPayloadLength(hdr),
                (unsigned)whip6_ipv6BasicHeaderGetNextHeader(hdr),
                (unsigned)whip6_ipv6BasicHeaderGetHopLimit(hdr)
        );
        call CommonObjectPrinter.printIpv6Addr(
                whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(hdr)
        );
        printFmt(";daddr=");
        call CommonObjectPrinter.printIpv6Addr(
                whip6_ipv6BasicHeaderGetDstAddrPtrForReading(hdr)
        );
        printFmt("]");
    }



    command void CommonObjectPrinter.printIpv6PacketBounds(
            whip6_ipv6_packet_t * pkt,
            uint8_t len
    )
    {
        whip6_iov_blist_t const *   iovElem;
        printFmt("[IPv6PKT::hdr=");
        call CommonObjectPrinter.printIpv6PacketBasicHeader(&pkt->header);
        printFmt(";pld={");
        iovElem = pkt->firstPayloadIov;
        if (iovElem != NULL)
        {
            if (whip6_ipv6BasicHeaderGetPayloadLength(&pkt->header) <= (ipv6_payload_length_t)len)
            {
                call CommonObjectPrinter.printIovFragmentContents(
                        iovElem,
                        0,
                        whip6_ipv6BasicHeaderGetPayloadLength(&pkt->header),
                        ' '
                );
            }
            else
            {
                uint8_t   numLeft;
                len = len >> 1;
                call CommonObjectPrinter.printIovFragmentContents(
                        iovElem,
                        0,
                        len,
                        ' '
                );
                printFmt(" ... ");
                iovElem = pkt->lastPayloadIov;
                numLeft = len;
                do
                {
                    if (iovElem->iov.len >= numLeft)
                    {
                        numLeft = iovElem->iov.len - numLeft;
                        call CommonObjectPrinter.printIovFragmentContents(
                                iovElem,
                                numLeft,
                                len,
                                ' '
                        );
                        break;
                    }
                    numLeft -= iovElem->iov.len;
                    iovElem = iovElem->prev;
                }
                while (iovElem != NULL);
            }
        }
        printFmt("}]");
    }



    command void CommonObjectPrinter.printEtx(
            etx_metric_host_t etx
    )
    {
        if (etx >= WHIP6_ETX_METRIC_INFINITE)
        {
            printFmt("INF");
        }
        else
        {
            printFmt(
                    "%u.%03u",
                    (unsigned)(etx / WHIP6_ETX_METRIC_ONE),
                    (unsigned)((etx % WHIP6_ETX_METRIC_ONE) * 1000 + (WHIP6_ETX_METRIC_ONE >> 1)) / WHIP6_ETX_METRIC_ONE
            );
        }
    }



    default command inline void CommonFormattedTextPrinter.printFormattedText(
            const char * fmt,
            va_list args
    )
    {
        vprintf(fmt, args);
    }
}
