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

#include <stdbool.h>

/* Provisioning is a process of configuring the device for the first time,
 * joining it to the system etc.
 *
 * It's a rare process, which is done after the device changes its owner,
 * installation place, configuration etc. Some devices need provisioning
 * after each reboot.
 *
 * Nevertheless, one can not assume that the device will be provisioned
 * once per reboot.
 */
interface Provisioning {
    command bool isDeviceProvisioned();

    /* Determines whether the provisioning is in progress, or the device is
     * ready to accept an external provisioning interaction.
     *
     * It is ok to return provisioning in progress when device is already
     * provisioned. This means that when the interaction is completed,
     * the configuation would change.
     *
     * On the other hand, it is perfectly possible to clear the configuration
     * and move to unprovisioned state as soon as startProvisioning() is
     * called. This is implementation-dependent.
     */
    command bool isProvisioningInProgress();

    command error_t startProvisioning();
    event void provisioningComplete(error_t status);
}
