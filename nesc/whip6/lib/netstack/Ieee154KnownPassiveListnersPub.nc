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
