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
 */
/*---------------------------------------------------------------------------*/
/**
 * \addtogroup cc26xx
 * @{
 *
 * \defgroup rf-core CC13xx/CC26xx RF core
 *
 * Different flavours of chips of the CC13xx/CC26xx family have different
 * radio capability. For example, the CC2650 can operate in IEEE 802.15.4 mode
 * at 2.4GHz, but it can also operate in BLE mode. The CC1310 only supports
 * sub-ghz mode.
 *
 * However, there are many radio functionalities that are identical across
 * all chips. The rf-core driver provides support for this common functionality
 *
 * @{
 *
 * \file
 * Header file for the CC13xx/CC26xx RF core driver
 */
/*---------------------------------------------------------------------------*/
#ifndef RF_CORE_H_
#define RF_CORE_H_
/*---------------------------------------------------------------------------*/
#include <stdint.h>
#include <stdbool.h>
/*---------------------------------------------------------------------------*/
#define RF_CORE_CMD_ERROR                     0
#define RF_CORE_CMD_OK                        1
/*---------------------------------------------------------------------------*/
/* RF Command status constants - Correspond to values in the CMDSTA register */
#define RF_CORE_CMDSTA_PENDING         0x00
#define RF_CORE_CMDSTA_DONE            0x01
#define RF_CORE_CMDSTA_ILLEGAL_PTR     0x81
#define RF_CORE_CMDSTA_UNKNOWN_CMD     0x82
#define RF_CORE_CMDSTA_UNKNOWN_DIR_CMD 0x83
#define RF_CORE_CMDSTA_CONTEXT_ERR     0x85
#define RF_CORE_CMDSTA_SCHEDULING_ERR  0x86
#define RF_CORE_CMDSTA_PAR_ERR         0x87
#define RF_CORE_CMDSTA_QUEUE_ERR       0x88
#define RF_CORE_CMDSTA_QUEUE_BUSY      0x89

/* Status values starting with 0x8 correspond to errors */
#define RF_CORE_CMDSTA_ERR_MASK        0x80

/* CMDSTA is 32-bits. Return value in bits 7:0 */
#define RF_CORE_CMDSTA_RESULT_MASK     0xFF

#define RF_CORE_RADIO_OP_STATUS_IDLE   0x0000
/*---------------------------------------------------------------------------*/
/* RF Radio Op status constants. Field 'status' in Radio Op command struct */
#define RF_CORE_RADIO_OP_STATUS_IDLE                     0x0000
#define RF_CORE_RADIO_OP_STATUS_PENDING                  0x0001
#define RF_CORE_RADIO_OP_STATUS_ACTIVE                   0x0002
#define RF_CORE_RADIO_OP_STATUS_SKIPPED                  0x0003
#define RF_CORE_RADIO_OP_STATUS_DONE_OK                  0x0400
#define RF_CORE_RADIO_OP_STATUS_DONE_COUNTDOWN           0x0401
#define RF_CORE_RADIO_OP_STATUS_DONE_RXERR               0x0402
#define RF_CORE_RADIO_OP_STATUS_DONE_TIMEOUT             0x0403
#define RF_CORE_RADIO_OP_STATUS_DONE_STOPPED             0x0404
#define RF_CORE_RADIO_OP_STATUS_DONE_ABORT               0x0405
#define RF_CORE_RADIO_OP_STATUS_ERROR_PAST_START         0x0800
#define RF_CORE_RADIO_OP_STATUS_ERROR_START_TRIG         0x0801
#define RF_CORE_RADIO_OP_STATUS_ERROR_CONDITION          0x0802
#define RF_CORE_RADIO_OP_STATUS_ERROR_PAR                0x0803
#define RF_CORE_RADIO_OP_STATUS_ERROR_POINTER            0x0804
#define RF_CORE_RADIO_OP_STATUS_ERROR_CMDID              0x0805
#define RF_CORE_RADIO_OP_STATUS_ERROR_NO_SETUP           0x0807
#define RF_CORE_RADIO_OP_STATUS_ERROR_NO_FS              0x0808
#define RF_CORE_RADIO_OP_STATUS_ERROR_SYNTH_PROG         0x0809

