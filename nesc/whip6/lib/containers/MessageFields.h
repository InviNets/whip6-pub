/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 * @author Konrad Iwanicki
 * @author Michal Marschall <m.marschall@invinets.com>
 * 
 * Definitions below allow forming of standardized binary messages understood by our servers in the cloud.
 * 
 * To this end, we utilize nesC nx_structs (which are packed) and nx_* types, which are stored in network order (big 
 * endian).
 * 
 * Each piece of information that a node can send or receive will have a very specific type. For example, we will have 
 * types like:
 *   - temperature in dC (dC = 0.1 degree C) from built-in sensor 0,
 *   - relative humidity in % from built-in sensor 0,
 *   - battery voltage reading.
 * 
 * The message will be formatted as a series of pairs:
 *   <type1><data1><type2><data2>...<typen><datan><null>
 * 
 * The <null> type is used to mark the end of (type, data) pair series. After it, arbitrary additional data can follow.
 *
 * The purpose is to give us the freedom of updating the backend servers without reprogramming the nodes. Each side can
 * safely handle types unknown to it by ignoring them. Older packets will remain compatible with newer backends.
 * 
 * The type uses two most significant bits to encode field length. The options are:
 *   - 0b00: 1 byte,
 *   - 0b01: 2 bytes,
 *   - 0b10: 4 bytes,
 *   - 0b11: other, may be variable (data format: <length><data>, length is 1-byte long).
 * 
 * To declare messages using this mechanism you must use macros provided in this file, for example:
 *   typedef nx_struct {
 *       DECLARE_i16_temp_dC_intsens0
 *       DECLARE_i16_battery_mV
 *       DECLARE_end_of_msg  // this MUST be the last DECLARE_* field
 *   } climboard_report_t;
 * 
 * Usage:
 *   climboard_report_t msg;
 * 
 *   SET_i16_temp_dC_intsens0(msg, 230); 
 *   SET_u8_rHumid_percent_intsens0(msg, 20);
 *   SET_end_of_msg(msg);  // you MUST always set all fields
 * 
 *   call Sender.send(&msg, sizeof(climboard_report_t));
 * 
 * If you want to piggy-back something on the nx_struct, you are allowed to do so, but you must place your declarations
 * after DECLARE_end_of_msg so that they will be ignored by the deserializer.
 *
 * To get data from a received packet, you cannot access fields directly, because they may be in any order. Instead, use
 * macros HAS_* and GET_* and pass a pointer to the packet buffer:
 *   int16_t temp = GET_i16_temp_dC_intsens0(bufPtr);
 *
 * To get a pointer to the first value after the packet (end of message symbol), use GET_end_of_msg(bufPtr).
 *
 * Some fields may have variable length. Their usage differs in a few aspects:
 *   - DECLARE_* macro takes an argument: maximum length,
 *   - SET_* macro takes an additional parameter: length (you are allowed to set values lower than the maximum length),
 *   - there is an addtional macro LENGTH_*, which returns the actual length of the field in a received packet.
 */

#ifndef MESSAGE_FIELDS_H_
#define MESSAGE_FIELDS_H_
 
/**
 * If you want to add a message type, follow these steps:
 * 1. Add an enum for the new type. Use IS_* macro to declare its length.
 * 2. Add defines: DECLARE_*, HAS_*, GET_*, and SET_*. In case of variable-length type, add also LENGTH_*.
 * 3. Go to whip6-webapp/wsn_ui/wsn_ui/lib/message_format/reader.py. Add your new field there.
 */
enum {
    IS_8_BIT  = (0 << 6),
    IS_16_BIT = (1 << 6),
    IS_32_BIT = (2 << 6),
    IS_OTHER  = (3 << 6),
    FIELD_LENGTH_MASK = 0xC0,
};

