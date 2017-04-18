/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 * 
 * This is a basic read interface, extended with units tag, which helps
 * determine what units is the value expressed at.
 */

#include "DimensionTypes.h"
#include "GlobalError.h"

interface DimensionalRead<units_tag, val_t> {
  /**
   * Initiates a read of the value.
   * 
   * @return SUCCESS if a readDone() event will eventually come back.
   */
  command error_t read();

  /**
   * Signals the completion of the read().
   *
   * @param result SUCCESS if the read() was successful
   * @param val the value that has been read
   */
  event void readDone(error_t result, val_t val);
}
