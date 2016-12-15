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


// Features generation for a Voice Activity Detector
interface AudioVADFeatures<feature_t> {
    /* Signaled to provide a new set of voice features. */
    event void ready(feature_t* features);

    /* Returns the number of features reported by ready(). */
    command uint8_t getNumberOfFeatures();
}
