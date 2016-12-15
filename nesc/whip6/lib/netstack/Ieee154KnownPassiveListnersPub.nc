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
 * All information about known passive listners will be combined
 * through this component.
 */

configuration Ieee154KnownPassiveListnersPub
{
    provides interface Ieee154KnownPassiveListners as PassiveListnersInfo;
    uses interface Ieee154KnownPassiveListners as PassiveListnersConnect;
}
implementation
{
    PassiveListnersInfo = PassiveListnersConnect;
}

