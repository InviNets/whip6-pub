/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ipv6/ucIpv6GenericInterfaceStateManipulation.h>
#include <ipv6/ucIpv6GenericInterfaceStateTypes.h>



/**
 * A glue module for the generic IPv6 stack.
 *
 * @param num_ifaces The number of network interfaces.
 *
 * @author Konrad Iwanicki
 */
generic module GenericIPv6StackGluePrv(
        ipv6_net_iface_id_t num_ifaces
)
{
    provides
    {
        interface Init;
        interface SynchronousStarter as AllStarter;
    }
    uses
    {
        interface Init as IfaceInit[ipv6_net_iface_id_t ifaceId];
        interface SynchronousStarter as IfaceStarter[ipv6_net_iface_id_t ifaceId];
        interface IPv6InterfaceStateProvider as IfaceStateProvider[ipv6_net_iface_id_t ifaceId];
    }
}
implementation
{

    enum
    {
        NUM_IFACES = num_ifaces,
    };


// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

    command error_t Init.init()
    {
        whip6_ipv6_net_iface_generic_state_t *   currIfacePtr;
        whip6_ipv6_net_iface_generic_state_t *   otherIfacePtr;
        ipv6_net_iface_id_t                      ifaceId;
        error_t                                  status;

        // Generic collective initialization.
        currIfacePtr = call IfaceStateProvider.getInterfaceStatePtr[0]();
        if (currIfacePtr == NULL)
        {
            return ESTATE;
        }
        whip6_ipv6InterfaceSetPrevInterface(currIfacePtr, NULL);
        whip6_ipv6InterfaceSetIndex(currIfacePtr, 0);
        whip6_ipv6InterfaceClearFlags(currIfacePtr);
        for (ifaceId = 1; ifaceId < NUM_IFACES; ++ifaceId)
        {
            otherIfacePtr = call IfaceStateProvider.getInterfaceStatePtr[ifaceId]();
            whip6_ipv6InterfaceSetNextInterface(currIfacePtr, otherIfacePtr);
            whip6_ipv6InterfaceSetPrevInterface(otherIfacePtr, currIfacePtr);
            whip6_ipv6InterfaceSetIndex(otherIfacePtr, ifaceId);
            whip6_ipv6InterfaceClearFlags(otherIfacePtr);
            currIfacePtr = otherIfacePtr;
        }
        whip6_ipv6InterfaceSetNextInterface(currIfacePtr, NULL);

        // Interface-specific initialization.
        for (ifaceId = 0; ifaceId < NUM_IFACES; ++ifaceId)
        {
            status = call IfaceInit.init[ifaceId]();
            if (status != SUCCESS)
            {
                return status;
            }
        }

        return SUCCESS;
    }



    command error_t AllStarter.start()
    {
        ipv6_net_iface_id_t   ifaceId;
        error_t               status;

        for (ifaceId = 0; ifaceId < NUM_IFACES; ++ifaceId)
        {
            status = call IfaceStarter.start[ifaceId]();

            local_dbg("[IPv6:Glue] Status of starting interface %u: %u.\r\n",
                (unsigned)ifaceId, (unsigned)status);

            if (status != SUCCESS && status != EALREADY)
            {
                return status;
            }
        }
        return SUCCESS;
    }



    default command inline error_t IfaceInit.init[ipv6_net_iface_id_t ifaceId]()
    {
        return FAIL;
    }



    default command inline error_t IfaceStarter.start[ipv6_net_iface_id_t ifaceId]()
    {
        return FAIL;
    }



    default command inline whip6_ipv6_net_iface_generic_state_t * IfaceStateProvider.getInterfaceStatePtr[ipv6_net_iface_id_t ifaceId]()
    {
        return NULL;
    }

#undef local_dbg
}
