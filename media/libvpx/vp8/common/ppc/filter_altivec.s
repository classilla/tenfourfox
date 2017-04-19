# 1 "filter_altivec.asm"
# 1 "<built-in>"
# 1 "<command line>"
# 1 "filter_altivec.asm"
;
;  Copyright (c) 2010 The WebM project authors. All Rights Reserved.
;
;  Use of this source code is governed by a BSD-style license
;  that can be found in the LICENSE file in the root of the source
;  tree. An additional intellectual property rights grant can be found
;  in the file PATENTS.  All contributing project authors may
;  be found in the AUTHORS file in the root of the source tree.
;


    .globl _sixtap_predict_ppc
    .globl _sixtap_predict8x4_ppc
    .globl _sixtap_predict8x8_ppc
    .globl _sixtap_predict16x16_ppc



;# Vertical filtering






















    .align 2
;# r3 unsigned char * src
;# r4 int src_pitch
;# r5 int x_offset
;# r6 int y_offset
;# r7 unsigned char * dst
;# r8 int dst_pitch
_sixtap_predict_ppc:
    mfspr   r11, 256            ;# get old VRSAVE
    oris    r12, r11, 0xff87
    ori     r12, r12, 0xffc0
    mtspr   256, r12            ;# set VRSAVE

    stwu    r1,-32(r1)          ;# create space on the stack

    slwi.   r5, r5, 5           ;# index into horizontal filter array

    vspltish v19, 7

    ;# If there isn't any filtering to be done for the horizontal, then
    ;#  just skip to the second pass.
    beq-    vertical_only_4x4

    ;# load up horizontal filter
    lis     r9, ha16(HFilter)
    la      r10, lo16(HFilter)(r9)
    lvx     v13, r5, r10

    addi    r5,  r5, 16
    lvx     v14, r5, r10

    ;# rounding added in on the multiply
    vspltisw v16, 8
    vspltisw v15, 3
    vslw    v15, v16, v15       ;# 0x00000040000000400000004000000040

    ;# Load up permutation constants
    lis     r9, ha16(B_0123)
    la      r10, lo16(B_0123)(r9)
    lvx     v16, 0, r10
    lis     r9, ha16(B_4567)
    la      r10, lo16(B_4567)(r9)
    lvx     v17, 0, r10
    lis     r9, ha16(B_89AB)
    la      r10, lo16(B_89AB)(r9)
    lvx     v18, 0, r10

    ;# Back off input buffer by 2 bytes.  Need 2 before and 3 after
    addi    r3, r3, -2

    addi    r9, r3, 0
    li      r10, 16
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v2,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v2, v2, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v3,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v3, v3, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v4,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v4, v4, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v5,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v5, v5, v20, v21

    slwi.   r6, r6, 4           ;# index into vertical filter array

    ;# filter a line
    vperm   v20, v2, v2, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v2, v2, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v2, v2, v2, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v2, v21

    vpkswus v2, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v2, v2, v19

    vpkuhus v2, v2, v2          ;# saturate and pack

    vperm   v20, v3, v3, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v3, v3, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v3, v3, v3, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v3, v21

    vpkswus v3, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v3, v3, v19

    vpkuhus v3, v3, v3          ;# saturate and pack

    vperm   v20, v4, v4, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v4, v4, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v4, v4, v4, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v4, v21

    vpkswus v4, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v4, v4, v19

    vpkuhus v4, v4, v4          ;# saturate and pack

    vperm   v20, v5, v5, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v5, v5, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v5, v5, v5, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v5, v21

    vpkswus v5, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v5, v5, v19

    vpkuhus v5, v5, v5          ;# saturate and pack


    ;# Finished filtering main horizontal block.  If there is no
    ;#  vertical filtering, jump to storing the data.  Otherwise
    ;#  load up and filter the additional 5 lines that are needed
    ;#  for the vertical filter.
    beq-    store_4x4

    ;# only needed if there is a vertical filter present
    ;# if the second filter is not null then need to back off by 2*pitch
    sub     r9, r9, r4
    sub     r9, r9, r4

    lvsl    v21,  0, r9        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v0,   0, r9
    lvx     v20, r10, r9

    add     r9, r9, r4

    vperm   v0, v0, v20, v21
    lvsl    v21,  0, r9        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v1,   0, r9
    lvx     v20, r10, r9


    vperm   v1, v1, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v6,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v6, v6, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v7,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v7, v7, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v8,   0, r3
    lvx     v20, r10, r3


    vperm   v8, v8, v20, v21

    vperm   v20, v0, v0, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v0, v0, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v0, v0, v0, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v0, v21

    vpkswus v0, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v0, v0, v19

    vpkuhus v0, v0, v0          ;# saturate and pack

    vperm   v20, v1, v1, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v1, v1, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v1, v1, v1, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v1, v21

    vpkswus v1, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v1, v1, v19

    vpkuhus v1, v1, v1          ;# saturate and pack

    vperm   v20, v6, v6, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v6, v6, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v6, v6, v6, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v6, v21

    vpkswus v6, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v6, v6, v19

    vpkuhus v6, v6, v6          ;# saturate and pack

    vperm   v20, v7, v7, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v7, v7, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v7, v7, v7, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v7, v21

    vpkswus v7, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v7, v7, v19

    vpkuhus v7, v7, v7          ;# saturate and pack

    vperm   v20, v8, v8, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v8, v8, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v8, v8, v8, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v8, v21

    vpkswus v8, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v8, v8, v19

    vpkuhus v8, v8, v8          ;# saturate and pack


    b       second_pass_4x4

