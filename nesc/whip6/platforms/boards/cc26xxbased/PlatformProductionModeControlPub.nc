/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2018 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */
configuration PlatformProductionModeControlPub {
    provides interface ProductionModeControl;
}
implementation {
    components HalProductionModeControlPub;
    ProductionModeControl = HalProductionModeControlPub;
}
