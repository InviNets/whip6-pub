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


#include <PlatformFrame.h>

interface RawFrameReceiver
{
  /**
   * Enables receiving a frame. The passed framePtr will be used to store
   * the received data. Its ownership is retained by the radio driver until
   * receivingFinished is signaled or cancelReceiving returns SUCCESS. It is
   * not possible to queue more than one frame_t buffer.
   *
   * @returns SUCCESS if the receive buffer was successfully set to the passed
   *   framePtr, EBUSY if another buffer is already set.
   */
  command error_t startReceiving(platform_frame_t * framePtr);

  /**
   * Cancels receiving and returns the ownership of framePtr to the caller.
   *
   * @returns SUCCESS if the passed framePtr was used for receiving (and now is
   *   no more), EINVAL if framePtr is not the current receive buffer.
   */
  command error_t cancelReceiving(platform_frame_t * framePtr);

  /**
   * Signals a received frame. Transfers back the ownership of framePtr to the
   * event handler. It's not called if receiving was cancelled.
   *
   * @param status  SUCCESS, I say. Anything else is a serious hardware
   *                problem.
   */
  event void receivingFinished(platform_frame_t * framePtr,
      error_t status);

  /**
   * Checks if a reception is active. This should return TRUE between
   * startReceiving and cancelReceiving or receivingFinished.
   */
  command bool isReceiving();
}
