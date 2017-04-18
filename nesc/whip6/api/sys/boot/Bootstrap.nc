/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

 
/** The basic synchronous initialization interface.
 *
 * @author Przemyslaw Horban
 * @date   July 10 2012
 */  
interface Bootstrap {
  /**
   * Called in the first phase of system initialization. Neither hardware
   * nor software is configured at this point. The system scheduler is
   * not available either, so tasks can not be used during bootstrap.
   * 
   * This is a good moment to disable watchdog.
   */
  command void bootstrap();
}
