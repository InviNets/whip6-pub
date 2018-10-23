/******************************************************************************
*  Filename:       ccfg.c
*  Revised:        $Date: 2015-11-20 10:02:17 +0100 (fr, 20 nov 2015) $
*  Revision:       $Revision: 16374 $
*
*  Description:    Customer Configuration for CC26xx device family (HW rev 2).
*
*  Copyright (C) 2014 Texas Instruments Incorporated - http://www.ti.com/
*
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions
*  are met:
*
*    Redistributions of source code must retain the above copyright
*    notice, this list of conditions and the following disclaimer.
*
*    Redistributions in binary form must reproduce the above copyright
*    notice, this list of conditions and the following disclaimer in the
*    documentation and/or other materials provided with the distribution.
*
*    Neither the name of Texas Instruments Incorporated nor the names of
*    its contributors may be used to endorse or promote products derived
*    from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
*  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
*  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
*  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
*  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
******************************************************************************/

#include "ccfg.h"
#include <inc/hw_ccfg_simple_struct.h>

//*****************************************************************************
//
// Customer Configuration Area in Lock Page
//
//*****************************************************************************
__attribute__((section(".ccfg"), used))
const ccfg_t __ccfg =
{                                     // Mapped to address
    DEFAULT_CCFG_O_EXT_LF_CLK       , // 0x50003FA8 (0x50003xxx maps to last
    DEFAULT_CCFG_MODE_CONF_1        , // 0x50003FAC  sector in FLASH.
    DEFAULT_CCFG_SIZE_AND_DIS_FLAGS , // 0x50003FB0  Independent of FLASH size)
    DEFAULT_CCFG_MODE_CONF          , // 0x50003FB4
    DEFAULT_CCFG_VOLT_LOAD_0        , // 0x50003FB8
    DEFAULT_CCFG_VOLT_LOAD_1        , // 0x50003FBC
    DEFAULT_CCFG_RTC_OFFSET         , // 0x50003FC0
    DEFAULT_CCFG_FREQ_OFFSET        , // 0x50003FC4
    DEFAULT_CCFG_IEEE_MAC_0         , // 0x50003FC8
    DEFAULT_CCFG_IEEE_MAC_1         , // 0x50003FCC
    DEFAULT_CCFG_IEEE_BLE_0         , // 0x50003FD0
    DEFAULT_CCFG_IEEE_BLE_1         , // 0x50003FD4
    DEFAULT_CCFG_BL_CONFIG          , // 0x50003FD8
    DEFAULT_CCFG_ERASE_CONF         , // 0x50003FDC
    DEFAULT_CCFG_CCFG_TI_OPTIONS    , // 0x50003FE0
    DEFAULT_CCFG_CCFG_TAP_DAP_0     , // 0x50003FE4
    DEFAULT_CCFG_CCFG_TAP_DAP_1     , // 0x50003FE8
    DEFAULT_CCFG_IMAGE_VALID_CONF   , // 0x50003FEC
    DEFAULT_CCFG_CCFG_PROT_31_0     , // 0x50003FF0
    DEFAULT_CCFG_CCFG_PROT_63_32    , // 0x50003FF4
    DEFAULT_CCFG_CCFG_PROT_95_64    , // 0x50003FF8
    DEFAULT_CCFG_CCFG_PROT_127_96   , // 0x50003FFC
};
