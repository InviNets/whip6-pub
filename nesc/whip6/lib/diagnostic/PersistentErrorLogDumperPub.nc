/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


configuration PersistentErrorLogDumperPub {
}
implementation {
    components PersistentErrorLogDumperPrv as Prv;

    components PlatformPersistentErrorLogPub as ErrorLog;
    Prv.ErrorLog -> ErrorLog;

    components BoardStartupPub;
    BoardStartupPub.InitSequence[6] -> Prv.Init;
}
