/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <stdio.h>

//#define dbgprintf printf
#define dbgprintf(...)

module CoreRadioSnifferPrv {
    uses interface Boot;
    uses interface Init as RadioInit;
    uses interface Init as AllocatorInit;
    uses interface RawFrameReceiver;
    uses interface RawFrame;
    uses interface RawFrameTimestamp<T32khz>;
    uses interface IOVWrite;

    uses interface Led;
    uses interface Timer<TMilli, uint32_t> as LedTimer;

    uses interface Queue<platform_frame_t*, uint8_t>;
    uses interface ObjectAllocator<platform_frame_t> as Allocator;
}
implementation {
    bool isReceiving = FALSE;
    bool isSending = FALSE;

    whip6_iov_blist_t iov1;
    whip6_iov_blist_t iov2;
    sniffer_header_t header;

    void blink() {
        call Led.on();
        call LedTimer.startWithTimeoutFromNow(20);
    }

    event void LedTimer.fired() {
        call Led.off();
    }

    void tryToRXTX() {
        if (!isReceiving) {
            platform_frame_t* frame = call Allocator.allocate();
            if (frame != NULL) {
                error_t result = call RawFrameReceiver.startReceiving(frame);
                if (result != SUCCESS) {
                    printf("startReceiving failed, err=%d\r\n", result);
                    call Allocator.free(frame);
                } else {
                    dbgprintf("startReceiving succeeded\r\n");
                    isReceiving = TRUE;
                }
            }
        }

        if (!isSending && !call Queue.isEmpty()) {
            platform_frame_t* frame = call Queue.peekFirst();
            uint16_t len;
            error_t result;

            header.timestamp_32khz = call RawFrameTimestamp.getTimestamp(frame);
            iov2.iov.ptr = call RawFrame.getData(frame);
            len = iov2.iov.len = call RawFrame.getLength(frame);
            len += sizeof(sniffer_header_t);

            result = call IOVWrite.startWrite(&iov1, len);
            if (result != SUCCESS) {
                printf("startWrite failed, err=%d\r\n", result);
            } else {
                dbgprintf("startWrite succeeded\r\n");
                isSending = TRUE;
            }
        }
    }

    event void RawFrameReceiver.receivingFinished(platform_frame_t* frame,
            error_t error) {
        isReceiving = FALSE;
        if (error) {
            printf("RawFrameReceiver.receivingFinished, receiving failed, "
                   "err=%d\r\n", error);
        } else {
            dbgprintf("RawFrameReceiver.receivingFinished OK\r\n");
            blink();
            call Queue.enqueueLast(frame);
        }
        tryToRXTX();
    }

    event void IOVWrite.writeDone(error_t result, whip6_iov_blist_t* iov,
            uint16_t size) {
        platform_frame_t* frame = call Queue.peekFirst();
        isSending = FALSE;
        call Queue.dequeueFirst();
        call Allocator.free(frame);

        if (result != SUCCESS) {
            printf("writeDone, sending failed, err=%d\r\n", result);
        } else {
            dbgprintf("writeDone OK\r\n");
        }

        tryToRXTX();
    }

    event void Boot.booted(){
        printf("CoreRadioSniffer booting...\r\n");

        iov1.iov.ptr = (uint8_t_xdata*)&header;
        iov1.iov.len = sizeof(sniffer_header_t);
        iov1.next = &iov2;
        iov2.prev = &iov1;

        call RadioInit.init();
        call AllocatorInit.init();
        call Led.off();
        dbgprintf("init done\r\n");
        tryToRXTX();
    }
}

#undef dbgprintf