vertical_only_4x4:
    ;# only needed if there is a vertical filter present
    ;# if the second filter is not null then need to back off by 2*pitch
    sub     r3, r3, r4
    sub     r3, r3, r4
    li      r10, 16

    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v0,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v0, v0, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v1,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v1, v1, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v2,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v2, v2, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v3,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v3, v3, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v4,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v4, v4, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v5,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v5, v5, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v6,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v6, v6, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v7,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v7, v7, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v8,   0, r3
    lvx     v20, r10, r3


    vperm   v8, v8, v20, v21

    slwi    r6, r6, 4           ;# index into vertical filter array

second_pass_4x4:
    lis     r9, ha16(b_hilo_4x4)
    la      r10, lo16(b_hilo_4x4)(r9)
    lvx     v20, 0, r10
    lis     r9, ha16(b_hilo)
    la      r10, lo16(b_hilo)(r9)
    lvx     v21, 0, r10

    ;# reposition input so that it can go through the
    ;# filtering phase with one pass.
    vperm   v0, v0, v1, v20     ;# 0 1 x x
    vperm   v2, v2, v3, v20     ;# 2 3 x x
    vperm   v4, v4, v5, v20     ;# 4 5 x x
    vperm   v6, v6, v7, v20     ;# 6 7 x x

    vperm   v0, v0, v2, v21     ;# 0 1 2 3
    vperm   v4, v4, v6, v21     ;# 4 5 6 7

    vsldoi  v1, v0, v4, 4
    vsldoi  v2, v0, v4, 8
    vsldoi  v3, v0, v4, 12

    vsldoi  v5, v4, v8, 4

    lis     r9, ha16(VFilter)
    la      r10, lo16(VFilter)(r9)
    lvx     v13, r6, r10

    vspltish v15, 8
    vspltish v20, 3
    vslh    v20, v15, v20       ;# 0x0040 0040 0040 0040 0040 0040 0040 0040

    vspltb  v14, v13, 1
    vspltb  v15, v13, 2
    vspltb  v16, v13, 3
    vspltb  v17, v13, 4
    vspltb  v18, v13, 5
    vspltb  v13, v13, 0

    vmuleub v24, v0, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v0, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v2, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v2, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v3, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v3, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v5, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v5, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v1, v14       ;# 2 negative taps
    vmuloub v24, v1, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v4, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v4, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v0, v23, v24       ;# P0 = 8-bit result

    stvx    v0, 0, r1

    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    add     r7, r7, r8

    lwz     r0, 4(r1)
    stw     r0, 0(r7)
    add     r7, r7, r8

    lwz     r0, 8(r1)
    stw     r0, 0(r7)
    add     r7, r7, r8

    lwz     r0, 12(r1)
    stw     r0, 0(r7)

    b       exit_4x4

store_4x4:

    stvx    v2, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    add     r7, r7, r8

    stvx    v3, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    add     r7, r7, r8

    stvx    v4, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    add     r7, r7, r8

    stvx    v5, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)

exit_4x4:

    addi    r1, r1, 32          ;# recover stack

    mtspr   256, r11            ;# reset old VRSAVE

    blr


    .align 2
;# r3 unsigned char * src
;# r4 int src_pitch
;# r5 int x_offset
;# r6 int y_offset
;# r7 unsigned char * dst
;# r8 int dst_pitch

_sixtap_predict8x4_ppc:
    mfspr   r11, 256            ;# get old VRSAVE
    oris    r12, r11, 0xffff
    ori     r12, r12, 0xffc0
    mtspr   256, r12            ;# set VRSAVE

    stwu    r1,-32(r1)          ;# create space on the stack

    slwi.   r5, r5, 5           ;# index into horizontal filter array

    vspltish v19, 7

    ;# If there isn't any filtering to be done for the horizontal, then
    ;#  just skip to the second pass.
    beq-    second_pass_pre_copy_8x4

    lis     r9, ha16(HFilter)
    la      r10, lo16(HFilter)(r9)
    lvx     v13, r5, r10

    addi    r5,  r5, 16
    lvx     v14, r5, r10

    ;# rounding added in on the multiply
    vspltisw v16, 8
    vspltisw v15, 3
    vslw    v15, v16, v15       ;# 0x00000040000000400000004000000040

    ;# Load up permutation constants
    lis     r9, ha16(B_0123)
    la      r10, lo16(B_0123)(r9)
    lvx     v16, 0, r10
    lis     r9, ha16(B_4567)
    la      r10, lo16(B_4567)(r9)
    lvx     v17, 0, r10
    lis     r9, ha16(B_89AB)
    la      r10, lo16(B_89AB)(r9)
    lvx     v18, 0, r10

    ;# Back off input buffer by 2 bytes.  Need 2 before and 3 after
    addi    r3, r3, -2

    addi    r9, r3, 0
    li      r10, 16
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v2,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v2, v2, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v3,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v3, v3, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v4,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v4, v4, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v5,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v5, v5, v20, v21

    slwi.   r6, r6, 4           ;# index into vertical filter array

    ;# filter a line
    vperm   v20, v2, v2, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v2, v2, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v2, v2, v2, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v2, v21

    vpkswus v2, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v2, v2, v19

    vpkuhus v2, v2, v2          ;# saturate and pack

    vperm   v20, v3, v3, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v3, v3, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v3, v3, v3, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v3, v21

    vpkswus v3, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v3, v3, v19

    vpkuhus v3, v3, v3          ;# saturate and pack

    vperm   v20, v4, v4, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v4, v4, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v4, v4, v4, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v4, v21

    vpkswus v4, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v4, v4, v19

    vpkuhus v4, v4, v4          ;# saturate and pack

    vperm   v20, v5, v5, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v5, v5, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v5, v5, v5, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v5, v21

    vpkswus v5, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v5, v5, v19

    vpkuhus v5, v5, v5          ;# saturate and pack


    ;# Finished filtering main horizontal block.  If there is no
    ;#  vertical filtering, jump to storing the data.  Otherwise
    ;#  load up and filter the additional 5 lines that are needed
    ;#  for the vertical filter.
    beq-    store_8x4

    ;# only needed if there is a vertical filter present
    ;# if the second filter is not null then need to back off by 2*pitch
    sub     r9, r9, r4
    sub     r9, r9, r4

    lvsl    v21,  0, r9        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v0,   0, r9
    lvx     v20, r10, r9

    add     r9, r9, r4

    vperm   v0, v0, v20, v21
    lvsl    v21,  0, r9        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v1,   0, r9
    lvx     v20, r10, r9


    vperm   v1, v1, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v6,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v6, v6, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v7,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v7, v7, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v8,   0, r3
    lvx     v20, r10, r3


    vperm   v8, v8, v20, v21

    vperm   v20, v0, v0, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v0, v0, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v0, v0, v0, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v0, v21

    vpkswus v0, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v0, v0, v19

    vpkuhus v0, v0, v0          ;# saturate and pack

    vperm   v20, v1, v1, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v1, v1, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v1, v1, v1, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v1, v21

    vpkswus v1, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v1, v1, v19

    vpkuhus v1, v1, v1          ;# saturate and pack

    vperm   v20, v6, v6, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v6, v6, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v6, v6, v6, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v6, v21

    vpkswus v6, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v6, v6, v19

    vpkuhus v6, v6, v6          ;# saturate and pack

    vperm   v20, v7, v7, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v7, v7, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v7, v7, v7, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v7, v21

    vpkswus v7, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v7, v7, v19

    vpkuhus v7, v7, v7          ;# saturate and pack

    vperm   v20, v8, v8, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v8, v8, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v8, v8, v8, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v8, v21

    vpkswus v8, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v8, v8, v19

    vpkuhus v8, v8, v8          ;# saturate and pack


    b       second_pass_8x4

