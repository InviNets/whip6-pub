/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <uart_serial_stdio.h>

#ifndef BANKED_CALLS_STATS_FREQUENCY
#define BANKED_CALLS_STATS_FREQUENCY 2048
#endif

/**
 * A component that causes printing statistics about banked calls. They are
 * printed periodically using UART.
 *
 * @author Michał Ciszewski <mc305195@students.mimuw.edu.pl>
 */
module BankedCallsStatsPrinterPub
{
   provides interface Init;
   uses interface Timer<TMilli, uint32_t>;
}
implementation
{
   extern volatile uint32_t_xdata stats_pure_banked_calls @C();
   extern volatile uint32_t_xdata stats_fake_banked_calls @C();
   extern volatile uint32_t_xdata stats_common_banked_calls @C();

   command error_t Init.init()
   {
      call Timer.startWithTimeoutFromNow(BANKED_CALLS_STATS_FREQUENCY);
      return SUCCESS;
   }

   event void Timer.fired()
   {
      uart_printf("%lu,%lu,%lu\n\r", stats_pure_banked_calls,
         stats_fake_banked_calls, stats_common_banked_calls);
      call Timer.startWithTimeoutFromLastTrigger(BANKED_CALLS_STATS_FREQUENCY);
   }
}