/* The field type must be in range [1, 63]. Two most significant bits are reserved for the length. */
enum {
    FT_u64_eui64 =                      1  | IS_OTHER,
    FT_i16_temp_dC_intsens0 =           10 | IS_16_BIT,
    FT_u8_rHumid_percent_intsens0 =     20 | IS_8_BIT,
    FT_i16_battery_mV =                 30 | IS_16_BIT,
    FT_u8_sensor_read_error =           40 | IS_8_BIT,
    FT_u32_time_since_reset_sec =       41 | IS_32_BIT,
    FT_u8_button_pressed =              42 | IS_8_BIT,
    FT_u16_transmit_interv_sec =        43 | IS_16_BIT,
    FT_u32_transmit_nr_since_start =    44 | IS_32_BIT,
    FT_u8_last_reset_reason =           45 | IS_8_BIT,
    FT_u8_is_last_flash_packet =        50 | IS_8_BIT,
    FT_u8_num_reports_in_packet =       51 | IS_8_BIT,
    FT_u16_num_crc_errors =             52 | IS_16_BIT,
    FT_u8_display_backlight =           53 | IS_8_BIT,
    FT_u8_display_led =                 54 | IS_8_BIT,
    FT_var_display_message =            56 | IS_OTHER,
    FT_var_reports =                    57 | IS_OTHER,
    FT_end_of_msg =                     0,
};

enum { 
    TEMP_READ_ERROR      = (1 << 0),
    HUMID_READ_ERROR     = (1 << 1),
    BATTERY_READ_ERROR   = (1 << 2),
    DBGLOCK_BIT_NOT_SET  = (1 << 3),
};

#define _DECLARE_FT(nx_type, field_name)                    nx_uint8_t field_name##_tp; \
                                                            nx_type field_name;

#define _DECLARE_FT_OTHER(length, field_name)               nx_uint8_t field_name##_tp; \
                                                            nx_uint8_t field_name##_len; \
                                                            nx_uint8_t field_name[length];

#define DECLARE_u64_eui64                                   _DECLARE_FT_OTHER(8, u64_eui64)
#define DECLARE_i16_temp_dC_intsens0                        _DECLARE_FT(nx_int16_t, i16_temp_dC_intsens0)
#define DECLARE_u8_rHumid_percent_intsens0                  _DECLARE_FT(nx_uint8_t, u8_rHumid_percent_intsens0)
#define DECLARE_i16_battery_mV                              _DECLARE_FT(nx_int16_t, i16_battery_mV)
#define DECLARE_u8_sensor_read_error                        _DECLARE_FT(nx_uint8_t, u8_sensor_read_error)
#define DECLARE_u32_time_since_reset_sec                    _DECLARE_FT(nx_uint32_t, u32_time_since_reset_sec)
#define DECLARE_u8_button_pressed                           _DECLARE_FT(nx_uint8_t, u8_button_pressed)
#define DECLARE_u16_transmit_interv_sec                     _DECLARE_FT(nx_uint16_t, u16_transmit_interv_sec)
#define DECLARE_u32_transmit_nr_since_start                 _DECLARE_FT(nx_uint32_t, u32_transmit_nr_since_start)
#define DECLARE_u8_last_reset_reason                        _DECLARE_FT(nx_uint8_t, u8_last_reset_reason)
#define DECLARE_u8_is_last_flash_packet                     _DECLARE_FT(nx_uint8_t, u8_is_last_flash_packet)
#define DECLARE_u8_num_reports_in_packet                    _DECLARE_FT(nx_uint8_t, u8_num_reports_in_packet)
#define DECLARE_u16_num_crc_errors                          _DECLARE_FT(nx_uint16_t, u16_num_crc_errors)
#define DECLARE_u8_display_backlight                        _DECLARE_FT(nx_uint8_t, u8_display_backlight)
#define DECLARE_u8_display_led                              _DECLARE_FT(nx_uint8_t, u8_display_led)
#define DECLARE_var_display_message(length)                 _DECLARE_FT_OTHER(length, var_display_message)
#define DECLARE_var_reports(length)                         _DECLARE_FT_OTHER(length, var_reports)
#define DECLARE_end_of_msg                                  nx_uint8_t end_of_msg_tp;

uint8_t _MessageFields_lengthFromType(uint8_t_xdata *data) {
    switch(*data & FIELD_LENGTH_MASK) {
        case IS_8_BIT:
            return 1;
        case IS_16_BIT:
            return 2;
        case IS_32_BIT:
            return 4;
        case IS_OTHER:
            return data[1];
        default:
            return 0;
    }
}

