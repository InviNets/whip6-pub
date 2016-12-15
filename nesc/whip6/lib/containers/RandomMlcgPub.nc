/*
 * Copyright (c) 2002-2005 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the
 * distribution.
 * - Neither the name of the University of California nor the names of
 * its contributors may be used to endorse or promote products derived
 * from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */

/** This code is a fast implementation of the Park-Miller Minimal Standard
 * Generator for pseudo-random numbers. It uses the 32 bit multiplicative
 * linear congruential generator,
 *
 * S' = (A x S) mod (2^31 - 1)
 *
 * for A = 16807.
 *
 *
 * @author Barbara Hohlt
 * @date March 1 2005
 */

module RandomMlcgPub
{
    provides interface ParameterInit<uint16_t> as SeedInit;
    provides interface Random;
}
implementation
{
    uint32_t   seed;

    command error_t SeedInit.init(uint16_t s)
    {
        atomic seed = (uint32_t)(s + 1);
        return SUCCESS;
    }

    command uint32_t Random.rand32()
    {
        uint32_t mlcg,p,q;
        uint64_t tmpseed;

        tmpseed = (uint64_t)33614U * (uint64_t)seed;
        q = tmpseed; /* low */
        q = q >> 1;
        p = tmpseed >> 32 ; /* hi */
        mlcg = p + q;
        if (mlcg & 0x80000000UL)
        {
            mlcg = mlcg & 0x7FFFFFFFUL;
            mlcg++;
        }
        seed = mlcg;
        return mlcg;
    }

    command uint16_t Random.rand16()
    {
        return (uint16_t)call Random.rand32();
    }

}

