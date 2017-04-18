/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


interface RawBLEAdvertiser
{
  command error_t sendAdvertisement(uint8_t_xdata* payload, uint8_t length);
  event void sendingFinished(uint8_t_xdata* payload, uint8_t length, error_t status);
}
