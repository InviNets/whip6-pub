/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include "GlobalPutchar.h"

module DummyPutcharProviderPub {
}
implementation {
	void whip6_putchar(char byte) __attribute__ ((spontaneous)) @C() {
	}
}
