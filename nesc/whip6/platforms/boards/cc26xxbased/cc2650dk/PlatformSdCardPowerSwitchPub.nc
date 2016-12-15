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

/**
 * @author Szymon Acedanski
 *
 * Component for switching on/off the power to the SD card. Please note that
 * after each power off, the card must be re-initialized. This should happen
 * automatically at the next access, if using the provided LogStorage
 * implementation.
 *
 * NOTE: The caller must ensure enough time for the SD card to settle before
 *       use.
 */

configuration PlatformSdCardPowerSwitchPub {
    provides interface OnOffSwitch;
}

implementation {
    components HalSdCardWirePub as SdCard;
    OnOffSwitch = SdCard.PowerSwitch;
}