second_pass_pre_copy_8x4:
    ;# only needed if there is a vertical filter present
    ;# if the second filter is not null then need to back off by 2*pitch
    sub     r3, r3, r4
    sub     r3, r3, r4
    li      r10, 16

    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v0,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v0, v0, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v1,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v1, v1, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v2,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v2, v2, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v3,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v3, v3, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v4,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v4, v4, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v5,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v5, v5, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v6,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v6, v6, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v7,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v7, v7, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v8,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v8, v8, v20, v21

    slwi    r6, r6, 4           ;# index into vertical filter array

second_pass_8x4:
    lis     r9, ha16(VFilter)
    la      r10, lo16(VFilter)(r9)
    lvx     v13, r6, r10

    vspltish v15, 8
    vspltish v20, 3
    vslh    v20, v15, v20       ;# 0x0040 0040 0040 0040 0040 0040 0040 0040

    vspltb  v14, v13, 1
    vspltb  v15, v13, 2
    vspltb  v16, v13, 3
    vspltb  v17, v13, 4
    vspltb  v18, v13, 5
    vspltb  v13, v13, 0

    vmuleub v24, v0, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v0, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v2, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v2, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v3, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v3, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v5, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v5, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v1, v14       ;# 2 negative taps
    vmuloub v24, v1, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v4, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v4, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v0, v23, v24       ;# P0 = 8-bit result
    vmuleub v24, v1, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v1, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v3, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v3, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v4, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v4, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v6, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v6, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v2, v14       ;# 2 negative taps
    vmuloub v24, v2, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v5, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v5, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v1, v23, v24       ;# P0 = 8-bit result
    vmuleub v24, v2, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v2, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v4, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v4, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v5, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v5, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v7, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v7, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v3, v14       ;# 2 negative taps
    vmuloub v24, v3, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v6, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v6, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v2, v23, v24       ;# P0 = 8-bit result
    vmuleub v24, v3, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v3, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v5, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v5, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v6, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v6, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v8, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v8, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v4, v14       ;# 2 negative taps
    vmuloub v24, v4, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v7, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v7, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v3, v23, v24       ;# P0 = 8-bit result

    cmpi    cr0, r8, 8
    beq     cr0, store_aligned_8x4

    stvx    v0, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v1, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v2, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v3, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8

    b       exit_8x4

store_aligned_8x4:

    lis     r9, ha16(b_hilo)
    la      r10, lo16(b_hilo)(r9)
    lvx     v10, 0, r10

    vperm   v0, v0, v1, v10
    vperm   v2, v2, v3, v10

    stvx    v0, 0, r7
    addi    r7, r7, 16
    stvx    v2, 0, r7

    b       exit_8x4

store_8x4:
    cmpi    cr0, r8, 8
    beq     cr0, store_aligned2_8x4

    stvx    v2, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v3, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v4, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v5, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8

    b       exit_8x4

store_aligned2_8x4:
    lis     r9, ha16(b_hilo)
    la      r10, lo16(b_hilo)(r9)
    lvx     v10, 0, r10

    vperm   v2, v2, v3, v10
    vperm   v4, v4, v5, v10

    stvx    v2, 0, r7
    addi    r7, r7, 16
    stvx    v4, 0, r7

exit_8x4:

    addi    r1, r1, 32          ;# recover stack

    mtspr   256, r11            ;# reset old VRSAVE


    blr

    .align 2
;# r3 unsigned char * src
;# r4 int src_pitch
;# r5 int x_offset
;# r6 int y_offset
;# r7 unsigned char * dst
;# r8 int dst_pitch

