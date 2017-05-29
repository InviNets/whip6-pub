#ifndef __COMMON__H__
#define __COMMON__H__

// This file is shared between hw-test on Supervisor, HWTest app and HWTestRadioServer app.
// Please be sure to update all of them in case of any changes.

#define TEMP_CMD    't'
#define LED_ON_CMD  'd'
#define XTAL_CMD    'x'
#define LED_OFF_CMD 'o'
#define RADIO_CMD   'r'
#define ICOUNT_CMD  'i'
#define UART_CMD    'u'

#define FRAME_LENGTH 120
const char *query = "ping";
const char *resp = "pong";

#endif // __COMMON__H__
