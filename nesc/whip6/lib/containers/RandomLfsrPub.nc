/*
 * Copyright (c) 2000-2003 The Regents of the University of California.
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704. Attention: Intel License Inquiry.
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

/*
 *
 * Authors: Alec Woo, David Gay, Philip Levis
 * Date last modified: 8/8/05
 *
 */

/**
 * This is a 16 bit Linear Feedback Shift Register pseudo random number
   generator. It is faster than the MLCG generator, but the numbers generated
 * have less randomness.
 *
 * NOTE: It is guaranteed that 32bit state is != 0.
 *
 * @author Alec Woo
 * @author David Gay
 * @author Philip Levis
 * @date August 8 2005
 */

generic module RandomLfsrPub()
{
    provides interface ParameterInit<uint16_t> as SeedInit;
    provides interface Random;
    provides interface RandomState;
}
implementation
{
    uint16_t shiftReg;
    uint16_t mask;

    command error_t SeedInit.init(uint16_t s)
    {
        shiftReg = 119 * 119 * (s + 1);
        mask = 137 * 29 * (s + 1);
        return SUCCESS;
    }

    command uint16_t Random.rand16()
    {
        bool       endbit;
        uint16_t   tmpShiftReg;

        tmpShiftReg = shiftReg;
        endbit = ((tmpShiftReg & 0x8000U) != 0);
        tmpShiftReg <<= 1;
        if (endbit)
        {
            tmpShiftReg ^= 0x100bU;
        }
        tmpShiftReg++;
        shiftReg = tmpShiftReg;
        tmpShiftReg = tmpShiftReg ^ mask;
        return tmpShiftReg;
    }

    command uint32_t Random.rand32()
    {
        return (((uint32_t)call Random.rand16()) << 16) | (call Random.rand16());
    }

    command uint32_t RandomState.getState() {
        uint32_t s = shiftReg;
        s <<= 16;
        s += mask;
        return s;
    }

    command void RandomState.setState(uint32_t state) {
        mask = (uint16_t)(state & 0xFFFF);
        state >>= 16;
        shiftReg = (uint16_t)(state & 0xFFFF);
    }
}