;# Because the width that needs to be filtered will fit in a single altivec
;#  register there is no need to loop.  Everything can stay in registers.
_sixtap_predict8x8_ppc:
    mfspr   r11, 256            ;# get old VRSAVE
    oris    r12, r11, 0xffff
    ori     r12, r12, 0xffc0
    mtspr   256, r12            ;# set VRSAVE

    stwu    r1,-32(r1)          ;# create space on the stack

    slwi.   r5, r5, 5           ;# index into horizontal filter array

    vspltish v19, 7

    ;# If there isn't any filtering to be done for the horizontal, then
    ;#  just skip to the second pass.
    beq-    second_pass_pre_copy_8x8

    lis     r9, ha16(HFilter)
    la      r10, lo16(HFilter)(r9)
    lvx     v13, r5, r10

    addi    r5,  r5, 16
    lvx     v14, r5, r10

    ;# rounding added in on the multiply
    vspltisw v16, 8
    vspltisw v15, 3
    vslw    v15, v16, v15       ;# 0x00000040000000400000004000000040

    ;# Load up permutation constants
    lis     r9, ha16(B_0123)
    la      r10, lo16(B_0123)(r9)
    lvx     v16, 0, r10
    lis     r9, ha16(B_4567)
    la      r10, lo16(B_4567)(r9)
    lvx     v17, 0, r10
    lis     r9, ha16(B_89AB)
    la      r10, lo16(B_89AB)(r9)
    lvx     v18, 0, r10

    ;# Back off input buffer by 2 bytes.  Need 2 before and 3 after
    addi    r3, r3, -2

    addi    r9, r3, 0
    li      r10, 16
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v2,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v2, v2, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v3,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v3, v3, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v4,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v4, v4, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v5,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v5, v5, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v6,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v6, v6, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v7,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v7, v7, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v8,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v8, v8, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v9,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v9, v9, v20, v21

    slwi.   r6, r6, 4           ;# index into vertical filter array

    ;# filter a line
    vperm   v20, v2, v2, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v2, v2, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v2, v2, v2, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v2, v21

    vpkswus v2, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v2, v2, v19

    vpkuhus v2, v2, v2          ;# saturate and pack

    vperm   v20, v3, v3, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v3, v3, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v3, v3, v3, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v3, v21

    vpkswus v3, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v3, v3, v19

    vpkuhus v3, v3, v3          ;# saturate and pack

    vperm   v20, v4, v4, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v4, v4, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v4, v4, v4, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v4, v21

    vpkswus v4, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v4, v4, v19

    vpkuhus v4, v4, v4          ;# saturate and pack

    vperm   v20, v5, v5, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v5, v5, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v5, v5, v5, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v5, v21

    vpkswus v5, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v5, v5, v19

    vpkuhus v5, v5, v5          ;# saturate and pack

    vperm   v20, v6, v6, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v6, v6, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v6, v6, v6, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v6, v21

    vpkswus v6, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v6, v6, v19

    vpkuhus v6, v6, v6          ;# saturate and pack

    vperm   v20, v7, v7, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v7, v7, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v7, v7, v7, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v7, v21

    vpkswus v7, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v7, v7, v19

    vpkuhus v7, v7, v7          ;# saturate and pack

    vperm   v20, v8, v8, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v8, v8, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v8, v8, v8, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v8, v21

    vpkswus v8, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v8, v8, v19

    vpkuhus v8, v8, v8          ;# saturate and pack

    vperm   v20, v9, v9, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v9, v9, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v9, v9, v9, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v9, v21

    vpkswus v9, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v9, v9, v19

    vpkuhus v9, v9, v9          ;# saturate and pack


    ;# Finished filtering main horizontal block.  If there is no
    ;#  vertical filtering, jump to storing the data.  Otherwise
    ;#  load up and filter the additional 5 lines that are needed
    ;#  for the vertical filter.
    beq-    store_8x8

    ;# only needed if there is a vertical filter present
    ;# if the second filter is not null then need to back off by 2*pitch
    sub     r9, r9, r4
    sub     r9, r9, r4

    lvsl    v21,  0, r9        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v0,   0, r9
    lvx     v20, r10, r9

    add     r9, r9, r4

    vperm   v0, v0, v20, v21
    lvsl    v21,  0, r9        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v1,   0, r9
    lvx     v20, r10, r9


    vperm   v1, v1, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v10,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v10, v10, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v11,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v11, v11, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v12,   0, r3
    lvx     v20, r10, r3


    vperm   v12, v12, v20, v21

    vperm   v20, v0, v0, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v0, v0, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v0, v0, v0, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v0, v21

    vpkswus v0, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v0, v0, v19

    vpkuhus v0, v0, v0          ;# saturate and pack

    vperm   v20, v1, v1, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v1, v1, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v1, v1, v1, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v1, v21

    vpkswus v1, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v1, v1, v19

    vpkuhus v1, v1, v1          ;# saturate and pack

    vperm   v20, v10, v10, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v10, v10, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v10, v10, v10, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v10, v21

    vpkswus v10, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v10, v10, v19

    vpkuhus v10, v10, v10          ;# saturate and pack

    vperm   v20, v11, v11, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v11, v11, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v11, v11, v11, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v11, v21

    vpkswus v11, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v11, v11, v19

    vpkuhus v11, v11, v11          ;# saturate and pack

    vperm   v20, v12, v12, v16    ;# v20 = 0123 1234 2345 3456
    vperm   v21, v12, v12, v17    ;# v21 = 4567 5678 6789 789A



    vmsummbm v20, v13, v20, v15
    vmsummbm v20, v14, v21, v20

    vperm   v12, v12, v12, v18     ;# R   = 89AB 9ABC ABCx BCxx



    vmsummbm v21, v13, v21, v15
    vmsummbm v21, v14, v12, v21

    vpkswus v12, v20, v21        ;#  R = 0 1 2 3 4 5 6 7
    vsrh    v12, v12, v19

    vpkuhus v12, v12, v12          ;# saturate and pack


    b       second_pass_8x8

