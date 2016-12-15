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
 * @author Michal Marschall <m.marschall@invinets.com>
 * 
 * A component which provides a way to read the software version of the
 * device by sending a packet with a single character '?'. The reply will
 * contain the software version as defined by WHIP6_SOFTWARE_VERSION or
 * YYYYMMDD-dev if not defined.
 */

#include <string.h>
#include "whip6_build.h"

generic module IOMuxVersionReporterPub() {
    provides interface Init @exactlyonce();
    uses interface PacketWrite @exactlyonce();
    uses interface PacketRead @exactlyonce();
}

implementation {
    char softwareVersion[64];

    char buf;

    command error_t Init.init() {
#ifdef WHIP6_SOFTWARE_VERSION
        strncpy(softwareVersion, WHIP6_SOFTWARE_VERSION, sizeof(softwareVersion));
        softwareVersion[sizeof(softwareVersion) - 1] = '\0'; /* in case the version string is too long */
#else
        if(BUILD_DATE_AVAILABLE && BUILD_TIME_AVAILABLE) {
            sprintf(softwareVersion, "dev-%04d%02d%02d%02d%02d%02d", BUILD_DATE_YEAR, BUILD_DATE_MONTH, BUILD_DATE_DAY, BUILD_TIME_HOUR,
                    BUILD_TIME_MINUTE, BUILD_TIME_SECOND);
        } else {
            strcpy(softwareVersion, "unknown-dev");
        }
#endif

        return call PacketRead.startRead((uint8_t_xdata *)&buf, 1);
    }

    event void PacketRead.readDone(uint8_t_xdata *buffer, uint16_t size) {
        if(size == 1 && buf == '?') {
            call PacketWrite.startWrite((uint8_t_xdata*)softwareVersion, sizeof(softwareVersion));
        }
        call PacketRead.startRead((uint8_t_xdata *)&buf, 1);
    }

    event void PacketWrite.writeDone(error_t result, uint8_t_xdata *buffer, uint16_t size) {}
}