/* Additional Op status values for IEEE mode */
#define RF_CORE_RADIO_OP_STATUS_IEEE_SUSPENDED           0x2001
#define RF_CORE_RADIO_OP_STATUS_IEEE_DONE_OK             0x2400
#define RF_CORE_RADIO_OP_STATUS_IEEE_DONE_BUSY           0x2401
#define RF_CORE_RADIO_OP_STATUS_IEEE_DONE_STOPPED        0x2402
#define RF_CORE_RADIO_OP_STATUS_IEEE_DONE_ACK            0x2403
#define RF_CORE_RADIO_OP_STATUS_IEEE_DONE_ACKPEND        0x2404
#define RF_CORE_RADIO_OP_STATUS_IEEE_DONE_TIMEOUT        0x2405
#define RF_CORE_RADIO_OP_STATUS_IEEE_DONE_BGEND          0x2406
#define RF_CORE_RADIO_OP_STATUS_IEEE_DONE_ABORT          0x2407
#define RF_CORE_RADIO_OP_STATUS_ERROR_WRONG_BG           0x0806
#define RF_CORE_RADIO_OP_STATUS_IEEE_ERROR_PAR           0x2800
#define RF_CORE_RADIO_OP_STATUS_IEEE_ERROR_NO_SETUP      0x2801
#define RF_CORE_RADIO_OP_STATUS_IEEE_ERROR_NO_FS         0x2802
#define RF_CORE_RADIO_OP_STATUS_IEEE_ERROR_SYNTH_PROG    0x2803
#define RF_CORE_RADIO_OP_STATUS_IEEE_ERROR_RXOVF         0x2804
#define RF_CORE_RADIO_OP_STATUS_IEEE_ERROR_TXUNF         0x2805

/* Op status values for BLE mode */
#define RF_CORE_RADIO_OP_STATUS_BLE_DONE_OK              0x1400
#define RF_CORE_RADIO_OP_STATUS_BLE_DONE_RXTIMEOUT       0x1401
#define RF_CORE_RADIO_OP_STATUS_BLE_DONE_NOSYNC          0x1402
#define RF_CORE_RADIO_OP_STATUS_BLE_DONE_RXERR           0x1403
#define RF_CORE_RADIO_OP_STATUS_BLE_DONE_CONNECT         0x1404
#define RF_CORE_RADIO_OP_STATUS_BLE_DONE_MAXNACK         0x1405
#define RF_CORE_RADIO_OP_STATUS_BLE_DONE_ENDED           0x1406
#define RF_CORE_RADIO_OP_STATUS_BLE_DONE_ABORT           0x1407
#define RF_CORE_RADIO_OP_STATUS_BLE_DONE_STOPPED         0x1408
#define RF_CORE_RADIO_OP_STATUS_BLE_ERROR_PAR            0x1800
#define RF_CORE_RADIO_OP_STATUS_BLE_ERROR_RXBUF          0x1801
#define RF_CORE_RADIO_OP_STATUS_BLE_ERROR_NO_SETUP       0x1802
#define RF_CORE_RADIO_OP_STATUS_BLE_ERROR_NO_FS          0x1803
#define RF_CORE_RADIO_OP_STATUS_BLE_ERROR_SYNTH_PROG     0x1804
#define RF_CORE_RADIO_OP_STATUS_BLE_ERROR_RXOVF          0x1805
#define RF_CORE_RADIO_OP_STATUS_BLE_ERROR_TXUNF          0x1806

