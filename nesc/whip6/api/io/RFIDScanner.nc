/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

interface RFIDScanner {
    command error_t startOneShotScan();
    event void cardDetected(uint8_t_xdata* uid, uint8_t len);
    event void scanFinished(error_t status);
}
