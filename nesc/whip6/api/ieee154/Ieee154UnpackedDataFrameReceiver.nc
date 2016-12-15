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

#include "Ieee154.h"


/**
 * A receiver of unpacked IEEE 802.15.4 data frames.
 *
 * @author Konrad Iwanicki
 */
interface Ieee154UnpackedDataFrameReceiver
{
    /**
     * Starts receiving an unpacked IEEE 802.15.4 data frame.
     * @param framePtr A pointer to a buffer into which
     *   the frame will be received.
     * @return SUCCESS if receiving has started successfully,
     *   in which case the <tt>frameReceivingFinished</tt> event
     *   will later be signaled and the ownership of the
     *   buffer is taken over by the implementing module;
     *   EALREADY if the implementing module is already receiving
     *   a frame to another buffer; EINVAL if the given buffer
     *   is incorrect; ESTATE if receiving cannot
     *   be started for some other reason.
     */
    command error_t startReceivingFrame(
        whip6_ieee154_dframe_info_t * framePtr
    );

    /**
     * Cancels receiving an unpacked IEEE 802.15.4 data frame.
     * @param framePtr A pointer to a buffer into which the
     *   receiving is taking place.
     * @return SUCCESS if canceling has been successful, in
     *   which case no subsequent <tt>frameReceivingFinished</tt>
     *   event will be signaled; EINVAL if the given buffer is
     *   not used for receiving any frame; EBUSY if frame
     *   receiving cannot be stopped at the moment.
     */
    command error_t stopReceivingFrame(
        whip6_ieee154_dframe_info_t * framePtr
    );

    /**
     * Signaled when an IEEE 802.15.4 receiving a data
     * frame has been finished.
     * @param framePtr A pointer to the buffer provided in
     *   the <tt>startReceivingFrame</tt> command that
     *   now contains the received frame. The ownership
     *   of the buffer is transferred to the even handler.
     *   The frame in the buffer is valid only if the
     *   receive status is SUCCESS.
     * @param status The status of receiving the frame.
     */
    event void frameReceivingFinished(
        whip6_ieee154_dframe_info_t * framePtr,
        error_t status
    );

}

