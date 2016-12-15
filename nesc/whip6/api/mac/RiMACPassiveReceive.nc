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


interface RiMACPassiveReceive {
    /**
     * Enables passive listening for frames. This means that the radio will be turned on,
     * and if a valid ieee154 frame arrives, it will be received.
     *
     * WARNING: The listening will start after the next rimac beacon. There might be a few
     * second delay (~3s).
     *
     * Note, that the other node must be aware that this node is a passive listner.
     * You can use:
     *
     * components new ThisIeee154ShortAddrAlwaysListensPrv(SHRT_ADDR);
     * components new ThisIeee154ExtAddrAlwaysListensPrv(...);
     *
     * to let it know about passive listners during compile time.
     */
    command void enablePassive();


    /**
     * Immidately disables passive listening. However if a frame was currently being
     * received while this call was made, then the frame might still be processed by
     * the network stack.
     */
    command void disablePassive();
}