uint8_t_xdata * _MessageFields_advancePointer(uint8_t_xdata *data) {
    uint8_t length = _MessageFields_lengthFromType(data);
    return length == 0? NULL : data + 1 + length + ((*data & FIELD_LENGTH_MASK) == IS_OTHER? 1 : 0);
}

uint8_t _MessageFields_getFieldLength(uint8_t_xdata *data, uint8_t fieldType) {
    while(data != NULL) {
        if(*data == fieldType) {
            return _MessageFields_lengthFromType(data);
        } else {
            data = _MessageFields_advancePointer(data);
        }
    }

    return 0;
}

uint8_t_xdata * _MessageFields_getFieldPointer(uint8_t_xdata *data, uint8_t fieldType) {
    while(data != NULL) {
        if(*data == fieldType) {
            return data + ((*data & FIELD_LENGTH_MASK) == IS_OTHER? 2 : 1);
        }

        if(*data == FT_end_of_msg) {
            return NULL;
        }

        data = _MessageFields_advancePointer(data);
    }

    return NULL;
}

#define _HAS_FT(message, field_name)                        (_MessageFields_getFieldPointer(message, FT_##field_name) != NULL)

#define HAS_u64_eui64(message)                              _HAS_FT(message, u64_eui64)
#define HAS_i16_temp_dC_intsens0(message)                   _HAS_FT(message, i16_temp_dC_intsens0)
#define HAS_u8_rHumid_percent_intsens0(message)             _HAS_FT(message, u8_rHumid_percent_intsens0)
#define HAS_i16_battery_mV(message)                         _HAS_FT(message, i16_battery_mV)
#define HAS_u8_sensor_read_error(message)                   _HAS_FT(message, u8_sensor_read_error)
#define HAS_u32_time_since_reset_sec(message)               _HAS_FT(message, u32_time_since_reset_sec)
#define HAS_u8_button_pressed(message)                      _HAS_FT(message, u8_button_pressed)
#define HAS_u16_transmit_interv_sec(message)                _HAS_FT(message, u16_transmit_interv_sec)
#define HAS_u32_transmit_nr_since_start(message)            _HAS_FT(message, u32_transmit_nr_since_start)
#define HAS_u8_last_reset_reason(message)                   _HAS_FT(message, u8_last_reset_reason)
#define HAS_u8_is_last_flash_packet(message)                _HAS_FT(message, u8_is_last_flash_packet)
#define HAS_u8_num_reports_in_packet(message)               _HAS_FT(message, u8_num_reports_in_packet)
#define HAS_u16_num_crc_errors(message)                     _HAS_FT(message, u16_num_crc_errors)
#define HAS_u8_display_backlight(message)                   _HAS_FT(message, u8_display_backlight)
#define HAS_u8_display_led(message)                         _HAS_FT(message, u8_display_led)
#define HAS_var_display_message(message)                    _HAS_FT(message, var_display_message)
#define HAS_var_reports(message)                            _HAS_FT(message, var_reports)

#define _GET_FT(message, field_name, nx_type)               (_HAS_FT(message, field_name)? *((nx_type *)_MessageFields_getFieldPointer(message, FT_##field_name)) : 0)

#define GET_u64_eui64(message)                              _MessageFields_getFieldPointer(message, FT_u64_eui64)
#define GET_i16_temp_dC_intsens0(message)                   _GET_FT(message, i16_temp_dC_intsens0, nx_int16_t)
#define GET_u8_rHumid_percent_intsens0(message)             _GET_FT(message, u8_rHumid_percent_intsens0, nx_uint8_t)
#define GET_i16_battery_mV(message)                         _GET_FT(message, i16_battery_mV, nx_int16_t)
#define GET_u8_sensor_read_error(message)                   _GET_FT(message, u8_sensor_read_error, nx_uint8_t)
#define GET_u32_time_since_reset_sec(message)               _GET_FT(message, u32_time_since_reset_sec, nx_uint32_t)
#define GET_u8_button_pressed(message)                      _GET_FT(message, u8_button_pressed, nx_uint8_t)
#define GET_u16_transmit_interv_sec(message)                _GET_FT(message, u16_transmit_interv_sec, nx_uint16_t)
#define GET_u32_transmit_nr_since_start(message)            _GET_FT(message, u32_transmit_nr_since_start, nx_uint32_t)
#define GET_u8_last_reset_reason(message)                   _GET_FT(message, u8_last_reset_reason, nx_uint8_t)
#define GET_u8_is_last_flash_packet(message)                _GET_FT(message, u8_is_last_flash_packet, nx_uint8_t)
#define GET_u8_num_reports_in_packet(message)               _GET_FT(message, u8_num_reports_in_packet, nx_uint8_t)
#define GET_u16_num_crc_errors(message)                     _GET_FT(message, u16_num_crc_errors, nx_uint16_t)
#define GET_u8_display_backlight(message)                   _GET_FT(message, u8_display_backlight, nx_uint8_t)
#define GET_u8_display_led(message)                         _GET_FT(message, u8_display_led, nx_uint8_t)
#define GET_var_display_message(message)                    _MessageFields_getFieldPointer(message, FT_var_display_message)
#define GET_var_reports(message)                            _MessageFields_getFieldPointer(message, FT_var_reports)
#define GET_end_of_msg(message)                             _MessageFields_getFieldPointer(message, FT_end_of_msg)

