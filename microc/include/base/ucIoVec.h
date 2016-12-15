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

#ifndef __WHIP6_MICROC_BASE_IO_VEC_H__
#define __WHIP6_MICROC_BASE_IO_VEC_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the I/O vector type and
 * corresponding operations.
 *
 */

#include <base/ucTypes.h>

/**
 * An element of an I/O vector.
 */
typedef struct iov_elem_s
{
    uint8_t MCS51_STORED_IN_RAM *   ptr;
    size_t                          len;
} iov_elem_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(iov_elem_t)


struct iov_blist_s;
typedef struct iov_blist_s iov_blist_t;
MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(iov_blist_t)

/**
 * A doubly-linked list of I/O vector elements.
 */
struct iov_blist_s
{
    iov_elem_t                          iov;
    iov_blist_t MCS51_STORED_IN_RAM *   next;
    iov_blist_t MCS51_STORED_IN_RAM *   prev;
};


struct iov_blist_iter_s;
typedef struct iov_blist_iter_s iov_blist_iter_t;
MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(iov_blist_iter_t)

/**
 * An iterator over a list of I/O vector elements.
 */
struct iov_blist_iter_s
{
    iov_blist_t MCS51_STORED_IN_RAM *   currElem;
    size_t                              offset;
};

/**
 * Returns the total length of an I/O vector.
 * @param iovList The I/O vector for which
 *   the length is to be returned.
 * @return The total length of the I/O vector.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX size_t whip6_iovGetTotalLength(
        iov_blist_t MCS51_STORED_IN_RAM const * iovList
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Compares up to 255 bytes from a buffer with
 * an I/O vector.
 * @param iovList The I/O vector to compare.
 * @param iovOffset The offset within the I/O
 *   vector from which to compare.
 * @param bufPtr The buffer to compare.
 * @param bufLen The number of bytes to compare.
 * @return Zero if at the given offset the I/O
 *   vector contains the given number of bytes
 *   that are equal to the bytes in the buffer;
 *   a negative value if the bytes in the I/O
 *   vector are lexicographically less; or
 *   a positive value otherwise.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX int8_t whip6_iovShortCompare(
        iov_blist_t MCS51_STORED_IN_RAM const * iovList,
        size_t iovOffset,
        uint8_t MCS51_STORED_IN_RAM const * bufPtr,
        uint8_t bufLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Writes up to 255 bytes from a buffer to an
 * I/O vector.
 * @param iovList The I/O vector to which to write.
 * @param iovOffset The offset within the I/O
 *   vector at which to write.
 * @param bufPtr The buffer from which to write.
 * @param bufLen The number of bytes to write.
 * @return The number of written bytes, which
 *   may be smaller than the buffer length if
 *   the I/O vector is shorter.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_iovShortWrite(
        iov_blist_t MCS51_STORED_IN_RAM * iovList,
        size_t iovOffset,
        uint8_t MCS51_STORED_IN_RAM const * bufPtr,
        uint8_t bufLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Reads up to 255 bytes from an I/O vector
 * to a buffer.
 * @param iovList The I/O vector from which to read.
 * @param iovOffset The offset within the I/O
 *   vector at which to read.
 * @param bufPtr The buffer to which to read.
 * @param bufLen The number of bytes to read.
 * @return The number of read bytes, which
 *   may be smaller than the buffer length if
 *   the I/O vector is shorter.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_iovShortRead(
        iov_blist_t MCS51_STORED_IN_RAM const * iovList,
        size_t iovOffset,
        uint8_t MCS51_STORED_IN_RAM * bufPtr,
        uint8_t bufLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Compares parts of two I/O vectors.
 * @param iovList1 The first I/O vector.
 * @param iovList2 The second I/O vector.
 * @param iovOffset1 The offset in the first I/O vector.
 * @param iovOffset2 The offset in the second I/O vector.
 * @param iovLength The number of bytes to compare.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX int8_t whip6_iovCompare(
        iov_blist_t MCS51_STORED_IN_RAM const * iovList1,
        iov_blist_t MCS51_STORED_IN_RAM const * iovList2,
        size_t iovOffset1,
        size_t iovOffset2,
        size_t iovLength
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;



/**
 * Initializes an I/O vector iterator to the
 * beginning of a given I/O vector.
 * @param iovList The I/O vector for which
 *   the iterator is to be initialized.
 * @param iovIter The iterator to be initialized.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_iovIteratorInitToBeginning(
        iov_blist_t MCS51_STORED_IN_RAM * iovList,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Invalidates an I/O vector iterator.
 * @param iovIter The iterator to be invalidated.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_iovIteratorInvalidate(
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Clones an I/O vector iterator.
 * @param srcIovIter The source iterator to be cloned.
 * @param dstIovIter The destinationiterator to
 *   which the source one will be cloned.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_iovIteratorClone(
        iov_blist_iter_t const * srcIovIter,
        iov_blist_iter_t * dstIovIter
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Checks if an I/O vector iterator is valid.
 * @param iovIter The iterator.
 * @return Zero if the iterator is not valid
 *   or nonzero otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_iovIteratorIsValid(
        iov_blist_iter_t const * iovIter
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Moves an I/O vector iterator forward by a given number
 * of bytes.
 * @param iovIter The iterator.
 * @param offset The number of bytes by which the
 *   iterator will be moved.
 * @return The actual number of bytes the iterator
 *   has been moved. It may be smaller than the
 *   given number if the I/O vector is shorter,
 *   in which case the iterator will not be valid.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX size_t whip6_iovIteratorMoveForward(
        iov_blist_iter_t * iovIter,
        size_t offset
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Moves an I/O vector iterator backward by a given number
 * of bytes.
 * @param iovIter The iterator.
 * @param offset The number of bytes by which the
 *   iterator will be moved.
 * @return The actual number of bytes the iterator
 *   has been moved. It may be smaller than the
 *   given number if the I/O vector is shorter,
 *   in which case the iterator will not be valid.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX size_t whip6_iovIteratorMoveBackward(
        iov_blist_iter_t * iovIter,
        size_t offset
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Reads into a buffer a given number of bytes
 * from an offset of an I/O vector given by
 * the iterator.
 * @param iovIter The iterator.
 * @param bufPtr A pointer to the buffer into
 *   which the bytes will be read.
 * @param bufLen The maximal number of bytes
 *   to be read.
 * @return The actual number of bytes read. The
 *   value may be smaller than the maximal one,
 *   because the I/O vector may be shorter.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX size_t whip6_iovIteratorReadAndMoveForward(
        iov_blist_iter_t * iovIter,
        uint8_t MCS51_STORED_IN_RAM * bufPtr,
        size_t bufLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Writes from a buffer a given number of bytes
 * at an offset of an I/O vector given by an iterator.
 * @param iovIter The iterator.
 * @param bufPtr A pointer to the buffer from
 *   which the bytes will be written.
 * @param bufLen The maximal number of bytes
 *   to be write.
 * @return The actual number of bytes written. The
 *   value may be smaller than the maximal one,
 *   because the I/O vector may be shorter.
 *
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX size_t whip6_iovIteratorWriteAndMoveForward(
        iov_blist_iter_t * iovIter,
        uint8_t MCS51_STORED_IN_RAM const * bufPtr,
        size_t bufLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Copies bytes from one I/O vector iterator to
 * another I/O vector iterator. It is assumed that
 * the iterators point to different I/O vectors.
 * @param srcIovIter The source I/O vector iterator.
 * @param dstIovIter The destination I/O vector iterator.
 * @param maxLen The maximal number of bytes to copy.
 * @return The actual number of bytes copied. The
 *   value may be smaller than the maximal one,
 *   because the I/O vectors may be shorter.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX size_t whip6_iovIteratorCopyBytesAndMoveForward(
        iov_blist_iter_t * srcIovIter,
        iov_blist_iter_t * dstIovIter,
        size_t maxLen
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


/**
 * Serializes a byte into an I/O vector at a
 * place pointed to by a given iterator and advances
 * the iterator.
 * @param iovIter The iterator.
 * @param b The byte to be serialized.
 * @return Zero if the byte was serialized correctly,
 *   otherwise the number of bytes by which the I/O vector
 *   would have to be extended to have enough capacity
 *   for the byte.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX size_t whip6_iovIteratorSerializeUInt8AndMoveForward(
        iov_blist_iter_t * iovIter,
        uint8_t b
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Serializes two bytes into an I/O vector at a
 * place pointed to by a given iterator and advances
 * the iterator.
 * @param iovIter The iterator.
 * @param w A word (the two bytes) to be serialized.
 * @return Zero if the word was serialized correctly,
 *   otherwise the number of bytes by which the I/O vector
 *   would have to be extended to have enough capacity
 *   for the word.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX size_t whip6_iovIteratorSerializeUInt16AndMoveForward(
        iov_blist_iter_t * iovIter,
        uint16_t w
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Serializes four bytes into an I/O vector at a
 * place pointed to by a given iterator and advances
 * the iterator.
 * @param iovIter The iterator.
 * @param d A double word (the four bytes) to be serialized.
 * @return Zero if the double word was serialized correctly,
 *   otherwise the number of bytes by which the I/O vector
 *   would have to be extended to have enough capacity
 *   for the double word.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX size_t whip6_iovIteratorSerializeUInt32AndMoveForward(
        iov_blist_iter_t * iovIter,
        uint32_t d
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;


#include <base/detail/ucIoVecImpl.h>

#endif /* __WHIP6_MICROC_BASE_IO_VEC_H__ */
