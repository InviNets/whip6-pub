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

