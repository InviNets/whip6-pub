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

generic module BufferedWriterMuxPub(int max_writers) {
    provides interface Init;
    provides interface IOVWrite as In[uint8_t num];
    provides interface IOChannelConfig[uint8_t num];
    uses interface BufferedWrite as Out;
}
implementation {
    enum {
        NUM_WRITERS = max_writers,
    };

    struct writer_s;
    typedef struct writer_s _writer_t;
    typedef _writer_t _writer_t_xdata;
    typedef _writer_t_xdata writer_t;

    struct writer_s {
        uint8_t channel;
        whip6_iov_blist_t* iov;
        whip6_iov_blist_t* iov_iter;
        uint16_t size;
        uint16_t bytes_left;
    };

    writer_t writers[NUM_WRITERS];

    typedef struct iomux_header _iomux_header_t;
    typedef _iomux_header_t _iomux_header_t_xdata;
    typedef _iomux_header_t_xdata iomux_header_t;

    typedef enum {
        IDLE,
        MAGIC,
        HEADER,
        DATA
    } state_t;

    state_t state = IDLE;

    uint32_t magic_buf = IOMUX_MAGIC;

    iomux_header_t header;
    writer_t* active_writer;

    writer_t* channel_to_writer(uint8_t channel) {
        uint8_t i;
        for (i = 0; i < NUM_WRITERS; i++) {
            if (writers[i].channel == channel) {
                return writers + i;
            }
        }
        return NULL;
    }

    void tryToWrite(void) {
        uint8_t i;
        if (state != IDLE)
            return;
        for (i = 0; i < NUM_WRITERS; i++) {
            writer_t* writer = writers + i;
            if (writer->iov != NULL) {
                state = MAGIC;
                active_writer = writer;
                CHECK(call Out.startWrite((uint8_t_xdata*)&magic_buf,
                        sizeof(magic_buf)) == SUCCESS);
                return;
            }
        }
    }

    void startWritingIov(void) {
        uint16_t len = active_writer->bytes_left;
        whip6_iov_blist_t* iov = active_writer->iov_iter;
        if (len > iov->iov.len)
            len = iov->iov.len;
        CHECK(call Out.startWrite(iov->iov.ptr, len) == SUCCESS);
    }

    event void Out.writeDone(error_t result, uint8_t_xdata* buffer,
            uint16_t capacity) {
        if (result != SUCCESS) {
            whip6_iov_blist_t* iov = active_writer->iov;
            active_writer->iov = NULL;
            state = IDLE;
            signal In.writeDone[active_writer - writers](result, iov,
                    active_writer->size);
            goto out;
        }
        switch (state) {
            case IDLE:
                CHECK(FALSE);
                break;
            case MAGIC:
                header.channel = active_writer->channel;
                header.size = iomux_htons(active_writer->size);
                state = HEADER;
                CHECK(call Out.startWrite((uint8_t_xdata*)&header,
                        sizeof(header)) == SUCCESS);
                break;
            case HEADER:
                state = DATA;
                startWritingIov();
                break;
            case DATA:
                active_writer->bytes_left -= capacity;
                if (active_writer->bytes_left == 0) {
                    whip6_iov_blist_t* iov = active_writer->iov;
                    active_writer->iov = NULL;
                    state = IDLE;
                    signal In.writeDone[active_writer - writers](SUCCESS, iov,
                            active_writer->size);
                } else {
                    active_writer->iov_iter = active_writer->iov_iter->next;
                    CHECK(active_writer->iov_iter != NULL);
                    startWritingIov();
                }
                break;
            default:
                CHECK(FALSE);
                state = IDLE;
        }
    out:
        tryToWrite();
    }

    default event void In.writeDone[uint8_t num](error_t result,
            whip6_iov_blist_t* iov, uint16_t size) { }

    command error_t Init.init(void) {
        return SUCCESS;
    }

    command void IOChannelConfig.setChannel[uint8_t num](
            uint8_t channel) {
        writers[num].channel = channel;
    }

    command error_t In.startWrite[uint8_t num](whip6_iov_blist_t* iov,
            uint16_t size) {
        writer_t* writer = writers + num;
        if (iov == NULL || size == 0)
            return EINVAL;
        if (writer->iov != NULL)
            return EBUSY;
        writer->iov = writer->iov_iter = iov;
        writer->size = writer->bytes_left = size;
        tryToWrite();
        return SUCCESS;
    }
}
