/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 * 
 * Debug pins for RiMAC (stub).
 */

configuration PlatformRiMACDebugPinsProviderPub {
  provides interface IOPin as P16;
  provides interface IOPin as P17;
}
implementation {
  components new DummyIOPinPub(TRUE, FALSE) as P16Pin;
  components new DummyIOPinPub(TRUE, FALSE) as P17Pin;

  P16 = P16Pin;
  P17 = P17Pin;
}
