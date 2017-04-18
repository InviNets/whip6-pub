/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <6lowpan/uc6LoWPANHeaderManipulation.h>
#include <6lowpan/uc6LoWPANNalpExtensionSoftwareAcknowledgments.h>
#include <ieee154/ucIeee154FrameManipulation.h>



typedef struct lowpan_nalp_ext_software_ack_payload_s
{
    uint8_t   lowpanNalpCode;
    uint8_t   softwareAckNalpCode;
    uint8_t   frameSeqNo;
} MICROC_NETWORK_STRUCT lowpan_nalp_ext_software_ack_payload_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_nalp_ext_software_ack_payload_t)




WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_lowpanNalpExtSoftwareAcknowledgmentIsAckFrame(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * inFrame,
        ieee154_frame_seq_no_t * ackSeqNoBufPtr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    if (whip6_ieee154DFrameGetPayloadLen(inFrame) == sizeof(lowpan_nalp_ext_software_ack_payload_t))
    {
        lowpan_nalp_ext_software_ack_payload_t MCS51_STORED_IN_RAM const *   saPayloadPtr;
        saPayloadPtr =
                (lowpan_nalp_ext_software_ack_payload_t MCS51_STORED_IN_RAM const *)(
                        whip6_ieee154DFrameUnsafeGetPayloadPtr(inFrame)
                );
        if ((saPayloadPtr->lowpanNalpCode & LOWPAN_DISPATCH_MASK_NALP) == LOWPAN_DISPATCH_PATTERN_NALP &&
                saPayloadPtr->softwareAckNalpCode == WHIP6_LOWPAN_NALP_EXTENSION_ID_SOFTWARE_ACK)
        {
            *ackSeqNoBufPtr = (ieee154_frame_seq_no_t)(saPayloadPtr->frameSeqNo);
            return 1;
        }
    }
    return 0;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_lowpanNalpExtSoftwareAcknowledgmentCreateAckFrame(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * ackFrame,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * inFrame
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_nalp_ext_software_ack_payload_t MCS51_STORED_IN_RAM *   saPayloadPtr;

    if (whip6_ieee154DFrameInfoCheckIfDestinationIsBroadcast(inFrame))
    {
        return 0;
    }
    if (whip6_ieee154DFrameInfoReinitializeFrameInOppositeDirection(ackFrame, inFrame) != WHIP6_NO_ERROR)
    {
        return 0;
    }
    saPayloadPtr =
            (lowpan_nalp_ext_software_ack_payload_t MCS51_STORED_IN_RAM *)(
                    whip6_ieee154DFrameGetPayloadPtr(
                            ackFrame,
                            sizeof(lowpan_nalp_ext_software_ack_payload_t)
                    )
            );
    if (saPayloadPtr == NULL)
    {
        return 0;
    }
    saPayloadPtr->lowpanNalpCode = LOWPAN_DISPATCH_PATTERN_NALP;
    saPayloadPtr->softwareAckNalpCode = WHIP6_LOWPAN_NALP_EXTENSION_ID_SOFTWARE_ACK;
    saPayloadPtr->frameSeqNo = whip6_ieee154DFrameGetSeqNo(inFrame);
    whip6_ieee154DFrameSetPayloadLen(ackFrame, sizeof(lowpan_nalp_ext_software_ack_payload_t));
    return 1;
}
