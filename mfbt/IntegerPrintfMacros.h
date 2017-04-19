/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set ts=8 sts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Implements the C99 <inttypes.h> interface. */

#ifndef mozilla_IntegerPrintfMacros_h_
#define mozilla_IntegerPrintfMacros_h_

/*
 * These macros should not be used with the NSPR printf-like functions or their
 * users, e.g. mozilla/Logging.h.  If you need to use NSPR's facilities, see the
 * comment on supported formats at the top of nsprpub/pr/include/prprf.h.
 */

/*
 * scanf is a footgun: if the input number exceeds the bounds of the target
 * type, behavior is undefined (in the compiler sense: that is, this code
 * could overwrite your hard drive with zeroes):
 *
 *   uint8_t u;
 *   sscanf("256", "%" SCNu8, &u); // BAD
 *
 * For this reason, *never* use the SCN* macros provided by this header!
 */

#include <inttypes.h>

/*
 * Fix up Android's broken [u]intptr_t inttype macros. Android's PRI*PTR
 * macros are defined as "ld", but sizeof(long) is 8 and sizeof(intptr_t)
 * is 4 on 32-bit Android. TestTypeTraits.cpp asserts that these new macro
 * definitions match the actual type sizes seen at compile time.
 */
#if defined(ANDROID) && !defined(__LP64__)
#  undef  PRIdPTR      /* intptr_t  */
#  define PRIdPTR "d"  /* intptr_t  */
#  undef  PRIiPTR      /* intptr_t  */
#  define PRIiPTR "i"  /* intptr_t  */
#  undef  PRIoPTR      /* uintptr_t */
#  define PRIoPTR "o"  /* uintptr_t */
#  undef  PRIuPTR      /* uintptr_t */
#  define PRIuPTR "u"  /* uintptr_t */
#  undef  PRIxPTR      /* uintptr_t */
#  define PRIxPTR "x"  /* uintptr_t */
#  undef  PRIXPTR      /* uintptr_t */
#  define PRIXPTR "X"  /* uintptr_t */
#endif

/* Fix issues with the 10.4 SDK using weird printf macros but not working
   properly with gcc-4.8. This causes failures in tests/coverage/simple.js
   and other less visible places (i.e., using %qu instead of %llu). */

#define __104PRI_64_LENGTH_MODIFIER__ "ll"
#undef PRId64
#  define PRId64        __104PRI_64_LENGTH_MODIFIER__ "d"
#undef PRIi64
#  define PRIi64        __104PRI_64_LENGTH_MODIFIER__ "i"
#undef PRIo64
#  define PRIo64        __104PRI_64_LENGTH_MODIFIER__ "o"
#undef PRIu64
#  define PRIu64        __104PRI_64_LENGTH_MODIFIER__ "u"
#undef PRIx64
#  define PRIx64        __104PRI_64_LENGTH_MODIFIER__ "x"
#undef PRIX64
#  define PRIX64        __104PRI_64_LENGTH_MODIFIER__ "X"

#endif  /* mozilla_IntegerPrintfMacros_h_ */
