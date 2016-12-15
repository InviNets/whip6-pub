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

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

#include "Assert.h"
#include "IOMuxPrv.h"

generic module BufferedReaderMuxPub(int max_readers) {
    provides interface Init;
    provides interface IOVRead as Out[uint8_t num];
    provides interface IOChannelConfig[uint8_t num];
    provides interface IOFlowControlHelper;
    uses interface BufferedRead as In;

    uses interface Led;
}
implementation {
    enum {
        NUM_READERS = max_readers,
    };

    struct reader_s;
    typedef struct reader_s _reader_t;
    typedef _reader_t _reader_t_xdata;
    typedef _reader_t_xdata reader_t;

    struct reader_s {
        uint8_t channel;
        whip6_iov_blist_t* iov;
        whip6_iov_blist_t* iov_iter;
        uint16_t max_size;
        uint16_t bytes_left;
    };

    reader_t readers[NUM_READERS];

    typedef struct iomux_header _iomux_header_t;
    typedef _iomux_header_t _iomux_header_t_xdata;
    typedef _iomux_header_t_xdata iomux_header_t;

    typedef enum {
        MAGIC,
        HEADER,
        DATA
    } state_t;

    state_t state = MAGIC;

    uint32_t good_magic = IOMUX_MAGIC;
    uint8_t magic_byte;
    uint8_t magic_byte_num = 0;

    iomux_header_t header;
    reader_t* active_reader = NULL;

    reader_t* channel_to_reader(uint8_t channel) {
        uint8_t i;
        for (i = 0; i < NUM_READERS; i++) {
            if (readers[i].channel == channel) {
                return readers + i;
            }
        }
        return NULL;
    }

    void startRead(void) {
        switch (state) {
            case MAGIC:
                CHECK(call In.startRead(&magic_byte, 1) == SUCCESS);
                break;
            case HEADER:
                CHECK(call In.startRead((uint8_t_xdata*)&header, sizeof(header)) == SUCCESS);
                break;
            case DATA:
            {
                uint16_t len = active_reader->bytes_left;
                whip6_iov_blist_t* iov = active_reader->iov_iter;
                if (len > iov->iov.len)
                    len = iov->iov.len;
                CHECK(call In.startRead(iov->iov.ptr, len) == SUCCESS);
                break;
            }
            default:
                CHECK(FALSE);
        }
    }

    event void In.readDone(uint8_t_xdata* buffer, uint16_t capacity) {
        switch (state) {
            case MAGIC:
            {
                uint8_t good_byte =
                        ((uint8_t_xdata*)&good_magic)[magic_byte_num];
                if (magic_byte != good_byte) {
                    good_byte = ((uint8_t_xdata*)&good_magic)[0];
                    if (magic_byte == good_byte) {
                        magic_byte_num = 1;
                    } else {
                        magic_byte_num = 0;
                    }
                } else if ((++magic_byte_num) == 4) {
                    magic_byte_num = 0;
                    state = HEADER;
                }
                break;
            }

            case HEADER:
            {
                uint8_t channel = header.channel;
                uint16_t size = iomux_ntohs(header.size);
                active_reader = channel_to_reader(channel);
                if (active_reader == NULL || active_reader->max_size == 0 ||
                        active_reader->max_size < size) {
                    active_reader = NULL;
                    state = MAGIC;
                } else {
                    whip6_iov_blist_t* iov =
                            signal Out.requestIOV[active_reader - readers](
                                size);
                    if (iov == NULL) {
                        active_reader = NULL;
                        state = MAGIC;
                        break;
                    }
                    active_reader->iov_iter = active_reader->iov = iov;
                    active_reader->bytes_left = size;
                    state = DATA;
                }
                break;
            }

            case DATA:
            {
                uint16_t size = iomux_ntohs(header.size);
                CHECK(capacity <= active_reader->iov_iter->iov.len);
                CHECK(capacity <= active_reader->bytes_left);
                CHECK(capacity == active_reader->iov_iter->iov.len ||
                      capacity == active_reader->bytes_left);
                active_reader->bytes_left -= capacity;
                if (active_reader->bytes_left == 0) {
                    whip6_iov_blist_t* iov = active_reader->iov;
                    active_reader->iov = NULL;
                    active_reader->max_size = 0;
                    signal IOFlowControlHelper.channelBusy(active_reader - readers);
                    signal Out.readDone[active_reader - readers](iov, size);
                    active_reader = NULL;
                    state = MAGIC;
                } else {
                    active_reader->iov_iter = active_reader->iov_iter->next;
                    CHECK(active_reader->iov_iter != NULL);
                }
                break;
            }

            default:
                CHECK(FALSE);
                active_reader = NULL;
                state = MAGIC;
        }
        startRead();
    }

    event void In.bytesLost(uint16_t count) {
        call In.flush();
        if (active_reader != NULL && active_reader->iov != NULL)
        {
            whip6_iov_blist_t * iov = active_reader->iov;
            active_reader->iov = NULL;
            active_reader->max_size = 0;
            signal Out.readDone[active_reader - readers](iov, 0);
        }
        active_reader = NULL;
        state = MAGIC;
        startRead();
    }

    default event void Out.readDone[uint8_t num](whip6_iov_blist_t* iov,
            uint16_t size) { }

    default event whip6_iov_blist_t* Out.requestIOV[uint8_t num](
            uint16_t size) { return NULL; }

    command error_t Init.init(void) {
        uint8_t i;
        for (i = 0; i < NUM_READERS; ++i)
        {
            readers[i].iov = NULL;
        }
        active_reader = NULL;
        state = MAGIC;
        startRead();
        call In.setActive(TRUE);
        return SUCCESS;
    }

    command void IOChannelConfig.setChannel[uint8_t num](
            uint8_t channel) {
        readers[num].channel = channel;
    }

    command error_t Out.startRead[uint8_t num](uint16_t max_size) {
        reader_t* reader = readers + num;
        if (max_size == 0)
            return EINVAL;
        if (reader->max_size != 0)
            return EBUSY;
        reader->max_size = max_size;
        signal IOFlowControlHelper.channelReady(num);
        return SUCCESS;
    }

    command inline uint8_t IOFlowControlHelper.maxReadyChannels() {
        return NUM_READERS;
    }

    command uint8_t IOFlowControlHelper.getReadyChannels(uint8_t_xdata* buf) {
        uint8_t* out = buf;
        reader_t* end = readers + NUM_READERS;
        reader_t* reader;
        for (reader = readers; reader != end; reader++) {
            if (reader->max_size != 0) {
                *(out++) = reader->channel;
            }
        }
        return out - buf;
    }

    default event inline void IOFlowControlHelper.channelBusy(uint8_t num) { }
    default event inline void IOFlowControlHelper.channelReady(uint8_t num) { }
}
