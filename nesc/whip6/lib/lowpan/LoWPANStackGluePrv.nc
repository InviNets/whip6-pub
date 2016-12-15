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
 * A glue module for the 6LoWPAN stack.
 *
 * @author Konrad Iwanicki
 */
generic module LoWPANStackGluePrv(
)
{
    provides
    {
        interface SynchronousStarter;
        interface LoWPANIPv6PacketAcceptor @exactlyonce();
    }
    uses
    {
        interface SynchronousStarter as DefragmenterStarter @exactlyonce();
        interface SynchronousStarter as ForwarderStarter @exactlyonce();
        interface SynchronousStarter as FragmenterStarter @exactlyonce();
        interface LoWPANDefragmenter @exactlyonce();
        interface StatsIncrementer<uint8_t> as NumPacketsPassedForAcceptanceStat;
    }
}
implementation
{
    command error_t SynchronousStarter.start()
    {
        error_t status;
        status = call DefragmenterStarter.start();
        if (status != SUCCESS)
        {
            // printf("%s, %d\r\n", __FILE__, __LINE__);
            return status;
        }
        status = call FragmenterStarter.start();
        if (status != SUCCESS)
        {
            // printf("%s, %d\r\n", __FILE__, __LINE__);
            return status;
        }
        status = call ForwarderStarter.start();
        if (status != SUCCESS)
        {
            // printf("%s, %d\r\n", __FILE__, __LINE__);
            return status;
        }
        return SUCCESS;
    }



    event inline void LoWPANDefragmenter.defragmentingIpv6PacketFinished(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * lastLinkAddr
    )
    {
        call NumPacketsPassedForAcceptanceStat.increment(1);
        signal LoWPANIPv6PacketAcceptor.acceptedIpv6PacketForProcessing(
                packet,
                lastLinkAddr
        );
    }



    default command inline void NumPacketsPassedForAcceptanceStat.increment(uint8_t val)
    {
    }
}

