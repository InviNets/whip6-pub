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
 * Helper interface for determining busy state of IO channels.
 *
 * Events should be generated when the ready-state of a channel changes.
 * It is allowed (but discouraged) to generate the same events many
 * times in a row.
 *
 * At the beginning it is assumed that all channels are busy
 * if the interface is used for reading and ready if the interface
 * is used for writing.
 *
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */
interface IOFlowControlHelper {
    command uint8_t maxReadyChannels();

    /*
     * Fills the array with the numbers of channels which are ready.
     * The array must be at least maxReadyChannels() long. Returns
     * the number of ready channels.
     */
    command uint8_t getReadyChannels(uint8_t_xdata* buf);

    event void channelReady(uint8_t num);
    event void channelBusy(uint8_t num);
}
