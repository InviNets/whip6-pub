/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "scif_framework.h"

interface SCIF {
    command error_t scifInit(); //const SCIF_DATA_T* pScifDriverSetup);
    command void scifUninit();

    event const SCIF_DATA_T* scifGetDriver();

    async event void scifAlertInt();
    async event void scifReadyInt();
}
