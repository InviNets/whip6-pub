/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


typedef bool bool_disjunction @combine("bool_disjunction_combine");

inline bool_disjunction bool_disjunction_combine(bool_disjunction r1, bool_disjunction r2)
{
  return r1 || r2;
}

interface Ieee154KnownPassiveListners {
    /**
     * Should return TRUE if the addr is a known passive listner
     * (generally a node connected to an unlimited power source).
     */
    command bool_disjunction isPassiveListner(whip6_ieee154_addr_t const *addr);
}
