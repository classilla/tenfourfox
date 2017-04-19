/* -*- Mode: asm -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

        .text
        .globl _SharedStub



       .if     3 < 10
        .globl  __ZN14nsXPTCStubBase5Stub3Ev
        .align  2
__ZN14nsXPTCStubBase5Stub3Ev:
        addi    r12,   0,3
        b       _SharedStub
        .elseif 3 < 100
        .globl  __ZN14nsXPTCStubBase6Stub3Ev
        .align  2
__ZN14nsXPTCStubBase6Stub3Ev:
        addi    r12,   0,3
        b       _SharedStub
        .elseif 3 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub3Ev
        .align  2
__ZN14nsXPTCStubBase7Stub3Ev:
        addi    r12,   0,3
        b       _SharedStub
        .else
        .err    "Stub3 >= 1000 not yet supported."
        .endif

       .if     4 < 10
        .globl  __ZN14nsXPTCStubBase5Stub4Ev
        .align  2
__ZN14nsXPTCStubBase5Stub4Ev:
        addi    r12,   0,4
        b       _SharedStub
        .elseif 4 < 100
        .globl  __ZN14nsXPTCStubBase6Stub4Ev
        .align  2
__ZN14nsXPTCStubBase6Stub4Ev:
        addi    r12,   0,4
        b       _SharedStub
        .elseif 4 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub4Ev
        .align  2
__ZN14nsXPTCStubBase7Stub4Ev:
        addi    r12,   0,4
        b       _SharedStub
        .else
        .err    "Stub4 >= 1000 not yet supported."
        .endif

       .if     5 < 10
        .globl  __ZN14nsXPTCStubBase5Stub5Ev
        .align  2
__ZN14nsXPTCStubBase5Stub5Ev:
        addi    r12,   0,5
        b       _SharedStub
        .elseif 5 < 100
        .globl  __ZN14nsXPTCStubBase6Stub5Ev
        .align  2
__ZN14nsXPTCStubBase6Stub5Ev:
        addi    r12,   0,5
        b       _SharedStub
        .elseif 5 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub5Ev
        .align  2
__ZN14nsXPTCStubBase7Stub5Ev:
        addi    r12,   0,5
        b       _SharedStub
        .else
        .err    "Stub5 >= 1000 not yet supported."
        .endif

       .if     6 < 10
        .globl  __ZN14nsXPTCStubBase5Stub6Ev
        .align  2
__ZN14nsXPTCStubBase5Stub6Ev:
        addi    r12,   0,6
        b       _SharedStub
        .elseif 6 < 100
        .globl  __ZN14nsXPTCStubBase6Stub6Ev
        .align  2
__ZN14nsXPTCStubBase6Stub6Ev:
        addi    r12,   0,6
        b       _SharedStub
        .elseif 6 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub6Ev
        .align  2
__ZN14nsXPTCStubBase7Stub6Ev:
        addi    r12,   0,6
        b       _SharedStub
        .else
        .err    "Stub6 >= 1000 not yet supported."
        .endif

       .if     7 < 10
        .globl  __ZN14nsXPTCStubBase5Stub7Ev
        .align  2
__ZN14nsXPTCStubBase5Stub7Ev:
        addi    r12,   0,7
        b       _SharedStub
        .elseif 7 < 100
        .globl  __ZN14nsXPTCStubBase6Stub7Ev
        .align  2
__ZN14nsXPTCStubBase6Stub7Ev:
        addi    r12,   0,7
        b       _SharedStub
        .elseif 7 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub7Ev
        .align  2
__ZN14nsXPTCStubBase7Stub7Ev:
        addi    r12,   0,7
        b       _SharedStub
        .else
        .err    "Stub7 >= 1000 not yet supported."
        .endif

       .if     8 < 10
        .globl  __ZN14nsXPTCStubBase5Stub8Ev
        .align  2
__ZN14nsXPTCStubBase5Stub8Ev:
        addi    r12,   0,8
        b       _SharedStub
        .elseif 8 < 100
        .globl  __ZN14nsXPTCStubBase6Stub8Ev
        .align  2
__ZN14nsXPTCStubBase6Stub8Ev:
        addi    r12,   0,8
        b       _SharedStub
        .elseif 8 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub8Ev
        .align  2
__ZN14nsXPTCStubBase7Stub8Ev:
        addi    r12,   0,8
        b       _SharedStub
        .else
        .err    "Stub8 >= 1000 not yet supported."
        .endif

       .if     9 < 10
        .globl  __ZN14nsXPTCStubBase5Stub9Ev
        .align  2
__ZN14nsXPTCStubBase5Stub9Ev:
        addi    r12,   0,9
        b       _SharedStub
        .elseif 9 < 100
        .globl  __ZN14nsXPTCStubBase6Stub9Ev
        .align  2
__ZN14nsXPTCStubBase6Stub9Ev:
        addi    r12,   0,9
        b       _SharedStub
        .elseif 9 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub9Ev
        .align  2
__ZN14nsXPTCStubBase7Stub9Ev:
        addi    r12,   0,9
        b       _SharedStub
        .else
        .err    "Stub9 >= 1000 not yet supported."
        .endif

       .if     10 < 10
        .globl  __ZN14nsXPTCStubBase5Stub10Ev
        .align  2
__ZN14nsXPTCStubBase5Stub10Ev:
        addi    r12,   0,10
        b       _SharedStub
        .elseif 10 < 100
        .globl  __ZN14nsXPTCStubBase6Stub10Ev
        .align  2
__ZN14nsXPTCStubBase6Stub10Ev:
        addi    r12,   0,10
        b       _SharedStub
        .elseif 10 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub10Ev
        .align  2
__ZN14nsXPTCStubBase7Stub10Ev:
        addi    r12,   0,10
        b       _SharedStub
        .else
        .err    "Stub10 >= 1000 not yet supported."
        .endif

       .if     11 < 10
        .globl  __ZN14nsXPTCStubBase5Stub11Ev
        .align  2
__ZN14nsXPTCStubBase5Stub11Ev:
        addi    r12,   0,11
        b       _SharedStub
        .elseif 11 < 100
        .globl  __ZN14nsXPTCStubBase6Stub11Ev
        .align  2
__ZN14nsXPTCStubBase6Stub11Ev:
        addi    r12,   0,11
        b       _SharedStub
        .elseif 11 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub11Ev
        .align  2
__ZN14nsXPTCStubBase7Stub11Ev:
        addi    r12,   0,11
        b       _SharedStub
        .else
        .err    "Stub11 >= 1000 not yet supported."
        .endif

       .if     12 < 10
        .globl  __ZN14nsXPTCStubBase5Stub12Ev
        .align  2
__ZN14nsXPTCStubBase5Stub12Ev:
        addi    r12,   0,12
        b       _SharedStub
        .elseif 12 < 100
        .globl  __ZN14nsXPTCStubBase6Stub12Ev
        .align  2
__ZN14nsXPTCStubBase6Stub12Ev:
        addi    r12,   0,12
        b       _SharedStub
        .elseif 12 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub12Ev
        .align  2
__ZN14nsXPTCStubBase7Stub12Ev:
        addi    r12,   0,12
        b       _SharedStub
        .else
        .err    "Stub12 >= 1000 not yet supported."
        .endif

       .if     13 < 10
        .globl  __ZN14nsXPTCStubBase5Stub13Ev
        .align  2
__ZN14nsXPTCStubBase5Stub13Ev:
        addi    r12,   0,13
        b       _SharedStub
        .elseif 13 < 100
        .globl  __ZN14nsXPTCStubBase6Stub13Ev
        .align  2
__ZN14nsXPTCStubBase6Stub13Ev:
        addi    r12,   0,13
        b       _SharedStub
        .elseif 13 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub13Ev
        .align  2
__ZN14nsXPTCStubBase7Stub13Ev:
        addi    r12,   0,13
        b       _SharedStub
        .else
        .err    "Stub13 >= 1000 not yet supported."
        .endif

       .if     14 < 10
        .globl  __ZN14nsXPTCStubBase5Stub14Ev
        .align  2
__ZN14nsXPTCStubBase5Stub14Ev:
        addi    r12,   0,14
        b       _SharedStub
        .elseif 14 < 100
        .globl  __ZN14nsXPTCStubBase6Stub14Ev
        .align  2
__ZN14nsXPTCStubBase6Stub14Ev:
        addi    r12,   0,14
        b       _SharedStub
        .elseif 14 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub14Ev
        .align  2
__ZN14nsXPTCStubBase7Stub14Ev:
        addi    r12,   0,14
        b       _SharedStub
        .else
        .err    "Stub14 >= 1000 not yet supported."
        .endif

       .if     15 < 10
        .globl  __ZN14nsXPTCStubBase5Stub15Ev
        .align  2
__ZN14nsXPTCStubBase5Stub15Ev:
        addi    r12,   0,15
        b       _SharedStub
        .elseif 15 < 100
        .globl  __ZN14nsXPTCStubBase6Stub15Ev
        .align  2
__ZN14nsXPTCStubBase6Stub15Ev:
        addi    r12,   0,15
        b       _SharedStub
        .elseif 15 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub15Ev
        .align  2
__ZN14nsXPTCStubBase7Stub15Ev:
        addi    r12,   0,15
        b       _SharedStub
        .else
        .err    "Stub15 >= 1000 not yet supported."
        .endif

       .if     16 < 10
        .globl  __ZN14nsXPTCStubBase5Stub16Ev
        .align  2
__ZN14nsXPTCStubBase5Stub16Ev:
        addi    r12,   0,16
        b       _SharedStub
        .elseif 16 < 100
        .globl  __ZN14nsXPTCStubBase6Stub16Ev
        .align  2
__ZN14nsXPTCStubBase6Stub16Ev:
        addi    r12,   0,16
        b       _SharedStub
        .elseif 16 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub16Ev
        .align  2
__ZN14nsXPTCStubBase7Stub16Ev:
        addi    r12,   0,16
        b       _SharedStub
        .else
        .err    "Stub16 >= 1000 not yet supported."
        .endif

       .if     17 < 10
        .globl  __ZN14nsXPTCStubBase5Stub17Ev
        .align  2
__ZN14nsXPTCStubBase5Stub17Ev:
        addi    r12,   0,17
        b       _SharedStub
        .elseif 17 < 100
        .globl  __ZN14nsXPTCStubBase6Stub17Ev
        .align  2
__ZN14nsXPTCStubBase6Stub17Ev:
        addi    r12,   0,17
        b       _SharedStub
        .elseif 17 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub17Ev
        .align  2
__ZN14nsXPTCStubBase7Stub17Ev:
        addi    r12,   0,17
        b       _SharedStub
        .else
        .err    "Stub17 >= 1000 not yet supported."
        .endif

       .if     18 < 10
        .globl  __ZN14nsXPTCStubBase5Stub18Ev
        .align  2
__ZN14nsXPTCStubBase5Stub18Ev:
        addi    r12,   0,18
        b       _SharedStub
        .elseif 18 < 100
        .globl  __ZN14nsXPTCStubBase6Stub18Ev
        .align  2
__ZN14nsXPTCStubBase6Stub18Ev:
        addi    r12,   0,18
        b       _SharedStub
        .elseif 18 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub18Ev
        .align  2
__ZN14nsXPTCStubBase7Stub18Ev:
        addi    r12,   0,18
        b       _SharedStub
        .else
        .err    "Stub18 >= 1000 not yet supported."
        .endif

       .if     19 < 10
        .globl  __ZN14nsXPTCStubBase5Stub19Ev
        .align  2
__ZN14nsXPTCStubBase5Stub19Ev:
        addi    r12,   0,19
        b       _SharedStub
        .elseif 19 < 100
        .globl  __ZN14nsXPTCStubBase6Stub19Ev
        .align  2
__ZN14nsXPTCStubBase6Stub19Ev:
        addi    r12,   0,19
        b       _SharedStub
        .elseif 19 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub19Ev
        .align  2
__ZN14nsXPTCStubBase7Stub19Ev:
        addi    r12,   0,19
        b       _SharedStub
        .else
        .err    "Stub19 >= 1000 not yet supported."
        .endif

       .if     20 < 10
        .globl  __ZN14nsXPTCStubBase5Stub20Ev
        .align  2
__ZN14nsXPTCStubBase5Stub20Ev:
        addi    r12,   0,20
        b       _SharedStub
        .elseif 20 < 100
        .globl  __ZN14nsXPTCStubBase6Stub20Ev
        .align  2
__ZN14nsXPTCStubBase6Stub20Ev:
        addi    r12,   0,20
        b       _SharedStub
        .elseif 20 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub20Ev
        .align  2
__ZN14nsXPTCStubBase7Stub20Ev:
        addi    r12,   0,20
        b       _SharedStub
        .else
        .err    "Stub20 >= 1000 not yet supported."
        .endif

       .if     21 < 10
        .globl  __ZN14nsXPTCStubBase5Stub21Ev
        .align  2
__ZN14nsXPTCStubBase5Stub21Ev:
        addi    r12,   0,21
        b       _SharedStub
        .elseif 21 < 100
        .globl  __ZN14nsXPTCStubBase6Stub21Ev
        .align  2
__ZN14nsXPTCStubBase6Stub21Ev:
        addi    r12,   0,21
        b       _SharedStub
        .elseif 21 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub21Ev
        .align  2
__ZN14nsXPTCStubBase7Stub21Ev:
        addi    r12,   0,21
        b       _SharedStub
        .else
        .err    "Stub21 >= 1000 not yet supported."
        .endif

       .if     22 < 10
        .globl  __ZN14nsXPTCStubBase5Stub22Ev
        .align  2
__ZN14nsXPTCStubBase5Stub22Ev:
        addi    r12,   0,22
        b       _SharedStub
        .elseif 22 < 100
        .globl  __ZN14nsXPTCStubBase6Stub22Ev
        .align  2
__ZN14nsXPTCStubBase6Stub22Ev:
        addi    r12,   0,22
        b       _SharedStub
        .elseif 22 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub22Ev
        .align  2
__ZN14nsXPTCStubBase7Stub22Ev:
        addi    r12,   0,22
        b       _SharedStub
        .else
        .err    "Stub22 >= 1000 not yet supported."
        .endif

       .if     23 < 10
        .globl  __ZN14nsXPTCStubBase5Stub23Ev
        .align  2
__ZN14nsXPTCStubBase5Stub23Ev:
        addi    r12,   0,23
        b       _SharedStub
        .elseif 23 < 100
        .globl  __ZN14nsXPTCStubBase6Stub23Ev
        .align  2
__ZN14nsXPTCStubBase6Stub23Ev:
        addi    r12,   0,23
        b       _SharedStub
        .elseif 23 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub23Ev
        .align  2
__ZN14nsXPTCStubBase7Stub23Ev:
        addi    r12,   0,23
        b       _SharedStub
        .else
        .err    "Stub23 >= 1000 not yet supported."
        .endif

       .if     24 < 10
        .globl  __ZN14nsXPTCStubBase5Stub24Ev
        .align  2
__ZN14nsXPTCStubBase5Stub24Ev:
        addi    r12,   0,24
        b       _SharedStub
        .elseif 24 < 100
        .globl  __ZN14nsXPTCStubBase6Stub24Ev
        .align  2
__ZN14nsXPTCStubBase6Stub24Ev:
        addi    r12,   0,24
        b       _SharedStub
        .elseif 24 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub24Ev
        .align  2
__ZN14nsXPTCStubBase7Stub24Ev:
        addi    r12,   0,24
        b       _SharedStub
        .else
        .err    "Stub24 >= 1000 not yet supported."
        .endif

       .if     25 < 10
        .globl  __ZN14nsXPTCStubBase5Stub25Ev
        .align  2
__ZN14nsXPTCStubBase5Stub25Ev:
        addi    r12,   0,25
        b       _SharedStub
        .elseif 25 < 100
        .globl  __ZN14nsXPTCStubBase6Stub25Ev
        .align  2
__ZN14nsXPTCStubBase6Stub25Ev:
        addi    r12,   0,25
        b       _SharedStub
        .elseif 25 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub25Ev
        .align  2
__ZN14nsXPTCStubBase7Stub25Ev:
        addi    r12,   0,25
        b       _SharedStub
        .else
        .err    "Stub25 >= 1000 not yet supported."
        .endif

       .if     26 < 10
        .globl  __ZN14nsXPTCStubBase5Stub26Ev
        .align  2
__ZN14nsXPTCStubBase5Stub26Ev:
        addi    r12,   0,26
        b       _SharedStub
        .elseif 26 < 100
        .globl  __ZN14nsXPTCStubBase6Stub26Ev
        .align  2
__ZN14nsXPTCStubBase6Stub26Ev:
        addi    r12,   0,26
        b       _SharedStub
        .elseif 26 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub26Ev
        .align  2
__ZN14nsXPTCStubBase7Stub26Ev:
        addi    r12,   0,26
        b       _SharedStub
        .else
        .err    "Stub26 >= 1000 not yet supported."
        .endif

       .if     27 < 10
        .globl  __ZN14nsXPTCStubBase5Stub27Ev
        .align  2
__ZN14nsXPTCStubBase5Stub27Ev:
        addi    r12,   0,27
        b       _SharedStub
        .elseif 27 < 100
        .globl  __ZN14nsXPTCStubBase6Stub27Ev
        .align  2
__ZN14nsXPTCStubBase6Stub27Ev:
        addi    r12,   0,27
        b       _SharedStub
        .elseif 27 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub27Ev
        .align  2
__ZN14nsXPTCStubBase7Stub27Ev:
        addi    r12,   0,27
        b       _SharedStub
        .else
        .err    "Stub27 >= 1000 not yet supported."
        .endif

       .if     28 < 10
        .globl  __ZN14nsXPTCStubBase5Stub28Ev
        .align  2
__ZN14nsXPTCStubBase5Stub28Ev:
        addi    r12,   0,28
        b       _SharedStub
        .elseif 28 < 100
        .globl  __ZN14nsXPTCStubBase6Stub28Ev
        .align  2
__ZN14nsXPTCStubBase6Stub28Ev:
        addi    r12,   0,28
        b       _SharedStub
        .elseif 28 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub28Ev
        .align  2
__ZN14nsXPTCStubBase7Stub28Ev:
        addi    r12,   0,28
        b       _SharedStub
        .else
        .err    "Stub28 >= 1000 not yet supported."
        .endif

       .if     29 < 10
        .globl  __ZN14nsXPTCStubBase5Stub29Ev
        .align  2
__ZN14nsXPTCStubBase5Stub29Ev:
        addi    r12,   0,29
        b       _SharedStub
        .elseif 29 < 100
        .globl  __ZN14nsXPTCStubBase6Stub29Ev
        .align  2
__ZN14nsXPTCStubBase6Stub29Ev:
        addi    r12,   0,29
        b       _SharedStub
        .elseif 29 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub29Ev
        .align  2
__ZN14nsXPTCStubBase7Stub29Ev:
        addi    r12,   0,29
        b       _SharedStub
        .else
        .err    "Stub29 >= 1000 not yet supported."
        .endif

       .if     30 < 10
        .globl  __ZN14nsXPTCStubBase5Stub30Ev
        .align  2
__ZN14nsXPTCStubBase5Stub30Ev:
        addi    r12,   0,30
        b       _SharedStub
        .elseif 30 < 100
        .globl  __ZN14nsXPTCStubBase6Stub30Ev
        .align  2
__ZN14nsXPTCStubBase6Stub30Ev:
        addi    r12,   0,30
        b       _SharedStub
        .elseif 30 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub30Ev
        .align  2
__ZN14nsXPTCStubBase7Stub30Ev:
        addi    r12,   0,30
        b       _SharedStub
        .else
        .err    "Stub30 >= 1000 not yet supported."
        .endif

       .if     31 < 10
        .globl  __ZN14nsXPTCStubBase5Stub31Ev
        .align  2
__ZN14nsXPTCStubBase5Stub31Ev:
        addi    r12,   0,31
        b       _SharedStub
        .elseif 31 < 100
        .globl  __ZN14nsXPTCStubBase6Stub31Ev
        .align  2
__ZN14nsXPTCStubBase6Stub31Ev:
        addi    r12,   0,31
        b       _SharedStub
        .elseif 31 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub31Ev
        .align  2
__ZN14nsXPTCStubBase7Stub31Ev:
        addi    r12,   0,31
        b       _SharedStub
        .else
        .err    "Stub31 >= 1000 not yet supported."
        .endif

       .if     32 < 10
        .globl  __ZN14nsXPTCStubBase5Stub32Ev
        .align  2
__ZN14nsXPTCStubBase5Stub32Ev:
        addi    r12,   0,32
        b       _SharedStub
        .elseif 32 < 100
        .globl  __ZN14nsXPTCStubBase6Stub32Ev
        .align  2
__ZN14nsXPTCStubBase6Stub32Ev:
        addi    r12,   0,32
        b       _SharedStub
        .elseif 32 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub32Ev
        .align  2
__ZN14nsXPTCStubBase7Stub32Ev:
        addi    r12,   0,32
        b       _SharedStub
        .else
        .err    "Stub32 >= 1000 not yet supported."
        .endif

       .if     33 < 10
        .globl  __ZN14nsXPTCStubBase5Stub33Ev
        .align  2
__ZN14nsXPTCStubBase5Stub33Ev:
        addi    r12,   0,33
        b       _SharedStub
        .elseif 33 < 100
        .globl  __ZN14nsXPTCStubBase6Stub33Ev
        .align  2
__ZN14nsXPTCStubBase6Stub33Ev:
        addi    r12,   0,33
        b       _SharedStub
        .elseif 33 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub33Ev
        .align  2
__ZN14nsXPTCStubBase7Stub33Ev:
        addi    r12,   0,33
        b       _SharedStub
        .else
        .err    "Stub33 >= 1000 not yet supported."
        .endif

       .if     34 < 10
        .globl  __ZN14nsXPTCStubBase5Stub34Ev
        .align  2
__ZN14nsXPTCStubBase5Stub34Ev:
        addi    r12,   0,34
        b       _SharedStub
        .elseif 34 < 100
        .globl  __ZN14nsXPTCStubBase6Stub34Ev
        .align  2
__ZN14nsXPTCStubBase6Stub34Ev:
        addi    r12,   0,34
        b       _SharedStub
        .elseif 34 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub34Ev
        .align  2
__ZN14nsXPTCStubBase7Stub34Ev:
        addi    r12,   0,34
        b       _SharedStub
        .else
        .err    "Stub34 >= 1000 not yet supported."
        .endif

       .if     35 < 10
        .globl  __ZN14nsXPTCStubBase5Stub35Ev
        .align  2
__ZN14nsXPTCStubBase5Stub35Ev:
        addi    r12,   0,35
        b       _SharedStub
        .elseif 35 < 100
        .globl  __ZN14nsXPTCStubBase6Stub35Ev
        .align  2
__ZN14nsXPTCStubBase6Stub35Ev:
        addi    r12,   0,35
        b       _SharedStub
        .elseif 35 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub35Ev
        .align  2
__ZN14nsXPTCStubBase7Stub35Ev:
        addi    r12,   0,35
        b       _SharedStub
        .else
        .err    "Stub35 >= 1000 not yet supported."
        .endif

       .if     36 < 10
        .globl  __ZN14nsXPTCStubBase5Stub36Ev
        .align  2
__ZN14nsXPTCStubBase5Stub36Ev:
        addi    r12,   0,36
        b       _SharedStub
        .elseif 36 < 100
        .globl  __ZN14nsXPTCStubBase6Stub36Ev
        .align  2
__ZN14nsXPTCStubBase6Stub36Ev:
        addi    r12,   0,36
        b       _SharedStub
        .elseif 36 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub36Ev
        .align  2
__ZN14nsXPTCStubBase7Stub36Ev:
        addi    r12,   0,36
        b       _SharedStub
        .else
        .err    "Stub36 >= 1000 not yet supported."
        .endif

       .if     37 < 10
        .globl  __ZN14nsXPTCStubBase5Stub37Ev
        .align  2
__ZN14nsXPTCStubBase5Stub37Ev:
        addi    r12,   0,37
        b       _SharedStub
        .elseif 37 < 100
        .globl  __ZN14nsXPTCStubBase6Stub37Ev
        .align  2
__ZN14nsXPTCStubBase6Stub37Ev:
        addi    r12,   0,37
        b       _SharedStub
        .elseif 37 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub37Ev
        .align  2
__ZN14nsXPTCStubBase7Stub37Ev:
        addi    r12,   0,37
        b       _SharedStub
        .else
        .err    "Stub37 >= 1000 not yet supported."
        .endif

       .if     38 < 10
        .globl  __ZN14nsXPTCStubBase5Stub38Ev
        .align  2
__ZN14nsXPTCStubBase5Stub38Ev:
        addi    r12,   0,38
        b       _SharedStub
        .elseif 38 < 100
        .globl  __ZN14nsXPTCStubBase6Stub38Ev
        .align  2
__ZN14nsXPTCStubBase6Stub38Ev:
        addi    r12,   0,38
        b       _SharedStub
        .elseif 38 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub38Ev
        .align  2
__ZN14nsXPTCStubBase7Stub38Ev:
        addi    r12,   0,38
        b       _SharedStub
        .else
        .err    "Stub38 >= 1000 not yet supported."
        .endif

       .if     39 < 10
        .globl  __ZN14nsXPTCStubBase5Stub39Ev
        .align  2
__ZN14nsXPTCStubBase5Stub39Ev:
        addi    r12,   0,39
        b       _SharedStub
        .elseif 39 < 100
        .globl  __ZN14nsXPTCStubBase6Stub39Ev
        .align  2
__ZN14nsXPTCStubBase6Stub39Ev:
        addi    r12,   0,39
        b       _SharedStub
        .elseif 39 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub39Ev
        .align  2
__ZN14nsXPTCStubBase7Stub39Ev:
        addi    r12,   0,39
        b       _SharedStub
        .else
        .err    "Stub39 >= 1000 not yet supported."
        .endif

       .if     40 < 10
        .globl  __ZN14nsXPTCStubBase5Stub40Ev
        .align  2
__ZN14nsXPTCStubBase5Stub40Ev:
        addi    r12,   0,40
        b       _SharedStub
        .elseif 40 < 100
        .globl  __ZN14nsXPTCStubBase6Stub40Ev
        .align  2
__ZN14nsXPTCStubBase6Stub40Ev:
        addi    r12,   0,40
        b       _SharedStub
        .elseif 40 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub40Ev
        .align  2
__ZN14nsXPTCStubBase7Stub40Ev:
        addi    r12,   0,40
        b       _SharedStub
        .else
        .err    "Stub40 >= 1000 not yet supported."
        .endif

       .if     41 < 10
        .globl  __ZN14nsXPTCStubBase5Stub41Ev
        .align  2
__ZN14nsXPTCStubBase5Stub41Ev:
        addi    r12,   0,41
        b       _SharedStub
        .elseif 41 < 100
        .globl  __ZN14nsXPTCStubBase6Stub41Ev
        .align  2
__ZN14nsXPTCStubBase6Stub41Ev:
        addi    r12,   0,41
        b       _SharedStub
        .elseif 41 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub41Ev
        .align  2
__ZN14nsXPTCStubBase7Stub41Ev:
        addi    r12,   0,41
        b       _SharedStub
        .else
        .err    "Stub41 >= 1000 not yet supported."
        .endif

       .if     42 < 10
        .globl  __ZN14nsXPTCStubBase5Stub42Ev
        .align  2
__ZN14nsXPTCStubBase5Stub42Ev:
        addi    r12,   0,42
        b       _SharedStub
        .elseif 42 < 100
        .globl  __ZN14nsXPTCStubBase6Stub42Ev
        .align  2
__ZN14nsXPTCStubBase6Stub42Ev:
        addi    r12,   0,42
        b       _SharedStub
        .elseif 42 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub42Ev
        .align  2
__ZN14nsXPTCStubBase7Stub42Ev:
        addi    r12,   0,42
        b       _SharedStub
        .else
        .err    "Stub42 >= 1000 not yet supported."
        .endif

       .if     43 < 10
        .globl  __ZN14nsXPTCStubBase5Stub43Ev
        .align  2
__ZN14nsXPTCStubBase5Stub43Ev:
        addi    r12,   0,43
        b       _SharedStub
        .elseif 43 < 100
        .globl  __ZN14nsXPTCStubBase6Stub43Ev
        .align  2
__ZN14nsXPTCStubBase6Stub43Ev:
        addi    r12,   0,43
        b       _SharedStub
        .elseif 43 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub43Ev
        .align  2
__ZN14nsXPTCStubBase7Stub43Ev:
        addi    r12,   0,43
        b       _SharedStub
        .else
        .err    "Stub43 >= 1000 not yet supported."
        .endif

       .if     44 < 10
        .globl  __ZN14nsXPTCStubBase5Stub44Ev
        .align  2
__ZN14nsXPTCStubBase5Stub44Ev:
        addi    r12,   0,44
        b       _SharedStub
        .elseif 44 < 100
        .globl  __ZN14nsXPTCStubBase6Stub44Ev
        .align  2
__ZN14nsXPTCStubBase6Stub44Ev:
        addi    r12,   0,44
        b       _SharedStub
        .elseif 44 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub44Ev
        .align  2
__ZN14nsXPTCStubBase7Stub44Ev:
        addi    r12,   0,44
        b       _SharedStub
        .else
        .err    "Stub44 >= 1000 not yet supported."
        .endif

       .if     45 < 10
        .globl  __ZN14nsXPTCStubBase5Stub45Ev
        .align  2
__ZN14nsXPTCStubBase5Stub45Ev:
        addi    r12,   0,45
        b       _SharedStub
        .elseif 45 < 100
        .globl  __ZN14nsXPTCStubBase6Stub45Ev
        .align  2
__ZN14nsXPTCStubBase6Stub45Ev:
        addi    r12,   0,45
        b       _SharedStub
        .elseif 45 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub45Ev
        .align  2
__ZN14nsXPTCStubBase7Stub45Ev:
        addi    r12,   0,45
        b       _SharedStub
        .else
        .err    "Stub45 >= 1000 not yet supported."
        .endif

       .if     46 < 10
        .globl  __ZN14nsXPTCStubBase5Stub46Ev
        .align  2
__ZN14nsXPTCStubBase5Stub46Ev:
        addi    r12,   0,46
        b       _SharedStub
        .elseif 46 < 100
        .globl  __ZN14nsXPTCStubBase6Stub46Ev
        .align  2
__ZN14nsXPTCStubBase6Stub46Ev:
        addi    r12,   0,46
        b       _SharedStub
        .elseif 46 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub46Ev
        .align  2
__ZN14nsXPTCStubBase7Stub46Ev:
        addi    r12,   0,46
        b       _SharedStub
        .else
        .err    "Stub46 >= 1000 not yet supported."
        .endif

       .if     47 < 10
        .globl  __ZN14nsXPTCStubBase5Stub47Ev
        .align  2
__ZN14nsXPTCStubBase5Stub47Ev:
        addi    r12,   0,47
        b       _SharedStub
        .elseif 47 < 100
        .globl  __ZN14nsXPTCStubBase6Stub47Ev
        .align  2
__ZN14nsXPTCStubBase6Stub47Ev:
        addi    r12,   0,47
        b       _SharedStub
        .elseif 47 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub47Ev
        .align  2
__ZN14nsXPTCStubBase7Stub47Ev:
        addi    r12,   0,47
        b       _SharedStub
        .else
        .err    "Stub47 >= 1000 not yet supported."
        .endif

       .if     48 < 10
        .globl  __ZN14nsXPTCStubBase5Stub48Ev
        .align  2
__ZN14nsXPTCStubBase5Stub48Ev:
        addi    r12,   0,48
        b       _SharedStub
        .elseif 48 < 100
        .globl  __ZN14nsXPTCStubBase6Stub48Ev
        .align  2
__ZN14nsXPTCStubBase6Stub48Ev:
        addi    r12,   0,48
        b       _SharedStub
        .elseif 48 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub48Ev
        .align  2
__ZN14nsXPTCStubBase7Stub48Ev:
        addi    r12,   0,48
        b       _SharedStub
        .else
        .err    "Stub48 >= 1000 not yet supported."
        .endif

       .if     49 < 10
        .globl  __ZN14nsXPTCStubBase5Stub49Ev
        .align  2
__ZN14nsXPTCStubBase5Stub49Ev:
        addi    r12,   0,49
        b       _SharedStub
        .elseif 49 < 100
        .globl  __ZN14nsXPTCStubBase6Stub49Ev
        .align  2
__ZN14nsXPTCStubBase6Stub49Ev:
        addi    r12,   0,49
        b       _SharedStub
        .elseif 49 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub49Ev
        .align  2
__ZN14nsXPTCStubBase7Stub49Ev:
        addi    r12,   0,49
        b       _SharedStub
        .else
        .err    "Stub49 >= 1000 not yet supported."
        .endif

       .if     50 < 10
        .globl  __ZN14nsXPTCStubBase5Stub50Ev
        .align  2
__ZN14nsXPTCStubBase5Stub50Ev:
        addi    r12,   0,50
        b       _SharedStub
        .elseif 50 < 100
        .globl  __ZN14nsXPTCStubBase6Stub50Ev
        .align  2
__ZN14nsXPTCStubBase6Stub50Ev:
        addi    r12,   0,50
        b       _SharedStub
        .elseif 50 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub50Ev
        .align  2
__ZN14nsXPTCStubBase7Stub50Ev:
        addi    r12,   0,50
        b       _SharedStub
        .else
        .err    "Stub50 >= 1000 not yet supported."
        .endif

       .if     51 < 10
        .globl  __ZN14nsXPTCStubBase5Stub51Ev
        .align  2
__ZN14nsXPTCStubBase5Stub51Ev:
        addi    r12,   0,51
        b       _SharedStub
        .elseif 51 < 100
        .globl  __ZN14nsXPTCStubBase6Stub51Ev
        .align  2
__ZN14nsXPTCStubBase6Stub51Ev:
        addi    r12,   0,51
        b       _SharedStub
        .elseif 51 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub51Ev
        .align  2
__ZN14nsXPTCStubBase7Stub51Ev:
        addi    r12,   0,51
        b       _SharedStub
        .else
        .err    "Stub51 >= 1000 not yet supported."
        .endif

       .if     52 < 10
        .globl  __ZN14nsXPTCStubBase5Stub52Ev
        .align  2
__ZN14nsXPTCStubBase5Stub52Ev:
        addi    r12,   0,52
        b       _SharedStub
        .elseif 52 < 100
        .globl  __ZN14nsXPTCStubBase6Stub52Ev
        .align  2
__ZN14nsXPTCStubBase6Stub52Ev:
        addi    r12,   0,52
        b       _SharedStub
        .elseif 52 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub52Ev
        .align  2
__ZN14nsXPTCStubBase7Stub52Ev:
        addi    r12,   0,52
        b       _SharedStub
        .else
        .err    "Stub52 >= 1000 not yet supported."
        .endif

       .if     53 < 10
        .globl  __ZN14nsXPTCStubBase5Stub53Ev
        .align  2
__ZN14nsXPTCStubBase5Stub53Ev:
        addi    r12,   0,53
        b       _SharedStub
        .elseif 53 < 100
        .globl  __ZN14nsXPTCStubBase6Stub53Ev
        .align  2
__ZN14nsXPTCStubBase6Stub53Ev:
        addi    r12,   0,53
        b       _SharedStub
        .elseif 53 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub53Ev
        .align  2
__ZN14nsXPTCStubBase7Stub53Ev:
        addi    r12,   0,53
        b       _SharedStub
        .else
        .err    "Stub53 >= 1000 not yet supported."
        .endif

       .if     54 < 10
        .globl  __ZN14nsXPTCStubBase5Stub54Ev
        .align  2
__ZN14nsXPTCStubBase5Stub54Ev:
        addi    r12,   0,54
        b       _SharedStub
        .elseif 54 < 100
        .globl  __ZN14nsXPTCStubBase6Stub54Ev
        .align  2
__ZN14nsXPTCStubBase6Stub54Ev:
        addi    r12,   0,54
        b       _SharedStub
        .elseif 54 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub54Ev
        .align  2
__ZN14nsXPTCStubBase7Stub54Ev:
        addi    r12,   0,54
        b       _SharedStub
        .else
        .err    "Stub54 >= 1000 not yet supported."
        .endif

       .if     55 < 10
        .globl  __ZN14nsXPTCStubBase5Stub55Ev
        .align  2
__ZN14nsXPTCStubBase5Stub55Ev:
        addi    r12,   0,55
        b       _SharedStub
        .elseif 55 < 100
        .globl  __ZN14nsXPTCStubBase6Stub55Ev
        .align  2
__ZN14nsXPTCStubBase6Stub55Ev:
        addi    r12,   0,55
        b       _SharedStub
        .elseif 55 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub55Ev
        .align  2
__ZN14nsXPTCStubBase7Stub55Ev:
        addi    r12,   0,55
        b       _SharedStub
        .else
        .err    "Stub55 >= 1000 not yet supported."
        .endif

       .if     56 < 10
        .globl  __ZN14nsXPTCStubBase5Stub56Ev
        .align  2
__ZN14nsXPTCStubBase5Stub56Ev:
        addi    r12,   0,56
        b       _SharedStub
        .elseif 56 < 100
        .globl  __ZN14nsXPTCStubBase6Stub56Ev
        .align  2
__ZN14nsXPTCStubBase6Stub56Ev:
        addi    r12,   0,56
        b       _SharedStub
        .elseif 56 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub56Ev
        .align  2
__ZN14nsXPTCStubBase7Stub56Ev:
        addi    r12,   0,56
        b       _SharedStub
        .else
        .err    "Stub56 >= 1000 not yet supported."
        .endif

       .if     57 < 10
        .globl  __ZN14nsXPTCStubBase5Stub57Ev
        .align  2
__ZN14nsXPTCStubBase5Stub57Ev:
        addi    r12,   0,57
        b       _SharedStub
        .elseif 57 < 100
        .globl  __ZN14nsXPTCStubBase6Stub57Ev
        .align  2
__ZN14nsXPTCStubBase6Stub57Ev:
        addi    r12,   0,57
        b       _SharedStub
        .elseif 57 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub57Ev
        .align  2
__ZN14nsXPTCStubBase7Stub57Ev:
        addi    r12,   0,57
        b       _SharedStub
        .else
        .err    "Stub57 >= 1000 not yet supported."
        .endif

       .if     58 < 10
        .globl  __ZN14nsXPTCStubBase5Stub58Ev
        .align  2
__ZN14nsXPTCStubBase5Stub58Ev:
        addi    r12,   0,58
        b       _SharedStub
        .elseif 58 < 100
        .globl  __ZN14nsXPTCStubBase6Stub58Ev
        .align  2
__ZN14nsXPTCStubBase6Stub58Ev:
        addi    r12,   0,58
        b       _SharedStub
        .elseif 58 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub58Ev
        .align  2
__ZN14nsXPTCStubBase7Stub58Ev:
        addi    r12,   0,58
        b       _SharedStub
        .else
        .err    "Stub58 >= 1000 not yet supported."
        .endif

       .if     59 < 10
        .globl  __ZN14nsXPTCStubBase5Stub59Ev
        .align  2
__ZN14nsXPTCStubBase5Stub59Ev:
        addi    r12,   0,59
        b       _SharedStub
        .elseif 59 < 100
        .globl  __ZN14nsXPTCStubBase6Stub59Ev
        .align  2
__ZN14nsXPTCStubBase6Stub59Ev:
        addi    r12,   0,59
        b       _SharedStub
        .elseif 59 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub59Ev
        .align  2
__ZN14nsXPTCStubBase7Stub59Ev:
        addi    r12,   0,59
        b       _SharedStub
        .else
        .err    "Stub59 >= 1000 not yet supported."
        .endif

       .if     60 < 10
        .globl  __ZN14nsXPTCStubBase5Stub60Ev
        .align  2
__ZN14nsXPTCStubBase5Stub60Ev:
        addi    r12,   0,60
        b       _SharedStub
        .elseif 60 < 100
        .globl  __ZN14nsXPTCStubBase6Stub60Ev
        .align  2
__ZN14nsXPTCStubBase6Stub60Ev:
        addi    r12,   0,60
        b       _SharedStub
        .elseif 60 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub60Ev
        .align  2
__ZN14nsXPTCStubBase7Stub60Ev:
        addi    r12,   0,60
        b       _SharedStub
        .else
        .err    "Stub60 >= 1000 not yet supported."
        .endif

       .if     61 < 10
        .globl  __ZN14nsXPTCStubBase5Stub61Ev
        .align  2
__ZN14nsXPTCStubBase5Stub61Ev:
        addi    r12,   0,61
        b       _SharedStub
        .elseif 61 < 100
        .globl  __ZN14nsXPTCStubBase6Stub61Ev
        .align  2
__ZN14nsXPTCStubBase6Stub61Ev:
        addi    r12,   0,61
        b       _SharedStub
        .elseif 61 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub61Ev
        .align  2
__ZN14nsXPTCStubBase7Stub61Ev:
        addi    r12,   0,61
        b       _SharedStub
        .else
        .err    "Stub61 >= 1000 not yet supported."
        .endif

       .if     62 < 10
        .globl  __ZN14nsXPTCStubBase5Stub62Ev
        .align  2
__ZN14nsXPTCStubBase5Stub62Ev:
        addi    r12,   0,62
        b       _SharedStub
        .elseif 62 < 100
        .globl  __ZN14nsXPTCStubBase6Stub62Ev
        .align  2
__ZN14nsXPTCStubBase6Stub62Ev:
        addi    r12,   0,62
        b       _SharedStub
        .elseif 62 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub62Ev
        .align  2
__ZN14nsXPTCStubBase7Stub62Ev:
        addi    r12,   0,62
        b       _SharedStub
        .else
        .err    "Stub62 >= 1000 not yet supported."
        .endif

       .if     63 < 10
        .globl  __ZN14nsXPTCStubBase5Stub63Ev
        .align  2
__ZN14nsXPTCStubBase5Stub63Ev:
        addi    r12,   0,63
        b       _SharedStub
        .elseif 63 < 100
        .globl  __ZN14nsXPTCStubBase6Stub63Ev
        .align  2
__ZN14nsXPTCStubBase6Stub63Ev:
        addi    r12,   0,63
        b       _SharedStub
        .elseif 63 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub63Ev
        .align  2
__ZN14nsXPTCStubBase7Stub63Ev:
        addi    r12,   0,63
        b       _SharedStub
        .else
        .err    "Stub63 >= 1000 not yet supported."
        .endif

       .if     64 < 10
        .globl  __ZN14nsXPTCStubBase5Stub64Ev
        .align  2
__ZN14nsXPTCStubBase5Stub64Ev:
        addi    r12,   0,64
        b       _SharedStub
        .elseif 64 < 100
        .globl  __ZN14nsXPTCStubBase6Stub64Ev
        .align  2
__ZN14nsXPTCStubBase6Stub64Ev:
        addi    r12,   0,64
        b       _SharedStub
        .elseif 64 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub64Ev
        .align  2
__ZN14nsXPTCStubBase7Stub64Ev:
        addi    r12,   0,64
        b       _SharedStub
        .else
        .err    "Stub64 >= 1000 not yet supported."
        .endif

       .if     65 < 10
        .globl  __ZN14nsXPTCStubBase5Stub65Ev
        .align  2
__ZN14nsXPTCStubBase5Stub65Ev:
        addi    r12,   0,65
        b       _SharedStub
        .elseif 65 < 100
        .globl  __ZN14nsXPTCStubBase6Stub65Ev
        .align  2
__ZN14nsXPTCStubBase6Stub65Ev:
        addi    r12,   0,65
        b       _SharedStub
        .elseif 65 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub65Ev
        .align  2
__ZN14nsXPTCStubBase7Stub65Ev:
        addi    r12,   0,65
        b       _SharedStub
        .else
        .err    "Stub65 >= 1000 not yet supported."
        .endif

       .if     66 < 10
        .globl  __ZN14nsXPTCStubBase5Stub66Ev
        .align  2
__ZN14nsXPTCStubBase5Stub66Ev:
        addi    r12,   0,66
        b       _SharedStub
        .elseif 66 < 100
        .globl  __ZN14nsXPTCStubBase6Stub66Ev
        .align  2
__ZN14nsXPTCStubBase6Stub66Ev:
        addi    r12,   0,66
        b       _SharedStub
        .elseif 66 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub66Ev
        .align  2
__ZN14nsXPTCStubBase7Stub66Ev:
        addi    r12,   0,66
        b       _SharedStub
        .else
        .err    "Stub66 >= 1000 not yet supported."
        .endif

       .if     67 < 10
        .globl  __ZN14nsXPTCStubBase5Stub67Ev
        .align  2
__ZN14nsXPTCStubBase5Stub67Ev:
        addi    r12,   0,67
        b       _SharedStub
        .elseif 67 < 100
        .globl  __ZN14nsXPTCStubBase6Stub67Ev
        .align  2
__ZN14nsXPTCStubBase6Stub67Ev:
        addi    r12,   0,67
        b       _SharedStub
        .elseif 67 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub67Ev
        .align  2
__ZN14nsXPTCStubBase7Stub67Ev:
        addi    r12,   0,67
        b       _SharedStub
        .else
        .err    "Stub67 >= 1000 not yet supported."
        .endif

       .if     68 < 10
        .globl  __ZN14nsXPTCStubBase5Stub68Ev
        .align  2
__ZN14nsXPTCStubBase5Stub68Ev:
        addi    r12,   0,68
        b       _SharedStub
        .elseif 68 < 100
        .globl  __ZN14nsXPTCStubBase6Stub68Ev
        .align  2
__ZN14nsXPTCStubBase6Stub68Ev:
        addi    r12,   0,68
        b       _SharedStub
        .elseif 68 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub68Ev
        .align  2
__ZN14nsXPTCStubBase7Stub68Ev:
        addi    r12,   0,68
        b       _SharedStub
        .else
        .err    "Stub68 >= 1000 not yet supported."
        .endif

       .if     69 < 10
        .globl  __ZN14nsXPTCStubBase5Stub69Ev
        .align  2
__ZN14nsXPTCStubBase5Stub69Ev:
        addi    r12,   0,69
        b       _SharedStub
        .elseif 69 < 100
        .globl  __ZN14nsXPTCStubBase6Stub69Ev
        .align  2
__ZN14nsXPTCStubBase6Stub69Ev:
        addi    r12,   0,69
        b       _SharedStub
        .elseif 69 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub69Ev
        .align  2
__ZN14nsXPTCStubBase7Stub69Ev:
        addi    r12,   0,69
        b       _SharedStub
        .else
        .err    "Stub69 >= 1000 not yet supported."
        .endif

       .if     70 < 10
        .globl  __ZN14nsXPTCStubBase5Stub70Ev
        .align  2
__ZN14nsXPTCStubBase5Stub70Ev:
        addi    r12,   0,70
        b       _SharedStub
        .elseif 70 < 100
        .globl  __ZN14nsXPTCStubBase6Stub70Ev
        .align  2
__ZN14nsXPTCStubBase6Stub70Ev:
        addi    r12,   0,70
        b       _SharedStub
        .elseif 70 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub70Ev
        .align  2
__ZN14nsXPTCStubBase7Stub70Ev:
        addi    r12,   0,70
        b       _SharedStub
        .else
        .err    "Stub70 >= 1000 not yet supported."
        .endif

       .if     71 < 10
        .globl  __ZN14nsXPTCStubBase5Stub71Ev
        .align  2
__ZN14nsXPTCStubBase5Stub71Ev:
        addi    r12,   0,71
        b       _SharedStub
        .elseif 71 < 100
        .globl  __ZN14nsXPTCStubBase6Stub71Ev
        .align  2
__ZN14nsXPTCStubBase6Stub71Ev:
        addi    r12,   0,71
        b       _SharedStub
        .elseif 71 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub71Ev
        .align  2
__ZN14nsXPTCStubBase7Stub71Ev:
        addi    r12,   0,71
        b       _SharedStub
        .else
        .err    "Stub71 >= 1000 not yet supported."
        .endif

       .if     72 < 10
        .globl  __ZN14nsXPTCStubBase5Stub72Ev
        .align  2
__ZN14nsXPTCStubBase5Stub72Ev:
        addi    r12,   0,72
        b       _SharedStub
        .elseif 72 < 100
        .globl  __ZN14nsXPTCStubBase6Stub72Ev
        .align  2
__ZN14nsXPTCStubBase6Stub72Ev:
        addi    r12,   0,72
        b       _SharedStub
        .elseif 72 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub72Ev
        .align  2
__ZN14nsXPTCStubBase7Stub72Ev:
        addi    r12,   0,72
        b       _SharedStub
        .else
        .err    "Stub72 >= 1000 not yet supported."
        .endif

       .if     73 < 10
        .globl  __ZN14nsXPTCStubBase5Stub73Ev
        .align  2
__ZN14nsXPTCStubBase5Stub73Ev:
        addi    r12,   0,73
        b       _SharedStub
        .elseif 73 < 100
        .globl  __ZN14nsXPTCStubBase6Stub73Ev
        .align  2
__ZN14nsXPTCStubBase6Stub73Ev:
        addi    r12,   0,73
        b       _SharedStub
        .elseif 73 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub73Ev
        .align  2
__ZN14nsXPTCStubBase7Stub73Ev:
        addi    r12,   0,73
        b       _SharedStub
        .else
        .err    "Stub73 >= 1000 not yet supported."
        .endif

       .if     74 < 10
        .globl  __ZN14nsXPTCStubBase5Stub74Ev
        .align  2
__ZN14nsXPTCStubBase5Stub74Ev:
        addi    r12,   0,74
        b       _SharedStub
        .elseif 74 < 100
        .globl  __ZN14nsXPTCStubBase6Stub74Ev
        .align  2
__ZN14nsXPTCStubBase6Stub74Ev:
        addi    r12,   0,74
        b       _SharedStub
        .elseif 74 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub74Ev
        .align  2
__ZN14nsXPTCStubBase7Stub74Ev:
        addi    r12,   0,74
        b       _SharedStub
        .else
        .err    "Stub74 >= 1000 not yet supported."
        .endif

       .if     75 < 10
        .globl  __ZN14nsXPTCStubBase5Stub75Ev
        .align  2
__ZN14nsXPTCStubBase5Stub75Ev:
        addi    r12,   0,75
        b       _SharedStub
        .elseif 75 < 100
        .globl  __ZN14nsXPTCStubBase6Stub75Ev
        .align  2
__ZN14nsXPTCStubBase6Stub75Ev:
        addi    r12,   0,75
        b       _SharedStub
        .elseif 75 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub75Ev
        .align  2
__ZN14nsXPTCStubBase7Stub75Ev:
        addi    r12,   0,75
        b       _SharedStub
        .else
        .err    "Stub75 >= 1000 not yet supported."
        .endif

       .if     76 < 10
        .globl  __ZN14nsXPTCStubBase5Stub76Ev
        .align  2
__ZN14nsXPTCStubBase5Stub76Ev:
        addi    r12,   0,76
        b       _SharedStub
        .elseif 76 < 100
        .globl  __ZN14nsXPTCStubBase6Stub76Ev
        .align  2
__ZN14nsXPTCStubBase6Stub76Ev:
        addi    r12,   0,76
        b       _SharedStub
        .elseif 76 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub76Ev
        .align  2
__ZN14nsXPTCStubBase7Stub76Ev:
        addi    r12,   0,76
        b       _SharedStub
        .else
        .err    "Stub76 >= 1000 not yet supported."
        .endif

       .if     77 < 10
        .globl  __ZN14nsXPTCStubBase5Stub77Ev
        .align  2
__ZN14nsXPTCStubBase5Stub77Ev:
        addi    r12,   0,77
        b       _SharedStub
        .elseif 77 < 100
        .globl  __ZN14nsXPTCStubBase6Stub77Ev
        .align  2
__ZN14nsXPTCStubBase6Stub77Ev:
        addi    r12,   0,77
        b       _SharedStub
        .elseif 77 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub77Ev
        .align  2
__ZN14nsXPTCStubBase7Stub77Ev:
        addi    r12,   0,77
        b       _SharedStub
        .else
        .err    "Stub77 >= 1000 not yet supported."
        .endif

       .if     78 < 10
        .globl  __ZN14nsXPTCStubBase5Stub78Ev
        .align  2
__ZN14nsXPTCStubBase5Stub78Ev:
        addi    r12,   0,78
        b       _SharedStub
        .elseif 78 < 100
        .globl  __ZN14nsXPTCStubBase6Stub78Ev
        .align  2
__ZN14nsXPTCStubBase6Stub78Ev:
        addi    r12,   0,78
        b       _SharedStub
        .elseif 78 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub78Ev
        .align  2
__ZN14nsXPTCStubBase7Stub78Ev:
        addi    r12,   0,78
        b       _SharedStub
        .else
        .err    "Stub78 >= 1000 not yet supported."
        .endif

       .if     79 < 10
        .globl  __ZN14nsXPTCStubBase5Stub79Ev
        .align  2
__ZN14nsXPTCStubBase5Stub79Ev:
        addi    r12,   0,79
        b       _SharedStub
        .elseif 79 < 100
        .globl  __ZN14nsXPTCStubBase6Stub79Ev
        .align  2
__ZN14nsXPTCStubBase6Stub79Ev:
        addi    r12,   0,79
        b       _SharedStub
        .elseif 79 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub79Ev
        .align  2
__ZN14nsXPTCStubBase7Stub79Ev:
        addi    r12,   0,79
        b       _SharedStub
        .else
        .err    "Stub79 >= 1000 not yet supported."
        .endif

       .if     80 < 10
        .globl  __ZN14nsXPTCStubBase5Stub80Ev
        .align  2
__ZN14nsXPTCStubBase5Stub80Ev:
        addi    r12,   0,80
        b       _SharedStub
        .elseif 80 < 100
        .globl  __ZN14nsXPTCStubBase6Stub80Ev
        .align  2
__ZN14nsXPTCStubBase6Stub80Ev:
        addi    r12,   0,80
        b       _SharedStub
        .elseif 80 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub80Ev
        .align  2
__ZN14nsXPTCStubBase7Stub80Ev:
        addi    r12,   0,80
        b       _SharedStub
        .else
        .err    "Stub80 >= 1000 not yet supported."
        .endif

       .if     81 < 10
        .globl  __ZN14nsXPTCStubBase5Stub81Ev
        .align  2
__ZN14nsXPTCStubBase5Stub81Ev:
        addi    r12,   0,81
        b       _SharedStub
        .elseif 81 < 100
        .globl  __ZN14nsXPTCStubBase6Stub81Ev
        .align  2
__ZN14nsXPTCStubBase6Stub81Ev:
        addi    r12,   0,81
        b       _SharedStub
        .elseif 81 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub81Ev
        .align  2
__ZN14nsXPTCStubBase7Stub81Ev:
        addi    r12,   0,81
        b       _SharedStub
        .else
        .err    "Stub81 >= 1000 not yet supported."
        .endif

       .if     82 < 10
        .globl  __ZN14nsXPTCStubBase5Stub82Ev
        .align  2
__ZN14nsXPTCStubBase5Stub82Ev:
        addi    r12,   0,82
        b       _SharedStub
        .elseif 82 < 100
        .globl  __ZN14nsXPTCStubBase6Stub82Ev
        .align  2
__ZN14nsXPTCStubBase6Stub82Ev:
        addi    r12,   0,82
        b       _SharedStub
        .elseif 82 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub82Ev
        .align  2
__ZN14nsXPTCStubBase7Stub82Ev:
        addi    r12,   0,82
        b       _SharedStub
        .else
        .err    "Stub82 >= 1000 not yet supported."
        .endif

       .if     83 < 10
        .globl  __ZN14nsXPTCStubBase5Stub83Ev
        .align  2
__ZN14nsXPTCStubBase5Stub83Ev:
        addi    r12,   0,83
        b       _SharedStub
        .elseif 83 < 100
        .globl  __ZN14nsXPTCStubBase6Stub83Ev
        .align  2
__ZN14nsXPTCStubBase6Stub83Ev:
        addi    r12,   0,83
        b       _SharedStub
        .elseif 83 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub83Ev
        .align  2
__ZN14nsXPTCStubBase7Stub83Ev:
        addi    r12,   0,83
        b       _SharedStub
        .else
        .err    "Stub83 >= 1000 not yet supported."
        .endif

       .if     84 < 10
        .globl  __ZN14nsXPTCStubBase5Stub84Ev
        .align  2
__ZN14nsXPTCStubBase5Stub84Ev:
        addi    r12,   0,84
        b       _SharedStub
        .elseif 84 < 100
        .globl  __ZN14nsXPTCStubBase6Stub84Ev
        .align  2
__ZN14nsXPTCStubBase6Stub84Ev:
        addi    r12,   0,84
        b       _SharedStub
        .elseif 84 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub84Ev
        .align  2
__ZN14nsXPTCStubBase7Stub84Ev:
        addi    r12,   0,84
        b       _SharedStub
        .else
        .err    "Stub84 >= 1000 not yet supported."
        .endif

       .if     85 < 10
        .globl  __ZN14nsXPTCStubBase5Stub85Ev
        .align  2
__ZN14nsXPTCStubBase5Stub85Ev:
        addi    r12,   0,85
        b       _SharedStub
        .elseif 85 < 100
        .globl  __ZN14nsXPTCStubBase6Stub85Ev
        .align  2
__ZN14nsXPTCStubBase6Stub85Ev:
        addi    r12,   0,85
        b       _SharedStub
        .elseif 85 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub85Ev
        .align  2
__ZN14nsXPTCStubBase7Stub85Ev:
        addi    r12,   0,85
        b       _SharedStub
        .else
        .err    "Stub85 >= 1000 not yet supported."
        .endif

       .if     86 < 10
        .globl  __ZN14nsXPTCStubBase5Stub86Ev
        .align  2
__ZN14nsXPTCStubBase5Stub86Ev:
        addi    r12,   0,86
        b       _SharedStub
        .elseif 86 < 100
        .globl  __ZN14nsXPTCStubBase6Stub86Ev
        .align  2
__ZN14nsXPTCStubBase6Stub86Ev:
        addi    r12,   0,86
        b       _SharedStub
        .elseif 86 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub86Ev
        .align  2
__ZN14nsXPTCStubBase7Stub86Ev:
        addi    r12,   0,86
        b       _SharedStub
        .else
        .err    "Stub86 >= 1000 not yet supported."
        .endif

       .if     87 < 10
        .globl  __ZN14nsXPTCStubBase5Stub87Ev
        .align  2
__ZN14nsXPTCStubBase5Stub87Ev:
        addi    r12,   0,87
        b       _SharedStub
        .elseif 87 < 100
        .globl  __ZN14nsXPTCStubBase6Stub87Ev
        .align  2
__ZN14nsXPTCStubBase6Stub87Ev:
        addi    r12,   0,87
        b       _SharedStub
        .elseif 87 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub87Ev
        .align  2
__ZN14nsXPTCStubBase7Stub87Ev:
        addi    r12,   0,87
        b       _SharedStub
        .else
        .err    "Stub87 >= 1000 not yet supported."
        .endif

       .if     88 < 10
        .globl  __ZN14nsXPTCStubBase5Stub88Ev
        .align  2
__ZN14nsXPTCStubBase5Stub88Ev:
        addi    r12,   0,88
        b       _SharedStub
        .elseif 88 < 100
        .globl  __ZN14nsXPTCStubBase6Stub88Ev
        .align  2
__ZN14nsXPTCStubBase6Stub88Ev:
        addi    r12,   0,88
        b       _SharedStub
        .elseif 88 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub88Ev
        .align  2
__ZN14nsXPTCStubBase7Stub88Ev:
        addi    r12,   0,88
        b       _SharedStub
        .else
        .err    "Stub88 >= 1000 not yet supported."
        .endif

       .if     89 < 10
        .globl  __ZN14nsXPTCStubBase5Stub89Ev
        .align  2
__ZN14nsXPTCStubBase5Stub89Ev:
        addi    r12,   0,89
        b       _SharedStub
        .elseif 89 < 100
        .globl  __ZN14nsXPTCStubBase6Stub89Ev
        .align  2
__ZN14nsXPTCStubBase6Stub89Ev:
        addi    r12,   0,89
        b       _SharedStub
        .elseif 89 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub89Ev
        .align  2
__ZN14nsXPTCStubBase7Stub89Ev:
        addi    r12,   0,89
        b       _SharedStub
        .else
        .err    "Stub89 >= 1000 not yet supported."
        .endif

       .if     90 < 10
        .globl  __ZN14nsXPTCStubBase5Stub90Ev
        .align  2
__ZN14nsXPTCStubBase5Stub90Ev:
        addi    r12,   0,90
        b       _SharedStub
        .elseif 90 < 100
        .globl  __ZN14nsXPTCStubBase6Stub90Ev
        .align  2
__ZN14nsXPTCStubBase6Stub90Ev:
        addi    r12,   0,90
        b       _SharedStub
        .elseif 90 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub90Ev
        .align  2
__ZN14nsXPTCStubBase7Stub90Ev:
        addi    r12,   0,90
        b       _SharedStub
        .else
        .err    "Stub90 >= 1000 not yet supported."
        .endif

       .if     91 < 10
        .globl  __ZN14nsXPTCStubBase5Stub91Ev
        .align  2
__ZN14nsXPTCStubBase5Stub91Ev:
        addi    r12,   0,91
        b       _SharedStub
        .elseif 91 < 100
        .globl  __ZN14nsXPTCStubBase6Stub91Ev
        .align  2
__ZN14nsXPTCStubBase6Stub91Ev:
        addi    r12,   0,91
        b       _SharedStub
        .elseif 91 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub91Ev
        .align  2
__ZN14nsXPTCStubBase7Stub91Ev:
        addi    r12,   0,91
        b       _SharedStub
        .else
        .err    "Stub91 >= 1000 not yet supported."
        .endif

       .if     92 < 10
        .globl  __ZN14nsXPTCStubBase5Stub92Ev
        .align  2
__ZN14nsXPTCStubBase5Stub92Ev:
        addi    r12,   0,92
        b       _SharedStub
        .elseif 92 < 100
        .globl  __ZN14nsXPTCStubBase6Stub92Ev
        .align  2
__ZN14nsXPTCStubBase6Stub92Ev:
        addi    r12,   0,92
        b       _SharedStub
        .elseif 92 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub92Ev
        .align  2
__ZN14nsXPTCStubBase7Stub92Ev:
        addi    r12,   0,92
        b       _SharedStub
        .else
        .err    "Stub92 >= 1000 not yet supported."
        .endif

       .if     93 < 10
        .globl  __ZN14nsXPTCStubBase5Stub93Ev
        .align  2
__ZN14nsXPTCStubBase5Stub93Ev:
        addi    r12,   0,93
        b       _SharedStub
        .elseif 93 < 100
        .globl  __ZN14nsXPTCStubBase6Stub93Ev
        .align  2
__ZN14nsXPTCStubBase6Stub93Ev:
        addi    r12,   0,93
        b       _SharedStub
        .elseif 93 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub93Ev
        .align  2
__ZN14nsXPTCStubBase7Stub93Ev:
        addi    r12,   0,93
        b       _SharedStub
        .else
        .err    "Stub93 >= 1000 not yet supported."
        .endif

       .if     94 < 10
        .globl  __ZN14nsXPTCStubBase5Stub94Ev
        .align  2
__ZN14nsXPTCStubBase5Stub94Ev:
        addi    r12,   0,94
        b       _SharedStub
        .elseif 94 < 100
        .globl  __ZN14nsXPTCStubBase6Stub94Ev
        .align  2
__ZN14nsXPTCStubBase6Stub94Ev:
        addi    r12,   0,94
        b       _SharedStub
        .elseif 94 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub94Ev
        .align  2
__ZN14nsXPTCStubBase7Stub94Ev:
        addi    r12,   0,94
        b       _SharedStub
        .else
        .err    "Stub94 >= 1000 not yet supported."
        .endif

       .if     95 < 10
        .globl  __ZN14nsXPTCStubBase5Stub95Ev
        .align  2
__ZN14nsXPTCStubBase5Stub95Ev:
        addi    r12,   0,95
        b       _SharedStub
        .elseif 95 < 100
        .globl  __ZN14nsXPTCStubBase6Stub95Ev
        .align  2
__ZN14nsXPTCStubBase6Stub95Ev:
        addi    r12,   0,95
        b       _SharedStub
        .elseif 95 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub95Ev
        .align  2
__ZN14nsXPTCStubBase7Stub95Ev:
        addi    r12,   0,95
        b       _SharedStub
        .else
        .err    "Stub95 >= 1000 not yet supported."
        .endif

       .if     96 < 10
        .globl  __ZN14nsXPTCStubBase5Stub96Ev
        .align  2
__ZN14nsXPTCStubBase5Stub96Ev:
        addi    r12,   0,96
        b       _SharedStub
        .elseif 96 < 100
        .globl  __ZN14nsXPTCStubBase6Stub96Ev
        .align  2
__ZN14nsXPTCStubBase6Stub96Ev:
        addi    r12,   0,96
        b       _SharedStub
        .elseif 96 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub96Ev
        .align  2
__ZN14nsXPTCStubBase7Stub96Ev:
        addi    r12,   0,96
        b       _SharedStub
        .else
        .err    "Stub96 >= 1000 not yet supported."
        .endif

       .if     97 < 10
        .globl  __ZN14nsXPTCStubBase5Stub97Ev
        .align  2
__ZN14nsXPTCStubBase5Stub97Ev:
        addi    r12,   0,97
        b       _SharedStub
        .elseif 97 < 100
        .globl  __ZN14nsXPTCStubBase6Stub97Ev
        .align  2
__ZN14nsXPTCStubBase6Stub97Ev:
        addi    r12,   0,97
        b       _SharedStub
        .elseif 97 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub97Ev
        .align  2
__ZN14nsXPTCStubBase7Stub97Ev:
        addi    r12,   0,97
        b       _SharedStub
        .else
        .err    "Stub97 >= 1000 not yet supported."
        .endif

       .if     98 < 10
        .globl  __ZN14nsXPTCStubBase5Stub98Ev
        .align  2
__ZN14nsXPTCStubBase5Stub98Ev:
        addi    r12,   0,98
        b       _SharedStub
        .elseif 98 < 100
        .globl  __ZN14nsXPTCStubBase6Stub98Ev
        .align  2
__ZN14nsXPTCStubBase6Stub98Ev:
        addi    r12,   0,98
        b       _SharedStub
        .elseif 98 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub98Ev
        .align  2
__ZN14nsXPTCStubBase7Stub98Ev:
        addi    r12,   0,98
        b       _SharedStub
        .else
        .err    "Stub98 >= 1000 not yet supported."
        .endif

       .if     99 < 10
        .globl  __ZN14nsXPTCStubBase5Stub99Ev
        .align  2
__ZN14nsXPTCStubBase5Stub99Ev:
        addi    r12,   0,99
        b       _SharedStub
        .elseif 99 < 100
        .globl  __ZN14nsXPTCStubBase6Stub99Ev
        .align  2
__ZN14nsXPTCStubBase6Stub99Ev:
        addi    r12,   0,99
        b       _SharedStub
        .elseif 99 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub99Ev
        .align  2
__ZN14nsXPTCStubBase7Stub99Ev:
        addi    r12,   0,99
        b       _SharedStub
        .else
        .err    "Stub99 >= 1000 not yet supported."
        .endif

       .if     100 < 10
        .globl  __ZN14nsXPTCStubBase5Stub100Ev
        .align  2
__ZN14nsXPTCStubBase5Stub100Ev:
        addi    r12,   0,100
        b       _SharedStub
        .elseif 100 < 100
        .globl  __ZN14nsXPTCStubBase6Stub100Ev
        .align  2
__ZN14nsXPTCStubBase6Stub100Ev:
        addi    r12,   0,100
        b       _SharedStub
        .elseif 100 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub100Ev
        .align  2
__ZN14nsXPTCStubBase7Stub100Ev:
        addi    r12,   0,100
        b       _SharedStub
        .else
        .err    "Stub100 >= 1000 not yet supported."
        .endif

       .if     101 < 10
        .globl  __ZN14nsXPTCStubBase5Stub101Ev
        .align  2
__ZN14nsXPTCStubBase5Stub101Ev:
        addi    r12,   0,101
        b       _SharedStub
        .elseif 101 < 100
        .globl  __ZN14nsXPTCStubBase6Stub101Ev
        .align  2
__ZN14nsXPTCStubBase6Stub101Ev:
        addi    r12,   0,101
        b       _SharedStub
        .elseif 101 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub101Ev
        .align  2
__ZN14nsXPTCStubBase7Stub101Ev:
        addi    r12,   0,101
        b       _SharedStub
        .else
        .err    "Stub101 >= 1000 not yet supported."
        .endif

       .if     102 < 10
        .globl  __ZN14nsXPTCStubBase5Stub102Ev
        .align  2
__ZN14nsXPTCStubBase5Stub102Ev:
        addi    r12,   0,102
        b       _SharedStub
        .elseif 102 < 100
        .globl  __ZN14nsXPTCStubBase6Stub102Ev
        .align  2
__ZN14nsXPTCStubBase6Stub102Ev:
        addi    r12,   0,102
        b       _SharedStub
        .elseif 102 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub102Ev
        .align  2
__ZN14nsXPTCStubBase7Stub102Ev:
        addi    r12,   0,102
        b       _SharedStub
        .else
        .err    "Stub102 >= 1000 not yet supported."
        .endif

       .if     103 < 10
        .globl  __ZN14nsXPTCStubBase5Stub103Ev
        .align  2
__ZN14nsXPTCStubBase5Stub103Ev:
        addi    r12,   0,103
        b       _SharedStub
        .elseif 103 < 100
        .globl  __ZN14nsXPTCStubBase6Stub103Ev
        .align  2
__ZN14nsXPTCStubBase6Stub103Ev:
        addi    r12,   0,103
        b       _SharedStub
        .elseif 103 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub103Ev
        .align  2
__ZN14nsXPTCStubBase7Stub103Ev:
        addi    r12,   0,103
        b       _SharedStub
        .else
        .err    "Stub103 >= 1000 not yet supported."
        .endif

       .if     104 < 10
        .globl  __ZN14nsXPTCStubBase5Stub104Ev
        .align  2
__ZN14nsXPTCStubBase5Stub104Ev:
        addi    r12,   0,104
        b       _SharedStub
        .elseif 104 < 100
        .globl  __ZN14nsXPTCStubBase6Stub104Ev
        .align  2
__ZN14nsXPTCStubBase6Stub104Ev:
        addi    r12,   0,104
        b       _SharedStub
        .elseif 104 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub104Ev
        .align  2
__ZN14nsXPTCStubBase7Stub104Ev:
        addi    r12,   0,104
        b       _SharedStub
        .else
        .err    "Stub104 >= 1000 not yet supported."
        .endif

       .if     105 < 10
        .globl  __ZN14nsXPTCStubBase5Stub105Ev
        .align  2
__ZN14nsXPTCStubBase5Stub105Ev:
        addi    r12,   0,105
        b       _SharedStub
        .elseif 105 < 100
        .globl  __ZN14nsXPTCStubBase6Stub105Ev
        .align  2
__ZN14nsXPTCStubBase6Stub105Ev:
        addi    r12,   0,105
        b       _SharedStub
        .elseif 105 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub105Ev
        .align  2
__ZN14nsXPTCStubBase7Stub105Ev:
        addi    r12,   0,105
        b       _SharedStub
        .else
        .err    "Stub105 >= 1000 not yet supported."
        .endif

       .if     106 < 10
        .globl  __ZN14nsXPTCStubBase5Stub106Ev
        .align  2
__ZN14nsXPTCStubBase5Stub106Ev:
        addi    r12,   0,106
        b       _SharedStub
        .elseif 106 < 100
        .globl  __ZN14nsXPTCStubBase6Stub106Ev
        .align  2
__ZN14nsXPTCStubBase6Stub106Ev:
        addi    r12,   0,106
        b       _SharedStub
        .elseif 106 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub106Ev
        .align  2
__ZN14nsXPTCStubBase7Stub106Ev:
        addi    r12,   0,106
        b       _SharedStub
        .else
        .err    "Stub106 >= 1000 not yet supported."
        .endif

       .if     107 < 10
        .globl  __ZN14nsXPTCStubBase5Stub107Ev
        .align  2
__ZN14nsXPTCStubBase5Stub107Ev:
        addi    r12,   0,107
        b       _SharedStub
        .elseif 107 < 100
        .globl  __ZN14nsXPTCStubBase6Stub107Ev
        .align  2
__ZN14nsXPTCStubBase6Stub107Ev:
        addi    r12,   0,107
        b       _SharedStub
        .elseif 107 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub107Ev
        .align  2
__ZN14nsXPTCStubBase7Stub107Ev:
        addi    r12,   0,107
        b       _SharedStub
        .else
        .err    "Stub107 >= 1000 not yet supported."
        .endif

       .if     108 < 10
        .globl  __ZN14nsXPTCStubBase5Stub108Ev
        .align  2
__ZN14nsXPTCStubBase5Stub108Ev:
        addi    r12,   0,108
        b       _SharedStub
        .elseif 108 < 100
        .globl  __ZN14nsXPTCStubBase6Stub108Ev
        .align  2
__ZN14nsXPTCStubBase6Stub108Ev:
        addi    r12,   0,108
        b       _SharedStub
        .elseif 108 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub108Ev
        .align  2
__ZN14nsXPTCStubBase7Stub108Ev:
        addi    r12,   0,108
        b       _SharedStub
        .else
        .err    "Stub108 >= 1000 not yet supported."
        .endif

       .if     109 < 10
        .globl  __ZN14nsXPTCStubBase5Stub109Ev
        .align  2
__ZN14nsXPTCStubBase5Stub109Ev:
        addi    r12,   0,109
        b       _SharedStub
        .elseif 109 < 100
        .globl  __ZN14nsXPTCStubBase6Stub109Ev
        .align  2
__ZN14nsXPTCStubBase6Stub109Ev:
        addi    r12,   0,109
        b       _SharedStub
        .elseif 109 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub109Ev
        .align  2
__ZN14nsXPTCStubBase7Stub109Ev:
        addi    r12,   0,109
        b       _SharedStub
        .else
        .err    "Stub109 >= 1000 not yet supported."
        .endif

       .if     110 < 10
        .globl  __ZN14nsXPTCStubBase5Stub110Ev
        .align  2
__ZN14nsXPTCStubBase5Stub110Ev:
        addi    r12,   0,110
        b       _SharedStub
        .elseif 110 < 100
        .globl  __ZN14nsXPTCStubBase6Stub110Ev
        .align  2
__ZN14nsXPTCStubBase6Stub110Ev:
        addi    r12,   0,110
        b       _SharedStub
        .elseif 110 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub110Ev
        .align  2
__ZN14nsXPTCStubBase7Stub110Ev:
        addi    r12,   0,110
        b       _SharedStub
        .else
        .err    "Stub110 >= 1000 not yet supported."
        .endif

       .if     111 < 10
        .globl  __ZN14nsXPTCStubBase5Stub111Ev
        .align  2
__ZN14nsXPTCStubBase5Stub111Ev:
        addi    r12,   0,111
        b       _SharedStub
        .elseif 111 < 100
        .globl  __ZN14nsXPTCStubBase6Stub111Ev
        .align  2
__ZN14nsXPTCStubBase6Stub111Ev:
        addi    r12,   0,111
        b       _SharedStub
        .elseif 111 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub111Ev
        .align  2
__ZN14nsXPTCStubBase7Stub111Ev:
        addi    r12,   0,111
        b       _SharedStub
        .else
        .err    "Stub111 >= 1000 not yet supported."
        .endif

       .if     112 < 10
        .globl  __ZN14nsXPTCStubBase5Stub112Ev
        .align  2
__ZN14nsXPTCStubBase5Stub112Ev:
        addi    r12,   0,112
        b       _SharedStub
        .elseif 112 < 100
        .globl  __ZN14nsXPTCStubBase6Stub112Ev
        .align  2
__ZN14nsXPTCStubBase6Stub112Ev:
        addi    r12,   0,112
        b       _SharedStub
        .elseif 112 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub112Ev
        .align  2
__ZN14nsXPTCStubBase7Stub112Ev:
        addi    r12,   0,112
        b       _SharedStub
        .else
        .err    "Stub112 >= 1000 not yet supported."
        .endif

       .if     113 < 10
        .globl  __ZN14nsXPTCStubBase5Stub113Ev
        .align  2
__ZN14nsXPTCStubBase5Stub113Ev:
        addi    r12,   0,113
        b       _SharedStub
        .elseif 113 < 100
        .globl  __ZN14nsXPTCStubBase6Stub113Ev
        .align  2
__ZN14nsXPTCStubBase6Stub113Ev:
        addi    r12,   0,113
        b       _SharedStub
        .elseif 113 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub113Ev
        .align  2
__ZN14nsXPTCStubBase7Stub113Ev:
        addi    r12,   0,113
        b       _SharedStub
        .else
        .err    "Stub113 >= 1000 not yet supported."
        .endif

       .if     114 < 10
        .globl  __ZN14nsXPTCStubBase5Stub114Ev
        .align  2
__ZN14nsXPTCStubBase5Stub114Ev:
        addi    r12,   0,114
        b       _SharedStub
        .elseif 114 < 100
        .globl  __ZN14nsXPTCStubBase6Stub114Ev
        .align  2
__ZN14nsXPTCStubBase6Stub114Ev:
        addi    r12,   0,114
        b       _SharedStub
        .elseif 114 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub114Ev
        .align  2
__ZN14nsXPTCStubBase7Stub114Ev:
        addi    r12,   0,114
        b       _SharedStub
        .else
        .err    "Stub114 >= 1000 not yet supported."
        .endif

       .if     115 < 10
        .globl  __ZN14nsXPTCStubBase5Stub115Ev
        .align  2
__ZN14nsXPTCStubBase5Stub115Ev:
        addi    r12,   0,115
        b       _SharedStub
        .elseif 115 < 100
        .globl  __ZN14nsXPTCStubBase6Stub115Ev
        .align  2
__ZN14nsXPTCStubBase6Stub115Ev:
        addi    r12,   0,115
        b       _SharedStub
        .elseif 115 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub115Ev
        .align  2
__ZN14nsXPTCStubBase7Stub115Ev:
        addi    r12,   0,115
        b       _SharedStub
        .else
        .err    "Stub115 >= 1000 not yet supported."
        .endif

       .if     116 < 10
        .globl  __ZN14nsXPTCStubBase5Stub116Ev
        .align  2
__ZN14nsXPTCStubBase5Stub116Ev:
        addi    r12,   0,116
        b       _SharedStub
        .elseif 116 < 100
        .globl  __ZN14nsXPTCStubBase6Stub116Ev
        .align  2
__ZN14nsXPTCStubBase6Stub116Ev:
        addi    r12,   0,116
        b       _SharedStub
        .elseif 116 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub116Ev
        .align  2
__ZN14nsXPTCStubBase7Stub116Ev:
        addi    r12,   0,116
        b       _SharedStub
        .else
        .err    "Stub116 >= 1000 not yet supported."
        .endif

       .if     117 < 10
        .globl  __ZN14nsXPTCStubBase5Stub117Ev
        .align  2
__ZN14nsXPTCStubBase5Stub117Ev:
        addi    r12,   0,117
        b       _SharedStub
        .elseif 117 < 100
        .globl  __ZN14nsXPTCStubBase6Stub117Ev
        .align  2
__ZN14nsXPTCStubBase6Stub117Ev:
        addi    r12,   0,117
        b       _SharedStub
        .elseif 117 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub117Ev
        .align  2
__ZN14nsXPTCStubBase7Stub117Ev:
        addi    r12,   0,117
        b       _SharedStub
        .else
        .err    "Stub117 >= 1000 not yet supported."
        .endif

       .if     118 < 10
        .globl  __ZN14nsXPTCStubBase5Stub118Ev
        .align  2
__ZN14nsXPTCStubBase5Stub118Ev:
        addi    r12,   0,118
        b       _SharedStub
        .elseif 118 < 100
        .globl  __ZN14nsXPTCStubBase6Stub118Ev
        .align  2
__ZN14nsXPTCStubBase6Stub118Ev:
        addi    r12,   0,118
        b       _SharedStub
        .elseif 118 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub118Ev
        .align  2
__ZN14nsXPTCStubBase7Stub118Ev:
        addi    r12,   0,118
        b       _SharedStub
        .else
        .err    "Stub118 >= 1000 not yet supported."
        .endif

       .if     119 < 10
        .globl  __ZN14nsXPTCStubBase5Stub119Ev
        .align  2
__ZN14nsXPTCStubBase5Stub119Ev:
        addi    r12,   0,119
        b       _SharedStub
        .elseif 119 < 100
        .globl  __ZN14nsXPTCStubBase6Stub119Ev
        .align  2
__ZN14nsXPTCStubBase6Stub119Ev:
        addi    r12,   0,119
        b       _SharedStub
        .elseif 119 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub119Ev
        .align  2
__ZN14nsXPTCStubBase7Stub119Ev:
        addi    r12,   0,119
        b       _SharedStub
        .else
        .err    "Stub119 >= 1000 not yet supported."
        .endif

       .if     120 < 10
        .globl  __ZN14nsXPTCStubBase5Stub120Ev
        .align  2
__ZN14nsXPTCStubBase5Stub120Ev:
        addi    r12,   0,120
        b       _SharedStub
        .elseif 120 < 100
        .globl  __ZN14nsXPTCStubBase6Stub120Ev
        .align  2
__ZN14nsXPTCStubBase6Stub120Ev:
        addi    r12,   0,120
        b       _SharedStub
        .elseif 120 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub120Ev
        .align  2
__ZN14nsXPTCStubBase7Stub120Ev:
        addi    r12,   0,120
        b       _SharedStub
        .else
        .err    "Stub120 >= 1000 not yet supported."
        .endif

       .if     121 < 10
        .globl  __ZN14nsXPTCStubBase5Stub121Ev
        .align  2
__ZN14nsXPTCStubBase5Stub121Ev:
        addi    r12,   0,121
        b       _SharedStub
        .elseif 121 < 100
        .globl  __ZN14nsXPTCStubBase6Stub121Ev
        .align  2
__ZN14nsXPTCStubBase6Stub121Ev:
        addi    r12,   0,121
        b       _SharedStub
        .elseif 121 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub121Ev
        .align  2
__ZN14nsXPTCStubBase7Stub121Ev:
        addi    r12,   0,121
        b       _SharedStub
        .else
        .err    "Stub121 >= 1000 not yet supported."
        .endif

       .if     122 < 10
        .globl  __ZN14nsXPTCStubBase5Stub122Ev
        .align  2
__ZN14nsXPTCStubBase5Stub122Ev:
        addi    r12,   0,122
        b       _SharedStub
        .elseif 122 < 100
        .globl  __ZN14nsXPTCStubBase6Stub122Ev
        .align  2
__ZN14nsXPTCStubBase6Stub122Ev:
        addi    r12,   0,122
        b       _SharedStub
        .elseif 122 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub122Ev
        .align  2
__ZN14nsXPTCStubBase7Stub122Ev:
        addi    r12,   0,122
        b       _SharedStub
        .else
        .err    "Stub122 >= 1000 not yet supported."
        .endif

       .if     123 < 10
        .globl  __ZN14nsXPTCStubBase5Stub123Ev
        .align  2
__ZN14nsXPTCStubBase5Stub123Ev:
        addi    r12,   0,123
        b       _SharedStub
        .elseif 123 < 100
        .globl  __ZN14nsXPTCStubBase6Stub123Ev
        .align  2
__ZN14nsXPTCStubBase6Stub123Ev:
        addi    r12,   0,123
        b       _SharedStub
        .elseif 123 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub123Ev
        .align  2
__ZN14nsXPTCStubBase7Stub123Ev:
        addi    r12,   0,123
        b       _SharedStub
        .else
        .err    "Stub123 >= 1000 not yet supported."
        .endif

       .if     124 < 10
        .globl  __ZN14nsXPTCStubBase5Stub124Ev
        .align  2
__ZN14nsXPTCStubBase5Stub124Ev:
        addi    r12,   0,124
        b       _SharedStub
        .elseif 124 < 100
        .globl  __ZN14nsXPTCStubBase6Stub124Ev
        .align  2
__ZN14nsXPTCStubBase6Stub124Ev:
        addi    r12,   0,124
        b       _SharedStub
        .elseif 124 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub124Ev
        .align  2
__ZN14nsXPTCStubBase7Stub124Ev:
        addi    r12,   0,124
        b       _SharedStub
        .else
        .err    "Stub124 >= 1000 not yet supported."
        .endif

       .if     125 < 10
        .globl  __ZN14nsXPTCStubBase5Stub125Ev
        .align  2
__ZN14nsXPTCStubBase5Stub125Ev:
        addi    r12,   0,125
        b       _SharedStub
        .elseif 125 < 100
        .globl  __ZN14nsXPTCStubBase6Stub125Ev
        .align  2
__ZN14nsXPTCStubBase6Stub125Ev:
        addi    r12,   0,125
        b       _SharedStub
        .elseif 125 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub125Ev
        .align  2
__ZN14nsXPTCStubBase7Stub125Ev:
        addi    r12,   0,125
        b       _SharedStub
        .else
        .err    "Stub125 >= 1000 not yet supported."
        .endif

       .if     126 < 10
        .globl  __ZN14nsXPTCStubBase5Stub126Ev
        .align  2
__ZN14nsXPTCStubBase5Stub126Ev:
        addi    r12,   0,126
        b       _SharedStub
        .elseif 126 < 100
        .globl  __ZN14nsXPTCStubBase6Stub126Ev
        .align  2
__ZN14nsXPTCStubBase6Stub126Ev:
        addi    r12,   0,126
        b       _SharedStub
        .elseif 126 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub126Ev
        .align  2
__ZN14nsXPTCStubBase7Stub126Ev:
        addi    r12,   0,126
        b       _SharedStub
        .else
        .err    "Stub126 >= 1000 not yet supported."
        .endif

       .if     127 < 10
        .globl  __ZN14nsXPTCStubBase5Stub127Ev
        .align  2
__ZN14nsXPTCStubBase5Stub127Ev:
        addi    r12,   0,127
        b       _SharedStub
        .elseif 127 < 100
        .globl  __ZN14nsXPTCStubBase6Stub127Ev
        .align  2
__ZN14nsXPTCStubBase6Stub127Ev:
        addi    r12,   0,127
        b       _SharedStub
        .elseif 127 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub127Ev
        .align  2
__ZN14nsXPTCStubBase7Stub127Ev:
        addi    r12,   0,127
        b       _SharedStub
        .else
        .err    "Stub127 >= 1000 not yet supported."
        .endif

       .if     128 < 10
        .globl  __ZN14nsXPTCStubBase5Stub128Ev
        .align  2
__ZN14nsXPTCStubBase5Stub128Ev:
        addi    r12,   0,128
        b       _SharedStub
        .elseif 128 < 100
        .globl  __ZN14nsXPTCStubBase6Stub128Ev
        .align  2
__ZN14nsXPTCStubBase6Stub128Ev:
        addi    r12,   0,128
        b       _SharedStub
        .elseif 128 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub128Ev
        .align  2
__ZN14nsXPTCStubBase7Stub128Ev:
        addi    r12,   0,128
        b       _SharedStub
        .else
        .err    "Stub128 >= 1000 not yet supported."
        .endif

       .if     129 < 10
        .globl  __ZN14nsXPTCStubBase5Stub129Ev
        .align  2
__ZN14nsXPTCStubBase5Stub129Ev:
        addi    r12,   0,129
        b       _SharedStub
        .elseif 129 < 100
        .globl  __ZN14nsXPTCStubBase6Stub129Ev
        .align  2
__ZN14nsXPTCStubBase6Stub129Ev:
        addi    r12,   0,129
        b       _SharedStub
        .elseif 129 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub129Ev
        .align  2
__ZN14nsXPTCStubBase7Stub129Ev:
        addi    r12,   0,129
        b       _SharedStub
        .else
        .err    "Stub129 >= 1000 not yet supported."
        .endif

       .if     130 < 10
        .globl  __ZN14nsXPTCStubBase5Stub130Ev
        .align  2
__ZN14nsXPTCStubBase5Stub130Ev:
        addi    r12,   0,130
        b       _SharedStub
        .elseif 130 < 100
        .globl  __ZN14nsXPTCStubBase6Stub130Ev
        .align  2
__ZN14nsXPTCStubBase6Stub130Ev:
        addi    r12,   0,130
        b       _SharedStub
        .elseif 130 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub130Ev
        .align  2
__ZN14nsXPTCStubBase7Stub130Ev:
        addi    r12,   0,130
        b       _SharedStub
        .else
        .err    "Stub130 >= 1000 not yet supported."
        .endif

       .if     131 < 10
        .globl  __ZN14nsXPTCStubBase5Stub131Ev
        .align  2
__ZN14nsXPTCStubBase5Stub131Ev:
        addi    r12,   0,131
        b       _SharedStub
        .elseif 131 < 100
        .globl  __ZN14nsXPTCStubBase6Stub131Ev
        .align  2
__ZN14nsXPTCStubBase6Stub131Ev:
        addi    r12,   0,131
        b       _SharedStub
        .elseif 131 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub131Ev
        .align  2
__ZN14nsXPTCStubBase7Stub131Ev:
        addi    r12,   0,131
        b       _SharedStub
        .else
        .err    "Stub131 >= 1000 not yet supported."
        .endif

       .if     132 < 10
        .globl  __ZN14nsXPTCStubBase5Stub132Ev
        .align  2
__ZN14nsXPTCStubBase5Stub132Ev:
        addi    r12,   0,132
        b       _SharedStub
        .elseif 132 < 100
        .globl  __ZN14nsXPTCStubBase6Stub132Ev
        .align  2
__ZN14nsXPTCStubBase6Stub132Ev:
        addi    r12,   0,132
        b       _SharedStub
        .elseif 132 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub132Ev
        .align  2
__ZN14nsXPTCStubBase7Stub132Ev:
        addi    r12,   0,132
        b       _SharedStub
        .else
        .err    "Stub132 >= 1000 not yet supported."
        .endif

       .if     133 < 10
        .globl  __ZN14nsXPTCStubBase5Stub133Ev
        .align  2
__ZN14nsXPTCStubBase5Stub133Ev:
        addi    r12,   0,133
        b       _SharedStub
        .elseif 133 < 100
        .globl  __ZN14nsXPTCStubBase6Stub133Ev
        .align  2
__ZN14nsXPTCStubBase6Stub133Ev:
        addi    r12,   0,133
        b       _SharedStub
        .elseif 133 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub133Ev
        .align  2
__ZN14nsXPTCStubBase7Stub133Ev:
        addi    r12,   0,133
        b       _SharedStub
        .else
        .err    "Stub133 >= 1000 not yet supported."
        .endif

       .if     134 < 10
        .globl  __ZN14nsXPTCStubBase5Stub134Ev
        .align  2
__ZN14nsXPTCStubBase5Stub134Ev:
        addi    r12,   0,134
        b       _SharedStub
        .elseif 134 < 100
        .globl  __ZN14nsXPTCStubBase6Stub134Ev
        .align  2
__ZN14nsXPTCStubBase6Stub134Ev:
        addi    r12,   0,134
        b       _SharedStub
        .elseif 134 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub134Ev
        .align  2
__ZN14nsXPTCStubBase7Stub134Ev:
        addi    r12,   0,134
        b       _SharedStub
        .else
        .err    "Stub134 >= 1000 not yet supported."
        .endif

       .if     135 < 10
        .globl  __ZN14nsXPTCStubBase5Stub135Ev
        .align  2
__ZN14nsXPTCStubBase5Stub135Ev:
        addi    r12,   0,135
        b       _SharedStub
        .elseif 135 < 100
        .globl  __ZN14nsXPTCStubBase6Stub135Ev
        .align  2
__ZN14nsXPTCStubBase6Stub135Ev:
        addi    r12,   0,135
        b       _SharedStub
        .elseif 135 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub135Ev
        .align  2
__ZN14nsXPTCStubBase7Stub135Ev:
        addi    r12,   0,135
        b       _SharedStub
        .else
        .err    "Stub135 >= 1000 not yet supported."
        .endif

       .if     136 < 10
        .globl  __ZN14nsXPTCStubBase5Stub136Ev
        .align  2
__ZN14nsXPTCStubBase5Stub136Ev:
        addi    r12,   0,136
        b       _SharedStub
        .elseif 136 < 100
        .globl  __ZN14nsXPTCStubBase6Stub136Ev
        .align  2
__ZN14nsXPTCStubBase6Stub136Ev:
        addi    r12,   0,136
        b       _SharedStub
        .elseif 136 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub136Ev
        .align  2
__ZN14nsXPTCStubBase7Stub136Ev:
        addi    r12,   0,136
        b       _SharedStub
        .else
        .err    "Stub136 >= 1000 not yet supported."
        .endif

       .if     137 < 10
        .globl  __ZN14nsXPTCStubBase5Stub137Ev
        .align  2
__ZN14nsXPTCStubBase5Stub137Ev:
        addi    r12,   0,137
        b       _SharedStub
        .elseif 137 < 100
        .globl  __ZN14nsXPTCStubBase6Stub137Ev
        .align  2
__ZN14nsXPTCStubBase6Stub137Ev:
        addi    r12,   0,137
        b       _SharedStub
        .elseif 137 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub137Ev
        .align  2
__ZN14nsXPTCStubBase7Stub137Ev:
        addi    r12,   0,137
        b       _SharedStub
        .else
        .err    "Stub137 >= 1000 not yet supported."
        .endif

       .if     138 < 10
        .globl  __ZN14nsXPTCStubBase5Stub138Ev
        .align  2
__ZN14nsXPTCStubBase5Stub138Ev:
        addi    r12,   0,138
        b       _SharedStub
        .elseif 138 < 100
        .globl  __ZN14nsXPTCStubBase6Stub138Ev
        .align  2
__ZN14nsXPTCStubBase6Stub138Ev:
        addi    r12,   0,138
        b       _SharedStub
        .elseif 138 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub138Ev
        .align  2
__ZN14nsXPTCStubBase7Stub138Ev:
        addi    r12,   0,138
        b       _SharedStub
        .else
        .err    "Stub138 >= 1000 not yet supported."
        .endif

       .if     139 < 10
        .globl  __ZN14nsXPTCStubBase5Stub139Ev
        .align  2
__ZN14nsXPTCStubBase5Stub139Ev:
        addi    r12,   0,139
        b       _SharedStub
        .elseif 139 < 100
        .globl  __ZN14nsXPTCStubBase6Stub139Ev
        .align  2
__ZN14nsXPTCStubBase6Stub139Ev:
        addi    r12,   0,139
        b       _SharedStub
        .elseif 139 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub139Ev
        .align  2
__ZN14nsXPTCStubBase7Stub139Ev:
        addi    r12,   0,139
        b       _SharedStub
        .else
        .err    "Stub139 >= 1000 not yet supported."
        .endif

       .if     140 < 10
        .globl  __ZN14nsXPTCStubBase5Stub140Ev
        .align  2
__ZN14nsXPTCStubBase5Stub140Ev:
        addi    r12,   0,140
        b       _SharedStub
        .elseif 140 < 100
        .globl  __ZN14nsXPTCStubBase6Stub140Ev
        .align  2
__ZN14nsXPTCStubBase6Stub140Ev:
        addi    r12,   0,140
        b       _SharedStub
        .elseif 140 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub140Ev
        .align  2
__ZN14nsXPTCStubBase7Stub140Ev:
        addi    r12,   0,140
        b       _SharedStub
        .else
        .err    "Stub140 >= 1000 not yet supported."
        .endif

       .if     141 < 10
        .globl  __ZN14nsXPTCStubBase5Stub141Ev
        .align  2
__ZN14nsXPTCStubBase5Stub141Ev:
        addi    r12,   0,141
        b       _SharedStub
        .elseif 141 < 100
        .globl  __ZN14nsXPTCStubBase6Stub141Ev
        .align  2
__ZN14nsXPTCStubBase6Stub141Ev:
        addi    r12,   0,141
        b       _SharedStub
        .elseif 141 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub141Ev
        .align  2
__ZN14nsXPTCStubBase7Stub141Ev:
        addi    r12,   0,141
        b       _SharedStub
        .else
        .err    "Stub141 >= 1000 not yet supported."
        .endif

       .if     142 < 10
        .globl  __ZN14nsXPTCStubBase5Stub142Ev
        .align  2
__ZN14nsXPTCStubBase5Stub142Ev:
        addi    r12,   0,142
        b       _SharedStub
        .elseif 142 < 100
        .globl  __ZN14nsXPTCStubBase6Stub142Ev
        .align  2
__ZN14nsXPTCStubBase6Stub142Ev:
        addi    r12,   0,142
        b       _SharedStub
        .elseif 142 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub142Ev
        .align  2
__ZN14nsXPTCStubBase7Stub142Ev:
        addi    r12,   0,142
        b       _SharedStub
        .else
        .err    "Stub142 >= 1000 not yet supported."
        .endif

       .if     143 < 10
        .globl  __ZN14nsXPTCStubBase5Stub143Ev
        .align  2
__ZN14nsXPTCStubBase5Stub143Ev:
        addi    r12,   0,143
        b       _SharedStub
        .elseif 143 < 100
        .globl  __ZN14nsXPTCStubBase6Stub143Ev
        .align  2
__ZN14nsXPTCStubBase6Stub143Ev:
        addi    r12,   0,143
        b       _SharedStub
        .elseif 143 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub143Ev
        .align  2
__ZN14nsXPTCStubBase7Stub143Ev:
        addi    r12,   0,143
        b       _SharedStub
        .else
        .err    "Stub143 >= 1000 not yet supported."
        .endif

       .if     144 < 10
        .globl  __ZN14nsXPTCStubBase5Stub144Ev
        .align  2
__ZN14nsXPTCStubBase5Stub144Ev:
        addi    r12,   0,144
        b       _SharedStub
        .elseif 144 < 100
        .globl  __ZN14nsXPTCStubBase6Stub144Ev
        .align  2
__ZN14nsXPTCStubBase6Stub144Ev:
        addi    r12,   0,144
        b       _SharedStub
        .elseif 144 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub144Ev
        .align  2
__ZN14nsXPTCStubBase7Stub144Ev:
        addi    r12,   0,144
        b       _SharedStub
        .else
        .err    "Stub144 >= 1000 not yet supported."
        .endif

       .if     145 < 10
        .globl  __ZN14nsXPTCStubBase5Stub145Ev
        .align  2
__ZN14nsXPTCStubBase5Stub145Ev:
        addi    r12,   0,145
        b       _SharedStub
        .elseif 145 < 100
        .globl  __ZN14nsXPTCStubBase6Stub145Ev
        .align  2
__ZN14nsXPTCStubBase6Stub145Ev:
        addi    r12,   0,145
        b       _SharedStub
        .elseif 145 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub145Ev
        .align  2
__ZN14nsXPTCStubBase7Stub145Ev:
        addi    r12,   0,145
        b       _SharedStub
        .else
        .err    "Stub145 >= 1000 not yet supported."
        .endif

       .if     146 < 10
        .globl  __ZN14nsXPTCStubBase5Stub146Ev
        .align  2
__ZN14nsXPTCStubBase5Stub146Ev:
        addi    r12,   0,146
        b       _SharedStub
        .elseif 146 < 100
        .globl  __ZN14nsXPTCStubBase6Stub146Ev
        .align  2
__ZN14nsXPTCStubBase6Stub146Ev:
        addi    r12,   0,146
        b       _SharedStub
        .elseif 146 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub146Ev
        .align  2
__ZN14nsXPTCStubBase7Stub146Ev:
        addi    r12,   0,146
        b       _SharedStub
        .else
        .err    "Stub146 >= 1000 not yet supported."
        .endif

       .if     147 < 10
        .globl  __ZN14nsXPTCStubBase5Stub147Ev
        .align  2
__ZN14nsXPTCStubBase5Stub147Ev:
        addi    r12,   0,147
        b       _SharedStub
        .elseif 147 < 100
        .globl  __ZN14nsXPTCStubBase6Stub147Ev
        .align  2
__ZN14nsXPTCStubBase6Stub147Ev:
        addi    r12,   0,147
        b       _SharedStub
        .elseif 147 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub147Ev
        .align  2
__ZN14nsXPTCStubBase7Stub147Ev:
        addi    r12,   0,147
        b       _SharedStub
        .else
        .err    "Stub147 >= 1000 not yet supported."
        .endif

       .if     148 < 10
        .globl  __ZN14nsXPTCStubBase5Stub148Ev
        .align  2
__ZN14nsXPTCStubBase5Stub148Ev:
        addi    r12,   0,148
        b       _SharedStub
        .elseif 148 < 100
        .globl  __ZN14nsXPTCStubBase6Stub148Ev
        .align  2
__ZN14nsXPTCStubBase6Stub148Ev:
        addi    r12,   0,148
        b       _SharedStub
        .elseif 148 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub148Ev
        .align  2
__ZN14nsXPTCStubBase7Stub148Ev:
        addi    r12,   0,148
        b       _SharedStub
        .else
        .err    "Stub148 >= 1000 not yet supported."
        .endif

       .if     149 < 10
        .globl  __ZN14nsXPTCStubBase5Stub149Ev
        .align  2
__ZN14nsXPTCStubBase5Stub149Ev:
        addi    r12,   0,149
        b       _SharedStub
        .elseif 149 < 100
        .globl  __ZN14nsXPTCStubBase6Stub149Ev
        .align  2
__ZN14nsXPTCStubBase6Stub149Ev:
        addi    r12,   0,149
        b       _SharedStub
        .elseif 149 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub149Ev
        .align  2
__ZN14nsXPTCStubBase7Stub149Ev:
        addi    r12,   0,149
        b       _SharedStub
        .else
        .err    "Stub149 >= 1000 not yet supported."
        .endif

       .if     150 < 10
        .globl  __ZN14nsXPTCStubBase5Stub150Ev
        .align  2
__ZN14nsXPTCStubBase5Stub150Ev:
        addi    r12,   0,150
        b       _SharedStub
        .elseif 150 < 100
        .globl  __ZN14nsXPTCStubBase6Stub150Ev
        .align  2
__ZN14nsXPTCStubBase6Stub150Ev:
        addi    r12,   0,150
        b       _SharedStub
        .elseif 150 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub150Ev
        .align  2
__ZN14nsXPTCStubBase7Stub150Ev:
        addi    r12,   0,150
        b       _SharedStub
        .else
        .err    "Stub150 >= 1000 not yet supported."
        .endif

       .if     151 < 10
        .globl  __ZN14nsXPTCStubBase5Stub151Ev
        .align  2
__ZN14nsXPTCStubBase5Stub151Ev:
        addi    r12,   0,151
        b       _SharedStub
        .elseif 151 < 100
        .globl  __ZN14nsXPTCStubBase6Stub151Ev
        .align  2
__ZN14nsXPTCStubBase6Stub151Ev:
        addi    r12,   0,151
        b       _SharedStub
        .elseif 151 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub151Ev
        .align  2
__ZN14nsXPTCStubBase7Stub151Ev:
        addi    r12,   0,151
        b       _SharedStub
        .else
        .err    "Stub151 >= 1000 not yet supported."
        .endif

       .if     152 < 10
        .globl  __ZN14nsXPTCStubBase5Stub152Ev
        .align  2
__ZN14nsXPTCStubBase5Stub152Ev:
        addi    r12,   0,152
        b       _SharedStub
        .elseif 152 < 100
        .globl  __ZN14nsXPTCStubBase6Stub152Ev
        .align  2
__ZN14nsXPTCStubBase6Stub152Ev:
        addi    r12,   0,152
        b       _SharedStub
        .elseif 152 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub152Ev
        .align  2
__ZN14nsXPTCStubBase7Stub152Ev:
        addi    r12,   0,152
        b       _SharedStub
        .else
        .err    "Stub152 >= 1000 not yet supported."
        .endif

       .if     153 < 10
        .globl  __ZN14nsXPTCStubBase5Stub153Ev
        .align  2
__ZN14nsXPTCStubBase5Stub153Ev:
        addi    r12,   0,153
        b       _SharedStub
        .elseif 153 < 100
        .globl  __ZN14nsXPTCStubBase6Stub153Ev
        .align  2
__ZN14nsXPTCStubBase6Stub153Ev:
        addi    r12,   0,153
        b       _SharedStub
        .elseif 153 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub153Ev
        .align  2
__ZN14nsXPTCStubBase7Stub153Ev:
        addi    r12,   0,153
        b       _SharedStub
        .else
        .err    "Stub153 >= 1000 not yet supported."
        .endif

       .if     154 < 10
        .globl  __ZN14nsXPTCStubBase5Stub154Ev
        .align  2
__ZN14nsXPTCStubBase5Stub154Ev:
        addi    r12,   0,154
        b       _SharedStub
        .elseif 154 < 100
        .globl  __ZN14nsXPTCStubBase6Stub154Ev
        .align  2
__ZN14nsXPTCStubBase6Stub154Ev:
        addi    r12,   0,154
        b       _SharedStub
        .elseif 154 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub154Ev
        .align  2
__ZN14nsXPTCStubBase7Stub154Ev:
        addi    r12,   0,154
        b       _SharedStub
        .else
        .err    "Stub154 >= 1000 not yet supported."
        .endif

       .if     155 < 10
        .globl  __ZN14nsXPTCStubBase5Stub155Ev
        .align  2
__ZN14nsXPTCStubBase5Stub155Ev:
        addi    r12,   0,155
        b       _SharedStub
        .elseif 155 < 100
        .globl  __ZN14nsXPTCStubBase6Stub155Ev
        .align  2
__ZN14nsXPTCStubBase6Stub155Ev:
        addi    r12,   0,155
        b       _SharedStub
        .elseif 155 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub155Ev
        .align  2
__ZN14nsXPTCStubBase7Stub155Ev:
        addi    r12,   0,155
        b       _SharedStub
        .else
        .err    "Stub155 >= 1000 not yet supported."
        .endif

       .if     156 < 10
        .globl  __ZN14nsXPTCStubBase5Stub156Ev
        .align  2
__ZN14nsXPTCStubBase5Stub156Ev:
        addi    r12,   0,156
        b       _SharedStub
        .elseif 156 < 100
        .globl  __ZN14nsXPTCStubBase6Stub156Ev
        .align  2
__ZN14nsXPTCStubBase6Stub156Ev:
        addi    r12,   0,156
        b       _SharedStub
        .elseif 156 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub156Ev
        .align  2
__ZN14nsXPTCStubBase7Stub156Ev:
        addi    r12,   0,156
        b       _SharedStub
        .else
        .err    "Stub156 >= 1000 not yet supported."
        .endif

       .if     157 < 10
        .globl  __ZN14nsXPTCStubBase5Stub157Ev
        .align  2
__ZN14nsXPTCStubBase5Stub157Ev:
        addi    r12,   0,157
        b       _SharedStub
        .elseif 157 < 100
        .globl  __ZN14nsXPTCStubBase6Stub157Ev
        .align  2
__ZN14nsXPTCStubBase6Stub157Ev:
        addi    r12,   0,157
        b       _SharedStub
        .elseif 157 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub157Ev
        .align  2
__ZN14nsXPTCStubBase7Stub157Ev:
        addi    r12,   0,157
        b       _SharedStub
        .else
        .err    "Stub157 >= 1000 not yet supported."
        .endif

       .if     158 < 10
        .globl  __ZN14nsXPTCStubBase5Stub158Ev
        .align  2
__ZN14nsXPTCStubBase5Stub158Ev:
        addi    r12,   0,158
        b       _SharedStub
        .elseif 158 < 100
        .globl  __ZN14nsXPTCStubBase6Stub158Ev
        .align  2
__ZN14nsXPTCStubBase6Stub158Ev:
        addi    r12,   0,158
        b       _SharedStub
        .elseif 158 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub158Ev
        .align  2
__ZN14nsXPTCStubBase7Stub158Ev:
        addi    r12,   0,158
        b       _SharedStub
        .else
        .err    "Stub158 >= 1000 not yet supported."
        .endif

       .if     159 < 10
        .globl  __ZN14nsXPTCStubBase5Stub159Ev
        .align  2
__ZN14nsXPTCStubBase5Stub159Ev:
        addi    r12,   0,159
        b       _SharedStub
        .elseif 159 < 100
        .globl  __ZN14nsXPTCStubBase6Stub159Ev
        .align  2
__ZN14nsXPTCStubBase6Stub159Ev:
        addi    r12,   0,159
        b       _SharedStub
        .elseif 159 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub159Ev
        .align  2
__ZN14nsXPTCStubBase7Stub159Ev:
        addi    r12,   0,159
        b       _SharedStub
        .else
        .err    "Stub159 >= 1000 not yet supported."
        .endif

       .if     160 < 10
        .globl  __ZN14nsXPTCStubBase5Stub160Ev
        .align  2
__ZN14nsXPTCStubBase5Stub160Ev:
        addi    r12,   0,160
        b       _SharedStub
        .elseif 160 < 100
        .globl  __ZN14nsXPTCStubBase6Stub160Ev
        .align  2
__ZN14nsXPTCStubBase6Stub160Ev:
        addi    r12,   0,160
        b       _SharedStub
        .elseif 160 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub160Ev
        .align  2
__ZN14nsXPTCStubBase7Stub160Ev:
        addi    r12,   0,160
        b       _SharedStub
        .else
        .err    "Stub160 >= 1000 not yet supported."
        .endif

       .if     161 < 10
        .globl  __ZN14nsXPTCStubBase5Stub161Ev
        .align  2
__ZN14nsXPTCStubBase5Stub161Ev:
        addi    r12,   0,161
        b       _SharedStub
        .elseif 161 < 100
        .globl  __ZN14nsXPTCStubBase6Stub161Ev
        .align  2
__ZN14nsXPTCStubBase6Stub161Ev:
        addi    r12,   0,161
        b       _SharedStub
        .elseif 161 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub161Ev
        .align  2
__ZN14nsXPTCStubBase7Stub161Ev:
        addi    r12,   0,161
        b       _SharedStub
        .else
        .err    "Stub161 >= 1000 not yet supported."
        .endif

       .if     162 < 10
        .globl  __ZN14nsXPTCStubBase5Stub162Ev
        .align  2
__ZN14nsXPTCStubBase5Stub162Ev:
        addi    r12,   0,162
        b       _SharedStub
        .elseif 162 < 100
        .globl  __ZN14nsXPTCStubBase6Stub162Ev
        .align  2
__ZN14nsXPTCStubBase6Stub162Ev:
        addi    r12,   0,162
        b       _SharedStub
        .elseif 162 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub162Ev
        .align  2
__ZN14nsXPTCStubBase7Stub162Ev:
        addi    r12,   0,162
        b       _SharedStub
        .else
        .err    "Stub162 >= 1000 not yet supported."
        .endif

       .if     163 < 10
        .globl  __ZN14nsXPTCStubBase5Stub163Ev
        .align  2
__ZN14nsXPTCStubBase5Stub163Ev:
        addi    r12,   0,163
        b       _SharedStub
        .elseif 163 < 100
        .globl  __ZN14nsXPTCStubBase6Stub163Ev
        .align  2
__ZN14nsXPTCStubBase6Stub163Ev:
        addi    r12,   0,163
        b       _SharedStub
        .elseif 163 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub163Ev
        .align  2
__ZN14nsXPTCStubBase7Stub163Ev:
        addi    r12,   0,163
        b       _SharedStub
        .else
        .err    "Stub163 >= 1000 not yet supported."
        .endif

       .if     164 < 10
        .globl  __ZN14nsXPTCStubBase5Stub164Ev
        .align  2
__ZN14nsXPTCStubBase5Stub164Ev:
        addi    r12,   0,164
        b       _SharedStub
        .elseif 164 < 100
        .globl  __ZN14nsXPTCStubBase6Stub164Ev
        .align  2
__ZN14nsXPTCStubBase6Stub164Ev:
        addi    r12,   0,164
        b       _SharedStub
        .elseif 164 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub164Ev
        .align  2
__ZN14nsXPTCStubBase7Stub164Ev:
        addi    r12,   0,164
        b       _SharedStub
        .else
        .err    "Stub164 >= 1000 not yet supported."
        .endif

       .if     165 < 10
        .globl  __ZN14nsXPTCStubBase5Stub165Ev
        .align  2
__ZN14nsXPTCStubBase5Stub165Ev:
        addi    r12,   0,165
        b       _SharedStub
        .elseif 165 < 100
        .globl  __ZN14nsXPTCStubBase6Stub165Ev
        .align  2
__ZN14nsXPTCStubBase6Stub165Ev:
        addi    r12,   0,165
        b       _SharedStub
        .elseif 165 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub165Ev
        .align  2
__ZN14nsXPTCStubBase7Stub165Ev:
        addi    r12,   0,165
        b       _SharedStub
        .else
        .err    "Stub165 >= 1000 not yet supported."
        .endif

       .if     166 < 10
        .globl  __ZN14nsXPTCStubBase5Stub166Ev
        .align  2
__ZN14nsXPTCStubBase5Stub166Ev:
        addi    r12,   0,166
        b       _SharedStub
        .elseif 166 < 100
        .globl  __ZN14nsXPTCStubBase6Stub166Ev
        .align  2
__ZN14nsXPTCStubBase6Stub166Ev:
        addi    r12,   0,166
        b       _SharedStub
        .elseif 166 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub166Ev
        .align  2
__ZN14nsXPTCStubBase7Stub166Ev:
        addi    r12,   0,166
        b       _SharedStub
        .else
        .err    "Stub166 >= 1000 not yet supported."
        .endif

       .if     167 < 10
        .globl  __ZN14nsXPTCStubBase5Stub167Ev
        .align  2
__ZN14nsXPTCStubBase5Stub167Ev:
        addi    r12,   0,167
        b       _SharedStub
        .elseif 167 < 100
        .globl  __ZN14nsXPTCStubBase6Stub167Ev
        .align  2
__ZN14nsXPTCStubBase6Stub167Ev:
        addi    r12,   0,167
        b       _SharedStub
        .elseif 167 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub167Ev
        .align  2
__ZN14nsXPTCStubBase7Stub167Ev:
        addi    r12,   0,167
        b       _SharedStub
        .else
        .err    "Stub167 >= 1000 not yet supported."
        .endif

       .if     168 < 10
        .globl  __ZN14nsXPTCStubBase5Stub168Ev
        .align  2
__ZN14nsXPTCStubBase5Stub168Ev:
        addi    r12,   0,168
        b       _SharedStub
        .elseif 168 < 100
        .globl  __ZN14nsXPTCStubBase6Stub168Ev
        .align  2
__ZN14nsXPTCStubBase6Stub168Ev:
        addi    r12,   0,168
        b       _SharedStub
        .elseif 168 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub168Ev
        .align  2
__ZN14nsXPTCStubBase7Stub168Ev:
        addi    r12,   0,168
        b       _SharedStub
        .else
        .err    "Stub168 >= 1000 not yet supported."
        .endif

       .if     169 < 10
        .globl  __ZN14nsXPTCStubBase5Stub169Ev
        .align  2
__ZN14nsXPTCStubBase5Stub169Ev:
        addi    r12,   0,169
        b       _SharedStub
        .elseif 169 < 100
        .globl  __ZN14nsXPTCStubBase6Stub169Ev
        .align  2
__ZN14nsXPTCStubBase6Stub169Ev:
        addi    r12,   0,169
        b       _SharedStub
        .elseif 169 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub169Ev
        .align  2
__ZN14nsXPTCStubBase7Stub169Ev:
        addi    r12,   0,169
        b       _SharedStub
        .else
        .err    "Stub169 >= 1000 not yet supported."
        .endif

       .if     170 < 10
        .globl  __ZN14nsXPTCStubBase5Stub170Ev
        .align  2
__ZN14nsXPTCStubBase5Stub170Ev:
        addi    r12,   0,170
        b       _SharedStub
        .elseif 170 < 100
        .globl  __ZN14nsXPTCStubBase6Stub170Ev
        .align  2
__ZN14nsXPTCStubBase6Stub170Ev:
        addi    r12,   0,170
        b       _SharedStub
        .elseif 170 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub170Ev
        .align  2
__ZN14nsXPTCStubBase7Stub170Ev:
        addi    r12,   0,170
        b       _SharedStub
        .else
        .err    "Stub170 >= 1000 not yet supported."
        .endif

       .if     171 < 10
        .globl  __ZN14nsXPTCStubBase5Stub171Ev
        .align  2
__ZN14nsXPTCStubBase5Stub171Ev:
        addi    r12,   0,171
        b       _SharedStub
        .elseif 171 < 100
        .globl  __ZN14nsXPTCStubBase6Stub171Ev
        .align  2
__ZN14nsXPTCStubBase6Stub171Ev:
        addi    r12,   0,171
        b       _SharedStub
        .elseif 171 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub171Ev
        .align  2
__ZN14nsXPTCStubBase7Stub171Ev:
        addi    r12,   0,171
        b       _SharedStub
        .else
        .err    "Stub171 >= 1000 not yet supported."
        .endif

       .if     172 < 10
        .globl  __ZN14nsXPTCStubBase5Stub172Ev
        .align  2
__ZN14nsXPTCStubBase5Stub172Ev:
        addi    r12,   0,172
        b       _SharedStub
        .elseif 172 < 100
        .globl  __ZN14nsXPTCStubBase6Stub172Ev
        .align  2
__ZN14nsXPTCStubBase6Stub172Ev:
        addi    r12,   0,172
        b       _SharedStub
        .elseif 172 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub172Ev
        .align  2
__ZN14nsXPTCStubBase7Stub172Ev:
        addi    r12,   0,172
        b       _SharedStub
        .else
        .err    "Stub172 >= 1000 not yet supported."
        .endif

       .if     173 < 10
        .globl  __ZN14nsXPTCStubBase5Stub173Ev
        .align  2
__ZN14nsXPTCStubBase5Stub173Ev:
        addi    r12,   0,173
        b       _SharedStub
        .elseif 173 < 100
        .globl  __ZN14nsXPTCStubBase6Stub173Ev
        .align  2
__ZN14nsXPTCStubBase6Stub173Ev:
        addi    r12,   0,173
        b       _SharedStub
        .elseif 173 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub173Ev
        .align  2
__ZN14nsXPTCStubBase7Stub173Ev:
        addi    r12,   0,173
        b       _SharedStub
        .else
        .err    "Stub173 >= 1000 not yet supported."
        .endif

       .if     174 < 10
        .globl  __ZN14nsXPTCStubBase5Stub174Ev
        .align  2
__ZN14nsXPTCStubBase5Stub174Ev:
        addi    r12,   0,174
        b       _SharedStub
        .elseif 174 < 100
        .globl  __ZN14nsXPTCStubBase6Stub174Ev
        .align  2
__ZN14nsXPTCStubBase6Stub174Ev:
        addi    r12,   0,174
        b       _SharedStub
        .elseif 174 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub174Ev
        .align  2
__ZN14nsXPTCStubBase7Stub174Ev:
        addi    r12,   0,174
        b       _SharedStub
        .else
        .err    "Stub174 >= 1000 not yet supported."
        .endif

       .if     175 < 10
        .globl  __ZN14nsXPTCStubBase5Stub175Ev
        .align  2
__ZN14nsXPTCStubBase5Stub175Ev:
        addi    r12,   0,175
        b       _SharedStub
        .elseif 175 < 100
        .globl  __ZN14nsXPTCStubBase6Stub175Ev
        .align  2
__ZN14nsXPTCStubBase6Stub175Ev:
        addi    r12,   0,175
        b       _SharedStub
        .elseif 175 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub175Ev
        .align  2
__ZN14nsXPTCStubBase7Stub175Ev:
        addi    r12,   0,175
        b       _SharedStub
        .else
        .err    "Stub175 >= 1000 not yet supported."
        .endif

       .if     176 < 10
        .globl  __ZN14nsXPTCStubBase5Stub176Ev
        .align  2
__ZN14nsXPTCStubBase5Stub176Ev:
        addi    r12,   0,176
        b       _SharedStub
        .elseif 176 < 100
        .globl  __ZN14nsXPTCStubBase6Stub176Ev
        .align  2
__ZN14nsXPTCStubBase6Stub176Ev:
        addi    r12,   0,176
        b       _SharedStub
        .elseif 176 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub176Ev
        .align  2
__ZN14nsXPTCStubBase7Stub176Ev:
        addi    r12,   0,176
        b       _SharedStub
        .else
        .err    "Stub176 >= 1000 not yet supported."
        .endif

       .if     177 < 10
        .globl  __ZN14nsXPTCStubBase5Stub177Ev
        .align  2
__ZN14nsXPTCStubBase5Stub177Ev:
        addi    r12,   0,177
        b       _SharedStub
        .elseif 177 < 100
        .globl  __ZN14nsXPTCStubBase6Stub177Ev
        .align  2
__ZN14nsXPTCStubBase6Stub177Ev:
        addi    r12,   0,177
        b       _SharedStub
        .elseif 177 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub177Ev
        .align  2
__ZN14nsXPTCStubBase7Stub177Ev:
        addi    r12,   0,177
        b       _SharedStub
        .else
        .err    "Stub177 >= 1000 not yet supported."
        .endif

       .if     178 < 10
        .globl  __ZN14nsXPTCStubBase5Stub178Ev
        .align  2
__ZN14nsXPTCStubBase5Stub178Ev:
        addi    r12,   0,178
        b       _SharedStub
        .elseif 178 < 100
        .globl  __ZN14nsXPTCStubBase6Stub178Ev
        .align  2
__ZN14nsXPTCStubBase6Stub178Ev:
        addi    r12,   0,178
        b       _SharedStub
        .elseif 178 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub178Ev
        .align  2
__ZN14nsXPTCStubBase7Stub178Ev:
        addi    r12,   0,178
        b       _SharedStub
        .else
        .err    "Stub178 >= 1000 not yet supported."
        .endif

       .if     179 < 10
        .globl  __ZN14nsXPTCStubBase5Stub179Ev
        .align  2
__ZN14nsXPTCStubBase5Stub179Ev:
        addi    r12,   0,179
        b       _SharedStub
        .elseif 179 < 100
        .globl  __ZN14nsXPTCStubBase6Stub179Ev
        .align  2
__ZN14nsXPTCStubBase6Stub179Ev:
        addi    r12,   0,179
        b       _SharedStub
        .elseif 179 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub179Ev
        .align  2
__ZN14nsXPTCStubBase7Stub179Ev:
        addi    r12,   0,179
        b       _SharedStub
        .else
        .err    "Stub179 >= 1000 not yet supported."
        .endif

       .if     180 < 10
        .globl  __ZN14nsXPTCStubBase5Stub180Ev
        .align  2
__ZN14nsXPTCStubBase5Stub180Ev:
        addi    r12,   0,180
        b       _SharedStub
        .elseif 180 < 100
        .globl  __ZN14nsXPTCStubBase6Stub180Ev
        .align  2
__ZN14nsXPTCStubBase6Stub180Ev:
        addi    r12,   0,180
        b       _SharedStub
        .elseif 180 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub180Ev
        .align  2
__ZN14nsXPTCStubBase7Stub180Ev:
        addi    r12,   0,180
        b       _SharedStub
        .else
        .err    "Stub180 >= 1000 not yet supported."
        .endif

       .if     181 < 10
        .globl  __ZN14nsXPTCStubBase5Stub181Ev
        .align  2
__ZN14nsXPTCStubBase5Stub181Ev:
        addi    r12,   0,181
        b       _SharedStub
        .elseif 181 < 100
        .globl  __ZN14nsXPTCStubBase6Stub181Ev
        .align  2
__ZN14nsXPTCStubBase6Stub181Ev:
        addi    r12,   0,181
        b       _SharedStub
        .elseif 181 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub181Ev
        .align  2
__ZN14nsXPTCStubBase7Stub181Ev:
        addi    r12,   0,181
        b       _SharedStub
        .else
        .err    "Stub181 >= 1000 not yet supported."
        .endif

       .if     182 < 10
        .globl  __ZN14nsXPTCStubBase5Stub182Ev
        .align  2
__ZN14nsXPTCStubBase5Stub182Ev:
        addi    r12,   0,182
        b       _SharedStub
        .elseif 182 < 100
        .globl  __ZN14nsXPTCStubBase6Stub182Ev
        .align  2
__ZN14nsXPTCStubBase6Stub182Ev:
        addi    r12,   0,182
        b       _SharedStub
        .elseif 182 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub182Ev
        .align  2
__ZN14nsXPTCStubBase7Stub182Ev:
        addi    r12,   0,182
        b       _SharedStub
        .else
        .err    "Stub182 >= 1000 not yet supported."
        .endif

       .if     183 < 10
        .globl  __ZN14nsXPTCStubBase5Stub183Ev
        .align  2
__ZN14nsXPTCStubBase5Stub183Ev:
        addi    r12,   0,183
        b       _SharedStub
        .elseif 183 < 100
        .globl  __ZN14nsXPTCStubBase6Stub183Ev
        .align  2
__ZN14nsXPTCStubBase6Stub183Ev:
        addi    r12,   0,183
        b       _SharedStub
        .elseif 183 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub183Ev
        .align  2
__ZN14nsXPTCStubBase7Stub183Ev:
        addi    r12,   0,183
        b       _SharedStub
        .else
        .err    "Stub183 >= 1000 not yet supported."
        .endif

       .if     184 < 10
        .globl  __ZN14nsXPTCStubBase5Stub184Ev
        .align  2
__ZN14nsXPTCStubBase5Stub184Ev:
        addi    r12,   0,184
        b       _SharedStub
        .elseif 184 < 100
        .globl  __ZN14nsXPTCStubBase6Stub184Ev
        .align  2
__ZN14nsXPTCStubBase6Stub184Ev:
        addi    r12,   0,184
        b       _SharedStub
        .elseif 184 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub184Ev
        .align  2
__ZN14nsXPTCStubBase7Stub184Ev:
        addi    r12,   0,184
        b       _SharedStub
        .else
        .err    "Stub184 >= 1000 not yet supported."
        .endif

       .if     185 < 10
        .globl  __ZN14nsXPTCStubBase5Stub185Ev
        .align  2
__ZN14nsXPTCStubBase5Stub185Ev:
        addi    r12,   0,185
        b       _SharedStub
        .elseif 185 < 100
        .globl  __ZN14nsXPTCStubBase6Stub185Ev
        .align  2
__ZN14nsXPTCStubBase6Stub185Ev:
        addi    r12,   0,185
        b       _SharedStub
        .elseif 185 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub185Ev
        .align  2
__ZN14nsXPTCStubBase7Stub185Ev:
        addi    r12,   0,185
        b       _SharedStub
        .else
        .err    "Stub185 >= 1000 not yet supported."
        .endif

       .if     186 < 10
        .globl  __ZN14nsXPTCStubBase5Stub186Ev
        .align  2
__ZN14nsXPTCStubBase5Stub186Ev:
        addi    r12,   0,186
        b       _SharedStub
        .elseif 186 < 100
        .globl  __ZN14nsXPTCStubBase6Stub186Ev
        .align  2
__ZN14nsXPTCStubBase6Stub186Ev:
        addi    r12,   0,186
        b       _SharedStub
        .elseif 186 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub186Ev
        .align  2
__ZN14nsXPTCStubBase7Stub186Ev:
        addi    r12,   0,186
        b       _SharedStub
        .else
        .err    "Stub186 >= 1000 not yet supported."
        .endif

       .if     187 < 10
        .globl  __ZN14nsXPTCStubBase5Stub187Ev
        .align  2
__ZN14nsXPTCStubBase5Stub187Ev:
        addi    r12,   0,187
        b       _SharedStub
        .elseif 187 < 100
        .globl  __ZN14nsXPTCStubBase6Stub187Ev
        .align  2
__ZN14nsXPTCStubBase6Stub187Ev:
        addi    r12,   0,187
        b       _SharedStub
        .elseif 187 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub187Ev
        .align  2
__ZN14nsXPTCStubBase7Stub187Ev:
        addi    r12,   0,187
        b       _SharedStub
        .else
        .err    "Stub187 >= 1000 not yet supported."
        .endif

       .if     188 < 10
        .globl  __ZN14nsXPTCStubBase5Stub188Ev
        .align  2
__ZN14nsXPTCStubBase5Stub188Ev:
        addi    r12,   0,188
        b       _SharedStub
        .elseif 188 < 100
        .globl  __ZN14nsXPTCStubBase6Stub188Ev
        .align  2
__ZN14nsXPTCStubBase6Stub188Ev:
        addi    r12,   0,188
        b       _SharedStub
        .elseif 188 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub188Ev
        .align  2
__ZN14nsXPTCStubBase7Stub188Ev:
        addi    r12,   0,188
        b       _SharedStub
        .else
        .err    "Stub188 >= 1000 not yet supported."
        .endif

       .if     189 < 10
        .globl  __ZN14nsXPTCStubBase5Stub189Ev
        .align  2
__ZN14nsXPTCStubBase5Stub189Ev:
        addi    r12,   0,189
        b       _SharedStub
        .elseif 189 < 100
        .globl  __ZN14nsXPTCStubBase6Stub189Ev
        .align  2
__ZN14nsXPTCStubBase6Stub189Ev:
        addi    r12,   0,189
        b       _SharedStub
        .elseif 189 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub189Ev
        .align  2
__ZN14nsXPTCStubBase7Stub189Ev:
        addi    r12,   0,189
        b       _SharedStub
        .else
        .err    "Stub189 >= 1000 not yet supported."
        .endif

       .if     190 < 10
        .globl  __ZN14nsXPTCStubBase5Stub190Ev
        .align  2
__ZN14nsXPTCStubBase5Stub190Ev:
        addi    r12,   0,190
        b       _SharedStub
        .elseif 190 < 100
        .globl  __ZN14nsXPTCStubBase6Stub190Ev
        .align  2
__ZN14nsXPTCStubBase6Stub190Ev:
        addi    r12,   0,190
        b       _SharedStub
        .elseif 190 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub190Ev
        .align  2
__ZN14nsXPTCStubBase7Stub190Ev:
        addi    r12,   0,190
        b       _SharedStub
        .else
        .err    "Stub190 >= 1000 not yet supported."
        .endif

       .if     191 < 10
        .globl  __ZN14nsXPTCStubBase5Stub191Ev
        .align  2
__ZN14nsXPTCStubBase5Stub191Ev:
        addi    r12,   0,191
        b       _SharedStub
        .elseif 191 < 100
        .globl  __ZN14nsXPTCStubBase6Stub191Ev
        .align  2
__ZN14nsXPTCStubBase6Stub191Ev:
        addi    r12,   0,191
        b       _SharedStub
        .elseif 191 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub191Ev
        .align  2
__ZN14nsXPTCStubBase7Stub191Ev:
        addi    r12,   0,191
        b       _SharedStub
        .else
        .err    "Stub191 >= 1000 not yet supported."
        .endif

       .if     192 < 10
        .globl  __ZN14nsXPTCStubBase5Stub192Ev
        .align  2
__ZN14nsXPTCStubBase5Stub192Ev:
        addi    r12,   0,192
        b       _SharedStub
        .elseif 192 < 100
        .globl  __ZN14nsXPTCStubBase6Stub192Ev
        .align  2
__ZN14nsXPTCStubBase6Stub192Ev:
        addi    r12,   0,192
        b       _SharedStub
        .elseif 192 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub192Ev
        .align  2
__ZN14nsXPTCStubBase7Stub192Ev:
        addi    r12,   0,192
        b       _SharedStub
        .else
        .err    "Stub192 >= 1000 not yet supported."
        .endif

       .if     193 < 10
        .globl  __ZN14nsXPTCStubBase5Stub193Ev
        .align  2
__ZN14nsXPTCStubBase5Stub193Ev:
        addi    r12,   0,193
        b       _SharedStub
        .elseif 193 < 100
        .globl  __ZN14nsXPTCStubBase6Stub193Ev
        .align  2
__ZN14nsXPTCStubBase6Stub193Ev:
        addi    r12,   0,193
        b       _SharedStub
        .elseif 193 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub193Ev
        .align  2
__ZN14nsXPTCStubBase7Stub193Ev:
        addi    r12,   0,193
        b       _SharedStub
        .else
        .err    "Stub193 >= 1000 not yet supported."
        .endif

       .if     194 < 10
        .globl  __ZN14nsXPTCStubBase5Stub194Ev
        .align  2
__ZN14nsXPTCStubBase5Stub194Ev:
        addi    r12,   0,194
        b       _SharedStub
        .elseif 194 < 100
        .globl  __ZN14nsXPTCStubBase6Stub194Ev
        .align  2
__ZN14nsXPTCStubBase6Stub194Ev:
        addi    r12,   0,194
        b       _SharedStub
        .elseif 194 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub194Ev
        .align  2
__ZN14nsXPTCStubBase7Stub194Ev:
        addi    r12,   0,194
        b       _SharedStub
        .else
        .err    "Stub194 >= 1000 not yet supported."
        .endif

       .if     195 < 10
        .globl  __ZN14nsXPTCStubBase5Stub195Ev
        .align  2
__ZN14nsXPTCStubBase5Stub195Ev:
        addi    r12,   0,195
        b       _SharedStub
        .elseif 195 < 100
        .globl  __ZN14nsXPTCStubBase6Stub195Ev
        .align  2
__ZN14nsXPTCStubBase6Stub195Ev:
        addi    r12,   0,195
        b       _SharedStub
        .elseif 195 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub195Ev
        .align  2
__ZN14nsXPTCStubBase7Stub195Ev:
        addi    r12,   0,195
        b       _SharedStub
        .else
        .err    "Stub195 >= 1000 not yet supported."
        .endif

       .if     196 < 10
        .globl  __ZN14nsXPTCStubBase5Stub196Ev
        .align  2
__ZN14nsXPTCStubBase5Stub196Ev:
        addi    r12,   0,196
        b       _SharedStub
        .elseif 196 < 100
        .globl  __ZN14nsXPTCStubBase6Stub196Ev
        .align  2
__ZN14nsXPTCStubBase6Stub196Ev:
        addi    r12,   0,196
        b       _SharedStub
        .elseif 196 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub196Ev
        .align  2
__ZN14nsXPTCStubBase7Stub196Ev:
        addi    r12,   0,196
        b       _SharedStub
        .else
        .err    "Stub196 >= 1000 not yet supported."
        .endif

       .if     197 < 10
        .globl  __ZN14nsXPTCStubBase5Stub197Ev
        .align  2
__ZN14nsXPTCStubBase5Stub197Ev:
        addi    r12,   0,197
        b       _SharedStub
        .elseif 197 < 100
        .globl  __ZN14nsXPTCStubBase6Stub197Ev
        .align  2
__ZN14nsXPTCStubBase6Stub197Ev:
        addi    r12,   0,197
        b       _SharedStub
        .elseif 197 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub197Ev
        .align  2
__ZN14nsXPTCStubBase7Stub197Ev:
        addi    r12,   0,197
        b       _SharedStub
        .else
        .err    "Stub197 >= 1000 not yet supported."
        .endif

       .if     198 < 10
        .globl  __ZN14nsXPTCStubBase5Stub198Ev
        .align  2
__ZN14nsXPTCStubBase5Stub198Ev:
        addi    r12,   0,198
        b       _SharedStub
        .elseif 198 < 100
        .globl  __ZN14nsXPTCStubBase6Stub198Ev
        .align  2
__ZN14nsXPTCStubBase6Stub198Ev:
        addi    r12,   0,198
        b       _SharedStub
        .elseif 198 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub198Ev
        .align  2
__ZN14nsXPTCStubBase7Stub198Ev:
        addi    r12,   0,198
        b       _SharedStub
        .else
        .err    "Stub198 >= 1000 not yet supported."
        .endif

       .if     199 < 10
        .globl  __ZN14nsXPTCStubBase5Stub199Ev
        .align  2
__ZN14nsXPTCStubBase5Stub199Ev:
        addi    r12,   0,199
        b       _SharedStub
        .elseif 199 < 100
        .globl  __ZN14nsXPTCStubBase6Stub199Ev
        .align  2
__ZN14nsXPTCStubBase6Stub199Ev:
        addi    r12,   0,199
        b       _SharedStub
        .elseif 199 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub199Ev
        .align  2
__ZN14nsXPTCStubBase7Stub199Ev:
        addi    r12,   0,199
        b       _SharedStub
        .else
        .err    "Stub199 >= 1000 not yet supported."
        .endif

       .if     200 < 10
        .globl  __ZN14nsXPTCStubBase5Stub200Ev
        .align  2
__ZN14nsXPTCStubBase5Stub200Ev:
        addi    r12,   0,200
        b       _SharedStub
        .elseif 200 < 100
        .globl  __ZN14nsXPTCStubBase6Stub200Ev
        .align  2
__ZN14nsXPTCStubBase6Stub200Ev:
        addi    r12,   0,200
        b       _SharedStub
        .elseif 200 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub200Ev
        .align  2
__ZN14nsXPTCStubBase7Stub200Ev:
        addi    r12,   0,200
        b       _SharedStub
        .else
        .err    "Stub200 >= 1000 not yet supported."
        .endif

       .if     201 < 10
        .globl  __ZN14nsXPTCStubBase5Stub201Ev
        .align  2
__ZN14nsXPTCStubBase5Stub201Ev:
        addi    r12,   0,201
        b       _SharedStub
        .elseif 201 < 100
        .globl  __ZN14nsXPTCStubBase6Stub201Ev
        .align  2
__ZN14nsXPTCStubBase6Stub201Ev:
        addi    r12,   0,201
        b       _SharedStub
        .elseif 201 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub201Ev
        .align  2
__ZN14nsXPTCStubBase7Stub201Ev:
        addi    r12,   0,201
        b       _SharedStub
        .else
        .err    "Stub201 >= 1000 not yet supported."
        .endif

       .if     202 < 10
        .globl  __ZN14nsXPTCStubBase5Stub202Ev
        .align  2
__ZN14nsXPTCStubBase5Stub202Ev:
        addi    r12,   0,202
        b       _SharedStub
        .elseif 202 < 100
        .globl  __ZN14nsXPTCStubBase6Stub202Ev
        .align  2
__ZN14nsXPTCStubBase6Stub202Ev:
        addi    r12,   0,202
        b       _SharedStub
        .elseif 202 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub202Ev
        .align  2
__ZN14nsXPTCStubBase7Stub202Ev:
        addi    r12,   0,202
        b       _SharedStub
        .else
        .err    "Stub202 >= 1000 not yet supported."
        .endif

       .if     203 < 10
        .globl  __ZN14nsXPTCStubBase5Stub203Ev
        .align  2
__ZN14nsXPTCStubBase5Stub203Ev:
        addi    r12,   0,203
        b       _SharedStub
        .elseif 203 < 100
        .globl  __ZN14nsXPTCStubBase6Stub203Ev
        .align  2
__ZN14nsXPTCStubBase6Stub203Ev:
        addi    r12,   0,203
        b       _SharedStub
        .elseif 203 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub203Ev
        .align  2
__ZN14nsXPTCStubBase7Stub203Ev:
        addi    r12,   0,203
        b       _SharedStub
        .else
        .err    "Stub203 >= 1000 not yet supported."
        .endif

       .if     204 < 10
        .globl  __ZN14nsXPTCStubBase5Stub204Ev
        .align  2
__ZN14nsXPTCStubBase5Stub204Ev:
        addi    r12,   0,204
        b       _SharedStub
        .elseif 204 < 100
        .globl  __ZN14nsXPTCStubBase6Stub204Ev
        .align  2
__ZN14nsXPTCStubBase6Stub204Ev:
        addi    r12,   0,204
        b       _SharedStub
        .elseif 204 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub204Ev
        .align  2
__ZN14nsXPTCStubBase7Stub204Ev:
        addi    r12,   0,204
        b       _SharedStub
        .else
        .err    "Stub204 >= 1000 not yet supported."
        .endif

       .if     205 < 10
        .globl  __ZN14nsXPTCStubBase5Stub205Ev
        .align  2
__ZN14nsXPTCStubBase5Stub205Ev:
        addi    r12,   0,205
        b       _SharedStub
        .elseif 205 < 100
        .globl  __ZN14nsXPTCStubBase6Stub205Ev
        .align  2
__ZN14nsXPTCStubBase6Stub205Ev:
        addi    r12,   0,205
        b       _SharedStub
        .elseif 205 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub205Ev
        .align  2
__ZN14nsXPTCStubBase7Stub205Ev:
        addi    r12,   0,205
        b       _SharedStub
        .else
        .err    "Stub205 >= 1000 not yet supported."
        .endif

       .if     206 < 10
        .globl  __ZN14nsXPTCStubBase5Stub206Ev
        .align  2
__ZN14nsXPTCStubBase5Stub206Ev:
        addi    r12,   0,206
        b       _SharedStub
        .elseif 206 < 100
        .globl  __ZN14nsXPTCStubBase6Stub206Ev
        .align  2
__ZN14nsXPTCStubBase6Stub206Ev:
        addi    r12,   0,206
        b       _SharedStub
        .elseif 206 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub206Ev
        .align  2
__ZN14nsXPTCStubBase7Stub206Ev:
        addi    r12,   0,206
        b       _SharedStub
        .else
        .err    "Stub206 >= 1000 not yet supported."
        .endif

       .if     207 < 10
        .globl  __ZN14nsXPTCStubBase5Stub207Ev
        .align  2
__ZN14nsXPTCStubBase5Stub207Ev:
        addi    r12,   0,207
        b       _SharedStub
        .elseif 207 < 100
        .globl  __ZN14nsXPTCStubBase6Stub207Ev
        .align  2
__ZN14nsXPTCStubBase6Stub207Ev:
        addi    r12,   0,207
        b       _SharedStub
        .elseif 207 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub207Ev
        .align  2
__ZN14nsXPTCStubBase7Stub207Ev:
        addi    r12,   0,207
        b       _SharedStub
        .else
        .err    "Stub207 >= 1000 not yet supported."
        .endif

       .if     208 < 10
        .globl  __ZN14nsXPTCStubBase5Stub208Ev
        .align  2
__ZN14nsXPTCStubBase5Stub208Ev:
        addi    r12,   0,208
        b       _SharedStub
        .elseif 208 < 100
        .globl  __ZN14nsXPTCStubBase6Stub208Ev
        .align  2
__ZN14nsXPTCStubBase6Stub208Ev:
        addi    r12,   0,208
        b       _SharedStub
        .elseif 208 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub208Ev
        .align  2
__ZN14nsXPTCStubBase7Stub208Ev:
        addi    r12,   0,208
        b       _SharedStub
        .else
        .err    "Stub208 >= 1000 not yet supported."
        .endif

       .if     209 < 10
        .globl  __ZN14nsXPTCStubBase5Stub209Ev
        .align  2
__ZN14nsXPTCStubBase5Stub209Ev:
        addi    r12,   0,209
        b       _SharedStub
        .elseif 209 < 100
        .globl  __ZN14nsXPTCStubBase6Stub209Ev
        .align  2
__ZN14nsXPTCStubBase6Stub209Ev:
        addi    r12,   0,209
        b       _SharedStub
        .elseif 209 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub209Ev
        .align  2
__ZN14nsXPTCStubBase7Stub209Ev:
        addi    r12,   0,209
        b       _SharedStub
        .else
        .err    "Stub209 >= 1000 not yet supported."
        .endif

       .if     210 < 10
        .globl  __ZN14nsXPTCStubBase5Stub210Ev
        .align  2
__ZN14nsXPTCStubBase5Stub210Ev:
        addi    r12,   0,210
        b       _SharedStub
        .elseif 210 < 100
        .globl  __ZN14nsXPTCStubBase6Stub210Ev
        .align  2
__ZN14nsXPTCStubBase6Stub210Ev:
        addi    r12,   0,210
        b       _SharedStub
        .elseif 210 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub210Ev
        .align  2
__ZN14nsXPTCStubBase7Stub210Ev:
        addi    r12,   0,210
        b       _SharedStub
        .else
        .err    "Stub210 >= 1000 not yet supported."
        .endif

       .if     211 < 10
        .globl  __ZN14nsXPTCStubBase5Stub211Ev
        .align  2
__ZN14nsXPTCStubBase5Stub211Ev:
        addi    r12,   0,211
        b       _SharedStub
        .elseif 211 < 100
        .globl  __ZN14nsXPTCStubBase6Stub211Ev
        .align  2
__ZN14nsXPTCStubBase6Stub211Ev:
        addi    r12,   0,211
        b       _SharedStub
        .elseif 211 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub211Ev
        .align  2
__ZN14nsXPTCStubBase7Stub211Ev:
        addi    r12,   0,211
        b       _SharedStub
        .else
        .err    "Stub211 >= 1000 not yet supported."
        .endif

       .if     212 < 10
        .globl  __ZN14nsXPTCStubBase5Stub212Ev
        .align  2
__ZN14nsXPTCStubBase5Stub212Ev:
        addi    r12,   0,212
        b       _SharedStub
        .elseif 212 < 100
        .globl  __ZN14nsXPTCStubBase6Stub212Ev
        .align  2
__ZN14nsXPTCStubBase6Stub212Ev:
        addi    r12,   0,212
        b       _SharedStub
        .elseif 212 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub212Ev
        .align  2
__ZN14nsXPTCStubBase7Stub212Ev:
        addi    r12,   0,212
        b       _SharedStub
        .else
        .err    "Stub212 >= 1000 not yet supported."
        .endif

       .if     213 < 10
        .globl  __ZN14nsXPTCStubBase5Stub213Ev
        .align  2
__ZN14nsXPTCStubBase5Stub213Ev:
        addi    r12,   0,213
        b       _SharedStub
        .elseif 213 < 100
        .globl  __ZN14nsXPTCStubBase6Stub213Ev
        .align  2
__ZN14nsXPTCStubBase6Stub213Ev:
        addi    r12,   0,213
        b       _SharedStub
        .elseif 213 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub213Ev
        .align  2
__ZN14nsXPTCStubBase7Stub213Ev:
        addi    r12,   0,213
        b       _SharedStub
        .else
        .err    "Stub213 >= 1000 not yet supported."
        .endif

       .if     214 < 10
        .globl  __ZN14nsXPTCStubBase5Stub214Ev
        .align  2
__ZN14nsXPTCStubBase5Stub214Ev:
        addi    r12,   0,214
        b       _SharedStub
        .elseif 214 < 100
        .globl  __ZN14nsXPTCStubBase6Stub214Ev
        .align  2
__ZN14nsXPTCStubBase6Stub214Ev:
        addi    r12,   0,214
        b       _SharedStub
        .elseif 214 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub214Ev
        .align  2
__ZN14nsXPTCStubBase7Stub214Ev:
        addi    r12,   0,214
        b       _SharedStub
        .else
        .err    "Stub214 >= 1000 not yet supported."
        .endif

       .if     215 < 10
        .globl  __ZN14nsXPTCStubBase5Stub215Ev
        .align  2
__ZN14nsXPTCStubBase5Stub215Ev:
        addi    r12,   0,215
        b       _SharedStub
        .elseif 215 < 100
        .globl  __ZN14nsXPTCStubBase6Stub215Ev
        .align  2
__ZN14nsXPTCStubBase6Stub215Ev:
        addi    r12,   0,215
        b       _SharedStub
        .elseif 215 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub215Ev
        .align  2
__ZN14nsXPTCStubBase7Stub215Ev:
        addi    r12,   0,215
        b       _SharedStub
        .else
        .err    "Stub215 >= 1000 not yet supported."
        .endif

       .if     216 < 10
        .globl  __ZN14nsXPTCStubBase5Stub216Ev
        .align  2
__ZN14nsXPTCStubBase5Stub216Ev:
        addi    r12,   0,216
        b       _SharedStub
        .elseif 216 < 100
        .globl  __ZN14nsXPTCStubBase6Stub216Ev
        .align  2
__ZN14nsXPTCStubBase6Stub216Ev:
        addi    r12,   0,216
        b       _SharedStub
        .elseif 216 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub216Ev
        .align  2
__ZN14nsXPTCStubBase7Stub216Ev:
        addi    r12,   0,216
        b       _SharedStub
        .else
        .err    "Stub216 >= 1000 not yet supported."
        .endif

       .if     217 < 10
        .globl  __ZN14nsXPTCStubBase5Stub217Ev
        .align  2
__ZN14nsXPTCStubBase5Stub217Ev:
        addi    r12,   0,217
        b       _SharedStub
        .elseif 217 < 100
        .globl  __ZN14nsXPTCStubBase6Stub217Ev
        .align  2
__ZN14nsXPTCStubBase6Stub217Ev:
        addi    r12,   0,217
        b       _SharedStub
        .elseif 217 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub217Ev
        .align  2
__ZN14nsXPTCStubBase7Stub217Ev:
        addi    r12,   0,217
        b       _SharedStub
        .else
        .err    "Stub217 >= 1000 not yet supported."
        .endif

       .if     218 < 10
        .globl  __ZN14nsXPTCStubBase5Stub218Ev
        .align  2
__ZN14nsXPTCStubBase5Stub218Ev:
        addi    r12,   0,218
        b       _SharedStub
        .elseif 218 < 100
        .globl  __ZN14nsXPTCStubBase6Stub218Ev
        .align  2
__ZN14nsXPTCStubBase6Stub218Ev:
        addi    r12,   0,218
        b       _SharedStub
        .elseif 218 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub218Ev
        .align  2
__ZN14nsXPTCStubBase7Stub218Ev:
        addi    r12,   0,218
        b       _SharedStub
        .else
        .err    "Stub218 >= 1000 not yet supported."
        .endif

       .if     219 < 10
        .globl  __ZN14nsXPTCStubBase5Stub219Ev
        .align  2
__ZN14nsXPTCStubBase5Stub219Ev:
        addi    r12,   0,219
        b       _SharedStub
        .elseif 219 < 100
        .globl  __ZN14nsXPTCStubBase6Stub219Ev
        .align  2
__ZN14nsXPTCStubBase6Stub219Ev:
        addi    r12,   0,219
        b       _SharedStub
        .elseif 219 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub219Ev
        .align  2
__ZN14nsXPTCStubBase7Stub219Ev:
        addi    r12,   0,219
        b       _SharedStub
        .else
        .err    "Stub219 >= 1000 not yet supported."
        .endif

       .if     220 < 10
        .globl  __ZN14nsXPTCStubBase5Stub220Ev
        .align  2
__ZN14nsXPTCStubBase5Stub220Ev:
        addi    r12,   0,220
        b       _SharedStub
        .elseif 220 < 100
        .globl  __ZN14nsXPTCStubBase6Stub220Ev
        .align  2
__ZN14nsXPTCStubBase6Stub220Ev:
        addi    r12,   0,220
        b       _SharedStub
        .elseif 220 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub220Ev
        .align  2
__ZN14nsXPTCStubBase7Stub220Ev:
        addi    r12,   0,220
        b       _SharedStub
        .else
        .err    "Stub220 >= 1000 not yet supported."
        .endif

       .if     221 < 10
        .globl  __ZN14nsXPTCStubBase5Stub221Ev
        .align  2
__ZN14nsXPTCStubBase5Stub221Ev:
        addi    r12,   0,221
        b       _SharedStub
        .elseif 221 < 100
        .globl  __ZN14nsXPTCStubBase6Stub221Ev
        .align  2
__ZN14nsXPTCStubBase6Stub221Ev:
        addi    r12,   0,221
        b       _SharedStub
        .elseif 221 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub221Ev
        .align  2
__ZN14nsXPTCStubBase7Stub221Ev:
        addi    r12,   0,221
        b       _SharedStub
        .else
        .err    "Stub221 >= 1000 not yet supported."
        .endif

       .if     222 < 10
        .globl  __ZN14nsXPTCStubBase5Stub222Ev
        .align  2
__ZN14nsXPTCStubBase5Stub222Ev:
        addi    r12,   0,222
        b       _SharedStub
        .elseif 222 < 100
        .globl  __ZN14nsXPTCStubBase6Stub222Ev
        .align  2
__ZN14nsXPTCStubBase6Stub222Ev:
        addi    r12,   0,222
        b       _SharedStub
        .elseif 222 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub222Ev
        .align  2
__ZN14nsXPTCStubBase7Stub222Ev:
        addi    r12,   0,222
        b       _SharedStub
        .else
        .err    "Stub222 >= 1000 not yet supported."
        .endif

       .if     223 < 10
        .globl  __ZN14nsXPTCStubBase5Stub223Ev
        .align  2
__ZN14nsXPTCStubBase5Stub223Ev:
        addi    r12,   0,223
        b       _SharedStub
        .elseif 223 < 100
        .globl  __ZN14nsXPTCStubBase6Stub223Ev
        .align  2
__ZN14nsXPTCStubBase6Stub223Ev:
        addi    r12,   0,223
        b       _SharedStub
        .elseif 223 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub223Ev
        .align  2
__ZN14nsXPTCStubBase7Stub223Ev:
        addi    r12,   0,223
        b       _SharedStub
        .else
        .err    "Stub223 >= 1000 not yet supported."
        .endif

       .if     224 < 10
        .globl  __ZN14nsXPTCStubBase5Stub224Ev
        .align  2
__ZN14nsXPTCStubBase5Stub224Ev:
        addi    r12,   0,224
        b       _SharedStub
        .elseif 224 < 100
        .globl  __ZN14nsXPTCStubBase6Stub224Ev
        .align  2
__ZN14nsXPTCStubBase6Stub224Ev:
        addi    r12,   0,224
        b       _SharedStub
        .elseif 224 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub224Ev
        .align  2
__ZN14nsXPTCStubBase7Stub224Ev:
        addi    r12,   0,224
        b       _SharedStub
        .else
        .err    "Stub224 >= 1000 not yet supported."
        .endif

       .if     225 < 10
        .globl  __ZN14nsXPTCStubBase5Stub225Ev
        .align  2
__ZN14nsXPTCStubBase5Stub225Ev:
        addi    r12,   0,225
        b       _SharedStub
        .elseif 225 < 100
        .globl  __ZN14nsXPTCStubBase6Stub225Ev
        .align  2
__ZN14nsXPTCStubBase6Stub225Ev:
        addi    r12,   0,225
        b       _SharedStub
        .elseif 225 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub225Ev
        .align  2
__ZN14nsXPTCStubBase7Stub225Ev:
        addi    r12,   0,225
        b       _SharedStub
        .else
        .err    "Stub225 >= 1000 not yet supported."
        .endif

       .if     226 < 10
        .globl  __ZN14nsXPTCStubBase5Stub226Ev
        .align  2
__ZN14nsXPTCStubBase5Stub226Ev:
        addi    r12,   0,226
        b       _SharedStub
        .elseif 226 < 100
        .globl  __ZN14nsXPTCStubBase6Stub226Ev
        .align  2
__ZN14nsXPTCStubBase6Stub226Ev:
        addi    r12,   0,226
        b       _SharedStub
        .elseif 226 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub226Ev
        .align  2
__ZN14nsXPTCStubBase7Stub226Ev:
        addi    r12,   0,226
        b       _SharedStub
        .else
        .err    "Stub226 >= 1000 not yet supported."
        .endif

       .if     227 < 10
        .globl  __ZN14nsXPTCStubBase5Stub227Ev
        .align  2
__ZN14nsXPTCStubBase5Stub227Ev:
        addi    r12,   0,227
        b       _SharedStub
        .elseif 227 < 100
        .globl  __ZN14nsXPTCStubBase6Stub227Ev
        .align  2
__ZN14nsXPTCStubBase6Stub227Ev:
        addi    r12,   0,227
        b       _SharedStub
        .elseif 227 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub227Ev
        .align  2
__ZN14nsXPTCStubBase7Stub227Ev:
        addi    r12,   0,227
        b       _SharedStub
        .else
        .err    "Stub227 >= 1000 not yet supported."
        .endif

       .if     228 < 10
        .globl  __ZN14nsXPTCStubBase5Stub228Ev
        .align  2
__ZN14nsXPTCStubBase5Stub228Ev:
        addi    r12,   0,228
        b       _SharedStub
        .elseif 228 < 100
        .globl  __ZN14nsXPTCStubBase6Stub228Ev
        .align  2
__ZN14nsXPTCStubBase6Stub228Ev:
        addi    r12,   0,228
        b       _SharedStub
        .elseif 228 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub228Ev
        .align  2
__ZN14nsXPTCStubBase7Stub228Ev:
        addi    r12,   0,228
        b       _SharedStub
        .else
        .err    "Stub228 >= 1000 not yet supported."
        .endif

       .if     229 < 10
        .globl  __ZN14nsXPTCStubBase5Stub229Ev
        .align  2
__ZN14nsXPTCStubBase5Stub229Ev:
        addi    r12,   0,229
        b       _SharedStub
        .elseif 229 < 100
        .globl  __ZN14nsXPTCStubBase6Stub229Ev
        .align  2
__ZN14nsXPTCStubBase6Stub229Ev:
        addi    r12,   0,229
        b       _SharedStub
        .elseif 229 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub229Ev
        .align  2
__ZN14nsXPTCStubBase7Stub229Ev:
        addi    r12,   0,229
        b       _SharedStub
        .else
        .err    "Stub229 >= 1000 not yet supported."
        .endif

       .if     230 < 10
        .globl  __ZN14nsXPTCStubBase5Stub230Ev
        .align  2
__ZN14nsXPTCStubBase5Stub230Ev:
        addi    r12,   0,230
        b       _SharedStub
        .elseif 230 < 100
        .globl  __ZN14nsXPTCStubBase6Stub230Ev
        .align  2
__ZN14nsXPTCStubBase6Stub230Ev:
        addi    r12,   0,230
        b       _SharedStub
        .elseif 230 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub230Ev
        .align  2
__ZN14nsXPTCStubBase7Stub230Ev:
        addi    r12,   0,230
        b       _SharedStub
        .else
        .err    "Stub230 >= 1000 not yet supported."
        .endif

       .if     231 < 10
        .globl  __ZN14nsXPTCStubBase5Stub231Ev
        .align  2
__ZN14nsXPTCStubBase5Stub231Ev:
        addi    r12,   0,231
        b       _SharedStub
        .elseif 231 < 100
        .globl  __ZN14nsXPTCStubBase6Stub231Ev
        .align  2
__ZN14nsXPTCStubBase6Stub231Ev:
        addi    r12,   0,231
        b       _SharedStub
        .elseif 231 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub231Ev
        .align  2
__ZN14nsXPTCStubBase7Stub231Ev:
        addi    r12,   0,231
        b       _SharedStub
        .else
        .err    "Stub231 >= 1000 not yet supported."
        .endif

       .if     232 < 10
        .globl  __ZN14nsXPTCStubBase5Stub232Ev
        .align  2
__ZN14nsXPTCStubBase5Stub232Ev:
        addi    r12,   0,232
        b       _SharedStub
        .elseif 232 < 100
        .globl  __ZN14nsXPTCStubBase6Stub232Ev
        .align  2
__ZN14nsXPTCStubBase6Stub232Ev:
        addi    r12,   0,232
        b       _SharedStub
        .elseif 232 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub232Ev
        .align  2
__ZN14nsXPTCStubBase7Stub232Ev:
        addi    r12,   0,232
        b       _SharedStub
        .else
        .err    "Stub232 >= 1000 not yet supported."
        .endif

       .if     233 < 10
        .globl  __ZN14nsXPTCStubBase5Stub233Ev
        .align  2
__ZN14nsXPTCStubBase5Stub233Ev:
        addi    r12,   0,233
        b       _SharedStub
        .elseif 233 < 100
        .globl  __ZN14nsXPTCStubBase6Stub233Ev
        .align  2
__ZN14nsXPTCStubBase6Stub233Ev:
        addi    r12,   0,233
        b       _SharedStub
        .elseif 233 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub233Ev
        .align  2
__ZN14nsXPTCStubBase7Stub233Ev:
        addi    r12,   0,233
        b       _SharedStub
        .else
        .err    "Stub233 >= 1000 not yet supported."
        .endif

       .if     234 < 10
        .globl  __ZN14nsXPTCStubBase5Stub234Ev
        .align  2
__ZN14nsXPTCStubBase5Stub234Ev:
        addi    r12,   0,234
        b       _SharedStub
        .elseif 234 < 100
        .globl  __ZN14nsXPTCStubBase6Stub234Ev
        .align  2
__ZN14nsXPTCStubBase6Stub234Ev:
        addi    r12,   0,234
        b       _SharedStub
        .elseif 234 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub234Ev
        .align  2
__ZN14nsXPTCStubBase7Stub234Ev:
        addi    r12,   0,234
        b       _SharedStub
        .else
        .err    "Stub234 >= 1000 not yet supported."
        .endif

       .if     235 < 10
        .globl  __ZN14nsXPTCStubBase5Stub235Ev
        .align  2
__ZN14nsXPTCStubBase5Stub235Ev:
        addi    r12,   0,235
        b       _SharedStub
        .elseif 235 < 100
        .globl  __ZN14nsXPTCStubBase6Stub235Ev
        .align  2
__ZN14nsXPTCStubBase6Stub235Ev:
        addi    r12,   0,235
        b       _SharedStub
        .elseif 235 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub235Ev
        .align  2
__ZN14nsXPTCStubBase7Stub235Ev:
        addi    r12,   0,235
        b       _SharedStub
        .else
        .err    "Stub235 >= 1000 not yet supported."
        .endif

       .if     236 < 10
        .globl  __ZN14nsXPTCStubBase5Stub236Ev
        .align  2
__ZN14nsXPTCStubBase5Stub236Ev:
        addi    r12,   0,236
        b       _SharedStub
        .elseif 236 < 100
        .globl  __ZN14nsXPTCStubBase6Stub236Ev
        .align  2
__ZN14nsXPTCStubBase6Stub236Ev:
        addi    r12,   0,236
        b       _SharedStub
        .elseif 236 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub236Ev
        .align  2
__ZN14nsXPTCStubBase7Stub236Ev:
        addi    r12,   0,236
        b       _SharedStub
        .else
        .err    "Stub236 >= 1000 not yet supported."
        .endif

       .if     237 < 10
        .globl  __ZN14nsXPTCStubBase5Stub237Ev
        .align  2
__ZN14nsXPTCStubBase5Stub237Ev:
        addi    r12,   0,237
        b       _SharedStub
        .elseif 237 < 100
        .globl  __ZN14nsXPTCStubBase6Stub237Ev
        .align  2
__ZN14nsXPTCStubBase6Stub237Ev:
        addi    r12,   0,237
        b       _SharedStub
        .elseif 237 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub237Ev
        .align  2
__ZN14nsXPTCStubBase7Stub237Ev:
        addi    r12,   0,237
        b       _SharedStub
        .else
        .err    "Stub237 >= 1000 not yet supported."
        .endif

       .if     238 < 10
        .globl  __ZN14nsXPTCStubBase5Stub238Ev
        .align  2
__ZN14nsXPTCStubBase5Stub238Ev:
        addi    r12,   0,238
        b       _SharedStub
        .elseif 238 < 100
        .globl  __ZN14nsXPTCStubBase6Stub238Ev
        .align  2
__ZN14nsXPTCStubBase6Stub238Ev:
        addi    r12,   0,238
        b       _SharedStub
        .elseif 238 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub238Ev
        .align  2
__ZN14nsXPTCStubBase7Stub238Ev:
        addi    r12,   0,238
        b       _SharedStub
        .else
        .err    "Stub238 >= 1000 not yet supported."
        .endif

       .if     239 < 10
        .globl  __ZN14nsXPTCStubBase5Stub239Ev
        .align  2
__ZN14nsXPTCStubBase5Stub239Ev:
        addi    r12,   0,239
        b       _SharedStub
        .elseif 239 < 100
        .globl  __ZN14nsXPTCStubBase6Stub239Ev
        .align  2
__ZN14nsXPTCStubBase6Stub239Ev:
        addi    r12,   0,239
        b       _SharedStub
        .elseif 239 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub239Ev
        .align  2
__ZN14nsXPTCStubBase7Stub239Ev:
        addi    r12,   0,239
        b       _SharedStub
        .else
        .err    "Stub239 >= 1000 not yet supported."
        .endif

       .if     240 < 10
        .globl  __ZN14nsXPTCStubBase5Stub240Ev
        .align  2
__ZN14nsXPTCStubBase5Stub240Ev:
        addi    r12,   0,240
        b       _SharedStub
        .elseif 240 < 100
        .globl  __ZN14nsXPTCStubBase6Stub240Ev
        .align  2
__ZN14nsXPTCStubBase6Stub240Ev:
        addi    r12,   0,240
        b       _SharedStub
        .elseif 240 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub240Ev
        .align  2
__ZN14nsXPTCStubBase7Stub240Ev:
        addi    r12,   0,240
        b       _SharedStub
        .else
        .err    "Stub240 >= 1000 not yet supported."
        .endif

       .if     241 < 10
        .globl  __ZN14nsXPTCStubBase5Stub241Ev
        .align  2
__ZN14nsXPTCStubBase5Stub241Ev:
        addi    r12,   0,241
        b       _SharedStub
        .elseif 241 < 100
        .globl  __ZN14nsXPTCStubBase6Stub241Ev
        .align  2
__ZN14nsXPTCStubBase6Stub241Ev:
        addi    r12,   0,241
        b       _SharedStub
        .elseif 241 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub241Ev
        .align  2
__ZN14nsXPTCStubBase7Stub241Ev:
        addi    r12,   0,241
        b       _SharedStub
        .else
        .err    "Stub241 >= 1000 not yet supported."
        .endif

       .if     242 < 10
        .globl  __ZN14nsXPTCStubBase5Stub242Ev
        .align  2
__ZN14nsXPTCStubBase5Stub242Ev:
        addi    r12,   0,242
        b       _SharedStub
        .elseif 242 < 100
        .globl  __ZN14nsXPTCStubBase6Stub242Ev
        .align  2
__ZN14nsXPTCStubBase6Stub242Ev:
        addi    r12,   0,242
        b       _SharedStub
        .elseif 242 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub242Ev
        .align  2
__ZN14nsXPTCStubBase7Stub242Ev:
        addi    r12,   0,242
        b       _SharedStub
        .else
        .err    "Stub242 >= 1000 not yet supported."
        .endif

       .if     243 < 10
        .globl  __ZN14nsXPTCStubBase5Stub243Ev
        .align  2
__ZN14nsXPTCStubBase5Stub243Ev:
        addi    r12,   0,243
        b       _SharedStub
        .elseif 243 < 100
        .globl  __ZN14nsXPTCStubBase6Stub243Ev
        .align  2
__ZN14nsXPTCStubBase6Stub243Ev:
        addi    r12,   0,243
        b       _SharedStub
        .elseif 243 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub243Ev
        .align  2
__ZN14nsXPTCStubBase7Stub243Ev:
        addi    r12,   0,243
        b       _SharedStub
        .else
        .err    "Stub243 >= 1000 not yet supported."
        .endif

       .if     244 < 10
        .globl  __ZN14nsXPTCStubBase5Stub244Ev
        .align  2
__ZN14nsXPTCStubBase5Stub244Ev:
        addi    r12,   0,244
        b       _SharedStub
        .elseif 244 < 100
        .globl  __ZN14nsXPTCStubBase6Stub244Ev
        .align  2
__ZN14nsXPTCStubBase6Stub244Ev:
        addi    r12,   0,244
        b       _SharedStub
        .elseif 244 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub244Ev
        .align  2
__ZN14nsXPTCStubBase7Stub244Ev:
        addi    r12,   0,244
        b       _SharedStub
        .else
        .err    "Stub244 >= 1000 not yet supported."
        .endif

       .if     245 < 10
        .globl  __ZN14nsXPTCStubBase5Stub245Ev
        .align  2
__ZN14nsXPTCStubBase5Stub245Ev:
        addi    r12,   0,245
        b       _SharedStub
        .elseif 245 < 100
        .globl  __ZN14nsXPTCStubBase6Stub245Ev
        .align  2
__ZN14nsXPTCStubBase6Stub245Ev:
        addi    r12,   0,245
        b       _SharedStub
        .elseif 245 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub245Ev
        .align  2
__ZN14nsXPTCStubBase7Stub245Ev:
        addi    r12,   0,245
        b       _SharedStub
        .else
        .err    "Stub245 >= 1000 not yet supported."
        .endif

       .if     246 < 10
        .globl  __ZN14nsXPTCStubBase5Stub246Ev
        .align  2
__ZN14nsXPTCStubBase5Stub246Ev:
        addi    r12,   0,246
        b       _SharedStub
        .elseif 246 < 100
        .globl  __ZN14nsXPTCStubBase6Stub246Ev
        .align  2
__ZN14nsXPTCStubBase6Stub246Ev:
        addi    r12,   0,246
        b       _SharedStub
        .elseif 246 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub246Ev
        .align  2
__ZN14nsXPTCStubBase7Stub246Ev:
        addi    r12,   0,246
        b       _SharedStub
        .else
        .err    "Stub246 >= 1000 not yet supported."
        .endif

       .if     247 < 10
        .globl  __ZN14nsXPTCStubBase5Stub247Ev
        .align  2
__ZN14nsXPTCStubBase5Stub247Ev:
        addi    r12,   0,247
        b       _SharedStub
        .elseif 247 < 100
        .globl  __ZN14nsXPTCStubBase6Stub247Ev
        .align  2
__ZN14nsXPTCStubBase6Stub247Ev:
        addi    r12,   0,247
        b       _SharedStub
        .elseif 247 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub247Ev
        .align  2
__ZN14nsXPTCStubBase7Stub247Ev:
        addi    r12,   0,247
        b       _SharedStub
        .else
        .err    "Stub247 >= 1000 not yet supported."
        .endif

       .if     248 < 10
        .globl  __ZN14nsXPTCStubBase5Stub248Ev
        .align  2
__ZN14nsXPTCStubBase5Stub248Ev:
        addi    r12,   0,248
        b       _SharedStub
        .elseif 248 < 100
        .globl  __ZN14nsXPTCStubBase6Stub248Ev
        .align  2
__ZN14nsXPTCStubBase6Stub248Ev:
        addi    r12,   0,248
        b       _SharedStub
        .elseif 248 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub248Ev
        .align  2
__ZN14nsXPTCStubBase7Stub248Ev:
        addi    r12,   0,248
        b       _SharedStub
        .else
        .err    "Stub248 >= 1000 not yet supported."
        .endif

       .if     249 < 10
        .globl  __ZN14nsXPTCStubBase5Stub249Ev
        .align  2
__ZN14nsXPTCStubBase5Stub249Ev:
        addi    r12,   0,249
        b       _SharedStub
        .elseif 249 < 100
        .globl  __ZN14nsXPTCStubBase6Stub249Ev
        .align  2
__ZN14nsXPTCStubBase6Stub249Ev:
        addi    r12,   0,249
        b       _SharedStub
        .elseif 249 < 1000
        .globl  __ZN14nsXPTCStubBase7Stub249Ev
        .align  2
__ZN14nsXPTCStubBase7Stub249Ev:
        addi    r12,   0,249
        b       _SharedStub
        .else
        .err    "Stub249 >= 1000 not yet supported."
        .endif







// See also xptcstubs_ppc_rhapsody.cpp:PrepareAndDispatch.
_SharedStub:
                                // Prolog(ue)
        mflr     r0             // Save the link register in the caller's
        stw      r0,   8(r1)    //   stack frame
        stwu     r1,-176(r1)    // Allocate stack space for our own frame and
                                //   adjust stack pointer

                                // Linkage area, 0(r1) to 24(r1)
                                // Original sp saved at 0(r1)

                                // Parameter area, 20 bytes from 24(r1) to
                                //   44(r1) to accomodate 5 arguments passed
                                //   to PrepareAndDispatch

                                // Local variables, 132 bytes from 44(r1)
                                //   to 176(r1), to accomodate 5 words and
                                //   13 doubles

        stw      r4,  44(r1)    // Save parameters passed in GPRs r4-r10;
        stw      r5,  48(r1)    //   a pointer to here will be passed to
        stw      r6,  52(r1)    //   PrepareAndDispatch for access to
        stw      r7,  56(r1)    //   arguments passed in registers.  r3,
        stw      r8,  60(r1)    //   the self pointer, is used for the
        stw      r9,  64(r1)    //   call but isn't otherwise needed in
        stw     r10,  68(r1)    //   PrepareAndDispatch, so it is not saved.

        stfd     f1,  72(r1)    // Do the same for floating-point parameters
        stfd     f2,  80(r1)    //   passed in FPRs f1-f13
        stfd     f3,  88(r1)
        stfd     f4,  96(r1)
        stfd     f5, 104(r1)
        stfd     f6, 112(r1)
        stfd     f7, 120(r1)
        stfd     f8, 128(r1)
        stfd     f9, 136(r1)
        stfd    f10, 144(r1)
        stfd    f11, 152(r1)
        stfd    f12, 160(r1)
        stfd    f13, 168(r1)

                                // Set up parameters for call to
                                //   PrepareAndDispatch.  argument=
                                // 0, pointer to self, already in r3
        mr       r4,r12         // 1, stub number
        addi     r5, r1, 204    // 2, pointer to the parameter area in our
                                //   caller's stack, for access to
                                //   parameters beyond those passed in
                                //   registers.  Skip past the first parameter
                                //   (corresponding to r3) for the same reason
                                //   as above.  176 (size of our frame) + 24
                                //   (size of caller's linkage) + 4 (skipped
                                //   parameter)
        addi     r6, r1,  44    // 3, pointer to saved GPRs
        addi     r7, r1,  72    // 4, pointer to saved FPRs

        //bl      L_PrepareAndDispatch$stub
        bl      _PrepareAndDispatch
                                // Do it
        nop                     // Leave room for linker magic

                                // Epilog(ue)
        lwz      r0, 184(r1)    // Retrieve old link register value
        mtlr     r0             // Restore link register
        addi     r1, r1, 176    // Restore stack pointer
        blr                     // Return

.picsymbol_stub
L_PrepareAndDispatch$stub:      // Standard PIC symbol stub
        .indirect_symbol _PrepareAndDispatch
        mflr    r0
        bcl     20,31,L1$pb
L1$pb:
        mflr    r11
        addis   r11,r11,ha16(L1$lz-L1$pb)
        mtlr    r0
        lwz     r12,lo16(L1$lz-L1$pb)(r11)
        mtctr   r12
        addi    r11,r11,lo16(L1$lz-L1$pb)
#if _PPC970_
#warning G5 version
	// Keep the bctr out of the branch slot.
	nop
	nop
	nop
#endif
        bctr
.lazy_symbol_pointer
L1$lz:
        .indirect_symbol _PrepareAndDispatch
        .long   dyld_stub_binding_helper
