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

interface RFIDScanner {
    command error_t startOneShotScan();
    event void cardDetected(uint8_t_xdata* uid, uint8_t len);
    event void scanFinished(error_t status);
}
