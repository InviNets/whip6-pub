/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */




/**
 * A raw UDP socket.
 *
 * @author Konrad Iwanicki
 */
generic configuration RawUDPSocketPub()
{
    provides
    {
        interface UDPSocketController;
        interface UDPRawReceiver;
        interface UDPRawSender;
    }
}
implementation
{
    enum
    {
        SOCKET_IDX = unique("GenericRawUDPSocketManagerPrv::Socket"),
    };

    components GenericRawUDPSocketManagerPrv as ManagerPrv;

    UDPSocketController = ManagerPrv.UDPSocketController[SOCKET_IDX];
    UDPRawReceiver = ManagerPrv.UDPRawReceiver[SOCKET_IDX];
    UDPRawSender = ManagerPrv.UDPRawSender[SOCKET_IDX];
}
