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

#include "iomux.h"
#include <sys/uio.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>

static const char magic[4] = "\xef\xbe\xeb\xfe";

typedef struct {
    uint8_t channel;
    uint16_t len;
} __attribute__((packed)) iomux_header_t;

int iomux_write_packet(int fd, uint8_t channel, const char* buf,
        uint16_t len) {
    iomux_header_t header;
    struct iovec iov[3];
    header.channel = channel;
    header.len = htons(len);
    iov[0].iov_base = (char*)magic;
    iov[0].iov_len = sizeof(magic);
    iov[1].iov_base = &header;
    iov[1].iov_len = sizeof(header);
    iov[2].iov_base = (char*)buf;
    iov[2].iov_len = len;
    return writev(fd, iov, 3);
}

static int iomux_read_magic(int fd) {
    int bytes_ok = 0;
    for (;;) {
        char c;
        ssize_t n = read(fd, &c, 1);
        if (n == 0) {
            errno = EPIPE;
        }
        if (n <= 0) {
            return -1;
        }
        if (magic[bytes_ok++] != c)
            bytes_ok = 0;
        if (bytes_ok == sizeof(magic))
            return 0;
    }
}

static int read_buf(int fd, void* buf, size_t len) {
    while (len > 0) {
        ssize_t n = read(fd, buf, len);
        if (n <= 0)
            return -1;
        buf += n;
        len -= n;
    }
    return 0;
}

int iomux_read_packet(int fd, void* buf, size_t* len, uint8_t* channel) {
    iomux_header_t header;
    for (;;) {
        if (iomux_read_magic(fd) < 0)
            return -1;
        if (read_buf(fd, &header, sizeof(header)) < 0)
            return -1;
        if (ntohs(header.len) > *len)
            continue;
        *len = ntohs(header.len);
        *channel = header.channel;
        if (read_buf(fd, buf, *len) < 0)
            return -1;
        return 0;
    }
}
