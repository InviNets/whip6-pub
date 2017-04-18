/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "BaseCompileTimeConfig.h"
#include "NetStackCompileTimeConfig.h"



/**
 * A generic manager for simple UDP sockets.
 *
 * @author Konrad Iwanicki
 */
configuration GenericSimpleUDPSocketManagerPrv
{
    provides
    {
        interface UDPSimpleReceiver[udp_socket_id_t sockId];
        interface UDPSimpleSender[udp_socket_id_t sockId];
    }
    uses
    {
        interface UDPRawReceiver[udp_socket_id_t sockId];
        interface UDPRawSender[udp_socket_id_t sockId];
        interface UDPSocketController[udp_socket_id_t sockId];
    }
}
implementation
{
    enum
    {
        NUM_SOCKETS = uniqueCount("GenericSimpleUDPSocketManagerPrv::Socket"),
    };

    enum
    {
        MAX_BYTES_COPIED_PER_TASK = WHIP6_BASE_MAX_BYTES_PROCESSED_PER_TASK,
    };

    components BoardStartupPub as GlobalMainPrv;
    components GenericRawUDPSocketManagerPrv as RawSocketManagerPrv;
    components new UDPSimpleSocketVirtualizerPrv(
            NUM_SOCKETS,
            MAX_BYTES_COPIED_PER_TASK
    ) as ImplPrv;

    UDPSimpleReceiver = ImplPrv.UDPSimpleReceiver;
    UDPSimpleSender = ImplPrv.UDPSimpleSender;

    ImplPrv.UDPRawReceiver = UDPRawReceiver;
    ImplPrv.UDPRawSender = UDPRawSender;
    ImplPrv.UDPSocketController = UDPSocketController;

    GlobalMainPrv.InitSequence[1] -> ImplPrv;
}
