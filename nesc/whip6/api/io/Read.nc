/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 */
interface Read<val_t> {
  /**
   * Reads a value into the pointer. If the value is not available, returns FAIL;
   */
  async command error_t read(val_t *value);
}