second_pass_pre_copy_8x8:
    ;# only needed if there is a vertical filter present
    ;# if the second filter is not null then need to back off by 2*pitch
    sub     r3, r3, r4
    sub     r3, r3, r4
    li      r10, 16

    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v0,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v0, v0, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v1,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v1, v1, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v2,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v2, v2, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v3,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v3, v3, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v4,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v4, v4, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v5,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v5, v5, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v6,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v6, v6, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v7,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v7, v7, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v8,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v8, v8, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v9,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v9, v9, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v10,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v10, v10, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v11,   0, r3
    lvx     v20, r10, r3

    add     r3, r3, r4

    vperm   v11, v11, v20, v21
    lvsl    v21,  0, r3        ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v12,   0, r3
    lvx     v20, r10, r3


    vperm   v12, v12, v20, v21

    slwi    r6, r6, 4           ;# index into vertical filter array

second_pass_8x8:
    lis     r9, ha16(VFilter)
    la      r10, lo16(VFilter)(r9)
    lvx     v13, r6, r10

    vspltish v15, 8
    vspltish v20, 3
    vslh    v20, v15, v20       ;# 0x0040 0040 0040 0040 0040 0040 0040 0040

    vspltb  v14, v13, 1
    vspltb  v15, v13, 2
    vspltb  v16, v13, 3
    vspltb  v17, v13, 4
    vspltb  v18, v13, 5
    vspltb  v13, v13, 0

    vmuleub v24, v0, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v0, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v2, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v2, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v3, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v3, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v5, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v5, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v1, v14       ;# 2 negative taps
    vmuloub v24, v1, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v4, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v4, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v0, v23, v24       ;# P0 = 8-bit result
    vmuleub v24, v1, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v1, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v3, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v3, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v4, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v4, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v6, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v6, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v2, v14       ;# 2 negative taps
    vmuloub v24, v2, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v5, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v5, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v1, v23, v24       ;# P0 = 8-bit result
    vmuleub v24, v2, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v2, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v4, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v4, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v5, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v5, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v7, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v7, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v3, v14       ;# 2 negative taps
    vmuloub v24, v3, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v6, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v6, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v2, v23, v24       ;# P0 = 8-bit result
    vmuleub v24, v3, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v3, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v5, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v5, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v6, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v6, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v8, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v8, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v4, v14       ;# 2 negative taps
    vmuloub v24, v4, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v7, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v7, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v3, v23, v24       ;# P0 = 8-bit result
    vmuleub v24, v4, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v4, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v6, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v6, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v7, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v7, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v9, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v9, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v5, v14       ;# 2 negative taps
    vmuloub v24, v5, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v8, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v8, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v4, v23, v24       ;# P0 = 8-bit result
    vmuleub v24, v5, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v5, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v7, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v7, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v8, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v8, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v10, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v10, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v6, v14       ;# 2 negative taps
    vmuloub v24, v6, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v9, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v9, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v5, v23, v24       ;# P0 = 8-bit result
    vmuleub v24, v6, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v6, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v8, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v8, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v9, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v9, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v11, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v11, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v7, v14       ;# 2 negative taps
    vmuloub v24, v7, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v10, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v10, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v6, v23, v24       ;# P0 = 8-bit result
    vmuleub v24, v7, v13       ;# 64 + 4 positive taps
    vadduhm v21, v20, v24
    vmuloub v24, v7, v13
    vadduhm v22, v20, v24
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v9, v15        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v9, v15
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v10, v16        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v10, v16
    vadduhm v22, v22, v25      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v12, v18        ;# trashes v8
    vadduhm v21, v21, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v12, v18
    vadduhm v22, v22, v25      ;# Ro = odds

    vmuleub v23, v8, v14       ;# 2 negative taps
    vmuloub v24, v8, v14
                                ;# (Re,Ro) += (V*T)
    vmuleub v25, v11, v17        ;# trashes v8
    vadduhm v23, v23, v25      ;# Re = evens, saturation unnecessary
    vmuloub v25, v11, v17
    vadduhm v24, v24, v25      ;# Ro = odds

    vsubuhs v21, v21, v23       ;# subtract neg from pos
    vsubuhs v22, v22, v24
    vsrh    v21, v21, v19       ;# divide by 128
    vsrh    v22, v22, v19       ;# v16 v17 = evens, odds
    vmrghh  v23, v21, v22       ;# v18 v19 = 16-bit result in order
    vmrglh  v24, v21, v22
    vpkuhus v7, v23, v24       ;# P0 = 8-bit result

    cmpi    cr0, r8, 8
    beq     cr0, store_aligned_8x8

    stvx    v0, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v1, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v2, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v3, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v4, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v5, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v6, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v7, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8

    b       exit_8x8

store_aligned_8x8:

    lis     r9, ha16(b_hilo)
    la      r10, lo16(b_hilo)(r9)
    lvx     v10, 0, r10

    vperm   v0, v0, v1, v10
    vperm   v2, v2, v3, v10
    vperm   v4, v4, v5, v10
    vperm   v6, v6, v7, v10

    stvx    v0, 0, r7
    addi    r7, r7, 16
    stvx    v2, 0, r7
    addi    r7, r7, 16
    stvx    v4, 0, r7
    addi    r7, r7, 16
    stvx    v6, 0, r7

    b       exit_8x8

