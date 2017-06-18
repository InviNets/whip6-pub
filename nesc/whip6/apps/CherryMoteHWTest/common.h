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
// API doesn't provide any value, this one should work
#define MAX_DATA_FRAME_LEN 50

#define QUERY "ping"
#define RESP "pong"

#endif // __COMMON__H__
