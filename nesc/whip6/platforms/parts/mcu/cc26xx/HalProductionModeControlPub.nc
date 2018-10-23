/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <stdint.h>
#include <inc/hw_types.h>
#include <inc/hw_ccfg.h>
#include <inc/hw_ccfg_simple_struct.h>
#include <driverlib/vims.h>
#include <driverlib/flash.h>

// defined in native/startup/ccfg.c
extern const ccfg_t __ccfg;

#if PLATFORM_DISABLE_PRODUCTION_MODE_SUPPORT
// To disable production mode, we need some scratch space
// to save the final flash sector. We use flog for this.
#include "native/flog/flog.h"
// ... and the original CCFG values.
#include "native/startup/ccfg.h"
#endif

module HalProductionModeControlPub
{
    provides interface ProductionModeControl;
    uses interface BusyWait<TMicro, uint16_t>;
}
implementation {
    /* The recommended way to configure a device for final production is as
     * follows:
     *
     * 1. The BL_CONFIG:BOOTLOADER_ENABLE register and the BL_CONFIG:BL_ENABLE
     *    register must be set to 0x00 to disallow access to Flash contents
     *    through the bootloader interface.
     *
     * 2. The CCFG_TI_OPTIONS:TI_FA_ENABLE register must be set to 0x00 to
     *    disallow failure analysis access by TI.
     *
     * 3. The CCFG_TAP_DAP_0:PRCM_TAP_ENABLE register, the
     *    CCFG_TAP_DAP_0:TEST_TAP_ENABLE register, and the
     *    CCFG_TAP_DAP_0:CPU_DAP_ENABLE register must be set to set to 0x00 to
     *    disallow access to these module through JTAG.
     *
     * 4. The CCFG_TAP_DAP_1 register must be set to 0xFF00 0000 to disallow
     *    access to these modules through JTAG.
     *
     * 5. The IMAGE_VALID_CONF:IMAGE_VALID register must be set to 0x0000 0000
     *    to pass control to the programmed image in Flash at boot.
     *
     * 6. Optionally, the ERASE_CONF:CHIP_ERASE_DIS_N register can be set to 0x0
     *    to disallow erasing of the Flash.
     *
     * 7. Use the CCFG_PROT_n registers to write and erase protect the sectors
     *    of Flash that are not designed to be updated in-system by the final
     *    product.
     *
     * -- CC13x0, CC26x0 SimpleLinkTM Wireless MCU Technical Reference Manual,
     *    section 9.1
     */

    typedef struct {
        const uint32_t* ptr;
        uint32_t value;
    } mask_t;

    static const mask_t PROD_MODE_MASKS[] = {
        { &__ccfg.CCFG_BL_CONFIG,       0x00FE0000 },
        { &__ccfg.CCFG_CCFG_TI_OPTIONS, 0xFFFFFF00 },
        { &__ccfg.CCFG_CCFG_TAP_DAP_0,  0xFF000000 },
        { &__ccfg.CCFG_CCFG_TAP_DAP_1,  0xFF000000 },
        { NULL, 0 }
    };

#if PLATFORM_DISABLE_PRODUCTION_MODE_SUPPORT
    static const mask_t DEV_MODE_MASKS[] = {
        { &__ccfg.CCFG_BL_CONFIG,       DEFAULT_CCFG_BL_CONFIG },
        { &__ccfg.CCFG_CCFG_TI_OPTIONS, DEFAULT_CCFG_CCFG_TI_OPTIONS },
        { &__ccfg.CCFG_CCFG_TAP_DAP_0,  DEFAULT_CCFG_CCFG_TAP_DAP_0 },
        { &__ccfg.CCFG_CCFG_TAP_DAP_1,  DEFAULT_CCFG_CCFG_TAP_DAP_1 },
        { NULL, 0 }
    };
#endif

    enum {
        MAX_WRITE_RETRIES = 32,
    };

    command bool ProductionModeControl.isInProductionMode() {
        const mask_t* p = PROD_MODE_MASKS;
        while (p->ptr != NULL) {
            if (HWREG(p->ptr) != p->value) {
                printf("[HalProductionModeControlPub] 0x%08x: 0x%08x != 0x%08x\r\n",
                        p->ptr, *p->ptr, p->value);
                return false;
            }
            p++;
        }
        return true;
    }

#if PLATFORM_DISABLE_PRODUCTION_MODE_SUPPORT
    error_t disableProductionMode() {
        int sector_size = FlashSectorSizeGet();
        uint32_t ccfg_sector = ((uint32_t)&__ccfg) & ~(sector_size - 1);
        uint32_t offset;
        error_t err = SUCCESS;

        FlashSectorErase((uint32_t)&_flog);
        FlashProgram((uint8_t*)ccfg_sector, (uint32_t)&_flog, sector_size);
        if (memcmp(&_flog, (uint8_t*)ccfg_sector, sector_size)) {
            printf("[HalProductionModeControlPub] EIO saving CCFG sector to "
                   "scratch area\r\n");
            err = EIO;
            goto out;
        }

        FlashSectorErase(ccfg_sector);
        for (offset = 0; offset < sector_size; offset += 4) {
            uint32_t to_write = *((uint32_t*)(&_flog + offset));
            const mask_t* p = DEV_MODE_MASKS;
            uint32_t check;
            while (p->ptr != NULL) {
                if ((uint32_t)p->ptr == ccfg_sector + offset) {
                    to_write = p->value;
                }
                p++;
            }
            FlashProgram((uint8_t*)&to_write, ccfg_sector + offset, 4);
            check = HWREG(ccfg_sector + offset);
            if (to_write != check) {
                printf("[HalProductionModeControlPub] EIO writing CCFG sector at "
                       "0x%08x (got 0x%08x, expected 0x%08x)\r\n",
                       ccfg_sector + offset, check, to_write);
                err = EIO;
                // Continue anyway, as it's better than leaving obviously
                // invalid CCFG.
            }
        }

out:
        flog_clear();

        return err;
    }
#endif

    error_t enableProductionMode() {
        const mask_t* p = PROD_MODE_MASKS;
        while (p->ptr != NULL) {
            if ((HWREG(p->ptr) & p->value) != p->value) {
                // We can only clear bits without erasing the flash, so in this
                // case we cannot proceed. This shouldn't really happen.
                //printf("[HalProductionModeControlPub] 0x%08x: 0x%08x -> 0x%08x!\r\n",
                //        p->ptr, *p->ptr, p->value);
                return EINTERNAL;
            }
            {
                int retry;
                for (retry = 0; retry < MAX_WRITE_RETRIES; retry++) {
                    if (FlashProgram((uint8_t*)&p->value, (uint32_t)p->ptr, 4) !=
                            FAPI_STATUS_SUCCESS) {
                        return EIO;
                    }
                    if (HWREG(p->ptr) != p->value) {
                        printf("[HalProductionModeControlPub] Write to 0x%08x: 0x%08x != 0x%08x\r\n",
                                p->ptr, *p->ptr, p->value);
                    } else {
                        goto next;
                    }
                }
                return EIO;
            }
next:
            p++;
        }
        return SUCCESS;
    }

    command bool ProductionModeControl.setProductionMode(bool value) {
        uint32_t saved_vims_mode;
        error_t err;

        if (value == call ProductionModeControl.isInProductionMode()) {
            return EALREADY;
        }

#if !PLATFORM_DISABLE_PRODUCTION_MODE_SUPPORT
        if (!value) {
            return ENOSYS;
        }
#endif

        atomic {
            saved_vims_mode = VIMSModeGet(VIMS_BASE);
            if (saved_vims_mode == VIMS_MODE_CHANGING) {
                return EBUSY;
            }

            /* Disable the cache and the line buffers.
             *
             * It's a pity datasheet says nothing about it, but see
             * comments in driverlib's vims.h.
             */
            VIMSLineBufDisable(VIMS_BASE);
            VIMSModeSafeSet(VIMS_BASE, VIMS_MODE_OFF, true);

#if PLATFORM_DISABLE_PRODUCTION_MODE_SUPPORT
            if (!value) {
                err = disableProductionMode();
            } else {
#endif
                err = enableProductionMode();
#if PLATFORM_DISABLE_PRODUCTION_MODE_SUPPORT
            }
#endif

            VIMSModeSafeSet(VIMS_BASE, saved_vims_mode, true);
            VIMSLineBufEnable(VIMS_BASE);
        }

        return err;
    }
}