store_8x8:
    cmpi    cr0, r8, 8
    beq     cr0, store_aligned2_8x8

    stvx    v2, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v3, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v4, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v5, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v6, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v7, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v8, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8
    stvx    v9, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    lwz     r0, 4(r1)
    stw     r0, 4(r7)
    add     r7, r7, r8

    b       exit_8x8

store_aligned2_8x8:
    lis     r9, ha16(b_hilo)
    la      r10, lo16(b_hilo)(r9)
    lvx     v10, 0, r10

    vperm   v2, v2, v3, v10
    vperm   v4, v4, v5, v10
    vperm   v6, v6, v7, v10
    vperm   v8, v8, v9, v10

    stvx    v2, 0, r7
    addi    r7, r7, 16
    stvx    v4, 0, r7
    addi    r7, r7, 16
    stvx    v6, 0, r7
    addi    r7, r7, 16
    stvx    v8, 0, r7

exit_8x8:

    addi    r1, r1, 32          ;# recover stack

    mtspr   256, r11            ;# reset old VRSAVE

    blr

    .align 2
;# r3 unsigned char * src
;# r4 int src_pitch
;# r5 int x_offset
;# r6 int y_offset
;# r7 unsigned char * dst
;# r8 int dst_pitch

;# Two pass filtering.  First pass is Horizontal edges, second pass is vertical
;#  edges.  One of the filters can be null, but both won't be.  Needs to use a
;#  temporary buffer because the source buffer can't be modified and the buffer
;#  for the destination is not large enough to hold the temporary data.
_sixtap_predict16x16_ppc:
    mfspr   r11, 256            ;# get old VRSAVE
    oris    r12, r11, 0xffff
    ori     r12, r12, 0xf000
    mtspr   256, r12            ;# set VRSAVE

    stwu    r1,-416(r1)         ;# create space on the stack

    ;# Three possiblities
    ;#  1. First filter is null.  Don't use a temp buffer.
    ;#  2. Second filter is null.  Don't use a temp buffer.
    ;#  3. Neither are null, use temp buffer.

    ;# First Pass (horizontal edge)
    ;#  setup pointers for src
    ;#  if possiblity (1) then setup the src pointer to be the orginal and jump
    ;#  to second pass.  this is based on if x_offset is 0.

    ;# load up horizontal filter
    slwi.   r5, r5, 5           ;# index into horizontal filter array

    lis     r9, ha16(HFilter)
    la      r10, lo16(HFilter)(r9)
    lvx     v4, r5, r10

    addi    r5,  r5, 16
    lvx     v5, r5, r10

    beq-    copy_horizontal_16x21

    ;# Back off input buffer by 2 bytes.  Need 2 before and 3 after
    addi    r3, r3, -2

    slwi.   r6, r6, 4           ;# index into vertical filter array

    ;# setup constants
    ;# v14 permutation value for alignment
    lis     r9, ha16(b_hperm)
    la      r10, lo16(b_hperm)(r9)
    lvx     v14, 0, r10

    ;# These statements are guessing that there won't be a second pass,
    ;#  but if there is then inside the bypass they need to be set
    li      r0, 16              ;# prepare for no vertical filter

    ;# Change the output pointer and pitch to be the actual
    ;#  desination instead of a temporary buffer.
    addi    r9, r7, 0
    addi    r5, r8, 0

    ;# no vertical filter, so write the output from the first pass
    ;#  directly into the output buffer.
    beq-    no_vertical_filter_bypass

    ;# if the second filter is not null then need to back off by 2*pitch
    sub     r3, r3, r4
    sub     r3, r3, r4

    ;# setup counter for the number of lines that are going to be filtered
    li      r0, 21

    ;# use the stack as temporary storage
    la      r9, 48(r1)
    li      r5, 16

no_vertical_filter_bypass:

    mtspr 9, r0

    ;# rounding added in on the multiply
    vspltisw v10, 8
    vspltisw v12, 3
    vslw    v12, v10, v12       ;# 0x00000040000000400000004000000040

    ;# downshift by 7 ( divide by 128 ) at the end
    vspltish v13, 7

    ;# index to the next set of vectors in the row.
    li      r10, 16
    li      r12, 32

horizontal_loop_16x16:

    lvsl    v15,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v1,   0, r3
    lvx     v2, r10, r3
    lvx     v3, r12, r3

    vperm   v8, v1, v2, v15
    vperm   v9, v2, v3, v15     ;# v8 v9 = 21 input pixels left-justified

    vsldoi  v11, v8, v9, 4

    ;# set 0
    vmsummbm v6, v4, v8, v12    ;# taps times elements
    vmsummbm v0, v5, v11, v6

    ;# set 1
    vsldoi  v10, v8, v9, 1
    vsldoi  v11, v8, v9, 5

    vmsummbm v6, v4, v10, v12
    vmsummbm v1, v5, v11, v6

    ;# set 2
    vsldoi  v10, v8, v9, 2
    vsldoi  v11, v8, v9, 6

    vmsummbm v6, v4, v10, v12
    vmsummbm v2, v5, v11, v6

    ;# set 3
    vsldoi  v10, v8, v9, 3
    vsldoi  v11, v8, v9, 7

    vmsummbm v6, v4, v10, v12
    vmsummbm v3, v5, v11, v6

    vpkswus v0, v0, v1          ;# v0 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v1, v2, v3          ;# v1 = 2 6 A E 3 7 B F

    vsrh    v0, v0, v13         ;# divide v0, v1 by 128
    vsrh    v1, v1, v13

    vpkuhus v0, v0, v1          ;# v0 = scrambled 8-bit result
    vperm   v0, v0, v0, v14     ;# v0 = correctly-ordered result

    stvx    v0,  0, r9
    add     r9, r9, r5

    add     r3, r3, r4

    bdnz    horizontal_loop_16x16

    ;# check again to see if vertical filter needs to be done.
    cmpi    cr0, r6, 0
    beq     cr0, end_16x16

    ;# yes there is, so go to the second pass
    b       second_pass_16x16

