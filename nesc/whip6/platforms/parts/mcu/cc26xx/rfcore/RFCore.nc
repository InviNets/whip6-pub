/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#define __RFC_STRUCT
#include <driverlib/rf_common_cmd.h>

interface RFCore {
  command void init();

  command bool sendCmd(uint32_t cmd, uint32_t *status,
      bool interruptWhenDone);
  command bool waitCmdDone(rfc_radioOp_t* cmd);

  command bool powerUp(bool startRAT);
  command void powerDown();
  command bool startRAT();

  command void initRadioOp(rfc_radioOp_t *op, uint16_t len, uint16_t cmd);

  event void fatalError(const char* message);

  async event void onLastFGCommandDone();
  async event void onLastCommandDone();
  async event void onRXDone();
  async event void onTXDone();
  async event void onTXPkt();
}
