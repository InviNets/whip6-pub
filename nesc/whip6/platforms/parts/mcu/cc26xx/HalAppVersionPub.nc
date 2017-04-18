/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

module HalAppVersionPub {
    provides interface AppVersion;
}

implementation {
    extern volatile const char _appversion[] @C();

    command const char* AppVersion.getAppVersion() {
        return (const char*)_appversion;
    }
}
