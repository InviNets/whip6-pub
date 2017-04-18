/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#define _BSD_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <poll.h>
#include <assert.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <syslog.h>
#include <pcap/pcap.h>

#include "iomux.h"
#include "CoreRadioSniffer.h"

#define MAX_PACKET_SIZE (1500 + sizeof(sniffer_header_t))

// Sometimes valgrind is distributed with an older-version headers
// for libpcap, which do not have this link type defined.
#define LINKTYPE_IEEE802_15_4_NOFCS           230

static int iomux_fd;
static pcap_dumper_t* pcap_dumper;
static pcap_t* pcap;
static uint32_t last_timestamp_32khz;
static uint32_t timestamp_overflows;

static int wait_until_can_read_fd(int fd, int timeout_sec) {
    struct pollfd pfd;
    pfd.fd = fd;
    pfd.events = POLLIN;
    if (poll(&pfd, 1, timeout_sec * 1000) < 0)
        return -1;
    if (pfd.revents & (POLLERR|POLLHUP))
        return -1;
    if (pfd.revents & POLLIN)
        return 1;
    return 0;
}

static ssize_t pcap_write_ipv6_packet(sniffer_packet_t* packet, size_t len) {
    struct pcap_pkthdr pkthdr;
    uint64_t timestamp_32khz = packet->header.timestamp_32khz;
    uint64_t timestamp_usec;

    if (len < sizeof(sniffer_packet_t)) {
        fprintf(stderr, "invalid iomux packet: %ld bytes\n", len);
        errno = EINVAL;
        return -1;
    }

    if (timestamp_32khz < last_timestamp_32khz) {
        timestamp_overflows++;
    }
    last_timestamp_32khz = timestamp_32khz;

    timestamp_32khz += ((uint64_t)timestamp_overflows) << 32;
    timestamp_usec = timestamp_32khz * 1000000ULL / 32768;

    pkthdr.ts.tv_sec = timestamp_usec / 1000000;
    pkthdr.ts.tv_usec = timestamp_usec % 1000000;
    pkthdr.caplen = pkthdr.len = len - sizeof(sniffer_header_t);
    pcap_dump((u_char*)pcap_dumper, &pkthdr, packet->data);
    if (pcap_dump_flush(pcap_dumper) != 0) {
        syslog(LOG_ERR, "pcap_dump_flush: %s (terminating)",
                pcap_geterr(pcap));
        exit(1);
    }
    fflush(stdout);
    return len;
}

static void main_loop(void) {
    char buf[MAX_PACKET_SIZE];
    for (;;) {
        size_t size = MAX_PACKET_SIZE;
        uint8_t channel;
        switch (wait_until_can_read_fd(iomux_fd, 1)) {
            case -1:
                syslog(LOG_WARNING, "poll(iomux): %s", strerror(errno));
                return;
            case 0:
                break;
            case 1:
                if (iomux_read_packet(iomux_fd, buf, &size, &channel) < 0) {
                    syslog(LOG_WARNING, "iomux_read_packet: %s",
                            strerror(errno));
                    return;
                }
                if (channel != IOMUX_SNIFFER_CHANNEL)
                    break;
                if (pcap_write_ipv6_packet((sniffer_packet_t*)buf, size)
                        != size) {
                    syslog(LOG_WARNING, "pcap_write_ipv6_packet: %s",
                            strerror(errno));
                    return;
                }
                break;
            default:
                assert(0);
        }
        continue;
    }
}

static int open_iomux(const char* filename) {
    struct termios termios;
    iomux_fd = open(filename, O_RDWR);
    if (iomux_fd < 0)
        return iomux_fd;
    if (tcgetattr(iomux_fd, &termios) < 0) {
        syslog(LOG_WARNING, "tcgetattr: %s", strerror(errno));
    } else {
        cfmakeraw(&termios);
        cfsetspeed(&termios, B115200);
        if (tcsetattr(iomux_fd, TCSAFLUSH, &termios) < 0) {
            syslog(LOG_WARNING, "tcsetattr: %s", strerror(errno));
        }
    }
    return 0;
}

int main(int argc, char** argv) {
    const char* iomux_filename;
    int open_iomux_error_logged = 0;

    if (argc != 2) {
        fprintf(stderr, "usage: %s iomux_device\n", argv[0]);
        fprintf(stderr, "\n");
        fprintf(stderr, "The program captures packets received by a device\n");
        fprintf(stderr, "with CoreRadioSniffer appliction programmed and\n");
        fprintf(stderr, "dumps the data to stdout in libpcap format.\n");
        fprintf(stderr, "\n");
        fprintf(stderr, "To see the data live, do something like this:\n");
        fprintf(stderr, "\n");
        fprintf(stderr, " # %s /dev/ttyACM0 | wireshark -k -i -\n", argv[0]);
        fprintf(stderr, "\n");
        return 1;
    }
    iomux_filename = argv[1];

    pcap = pcap_open_dead(DLT_IEEE802_15_4_NOFCS, -1);
    pcap_dumper = pcap_dump_fopen(pcap, stdout);
    if (pcap_dumper == NULL) {
        pcap_perror(pcap, "pcap_dump_fopen");
        return 1;
    }

    openlog(PROJECT_NAME, LOG_PERROR, LOG_DAEMON);
    syslog(LOG_INFO, PROJECT_NAME " [%s] starting", iomux_filename);

    for (;;) {
        if (open_iomux(iomux_filename) == 0) {
            syslog(LOG_INFO, "opened IOMUX device");
            open_iomux_error_logged = 0;
            main_loop();
            close(iomux_fd);
        } else if (!open_iomux_error_logged) {
            open_iomux_error_logged = 1;
            syslog(LOG_WARNING, "open_iomux: %s", strerror(errno));
        }
        sleep(1);
    }
}
