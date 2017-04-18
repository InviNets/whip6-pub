/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

INT(INT_NMI_FAULT, NMIFault)  // NMI Fault
INT(INT_MEMMANAGE_FAULT, MPUFault)  // Memory Management (MemManage) Fault
INT(INT_BUS_FAULT, BusFault)  // Bus Fault
INT(INT_USAGE_FAULT, UsageFault)  // Usage Fault
INT(INT_SVCALL, SVCallFault)  // Supervisor Call (SVCall)
INT(INT_DEBUG, DebugFault)  // Debug Monitor
INT(INT_SYSTICK, SysTickFault)  // SysTick Interrupt from the System Timer in NVIC.
INT(INT_AON_GPIO_EDGE, GPIO)  // Edge detect event from IOC
INT(INT_I2C_IRQ, I2C)  // Interrupt event from I2C
INT(INT_RFC_CPE_1, RFCCPE1)  // Combined Interrupt for CPE Generated events
INT(19, AON)               // (Not defined in hw_ints.h)
INT(INT_AON_RTC_COMB, AONRTC)  // Event from AON_RTC
INT(INT_UART0_COMB, UART0)  // UART0 combined interrupt
INT(INT_AUX_SWEV0, AUXSW0)  // AUX software event 0
INT(INT_SSI0_COMB, SSI0)  // SSI0 combined interrupt
INT(INT_SSI1_COMB, SSI1)  // SSI0 combined interrupt
INT(INT_RFC_CPE_0, RFCCPE0)  // Combined Interrupt for CPE Generated events
INT(INT_RFC_HW_COMB, RFCHw)  // Combined RCF hardware interrupt
INT(INT_RFC_CMD_ACK, RFCAck)  // RFC Doorbell Command Acknowledgement Interrupt
INT(INT_I2S_IRQ, I2S)  // Interrupt event from I2S
INT(INT_AUX_SWEV1, AUXSW1)  // AUX software event 1
INT(INT_WDT_IRQ, Watchdog)  // Watchdog interrupt event
INT(INT_GPT0A, Timer0A)  // GPT0A interrupt event
INT(INT_GPT0B, Timer0B)  // GPT0B interrupt event
INT(INT_GPT1A, Timer1A)  // GPT1A interrupt event
INT(INT_GPT1B, Timer1B)  // GPT1B interrupt event
INT(INT_GPT2A, Timer2A)  // GPT2A interrupt event
INT(INT_GPT2B, Timer2B)  // GPT2B interrupt event
INT(INT_GPT3A, Timer3A)  // GPT3A interrupt event
INT(INT_GPT3B, Timer3B)  // GPT3B interrupt event
INT(INT_CRYPTO_RESULT_AVAIL_IRQ, Crypto)  // CRYPTO result available interupt event
INT(INT_DMA_DONE_COMB, UDMA)  // Combined DMA done
INT(INT_DMA_ERR, UDMAErr)  // DMA bus error
INT(INT_FLASH, Flash)  // FLASH controller error event
INT(INT_SWEV0, SWEvent0)  // Software event 0
INT(INT_AUX_COMB, AUX)  // AUX combined event
INT(INT_AON_PROG0, AONProg)  // AON programmable event 0
INT(INT_PROG0, DynProg)  // Programmable Interrupt 0
INT(INT_AUX_COMPA, AUXCompA)  // AUX Compare A event
INT(INT_AUX_ADC_IRQ, AUXADC)  // AUX ADC interrupt event
INT(INT_TRNG_IRQ, TRNG)  // TRNG Interrupt event

// These are handled specially in startup.c
//INT(INT_HARD_FAULT, HardFault)  // Hard Fault
//INT(INT_PENDSV, PendSVFault)  // Pending Service Call (PendSV)