/* Op status values for proprietary mode */
#define RF_CORE_RADIO_OP_STATUS_PROP_DONE_OK             0x3400
#define RF_CORE_RADIO_OP_STATUS_PROP_DONE_RXTIMEOUT      0x3401
#define RF_CORE_RADIO_OP_STATUS_PROP_DONE_BREAK          0x3402
#define RF_CORE_RADIO_OP_STATUS_PROP_DONE_ENDED          0x3403
#define RF_CORE_RADIO_OP_STATUS_PROP_DONE_STOPPED        0x3404
#define RF_CORE_RADIO_OP_STATUS_PROP_DONE_ABORT          0x3405
#define RF_CORE_RADIO_OP_STATUS_PROP_DONE_RXERR          0x3406
#define RF_CORE_RADIO_OP_STATUS_PROP_DONE_IDLE           0x3407
#define RF_CORE_RADIO_OP_STATUS_PROP_DONE_BUSY           0x3408
#define RF_CORE_RADIO_OP_STATUS_PROP_DONE_IDLETIMEOUT    0x3409
#define RF_CORE_RADIO_OP_STATUS_PROP_DONE_BUSYTIMEOUT    0x340A
#define RF_CORE_RADIO_OP_STATUS_PROP_ERROR_PAR           0x3800
#define RF_CORE_RADIO_OP_STATUS_PROP_ERROR_RXBUF         0x3801
#define RF_CORE_RADIO_OP_STATUS_PROP_ERROR_RXFULL        0x3802
#define RF_CORE_RADIO_OP_STATUS_PROP_ERROR_NO_SETUP      0x3803
#define RF_CORE_RADIO_OP_STATUS_PROP_ERROR_NO_FS         0x3804
#define RF_CORE_RADIO_OP_STATUS_PROP_ERROR_RXOVF         0x3805
#define RF_CORE_RADIO_OP_STATUS_PROP_ERROR_TXUNF         0x3806

/* Bits 15:12 signify the protocol */
#define RF_CORE_RADIO_OP_STATUS_PROTO_MASK               0xF000
#define RF_CORE_RADIO_OP_STATUS_PROTO_GENERIC            0x0000
#define RF_CORE_RADIO_OP_STATUS_PROTO_BLE                0x1000
#define RF_CORE_RADIO_OP_STATUS_PROTO_IEEE               0x2000
#define RF_CORE_RADIO_OP_STATUS_PROTO_PROP               0x3000

/* Bits 11:10 signify Running / Done OK / Done with error */
#define RF_CORE_RADIO_OP_MASKED_STATUS                   0x0C00
#define RF_CORE_RADIO_OP_MASKED_STATUS_RUNNING           0x0000
#define RF_CORE_RADIO_OP_MASKED_STATUS_DONE              0x0400
#define RF_CORE_RADIO_OP_MASKED_STATUS_ERROR             0x0800
/*---------------------------------------------------------------------------*/
/* Command Types */
#define RF_CORE_COMMAND_TYPE_MASK                        0x0C00
#define RF_CORE_COMMAND_TYPE_RADIO_OP                    0x0800
#define RF_CORE_COMMAND_TYPE_IEEE_BG_RADIO_OP            0x0800
#define RF_CORE_COMMAND_TYPE_IEEE_FG_RADIO_OP            0x0C00

#define RF_CORE_COMMAND_PROTOCOL_MASK                    0x3000
#define RF_CORE_COMMAND_PROTOCOL_COMMON                  0x0000
#define RF_CORE_COMMAND_PROTOCOL_BLE                     0x1000
#define RF_CORE_COMMAND_PROTOCOL_IEEE                    0x2000
#define RF_CORE_COMMAND_PROTOCOL_PROP                    0x3000
/*---------------------------------------------------------------------------*/
/* Data entry status field constants */
#define DATA_ENTRY_STATUS_PENDING    0x00 /* Not in use by the Radio CPU */
#define DATA_ENTRY_STATUS_ACTIVE     0x01 /* Open for r/w by the radio CPU */
#define DATA_ENTRY_STATUS_BUSY       0x02 /* Ongoing r/w */
#define DATA_ENTRY_STATUS_FINISHED   0x03 /* Free to use and to free */
#define DATA_ENTRY_STATUS_UNFINISHED 0x04 /* Partial RX entry */
/*---------------------------------------------------------------------------*/


#endif /* RF_CORE_H_ */