#define _SET_FT(message, value, field_name)                 { \
                                                                message.field_name##_tp = FT_##field_name; \
                                                                message.field_name = value; \
                                                            }

#define _SET_FT_OTHER(message, value, field_name, length)   do { \
                                                                message.field_name##_tp = FT_##field_name; \
                                                                message.field_name##_len = length; \
                                                                memmove(message.field_name, value, length); \
                                                            } while(FALSE)

#define SET_u64_eui64(message, value)                       _SET_FT_OTHER(message, value, u64_eui64, 8)
#define SET_i16_temp_dC_intsens0(message, value)            _SET_FT(message, value, i16_temp_dC_intsens0)
#define SET_u8_rHumid_percent_intsens0(message, value)      _SET_FT(message, value, u8_rHumid_percent_intsens0)
#define SET_i16_battery_mV(message, value)                  _SET_FT(message, value, i16_battery_mV)
#define SET_u8_sensor_read_error(message, value)            _SET_FT(message, value, u8_sensor_read_error)
#define SET_u32_time_since_reset_sec(message, value)        _SET_FT(message, value, u32_time_since_reset_sec)
#define SET_u8_button_pressed(message, value)               _SET_FT(message, value, u8_button_pressed)
#define SET_u16_transmit_interv_sec(message, value)         _SET_FT(message, value, u16_transmit_interv_sec)
#define SET_u32_transmit_nr_since_start(message, value)     _SET_FT(message, value, u32_transmit_nr_since_start)
#define SET_u8_last_reset_reason(message, value)            _SET_FT(message, value, u8_last_reset_reason)
#define SET_u8_is_last_flash_packet(message, value)         _SET_FT(message, value, u8_is_last_flash_packet)
#define SET_u8_num_reports_in_packet(message, value)        _SET_FT(message, value, u8_num_reports_in_packet)
#define SET_u16_num_crc_errors(message, value)              _SET_FT(message, value, u16_num_crc_errors)
#define SET_u8_display_backlight(message, value)            _SET_FT(message, value, u8_display_backlight)
#define SET_u8_display_led(message, value)                  _SET_FT(message, value, u8_display_led)
#define SET_var_display_message(message, value, length)     _SET_FT_OTHER(message, value, var_display_message, length)
#define SET_var_reports(message, value, length)             _SET_FT_OTHER(message, value, var_reports, length)
#define SET_end_of_msg(message)                             message.end_of_msg_tp = 0

#define _LENGTH_FT(message, field_type)                     _MessageFields_getFieldLength(message, FT_##field_type)

#define LENGTH_var_display_message(message)                 _LENGTH_FT(message, var_display_message)
#define LENGTH_var_reports(message)                         _LENGTH_FT(message, var_reports)

#define _SET_LENGTH_FT(message, field_name, length)         do { \
                                                                message.field_name##_tp = FT_##field_name; \
                                                                message.field_name##_len = length; \
                                                            } while(FALSE)

#define SET_LENGTH_var_display_message(message, length)     _SET_LENGTH_FT(message, var_display_message, length)
#define SET_LENGTH_var_reports(message, length)             _SET_LENGTH_FT(message, var_reports, length)

#endif // MESSAGE_FIELDS_H_
