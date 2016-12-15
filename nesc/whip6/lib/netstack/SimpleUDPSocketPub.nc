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
 * A simple UDP socket.
 *
 * @author Konrad Iwanicki
 */
generic configuration SimpleUDPSocketPub()
{
    provides
    {
        interface UDPSocketController;
        interface UDPSimpleReceiver;
        interface UDPSimpleSender;
    }
}
implementation
{
    enum
    {
        SOCKET_IDX = unique("GenericSimpleUDPSocketManagerPrv::Socket"),
    };

    components new RawUDPSocketPub() as RawSocketPrv;
    components GenericSimpleUDPSocketManagerPrv as ManagerPrv;

    UDPSocketController = RawSocketPrv.UDPSocketController;
    UDPSimpleReceiver = ManagerPrv.UDPSimpleReceiver[SOCKET_IDX];
    UDPSimpleSender = ManagerPrv.UDPSimpleSender[SOCKET_IDX];

    ManagerPrv.UDPSocketController[SOCKET_IDX] -> RawSocketPrv;
    ManagerPrv.UDPRawReceiver[SOCKET_IDX] -> RawSocketPrv;
    ManagerPrv.UDPRawSender[SOCKET_IDX] -> RawSocketPrv;
}