copy_horizontal_16x21:
    li      r10, 21
    mtspr 9, r10

    li      r10, 16

    sub     r3, r3, r4
    sub     r3, r3, r4

    ;# this is done above if there is a horizontal filter,
    ;#  if not it needs to be done down here.
    slwi    r6, r6, 4           ;# index into vertical filter array

    ;# always write to the stack when doing a horizontal copy
    la      r9, 48(r1)

copy_horizontal_loop_16x21:
    lvsl    v15,  0, r3         ;# permutate value for alignment

    lvx     v1,   0, r3
    lvx     v2, r10, r3

    vperm   v8, v1, v2, v15

    stvx    v8,  0, r9
    addi    r9, r9, 16

    add     r3, r3, r4

    bdnz    copy_horizontal_loop_16x21

second_pass_16x16:

    ;# always read from the stack when doing a vertical filter
    la      r9, 48(r1)

    ;# downshift by 7 ( divide by 128 ) at the end
    vspltish v7, 7

    lis     r3, ha16(VFilter)
    la      r10, lo16(VFilter)(r3)
    lvx     v0, r6, r10

    vspltish v5, 8
    vspltish v6, 3
    vslh    v6, v5, v6      ;# 0x0040 0040 0040 0040 0040 0040 0040 0040

    vspltb  v1, v0, 1
    vspltb  v2, v0, 2
    vspltb  v3, v0, 3
    vspltb  v4, v0, 4
    vspltb  v5, v0, 5
    vspltb  v0, v0, 0
    li      r10,  16
    lvx     v10,   0, r9    ;# v10..v14 = first 5 rows
    lvx     v11, r10, r9
    addi    r9,   r9, 32
    lvx     v12,   0, r9
    lvx     v13, r10, r9
    addi    r9,   r9, 32
    lvx     v14,   0, r9

    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v15,   0, r9
    vmuleub  v8, v10, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v10, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v12, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v12, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v13, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v13, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v11, v1        ;# 2 negative taps
    vmuloub v19, v11, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v14, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v14, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v10, v18, v19      ;# P0 = 8-bit result
    stvx    v10, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v10,   0, r9
    vmuleub  v8, v11, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v11, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v13, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v13, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v14, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v14, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v10, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v10, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v12, v1        ;# 2 negative taps
    vmuloub v19, v12, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v11, v18, v19      ;# P0 = 8-bit result
    stvx    v11, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v11,   0, r9
    vmuleub  v8, v12, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v12, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v14, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v14, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v11, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v11, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v13, v1        ;# 2 negative taps
    vmuloub v19, v13, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v10, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v10, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v12, v18, v19      ;# P0 = 8-bit result
    stvx    v12, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v12,   0, r9
    vmuleub  v8, v13, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v13, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v10, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v10, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v12, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v12, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v14, v1        ;# 2 negative taps
    vmuloub v19, v14, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v11, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v11, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v13, v18, v19      ;# P0 = 8-bit result
    stvx    v13, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v13,   0, r9
    vmuleub  v8, v14, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v14, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v10, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v10, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v11, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v11, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v13, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v13, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v15, v1        ;# 2 negative taps
    vmuloub v19, v15, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v12, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v12, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v14, v18, v19      ;# P0 = 8-bit result
    stvx    v14, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v14,   0, r9
    vmuleub  v8, v15, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v15, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v11, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v11, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v12, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v12, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v14, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v14, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v10, v1        ;# 2 negative taps
    vmuloub v19, v10, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v13, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v13, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v15, v18, v19      ;# P0 = 8-bit result
    stvx    v15, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v15,   0, r9
    vmuleub  v8, v10, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v10, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v12, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v12, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v13, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v13, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v11, v1        ;# 2 negative taps
    vmuloub v19, v11, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v14, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v14, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v10, v18, v19      ;# P0 = 8-bit result
    stvx    v10, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v10,   0, r9
    vmuleub  v8, v11, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v11, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v13, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v13, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v14, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v14, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v10, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v10, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v12, v1        ;# 2 negative taps
    vmuloub v19, v12, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v11, v18, v19      ;# P0 = 8-bit result
    stvx    v11, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v11,   0, r9
    vmuleub  v8, v12, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v12, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v14, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v14, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v11, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v11, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v13, v1        ;# 2 negative taps
    vmuloub v19, v13, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v10, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v10, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v12, v18, v19      ;# P0 = 8-bit result
    stvx    v12, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v12,   0, r9
    vmuleub  v8, v13, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v13, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v10, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v10, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v12, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v12, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v14, v1        ;# 2 negative taps
    vmuloub v19, v14, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v11, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v11, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v13, v18, v19      ;# P0 = 8-bit result
    stvx    v13, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v13,   0, r9
    vmuleub  v8, v14, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v14, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v10, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v10, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v11, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v11, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v13, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v13, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v15, v1        ;# 2 negative taps
    vmuloub v19, v15, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v12, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v12, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v14, v18, v19      ;# P0 = 8-bit result
    stvx    v14, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v14,   0, r9
    vmuleub  v8, v15, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v15, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v11, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v11, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v12, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v12, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v14, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v14, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v10, v1        ;# 2 negative taps
    vmuloub v19, v10, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v13, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v13, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v15, v18, v19      ;# P0 = 8-bit result
    stvx    v15, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v15,   0, r9
    vmuleub  v8, v10, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v10, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v12, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v12, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v13, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v13, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v11, v1        ;# 2 negative taps
    vmuloub v19, v11, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v14, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v14, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v10, v18, v19      ;# P0 = 8-bit result
    stvx    v10, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v10,   0, r9
    vmuleub  v8, v11, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v11, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v13, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v13, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v14, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v14, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v10, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v10, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v12, v1        ;# 2 negative taps
    vmuloub v19, v12, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v11, v18, v19      ;# P0 = 8-bit result
    stvx    v11, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v11,   0, r9
    vmuleub  v8, v12, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v12, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v14, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v14, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v11, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v11, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v13, v1        ;# 2 negative taps
    vmuloub v19, v13, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v10, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v10, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v12, v18, v19      ;# P0 = 8-bit result
    stvx    v12, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels
    addi    r9,   r9, 16        ;# P5 = newest input row
    lvx     v12,   0, r9
    vmuleub  v8, v13, v0        ;# 64 + 4 positive taps
    vadduhm v16, v6, v8
    vmuloub  v8, v13, v0
    vadduhm v17, v6, v8
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v15, v2        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v15, v2
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v10, v3        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v10, v3
    vadduhm v17, v17, v8      ;# Ro = odds
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v12, v5        ;# trashes v8
    vadduhm v16, v16, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v12, v5
    vadduhm v17, v17, v8      ;# Ro = odds

    vmuleub v18, v14, v1        ;# 2 negative taps
    vmuloub v19, v14, v1
                                ;# (Re,Ro) += (V*T)
    vmuleub v8, v11, v4        ;# trashes v8
    vadduhm v18, v18, v8      ;# Re = evens, saturation unnecessary
    vmuloub v8, v11, v4
    vadduhm v19, v19, v8      ;# Ro = odds

    vsubuhs v16, v16, v18       ;# subtract neg from pos
    vsubuhs v17, v17, v19
    vsrh    v16, v16, v7        ;# divide by 128
    vsrh    v17, v17, v7        ;# v16 v17 = evens, odds
    vmrghh  v18, v16, v17       ;# v18 v19 = 16-bit result in order
    vmrglh  v19, v16, v17
    vpkuhus  v13, v18, v19      ;# P0 = 8-bit result
    stvx    v13, 0, r7
    add     r7, r7, r8      ;# 33 ops per 16 pels

