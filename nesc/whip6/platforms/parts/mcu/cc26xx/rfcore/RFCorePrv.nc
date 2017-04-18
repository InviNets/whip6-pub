/*
 * Copyright (c) 2015, Texas Instruments Incorporated - http://www.ti.com/
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <Assert.h>
#include <driverlib/prcm.h>
#include <driverlib/rfc.h>
#include <driverlib/chipinfo.h>

#include "RFCore.h"

#define RF_CORE_WAIT_CMD_TIMEOUT_LOOPS 500000

#define RFCORE_ASSERT(cond) do { if (!(cond)) panic(); } while (0)
#define RFCORE_WARNPRINTF(...) printf(__VA_ARGS__)
//#define RFCORE_DBGPRINTF(...) printf(__VA_ARGS__)
#define RFCORE_DBGPRINTF(...)

/**
 * @author Szymon Acedanski
 *
 * CC26xx RF Core layer.
 *
 * Based on code from Contiki, licensed with the above TI license.
 */
module RFCorePrv {
  provides interface RFCore;
  provides interface RFCorePowerUpHook;

  uses interface ExternalEvent as CPE0Int;
  uses interface ExternalEvent as CPE1Int;

  uses interface ShareableOnOff as PowerDomain;
}

implementation {
  bool poweredUp = FALSE;
  bool ratRunning = FALSE;

  /* RAT <-> RTC synchronization */
  uint32_t rat0;
  bool rat0Valid = FALSE;

  /* Converts a raw command value to a pointer to rfc_radioOp_t, if it is
   * a radio OP, otherwise returns NULL. */
  static rfc_radioOp_t* cmdToRadioOp(uint32_t cmd) {
    if((cmd & 0x03) == 0) {
      uint32_t cmd_type;
      cmd_type = ((rfc_command_t *)cmd)->commandNo & RF_CORE_COMMAND_TYPE_MASK;
      if(cmd_type == RF_CORE_COMMAND_TYPE_IEEE_FG_RADIO_OP ||
         cmd_type == RF_CORE_COMMAND_TYPE_RADIO_OP) {
        return (rfc_radioOp_t*)cmd;
      }
    }
    return NULL;
  }

  command bool RFCore.sendCmd(uint32_t cmd, uint32_t *status,
      bool interruptWhenDone)
  {
    rfc_radioOp_t* radioOp = cmdToRadioOp(cmd);
    rfc_radioOp_t* op;

    RFCORE_ASSERT(PRCMRfReady());

    if (radioOp) {
      for (op = radioOp; op; op = op->pNextOp)
        op->status = RF_CORE_RADIO_OP_STATUS_IDLE;
    }

    if (interruptWhenDone) {
      uint32_t cmd_type, irq = 0;
      RFCORE_ASSERT(radioOp);
      op = radioOp;
      //while (op->pNextOp) {
      //  op = op->pNextOp;
      //}
      cmd_type = op->commandNo & RF_CORE_COMMAND_TYPE_MASK;
      if(cmd_type == RF_CORE_COMMAND_TYPE_IEEE_FG_RADIO_OP) {
        irq = IRQ_LAST_FG_COMMAND_DONE;
      } else if (cmd_type == RF_CORE_COMMAND_TYPE_RADIO_OP) {
        irq = IRQ_LAST_COMMAND_DONE;
      } else {
        RFCORE_ASSERT(FALSE);
      }
      RFCORE_DBGPRINTF("%d when done\r\n", irq);
      RFCCpeIntClear(irq);
      RFCCpe0IntEnable(irq);
    }

    *status = RFCDoorbellSendTo(cmd);

    /*
     * If we reach here the command is no longer pending. It is either completed
     * successfully or with error
     */
    return (*status & RF_CORE_CMDSTA_RESULT_MASK) == RF_CORE_CMDSTA_DONE;
  }
  /*---------------------------------------------------------------------------*/
  command bool RFCore.waitCmdDone(rfc_radioOp_t* cmd)
  {
    volatile rfc_radioOp_t* vcmd = cmd;
    uint32_t timeout_cnt = 0;

    /*
     * 0xn4nn=DONE, 0x0400=DONE_OK while all other "DONE" values means done
     * but with some kind of error (ref. "Common radio operation status codes")
     */
    do {
      if(++timeout_cnt > RF_CORE_WAIT_CMD_TIMEOUT_LOOPS) {
        return FALSE;
      }
    } while((vcmd->status & RF_CORE_RADIO_OP_MASKED_STATUS)
            != RF_CORE_RADIO_OP_MASKED_STATUS_DONE);

    return (vcmd->status & RF_CORE_RADIO_OP_MASKED_STATUS)
           == RF_CORE_RADIO_OP_STATUS_DONE_OK;
  }
  /*---------------------------------------------------------------------------*/
  command bool RFCore.powerUp(bool startRAT)
  {
    uint32_t cmd_status;

    if (poweredUp) {
      return TRUE;
    }

    /* Disable interrupts. Just to be sure. */
    call CPE0Int.asyncNotifications(FALSE);
    call CPE1Int.asyncNotifications(FALSE);

    /* Enable RF Core power domain ... */
    call PowerDomain.on();

    /* ... and clocks. */
    PRCMDomainEnable(PRCM_DOMAIN_RFCORE);
    PRCMLoadSet();
    while (!PRCMLoadGet()) /* nop */;

    /* Let CPE boot */
    RFCClockEnable();

    /* Send ping (to verify RFCore is ready and alive) */
    if (!call RFCore.sendCmd(CMDR_DIR_CMD(CMD_PING), &cmd_status, FALSE)) {
      RFCORE_WARNPRINTF("rf_core_power_up: CMD_PING fail, CMDSTA=0x%08lx\n", cmd_status);
      call RFCore.powerDown();
      signal RFCore.fatalError("Power-up ping failed");
      return FALSE;
    }

    /* Setup interrupts.
     *
     * For now, we route all interrupts to CPE0, as it's easier to handle with
     * the current API, which has RFCCpeIntGetAndClear function only.
     */
    RFCCpeIntDisable(0xffffffff);
    RFCCpe0IntEnable(IRQ_RX_ENTRY_DONE | IRQ_TX_ENTRY_DONE | IRQ_TX_DONE
            | IRQ_INTERNAL_ERROR);

    /* Enable interrupts */
    call CPE0Int.clearPending();
    call CPE1Int.clearPending();
    call CPE0Int.asyncNotifications(TRUE);
    call CPE1Int.asyncNotifications(TRUE);

    /* Start RAT if requested */
    if(startRAT && !call RFCore.startRAT()) {
      RFCORE_WARNPRINTF("rf_core_power_up: startRAT() failed\n");
      call RFCore.powerDown();
      signal RFCore.fatalError("RAT startup failed");
      return FALSE;
    }

    poweredUp = TRUE;

    signal RFCorePowerUpHook.poweredUp();

    return TRUE;
  }
  /*---------------------------------------------------------------------------*/
  command void RFCore.powerDown()
  {
    // Disable interrupts.
    RFCCpeIntDisable(0xffffffff);
    call CPE0Int.asyncNotifications(FALSE);
    call CPE1Int.asyncNotifications(FALSE);
    call CPE0Int.clearPending();
    call CPE1Int.clearPending();

    if (PRCMRfReady()) {
      rfc_CMD_FS_POWERDOWN_t cmd;
      uint32_t cmd_status;

      /* need to send FS_POWERDOWN or analog components will use power */

      call RFCore.initRadioOp((rfc_radioOp_t *)&cmd, sizeof(cmd),
          CMD_FS_POWERDOWN);

      if (!call RFCore.sendCmd((uint32_t)&cmd, &cmd_status, FALSE)) {
        RFCORE_WARNPRINTF("FSPowerdown: sendCmd failed\n");
        signal RFCore.fatalError("CMD_FS_POWERDOWN send failed");
        /* we continue shutting down the thing anyways... */
      } else if (!call RFCore.waitCmdDone((rfc_radioOp_t*)&cmd)) {
        RFCORE_WARNPRINTF("FSPowerdown: CMDSTA=0x%08lx, status=0x%04x\n",
               cmd_status, cmd.status);
        signal RFCore.fatalError("CMD_FS_POWERDOWN failed");
        /* we continue shutting down the thing anyways... */
      }
    }

    if (PRCMRfReady() && ratRunning) {
      rfc_CMD_SYNC_STOP_RAT_t cmd;
      uint32_t cmd_status;

      /* synchronize RAT to RTC */

      call RFCore.initRadioOp((rfc_radioOp_t *)&cmd, sizeof(cmd),
          CMD_SYNC_STOP_RAT);

      if (!call RFCore.sendCmd((uint32_t)&cmd, &cmd_status, FALSE)) {
        RFCORE_WARNPRINTF("SYNC_STOP_RAT: sendCmd failed\n");
        signal RFCore.fatalError("CMD_SYNC_STOP_RAT send failed");
        /* we continue shutting down the thing anyways... */
      } else if (!call RFCore.waitCmdDone((rfc_radioOp_t*)&cmd)) {
        RFCORE_WARNPRINTF("SYNC_STOP_RAT: CMDSTA=0x%08lx, status=0x%04x\n",
               cmd_status, cmd.status);
        signal RFCore.fatalError("CMD_SYNC_STOP_RAT failed");
        /* we continue shutting down the thing anyways... */
      }

      rat0 = cmd.rat0;
      rat0Valid = TRUE;
      ratRunning = FALSE;
    }

    /* Disable clocks */
    RFCClockDisable();

    /* Shut down the RFCORE clock domain in the MCU VD */
    PRCMDomainDisable(PRCM_DOMAIN_RFCORE);
    PRCMLoadSet();
    while (!PRCMLoadGet()) /* nop */;

    /* Turn off RFCORE PD */
    call PowerDomain.off();

    /* Set flag */
    poweredUp = FALSE;
  }
  /*---------------------------------------------------------------------------*/
  command bool RFCore.startRAT()
  {
    uint32_t cmd_status;

    if (ratRunning) {
        return TRUE;
    }

    if (rat0Valid) {
      rfc_CMD_SYNC_START_RAT_t cmd;
      call RFCore.initRadioOp((rfc_radioOp_t *)&cmd, sizeof(cmd),
          CMD_SYNC_START_RAT);
      cmd.rat0 = rat0;

      if (!call RFCore.sendCmd((uint32_t)&cmd, &cmd_status, FALSE)) {
        RFCORE_WARNPRINTF("SYNC_START_RAT: sendCmd failed\n");
        signal RFCore.fatalError("CMD_SYNC_START_RAT send failed");
        return FALSE;
      } else if (!call RFCore.waitCmdDone((rfc_radioOp_t*)&cmd)) {
        RFCORE_WARNPRINTF("SYNC_START_RAT: CMDSTA=0x%08lx, status=0x%04x\n",
               cmd_status, cmd.status);
        signal RFCore.fatalError("CMD_SYNC_START_RAT failed");
        return FALSE;
      }
    } else {
      if (!call RFCore.sendCmd(CMDR_DIR_CMD(CMD_START_RAT), &cmd_status, FALSE)) {
        RFCORE_WARNPRINTF("rf_core_apply_patches: START_RAT fail, CMDSTA=0x%08lx\n",
               cmd_status);
        signal RFCore.fatalError("CMD_START_RAT failed");
        return FALSE;
      }
    }

    ratRunning = TRUE;
    return TRUE;
  }
  /*---------------------------------------------------------------------------*/

  async event void CPE0Int.triggered() {
    uint32_t flags = RFCCpeIntGetAndClear();

    RFCORE_DBGPRINTF("CPE0Int: rflags=0x%08x\r\n", flags);

    flags &= HWREG(RFC_DBELL_BASE + RFC_DBELL_O_RFCPEIEN);

    if (flags & IRQ_LAST_FG_COMMAND_DONE) {
      RFCCpeIntDisable(IRQ_LAST_FG_COMMAND_DONE);
      signal RFCore.onLastFGCommandDone();
    }

    if (flags & IRQ_RX_ENTRY_DONE) {
      signal RFCore.onRXDone();
    }

    if (flags & IRQ_TX_ENTRY_DONE) {
      signal RFCore.onTXDone();
    }

    if (flags & IRQ_TX_DONE) {
      signal RFCore.onTXPkt();
    }

    if (flags & IRQ_LAST_COMMAND_DONE) {
      RFCCpeIntDisable(IRQ_LAST_COMMAND_DONE);
      signal RFCore.onLastCommandDone();
    }

    if (flags & IRQ_INTERNAL_ERROR) {
      panic("[RFCore] Internal error interrupt");
    }
  }

  async event void CPE1Int.triggered() {
      // May be used in the future, for now we use CPE0 only.
      panic("[RFCore] Spurious CPE1 interrupt");
  }

  /*---------------------------------------------------------------------------*/
  command void RFCore.initRadioOp(rfc_radioOp_t *op, uint16_t len, uint16_t cmd)
  {
    memset(op, 0, len);
    op->commandNo = cmd;
    op->condition.rule = COND_NEVER;
  }

  /*---------------------------------------------------------------------------*/
  /* One-time initialization                                                   */
  /*---------------------------------------------------------------------------*/

  static void setModesel()
  {
    if(ChipInfo_ChipFamilyIsCC26xx()) {
      if(ChipInfo_SupportsBLE() &&
         ChipInfo_SupportsIEEE_802_15_4()) {
        /* CC2650 */
        HWREG(PRCM_BASE + PRCM_O_RFCMODESEL) = PRCM_RFCMODESEL_CURR_MODE5;
      } else if(!ChipInfo_SupportsBLE() &&
                ChipInfo_SupportsIEEE_802_15_4()) {
        /* CC2630 */
        HWREG(PRCM_BASE + PRCM_O_RFCMODESEL) = PRCM_RFCMODESEL_CURR_MODE2;
      }
    } else {
      panic("[RFCore] Unsupported CC26xx chip");
    }
  }

  command void RFCore.init() {
    setModesel();
  }

  default event void RFCorePowerUpHook.poweredUp() { }
}

// vim:sw=2:ts=2
