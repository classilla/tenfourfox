# -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifdef __i386__
#include "os_Darwin_x86.s"

	.align 4
	.globl _TenFourFoxAtomicSet
_TenFourFoxAtomicSet:
	movl 4(%esp), %ecx
	movl 8(%esp), %eax
	xchgl %eax, (%ecx)
	ret

#elif defined(__x86_64__)
#include "os_Darwin_x86_64.s"
#elif defined(__ppc__)
#include "os_Darwin_ppc.s"

	.align 5
	.globl _TenFourFoxAtomicSet

# This exactly emulates __sync_lock_test_and_set() on gcc 4.0.1.
# In fact, it's mostly the same code: gcc.gnu.org/ml/gcc/2008-09/msg00038.html
# PRInt32 TenFourFoxAtomicSet(PRInt32 *ptr, PRInt32 value);
# However, the browser does not appear to need any read/write barriers, so
# we observe great justice/performance with this very tight routine.

_TenFourFoxAtomicSet:
	mr r6, r3

tryhardforlock:
	lwarx r3, 0, r6
	stwcx. r4, 0, r6
	bne- tryhardforlock

# leave r3 where it is
	blr

# Sync-less atomic add (TenFourFox issue 205).

	.align 5
	.globl _TenFourFoxAtomicAdd

_TenFourFoxAtomicAdd:
	lwarx r5, 0, r3
	add r0, r4, r5
	stwcx. r0, 0, r3
	bne- _TenFourFoxAtomicAdd

	mr r3, r0
	blr

#endif
