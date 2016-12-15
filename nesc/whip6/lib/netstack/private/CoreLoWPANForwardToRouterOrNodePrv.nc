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


#include <ipv6/ucIpv6AddressManipulation.h>

//#define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

uint8_t_code NODE_NEXT_HOP_ADDR_8B[8] = {0, 0, 0, 0, 0, 0, 0, 0};

generic module CoreLoWPANForwardToRouterOrNodePrv(uint16_t routerAddrId) {
    provides interface LoWPANSimpleRoutingStrategy;

    provides interface Init;
    uses interface Timer<TMilli, uint32_t> as RouterRetryTimer;
    uses interface ConfigValue<uint32_t> as
        Ipv6RoutingSimpleStrategyRetryRouterAfterMillis @exactlyonce();
}
implementation
{
    whip6_ieee154_addr_t nodeAddr;
    whip6_ieee154_addr_t routerAddr;

    bool canTryRouter = TRUE;

    bool isShort(uint8_t_code *src) {
        int i;
        for (i = 2; i < 8; i++)
            if (src[i] != 0)
                return FALSE;
        return TRUE;
    }

    void setAddress(uint8_t_code *src, whip6_ieee154_addr_t * addr) {
        int i;
        if (isShort(src)) {
            uint8_t_xdata * addrPtr = &(addr->vars.shrt.data[0]);
            addr->mode = IEEE154_ADDR_MODE_SHORT;
            for (i = 0; i < 2; i++) {
                *addrPtr = src[i];
                addrPtr++;
            }
        }
        else {
            uint8_t_xdata * addrPtr = &(addr->vars.ext.data[0]);
            addr->mode = IEEE154_ADDR_MODE_EXT;
            for (i = 0; i < 8; i++) {
                *addrPtr = src[i];
                addrPtr++;
            }
        }
    }

    command error_t Init.init() {
        setAddress(NODE_NEXT_HOP_ADDR_8B, &nodeAddr);

        routerAddr.mode = IEEE154_ADDR_MODE_SHORT;
        routerAddr.vars.shrt.data[0] = (uint8_t)routerAddrId;
        routerAddr.vars.shrt.data[1] = (uint8_t)(routerAddrId >> 8);

        return SUCCESS;
    }

    command void LoWPANSimpleRoutingStrategy.pickFirstRouteLinkLayerAddr(
            whip6_ipv6_out_packet_processing_state_t *outPacket,
            whip6_ipv6_addr_t const *dstAddr,
            whip6_ieee154_addr_t  *llAddr) {
        if (canTryRouter) {
            local_dbg("[IPv6:RoutePick] pickFirstRouteLinkLayerAddr"
                    " - trying router\n");
            whip6_ieee154AddrAnyCpy(&routerAddr, llAddr);
        }
        else {
            local_dbg("[IPv6:RoutePick] pickFirstRouteLinkLayerAddr - "
                    "trying node\n");
            whip6_ieee154AddrAnyCpy(&nodeAddr, llAddr);
        }
    }

    command void LoWPANSimpleRoutingStrategy.pickNextRouteLinkLayerAddr(
            whip6_ipv6_out_packet_processing_state_t *outPacket,
            whip6_ipv6_addr_t const *dstAddr,
            whip6_ieee154_addr_t const *lastLLAddr,
            error_t lastStatus,
            whip6_ieee154_addr_t  *llAddr) {

        if (lastStatus == SUCCESS ||
            whip6_ieee154AddrAnyCmp(lastLLAddr, &nodeAddr) == 0) {

            local_dbg("[IPv6:RoutePick] pickNextRouteLinkLayerAddr"
                    " trying NONE\n");
            whip6_ieee154AddrAnySetNone(llAddr);
            return;
        }

        if (canTryRouter) {
            canTryRouter = FALSE;
            call RouterRetryTimer.startWithTimeoutFromNow(
                call Ipv6RoutingSimpleStrategyRetryRouterAfterMillis.get());
        }
        local_dbg("[IPv6:RoutePick] pickNextRouteLinkLayerAddr"
                " trying node\n");
        whip6_ieee154AddrAnyCpy(&nodeAddr, llAddr);
    }

    event void RouterRetryTimer.fired() {
        canTryRouter = TRUE;
    }
}

#undef local_dbg
