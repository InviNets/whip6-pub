/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <PlatformFrame.h>

interface RawFrameSender
{
  /**
   * Begins transmission of a frame. The ownership of framePtr is retained
   * by the radio driver until sendingFinished is signaled or cancelSending
   * returns SUCCESS. Frames are not queued.
   *
   * @returns SUCCESS if the frame was successfully queued, EBUSY if another
   *   transmission is already in progress.
   */
  command error_t startSending(platform_frame_t * framePtr);

  /**
   * Cancels a pending transmission. If SUCCESS is returned, then sendingFinished
   * will not be called.

   * @returns SUCCESS if the transmission was cancelled, EINVAL if framePtr is
   *   not the currently transmitted frame.
   */
  command error_t cancelSending(platform_frame_t * framePtr);

  /**
   * Signals a completed or failed transmission. Transfers back the ownership of
   * framePtr to the event handler. It's not called for cancelled transmissions.
   */
  event void sendingFinished(platform_frame_t * framePtr, error_t status);

  /**
   * Checks if a transmission is active. This should return TRUE between
   * startSending and cancelSending or sendingFinished.
   */
  command bool isSending();
}
