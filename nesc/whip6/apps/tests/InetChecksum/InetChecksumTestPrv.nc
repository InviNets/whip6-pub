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


#include <ipv6/ucIpv6Checksum.h>



/**
 * An application testing the functionality
 * related to computing Internet checksums
 * by the microc library.
 *
 * @author Konrad Iwanicki 
 */
module InetChecksumTestPrv
{
    uses interface Boot;
}
implementation
{
    enum
    {
        BUFFER_LENGTH = 2048,
        NUM_IOVEC_ELEMS = 3,
        DEF_IOV_ELEM_SIZE = 512,
    };

    uint8_t_xdata       m_byteArrPtr[BUFFER_LENGTH];
    whip6_iov_blist_t   m_iovElems[NUM_IOVEC_ELEMS];


    uint16_t checksum(uint8_t * ptr, size_t length)
    {
        uint32_t   sum = 0;
        uint16_t   cur = 0;
        size_t     i;

        for (i = 0; i < length; i++)
        {
            //printf(" %02x", (unsigned)ptr[i]);
            if (i % 2 == 0)
            {
                cur |= ((uint16_t)ptr[i]) << 8;
                if (i + 1 == length)
                {
                  goto FINISH;
                }
            }
            else
            {
                cur |= ptr[i];
    FINISH:
                // printf("%u: %u: %lu\n\r", (unsigned)ptr[i], (unsigned)cur, (long unsigned)sum);
                sum += cur;
                // printf("S: %lu\n\r", (long unsigned)res);
                cur = 0;
            }
        }
        while (sum >> 16)
        {
           sum = (sum & 0xffff) + (sum >> 16);
        }
        return (uint16_t)~sum;
    }

    whip6_iov_blist_t * wireIovLen(size_t len)
    {
        uint8_t               i;
        if (len > NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE)
        {
            len = NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE;
        }
        for (i = 0; i < NUM_IOVEC_ELEMS; ++i)
        {
            m_iovElems[i].iov.ptr = &(m_byteArrPtr[i * DEF_IOV_ELEM_SIZE]);
            m_iovElems[i].iov.len = DEF_IOV_ELEM_SIZE;
            if (i == 0)
            {
                m_iovElems[i].prev = NULL;
            }
            else
            {
                m_iovElems[i].prev = &(m_iovElems[i - 1]);
            }
            if (i == NUM_IOVEC_ELEMS - 1)
            {
                m_iovElems[i].next = NULL;
            }
            else
            {
                m_iovElems[i].next = &(m_iovElems[i + 1]);
            }
        }
        if (len == 0 || NUM_IOVEC_ELEMS == 0)
        {
            return NULL;
        }
        i = 0;
        while (len > 0 && i < NUM_IOVEC_ELEMS)
        {
            if (len < DEF_IOV_ELEM_SIZE)
            {
                m_iovElems[i].iov.len = len;
                m_iovElems[i].next = NULL;
                break;
            }
            else
            {
                len -= DEF_IOV_ELEM_SIZE;
                ++i;
            }
        }
        return &(m_iovElems[0]);
    }

    void fillBuffer(size_t len, uint8_t seed)
    {
        size_t i;
        for (i = 0; i < len; ++i)
        {
            uint8_t b = (uint8_t)i + seed;
            m_byteArrPtr[i] = b;
        }
    }

#define CHECK_CS(exp, act) do { \
    if ((exp) != (act)) \
    { \
        printf("ERROR: The actual checksum value, %u, does not match " \
            "the expected one, %u!\n\r", (unsigned)(act), (unsigned)(exp)); \
        return FALSE; \
    } \
} while (0);

