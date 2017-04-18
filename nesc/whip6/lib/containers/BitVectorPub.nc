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
 * A vector of bits with synchronous interfaces.
 *
 * @param size_val The size of the bit vector.
 *
 * @author Konrad Iwanicki
 */
generic module BitVectorPub(size_t size_val)
{
    provides interface Bit[size_t];
}
implementation
{
    enum
    {
        NUM_BITS = size_val,
        NUM_BYTES = (NUM_BITS + 7) >> 3,
    };

    uint8_t m_bitArray[NUM_BYTES];


    command inline bool Bit.isSet[size_t idx]()
    {
        uint8_t  mask = 1 << (idx & 0x07);
        return (m_bitArray[idx >> 3] & mask) != 0;
    }



    command inline bool Bit.isClear[size_t idx]()
    {
        return ! call Bit.isSet[idx]();
    }



    command inline void Bit.set[size_t idx]()
    {
        uint8_t  mask = 1 << (idx & 0x07);
        m_bitArray[idx >> 3] |= mask;
    }



    command inline void Bit.clear[size_t idx]()
    {
        uint8_t  mask = 1 << (idx & 0x07);
        m_bitArray[idx >> 3] &= ~mask;
    }



    command inline void Bit.assignBoolValue[size_t idx](bool val)
    {
        uint8_t mask = 1 << (idx & 0x07);
        if (val)
        {
            m_bitArray[idx >> 3] |= mask;
        }
        else
        {
            m_bitArray[idx >> 3] &= ~mask;
        }
    }



    command inline void Bit.toggleValue[size_t idx]()
    {
        uint8_t mask = 1 << (idx & 0x07);
        if ((m_bitArray[idx >> 3] & mask) != 0)
        {
            m_bitArray[idx >> 3] &= ~mask;
        }
        else
        {
            m_bitArray[idx >> 3] |= mask;
        }
    }
}
