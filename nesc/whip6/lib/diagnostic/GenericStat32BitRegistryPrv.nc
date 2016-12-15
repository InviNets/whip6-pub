/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */




/**
 * An implementation of a generic register of
 * 32-bit statistics.
 *
 * @param num_stats The number of statistics.
 *
 * @author Konrad Iwanicki
 */
generic module GenericStat32BitRegistryPrv(
        uint16_t num_stats
)
{
    provides
    {
        interface Init;
        interface StatsRegistry;
        interface StatsPrinter[uint16_t];
    }
    uses
    {
        interface StatsName[uint16_t];
        interface StatsGetter<uint32_t>[uint16_t];
        interface StatsSetter<uint32_t>[uint16_t];
        interface CommonFormattedTextPrinter;
    }
}
implementation
{
    enum
    {
        NUM_STATS = num_stats,
    };

    static void printFmt(char const * fmt, ...)
    {
        va_list args;
        va_start(args, fmt);
        call CommonFormattedTextPrinter.printFormattedText(fmt, args);
        va_end(args);
    }

    command inline error_t Init.init()
    {
        call StatsRegistry.resetAll();
        return SUCCESS;
    }

    command inline uint16_t StatsRegistry.getNumStats()
    {
        return NUM_STATS;
    }

    command void StatsRegistry.resetAll()
    {
        uint16_t   i;
        for (i = 0; i < NUM_STATS; ++i)
        {
            call StatsSetter.setToDefault[i]();
        }
    }

    command void StatsRegistry.printAll(char const * separator)
    {
        uint16_t   i;
        if (NUM_STATS == 0)
        {
            return;
        }
        if (separator == NULL)
        {
            separator = "\r\n";
        }
        call StatsPrinter.print[0]();
        for (i = 1; i < NUM_STATS; ++i)
        {
            printFmt("%s", separator);
            call StatsPrinter.print[i]();
        }
    }

    command void StatsPrinter.print[uint16_t idx]()
    {
        printFmt(
                "[STAT|%05u|%s|%lu]",
                (unsigned)call StatsName.id[idx](),
                call StatsName.name[idx](),
                (long unsigned)call StatsGetter.get[idx]()
        );
    }

    default command inline void CommonFormattedTextPrinter.printFormattedText(
            const char * fmt,
            va_list args
    )
    {
        vprintf(fmt, args);
    }

    default command inline char const * StatsName.name[uint16_t idx]()
    {
        return NULL;
    }

    default command inline uint16_t StatsName.id[uint16_t idx]()
    {
        return 0xffffUL;
    }

    default command inline uint32_t StatsGetter.get[uint16_t idx]()
    {
        return 0;
    }

    default command inline void StatsSetter.setToDefault[uint16_t idx]()
    {
    }
    
    default command inline void StatsSetter.setToValue[uint16_t idx](uint32_t val)
    {
        (void)val;
    }

}