#define CHECK_EQ(exp, act) do { \
    if ((exp) != (act)) \
    { \
        printf("ERROR: The actual value, %lu, does not match the expected " \
            "one, %lu!\n\r", (long unsigned)(act), (long unsigned)(exp)); \
        return FALSE; \
    } \
} while (0);

    bool initializeAndFinalize_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;

        whip6_ipv6ChecksumComputationInit(&csComp);
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal = checksum(NULL, 0);
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }

    bool sumOneByte_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;

        m_byteArrPtr[0] = 123;
        whip6_ipv6ChecksumComputationInit(&csComp);
        whip6_ipv6ChecksumComputationProvideWithOneByte(&csComp, m_byteArrPtr[0]);
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal = checksum(m_byteArrPtr, 1);
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }

    bool sumTwoBytes_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;

        m_byteArrPtr[0] = 1;
        m_byteArrPtr[1] = 234;
        whip6_ipv6ChecksumComputationInit(&csComp);
        whip6_ipv6ChecksumComputationProvideWithOneByte(&csComp, m_byteArrPtr[0]);
        whip6_ipv6ChecksumComputationProvideWithOneByte(&csComp, m_byteArrPtr[1]);
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal = checksum(m_byteArrPtr, 2);
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }

    bool sumOddNumberOfBytesByteByByte_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;
        size_t                        i;

        whip6_ipv6ChecksumComputationInit(&csComp);
        for (i = 0; i < ((BUFFER_LENGTH >> 1) << 1) - 1; ++i)
        {
            uint8_t b = (uint8_t)i;
            whip6_ipv6ChecksumComputationProvideWithOneByte(&csComp, b);
            m_byteArrPtr[i] = b;
        }
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal = checksum(m_byteArrPtr, ((BUFFER_LENGTH >> 1) << 1) - 1);
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }

    bool sumEvenNumberOfBytesByteByByte_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;
        size_t                        i;

        whip6_ipv6ChecksumComputationInit(&csComp);
        for (i = 0; i < ((BUFFER_LENGTH >> 1) << 1); ++i)
        {
            uint8_t b = (uint8_t)i;
            whip6_ipv6ChecksumComputationProvideWithOneByte(&csComp, b);
            m_byteArrPtr[i] = b;
        }
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal = checksum(m_byteArrPtr, ((BUFFER_LENGTH >> 1) << 1));
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }

    bool sumOddNumberOfBytesInByteArray_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;

        fillBuffer(((BUFFER_LENGTH >> 1) << 1) - 1, 123);
        whip6_ipv6ChecksumComputationInit(&csComp);
        whip6_ipv6ChecksumComputationProvideWithByteArray(
                &csComp,
                m_byteArrPtr,
                ((BUFFER_LENGTH >> 1) << 1) - 1
        );
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal = checksum(m_byteArrPtr, ((BUFFER_LENGTH >> 1) << 1) - 1);
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }

    bool sumEvenNumberOfBytesInByteArray_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;

        fillBuffer((BUFFER_LENGTH >> 1) << 1, 232);
        whip6_ipv6ChecksumComputationInit(&csComp);
        whip6_ipv6ChecksumComputationProvideWithByteArray(
                &csComp,
                m_byteArrPtr,
                ((BUFFER_LENGTH >> 1) << 1)
        );
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal = checksum(m_byteArrPtr, ((BUFFER_LENGTH >> 1) << 1));
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }

    bool sumOddNumberOfBytesInIoVec_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        iov_blist_iter_t              iovIter;
        whip6_iov_blist_t *           iovList;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;

        fillBuffer((((NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE) >> 1) << 1) - 1, 44);
        iovList = wireIovLen((((NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE) >> 1) << 1) - 1);
        whip6_iovIteratorInitToBeginning(iovList, &iovIter);
        whip6_iovIteratorMoveForward(&iovIter, DEF_IOV_ELEM_SIZE >> 1);
        whip6_ipv6ChecksumComputationInit(&csComp);
        CHECK_EQ(whip6_ipv6ChecksumComputationProvideWithIovAndAdvanceIovIterator(
                &csComp,
                &iovIter,
                ((((NUM_IOVEC_ELEMS - 1) * DEF_IOV_ELEM_SIZE) >> 1) << 1) - 1
        ), ((((NUM_IOVEC_ELEMS - 1) * DEF_IOV_ELEM_SIZE) >> 1) << 1) - 1);
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal =
                checksum(
                        m_byteArrPtr + (DEF_IOV_ELEM_SIZE >> 1),
                        ((((NUM_IOVEC_ELEMS - 1) * DEF_IOV_ELEM_SIZE) >> 1) << 1) - 1
        );
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }

    bool sumEvenNumberOfBytesInIoVec_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        iov_blist_iter_t              iovIter;
        whip6_iov_blist_t *           iovList;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;

        fillBuffer((((NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE) >> 1) << 1), 68);
        iovList = wireIovLen((((NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE) >> 1) << 1));
        whip6_iovIteratorInitToBeginning(iovList, &iovIter);
        whip6_iovIteratorMoveForward(&iovIter, DEF_IOV_ELEM_SIZE >> 1);
        whip6_ipv6ChecksumComputationInit(&csComp);
        CHECK_EQ(whip6_ipv6ChecksumComputationProvideWithIovAndAdvanceIovIterator(
                &csComp,
                &iovIter,
                ((((NUM_IOVEC_ELEMS - 1) * DEF_IOV_ELEM_SIZE) >> 1) << 1)
        ), ((((NUM_IOVEC_ELEMS - 1) * DEF_IOV_ELEM_SIZE) >> 1) << 1));
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal =
                checksum(
                        m_byteArrPtr + (DEF_IOV_ELEM_SIZE >> 1),
                        ((((NUM_IOVEC_ELEMS - 1) * DEF_IOV_ELEM_SIZE) >> 1) << 1)
        );
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }

    bool sumZeroBytesInIoVec_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        iov_blist_iter_t              iovIter;
        whip6_iov_blist_t *           iovList;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;

        fillBuffer((((NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE) >> 1) << 1) - 1, 77);
        iovList = wireIovLen((((NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE) >> 1) << 1) - 1);
        whip6_iovIteratorInitToBeginning(iovList, &iovIter);
        whip6_iovIteratorMoveForward(&iovIter, DEF_IOV_ELEM_SIZE >> 1);
        whip6_ipv6ChecksumComputationInit(&csComp);
        CHECK_EQ(whip6_ipv6ChecksumComputationProvideWithIovAndAdvanceIovIterator(&csComp, &iovIter, 0), 0);
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal =
                checksum(
                        m_byteArrPtr + (DEF_IOV_ELEM_SIZE >> 1),
                        0
        );
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }


    bool sumPositiveBytesInEmptyIoVec_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        iov_blist_iter_t              iovIter;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;

        fillBuffer((((NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE) >> 1) << 1) - 1, 23);
        wireIovLen((((NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE) >> 1) << 1) - 1);
        whip6_iovIteratorInvalidate(&iovIter);
        whip6_ipv6ChecksumComputationInit(&csComp);
        CHECK_EQ(whip6_ipv6ChecksumComputationProvideWithIovAndAdvanceIovIterator(&csComp, &iovIter, (((NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE) >> 1) << 1) - 1), 0);
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal = checksum(m_byteArrPtr, 0);
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }

    bool sumFewBytesInIoVec_ShouldSucceed()
    {
        ipv6_checksum_computation_t   csComp;
        iov_blist_iter_t              iovIter;
        whip6_iov_blist_t *           iovList;
        ipv6_checksum_t               csActVal;
        ipv6_checksum_t               csExpVal;

        fillBuffer((((NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE) >> 1) << 1), 0xaa);
        iovList = wireIovLen((((NUM_IOVEC_ELEMS * DEF_IOV_ELEM_SIZE) >> 1) << 1));
        whip6_iovIteratorInitToBeginning(iovList, &iovIter);
        whip6_iovIteratorMoveForward(&iovIter, DEF_IOV_ELEM_SIZE >> 2);
        whip6_ipv6ChecksumComputationInit(&csComp);
        CHECK_EQ(whip6_ipv6ChecksumComputationProvideWithIovAndAdvanceIovIterator(
                &csComp,
                &iovIter,
                DEF_IOV_ELEM_SIZE >> 1
        ), DEF_IOV_ELEM_SIZE >> 1);
        csActVal = whip6_ipv6ChecksumComputationFinalize(&csComp);
        csExpVal =
                checksum(
                        m_byteArrPtr + (DEF_IOV_ELEM_SIZE >> 2),
                        DEF_IOV_ELEM_SIZE >> 1
        );
        CHECK_CS(csExpVal, csActVal);
        return TRUE;
    }

    // ***********************************************************************
    // *                                                                     *
    // *                              M A I N                                *
    // *                                                                     *
    // ***********************************************************************

