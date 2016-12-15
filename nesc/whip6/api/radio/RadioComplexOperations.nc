/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */


enum {
    RADIO_COMPLEX_OPERATION_SCHEDULED_TX,
} radio_complex_operation_type_t;

typedef struct {
    uint32_t startTime;
    platform_frame_t* frame;
} radio_scheduled_tx_op_t;

interface RadioComplexOperations
{
  /* NOTES:
   *
   * 1. It is allowed to have only one complex operation in progress
   *    at a given time. Staring a complex operation when another one is
   *    active returns EBUSY.
   *
   * 2. It is not allowed to mix complex operations with the basic ones.
   *    Starting a complex operation when a basic one is active returns
   *    EBUSY. Similarly, starting a basic operation when a complex one
   *    is active returns EBUSY as well.
   *
   * FOR SCHEDULED OPERATIONS:
   *
   * 1. All the timings are according to PlatformRadioTimerPub, which may be
   *    different than PlatformTimer32khzPub.
   *
   * 2. There is a minimum delay from the current clock value which is
   *    needed by the driver to guarantee enough time to setup the
   *    transmission. This value can be obtained using the
   *    RadioSchedulingInfo interface. Passing a smaller delay results
   *    in EINVAL.
   */

  /**
   * Starts the complex operation.
   *
   * See the description of a particular operation for the details on
   * the actual action performed.
   *
   * Note that usually the radio driver retains the ownership of the
   * additional data structure (the data argument), so it must not
   * reside on the caller's stack.
   */
  command error_t startComplexOp(radio_complex_operation_type_t type,
          void_xdata* data);

  /**
   * Stops the complex operation.
   *
   * Note that for simplicity, stopping complex operations may be implemented
   * only for these operations, which have no predefined duration.
   *
   * For others, startComplexOp() may return ENOTSUPP.
   */
  command error_t stopComplexOp();

  /**
   * Signals a completed or failed operation.
   */
  event void complexOpFinished(error_t status);
}