end_16x16:

    addi    r1, r1, 416         ;# recover stack

    mtspr   256, r11            ;# reset old VRSAVE

    blr

    .data

    .align 4
HFilter:
    .byte     0,  0,128,  0,  0,  0,128,  0,  0,  0,128,  0,  0,  0,128,  0
    .byte     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    .byte     0, -6,123, 12,  0, -6,123, 12,  0, -6,123, 12,  0, -6,123, 12
    .byte    -1,  0,  0,  0, -1,  0,  0,  0, -1,  0,  0,  0, -1,  0,  0,  0
    .byte     2,-11,108, 36,  2,-11,108, 36,  2,-11,108, 36,  2,-11,108, 36
    .byte    -8,  1,  0,  0, -8,  1,  0,  0, -8,  1,  0,  0, -8,  1,  0,  0
    .byte     0, -9, 93, 50,  0, -9, 93, 50,  0, -9, 93, 50,  0, -9, 93, 50
    .byte    -6,  0,  0,  0, -6,  0,  0,  0, -6,  0,  0,  0, -6,  0,  0,  0
    .byte     3,-16, 77, 77,  3,-16, 77, 77,  3,-16, 77, 77,  3,-16, 77, 77
    .byte   -16,  3,  0,  0,-16,  3,  0,  0,-16,  3,  0,  0,-16,  3,  0,  0
    .byte     0, -6, 50, 93,  0, -6, 50, 93,  0, -6, 50, 93,  0, -6, 50, 93
    .byte    -9,  0,  0,  0, -9,  0,  0,  0, -9,  0,  0,  0, -9,  0,  0,  0
    .byte     1, -8, 36,108,  1, -8, 36,108,  1, -8, 36,108,  1, -8, 36,108
    .byte   -11,  2,  0,  0,-11,  2,  0,  0,-11,  2,  0,  0,-11,  2,  0,  0
    .byte     0, -1, 12,123,  0, -1, 12,123,  0, -1, 12,123,  0, -1, 12,123
    .byte    -6,  0,  0,  0, -6,  0,  0,  0, -6,  0,  0,  0, -6,  0,  0,  0

    .align 4
VFilter:
    .byte     0,  0,128,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    .byte     0,  6,123, 12,  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    .byte     2, 11,108, 36,  8,  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    .byte     0,  9, 93, 50,  6,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    .byte     3, 16, 77, 77, 16,  3,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    .byte     0,  6, 50, 93,  9,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    .byte     1,  8, 36,108, 11,  2,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    .byte     0,  1, 12,123,  6,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0

    .align 4
b_hperm:
    .byte     0,  4,  8, 12,  1,  5,  9, 13,  2,  6, 10, 14,  3,  7, 11, 15

    .align 4
B_0123:
    .byte     0,  1,  2,  3,  1,  2,  3,  4,  2,  3,  4,  5,  3,  4,  5,  6

    .align 4
B_4567:
    .byte     4,  5,  6,  7,  5,  6,  7,  8,  6,  7,  8,  9,  7,  8,  9, 10

    .align 4
B_89AB:
    .byte     8,  9, 10, 11,  9, 10, 11, 12, 10, 11, 12, 13, 11, 12, 13, 14

    .align 4
b_hilo:
    .byte     0,  1,  2,  3,  4,  5,  6,  7, 16, 17, 18, 19, 20, 21, 22, 23

    .align 4
b_hilo_4x4:
    .byte     0,  1,  2,  3, 16, 17, 18, 19,  0,  0,  0,  0,  0,  0,  0,  0
.text