#define RUN_TEST(test) printf("TEST: " #test "\n\r"); test();
    void runAllTests()
    {
        RUN_TEST(initializeAndFinalize_ShouldSucceed);
        RUN_TEST(sumOneByte_ShouldSucceed);
        RUN_TEST(sumTwoBytes_ShouldSucceed);
        RUN_TEST(sumOddNumberOfBytesByteByByte_ShouldSucceed);
        RUN_TEST(sumEvenNumberOfBytesByteByByte_ShouldSucceed);
        RUN_TEST(sumOddNumberOfBytesInByteArray_ShouldSucceed);
        RUN_TEST(sumEvenNumberOfBytesInByteArray_ShouldSucceed);
        RUN_TEST(sumOddNumberOfBytesInIoVec_ShouldSucceed);
        RUN_TEST(sumEvenNumberOfBytesInIoVec_ShouldSucceed);
        RUN_TEST(sumZeroBytesInIoVec_ShouldSucceed);
        RUN_TEST(sumPositiveBytesInEmptyIoVec_ShouldSucceed);
        RUN_TEST(sumFewBytesInIoVec_ShouldSucceed);
    }

    task void unusedTask()
    {
        // There must be at least one task in each app.
        // Moreover, we call the functions from another place
        // to forbid nesC marking them as static inline.
    }
#undef RUN_TEST
 
    event void Boot.booted()
    {
        runAllTests();
    }

}

