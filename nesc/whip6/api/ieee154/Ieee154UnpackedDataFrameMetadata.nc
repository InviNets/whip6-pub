/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "Ieee154.h"



/**
 * Metadata associated with each
 * IEEE 802.15.4 data frame.
 *
 * @author Konrad Iwanicki
 */
interface Ieee154UnpackedDataFrameMetadata
{

    /**
     * Checks if during the reception of a given
     * frame, the quality of physical radio
     * signal was high. For a frame that was not
     * received, the result is undefined. If a
     * radio chip does not support signal quality
     * inference, FALSE should be returned.
     * @param framePtr A pointer to the frame.
     * @return TRUE if the signal quality was high
     *   or FALSE otherwise.
     */
    command bool wasPhysicalSignalQualityHighUponRx(
        whip6_ieee154_dframe_info_t * framePtr
    );
    
    /**
     * Returns the strength of the physical signal
     * for which a given frame was received.
     * For a frame that was not received, the result
     * is undefined. If a radio chip does not support
     * signal quality inference, -127 should be returned.
     * @param framePtr A pointer to the frame.
     * @return The received signal strength in dBm.
     */
    command int8_t getReceivedPhysicalSignalStrengthUponRx(
        whip6_ieee154_dframe_info_t * framePtr
    );
    
    /**
     * Returns the indicator of a physical link over which
     * a given frame was received.
     * For a frame that was not received, the result
     * is undefined. If a radio chip does not support
     * signal quality inference, 0 should be returned.
     * @param framePtr A pointer to the frame.
     * @return The link quality indicator. 0 denotes the
     *   minimal value. 255 denotes the maximal value.
     */
    command uint8_t getPhysicalLinkQualityIndicatorUponRx(
        whip6_ieee154_dframe_info_t * framePtr
    );
}
