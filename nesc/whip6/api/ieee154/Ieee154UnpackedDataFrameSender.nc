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
 * A sender of unpacked IEEE 802.15.4 data frames.
 *
 * @author Konrad Iwanicki
 */
interface Ieee154UnpackedDataFrameSender
{
    /**
     * Starts sending a frame.
     * @param framePtr A pointer to the frame to be sent.
     * @return SUCCESS if the frame has been successfully
     *   accepted for sending in which case the
     *   <tt>frameSendingFinished</tt> event is guaranteed to
     *   be signaled; EBUSY if the sender is busy sending another
     *   frame from the client (however, the implementer must
     *   guarantee that at least one frame can be sent
     *   per client; ESTATE if a fatal error occurred.
     */
    command error_t startSendingFrame(
            whip6_ieee154_dframe_info_t * framePtr
    );

    /**
     * Stops sending a frame.
     * @param framePtr A pointer to the frame sending which
     *   should be stopped.
     * @return SUCCESS if sending the frame has been stopped,
     *   (in which case no <tt>frameSendingFinished</tt> event
     *   will be signaled); EBUSY denoting that it is impossible
     *   to stop sending the frame at this point (in which case the
     *   <tt>frameSendingFinished</tt> event will be singled); EINVAL
     *   if the implementer is not aware of the frame.
     */
    command error_t stopSendingFrame(
            whip6_ieee154_dframe_info_t * framePtr
    );

    /**
     * Signaled when sending a frame has finished.
     * Note that this does not mean that the frame has
     * been sent successfully.
     * @param framePtr A pointer to the frame.
     * @param status The status of sending.
     */
    event void frameSendingFinished(
            whip6_ieee154_dframe_info_t * framePtr,
            error_t status
    );

}

