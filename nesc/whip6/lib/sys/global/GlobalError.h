/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
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

#ifndef TINY_ERROR_H_INCLUDED
#define TINY_ERROR_H_INCLUDED

/**
 * @author Phil Levis
 * @author David Gay
 * @author Przemyslaw Horban
 * Revision:  $Revision: 1.12 $
 *
 * Defines global error codes for error_t in TinyOS.
 */

enum {
  SUCCESS        =  0,
  FAIL           =  1,           // Generic condition: backwards compatible
  ESIZE          =  2,           // Parameter passed in was too big.
  ECANCEL        =  3,           // Operation cancelled by a call.
  EOFF           =  4,           // Subsystem is not active
  EBUSY          =  5,           // The underlying system is busy; retry later
  EINVAL         =  6,           // An invalid parameter was passed
  ERETRY         =  7,           // A rare and transient failure: can retry
  ERESERVE       =  8,           // Reservation required before usage
  EALREADY       =  9,           // The device state you are requesting is already set
  ENOMEM         = 10,           // Out of memory
  ENOACK         = 11,           // A packet was not acknowledged
  EINTERNAL      = 12,           // Internal error
  ESTATE         = 13,           // State error
  ENOSYS         = 14,           // Not implemented
  ENOROUTE       = 15,           // No valid route
  EIO            = 16,           // I/O error (e.g. device not responded)
  ENOSPC         = 17,           // No space left on device
  ENOTFOUND      = 18,           // Object not found
  ELAST          = 18            // Last enum value
};

#ifdef NESC

typedef uint8_t error_t @combine("ecombine");

error_t ecombine(error_t r1, error_t r2)
/* Returns: r1 if r1 == r2, FAIL otherwise. This is the standard error
     combination function: two successes, or two identical errors are
     preserved, while conflicting errors are represented by FAIL.
*/
{
  return r1 == r2 ? r1 : (uint8_t)FAIL;
}

#else  // NESC not defined

typedef uint8_t error_t;

#endif  // NESC

#endif
