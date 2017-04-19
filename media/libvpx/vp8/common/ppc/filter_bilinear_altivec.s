# 1 "filter_bilinear_altivec.asm"
# 1 "<built-in>"
# 1 "<command line>"
# 1 "filter_bilinear_altivec.asm"
;
;  Copyright (c) 2010 The WebM project authors. All Rights Reserved.
;
;  Use of this source code is governed by a BSD-style license
;  that can be found in the LICENSE file in the root of the source
;  tree. An additional intellectual property rights grant can be found
;  in the file PATENTS.  All contributing project authors may
;  be found in the AUTHORS file in the root of the source tree.
;


    .globl _bilinear_predict4x4_ppc
    .globl _bilinear_predict8x4_ppc
    .globl _bilinear_predict8x8_ppc
    .globl _bilinear_predict16x16_ppc




;# Filters a horizontal line
;# expects:
;#  r3  src_ptr
;#  r4  pitch
;#  r10 16
;#  r12 32
;#  v17 perm intput
;#  v18 rounding
;#  v19 shift
;#  v20 filter taps
;#  v21 tmp
;#  v22 tmp
;#  v23 tmp
;#  v24 tmp
;#  v25 tmp
;#  v26 tmp
;#  v27 tmp
;#  v28 perm output
;#









    .align 2
;# r3 unsigned char * src
;# r4 int src_pitch
;# r5 int x_offset
;# r6 int y_offset
;# r7 unsigned char * dst
;# r8 int dst_pitch
_bilinear_predict4x4_ppc:
    mfspr   r11, 256            ;# get old VRSAVE
    oris    r12, r11, 0xf830
    ori     r12, r12, 0xfff8
    mtspr   256, r12            ;# set VRSAVE

    stwu    r1,-32(r1)          ;# create space on the stack

    ;# load up horizontal filter
    slwi.   r5, r5, 4           ;# index into horizontal filter array

    ;# index to the next set of vectors in the row.
    li      r10, 16
    li      r12, 32

    ;# downshift by 7 ( divide by 128 ) at the end
    vspltish v19, 7

    ;# If there isn't any filtering to be done for the horizontal, then
    ;#  just skip to the second pass.
    beq     second_pass_4x4_pre_copy_b

    lis     r9, ha16(hfilter_b)
    la      r0, lo16(hfilter_b)(r9)
    lvx     v20, r5, r0

    ;# setup constants
    ;# v14 permutation value for alignment
    lis     r9, ha16(b_hperm_b)
    la      r0, lo16(b_hperm_b)(r9)
    lvx     v28, 0, r0

    ;# rounding added in on the multiply
    vspltisw v21, 8
    vspltisw v18, 3
    vslw    v18, v21, v18       ;# 0x00000040000000400000004000000040

    slwi.   r6, r6, 5           ;# index into vertical filter array

    ;# Load up permutation constants
    lis     r9, ha16(b_0123_b)
    la      r12, lo16(b_0123_b)(r9)
    lvx     v10, 0, r12
    lis     r9, ha16(b_4567_b)
    la      r12, lo16(b_4567_b)(r9)
    lvx     v11, 0, r12

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v0, v24, v24        ;# v0 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v1, v24, v24        ;# v1 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v2, v24, v24        ;# v2 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v3, v24, v24        ;# v3 = scrambled 8-bit result

    ;# Finished filtering main horizontal block.  If there is no
    ;#  vertical filtering, jump to storing the data.  Otherwise
    ;#  load up and filter the additional line that is needed
    ;#  for the vertical filter.
    beq     store_out_4x4_b

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v4, v24, v24        ;# v4 = scrambled 8-bit result

    b   second_pass_4x4_b

second_pass_4x4_pre_copy_b:
    slwi    r6, r6, 5           ;# index into vertical filter array

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v0, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v1, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v2, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v3, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v4, v21, v22, v17

second_pass_4x4_b:
    vspltish v20, 8
    vspltish v18, 3
    vslh    v18, v20, v18   ;# 0x0040 0040 0040 0040 0040 0040 0040 0040

    lis     r9, ha16(vfilter_b)
    la      r10, lo16(vfilter_b)(r9)
    lvx     v20, r6, r10

    addi    r6,  r6, 16
    lvx     v21, r6, r10

    vmuleub v22, v0, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v0, v20
    vadduhm v23, v18, v23

    vmuleub v24, v1, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v1, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v0, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v0, v0, v23       ;# P0 = 8-bit result
    vmuleub v22, v1, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v1, v20
    vadduhm v23, v18, v23

    vmuleub v24, v2, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v2, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v1, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v1, v1, v23       ;# P0 = 8-bit result
    vmuleub v22, v2, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v2, v20
    vadduhm v23, v18, v23

    vmuleub v24, v3, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v3, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v2, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v2, v2, v23       ;# P0 = 8-bit result
    vmuleub v22, v3, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v3, v20
    vadduhm v23, v18, v23

    vmuleub v24, v4, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v4, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v3, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v3, v3, v23       ;# P0 = 8-bit result

store_out_4x4_b:

    stvx    v0, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    add     r7, r7, r8

    stvx    v1, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    add     r7, r7, r8

    stvx    v2, 0, r1
    lwz     r0, 0(r1)
    stw     r0, 0(r7)
    add     r7, r7, r8

    stvx    v3, 0, r1
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
_bilinear_predict8x4_ppc:
    mfspr   r11, 256            ;# get old VRSAVE
    oris    r12, r11, 0xf830
    ori     r12, r12, 0xfff8
    mtspr   256, r12            ;# set VRSAVE

    stwu    r1,-32(r1)          ;# create space on the stack

    ;# load up horizontal filter
    slwi.   r5, r5, 4           ;# index into horizontal filter array

    ;# index to the next set of vectors in the row.
    li      r10, 16
    li      r12, 32

    ;# downshift by 7 ( divide by 128 ) at the end
    vspltish v19, 7

    ;# If there isn't any filtering to be done for the horizontal, then
    ;#  just skip to the second pass.
    beq     second_pass_8x4_pre_copy_b

    lis     r9, ha16(hfilter_b)
    la      r0, lo16(hfilter_b)(r9)
    lvx     v20, r5, r0

    ;# setup constants
    ;# v14 permutation value for alignment
    lis     r9, ha16(b_hperm_b)
    la      r0, lo16(b_hperm_b)(r9)
    lvx     v28, 0, r0

    ;# rounding added in on the multiply
    vspltisw v21, 8
    vspltisw v18, 3
    vslw    v18, v21, v18       ;# 0x00000040000000400000004000000040

    slwi.   r6, r6, 5           ;# index into vertical filter array

    ;# Load up permutation constants
    lis     r9, ha16(b_0123_b)
    la      r12, lo16(b_0123_b)(r9)
    lvx     v10, 0, r12
    lis     r9, ha16(b_4567_b)
    la      r12, lo16(b_4567_b)(r9)
    lvx     v11, 0, r12

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v0, v24, v24        ;# v0 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v1, v24, v24        ;# v1 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v2, v24, v24        ;# v2 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v3, v24, v24        ;# v3 = scrambled 8-bit result

    ;# Finished filtering main horizontal block.  If there is no
    ;#  vertical filtering, jump to storing the data.  Otherwise
    ;#  load up and filter the additional line that is needed
    ;#  for the vertical filter.
    beq     store_out_8x4_b

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v4, v24, v24        ;# v4 = scrambled 8-bit result

    b   second_pass_8x4_b

second_pass_8x4_pre_copy_b:
    slwi    r6, r6, 5           ;# index into vertical filter array

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v0, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v1, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v2, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v3, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v4, v21, v22, v17

second_pass_8x4_b:
    vspltish v20, 8
    vspltish v18, 3
    vslh    v18, v20, v18   ;# 0x0040 0040 0040 0040 0040 0040 0040 0040

    lis     r9, ha16(vfilter_b)
    la      r10, lo16(vfilter_b)(r9)
    lvx     v20, r6, r10

    addi    r6,  r6, 16
    lvx     v21, r6, r10

    vmuleub v22, v0, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v0, v20
    vadduhm v23, v18, v23

    vmuleub v24, v1, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v1, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v0, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v0, v0, v23       ;# P0 = 8-bit result
    vmuleub v22, v1, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v1, v20
    vadduhm v23, v18, v23

    vmuleub v24, v2, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v2, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v1, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v1, v1, v23       ;# P0 = 8-bit result
    vmuleub v22, v2, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v2, v20
    vadduhm v23, v18, v23

    vmuleub v24, v3, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v3, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v2, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v2, v2, v23       ;# P0 = 8-bit result
    vmuleub v22, v3, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v3, v20
    vadduhm v23, v18, v23

    vmuleub v24, v4, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v4, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v3, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v3, v3, v23       ;# P0 = 8-bit result

store_out_8x4_b:

    cmpi    cr0, r8, 8
    beq     cr0, store_aligned_8x4_b

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

store_aligned_8x4_b:
    lis     r9, ha16(b_hilo_b)
    la      r10, lo16(b_hilo_b)(r9)
    lvx     v10, 0, r10

    vperm   v0, v0, v1, v10
    vperm   v2, v2, v3, v10

    stvx    v0, 0, r7
    addi    r7, r7, 16
    stvx    v2, 0, r7

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
_bilinear_predict8x8_ppc:
    mfspr   r11, 256            ;# get old VRSAVE
    oris    r12, r11, 0xfff0
    ori     r12, r12, 0xffff
    mtspr   256, r12            ;# set VRSAVE

    stwu    r1,-32(r1)          ;# create space on the stack

    ;# load up horizontal filter
    slwi.   r5, r5, 4           ;# index into horizontal filter array

    ;# index to the next set of vectors in the row.
    li      r10, 16
    li      r12, 32

    ;# downshift by 7 ( divide by 128 ) at the end
    vspltish v19, 7

    ;# If there isn't any filtering to be done for the horizontal, then
    ;#  just skip to the second pass.
    beq     second_pass_8x8_pre_copy_b

    lis     r9, ha16(hfilter_b)
    la      r0, lo16(hfilter_b)(r9)
    lvx     v20, r5, r0

    ;# setup constants
    ;# v14 permutation value for alignment
    lis     r9, ha16(b_hperm_b)
    la      r0, lo16(b_hperm_b)(r9)
    lvx     v28, 0, r0

    ;# rounding added in on the multiply
    vspltisw v21, 8
    vspltisw v18, 3
    vslw    v18, v21, v18       ;# 0x00000040000000400000004000000040

    slwi.   r6, r6, 5           ;# index into vertical filter array

    ;# Load up permutation constants
    lis     r9, ha16(b_0123_b)
    la      r12, lo16(b_0123_b)(r9)
    lvx     v10, 0, r12
    lis     r9, ha16(b_4567_b)
    la      r12, lo16(b_4567_b)(r9)
    lvx     v11, 0, r12

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v0, v24, v24        ;# v0 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v1, v24, v24        ;# v1 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v2, v24, v24        ;# v2 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v3, v24, v24        ;# v3 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v4, v24, v24        ;# v4 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v5, v24, v24        ;# v5 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v6, v24, v24        ;# v6 = scrambled 8-bit result
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v7, v24, v24        ;# v7 = scrambled 8-bit result

    ;# Finished filtering main horizontal block.  If there is no
    ;#  vertical filtering, jump to storing the data.  Otherwise
    ;#  load up and filter the additional line that is needed
    ;#  for the vertical filter.
    beq     store_out_8x8_b

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 9 bytes wide, output is 8 bytes.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    vperm   v21, v21, v22, v17

    vperm   v24, v21, v21, v10  ;# v20 = 0123 1234 2345 3456
    vperm   v25, v21, v21, v11  ;# v21 = 4567 5678 6789 789A

    vmsummbm v24, v20, v24, v18
    vmsummbm v25, v20, v25, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128

    vpkuhus v8, v24, v24        ;# v8 = scrambled 8-bit result

    b   second_pass_8x8_b

second_pass_8x8_pre_copy_b:
    slwi    r6, r6, 5           ;# index into vertical filter array

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v0, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v1, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v2, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v3, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v4, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v5, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v6, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v7, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3


    vperm   v8, v21, v22, v17

second_pass_8x8_b:
    vspltish v20, 8
    vspltish v18, 3
    vslh    v18, v20, v18   ;# 0x0040 0040 0040 0040 0040 0040 0040 0040

    lis     r9, ha16(vfilter_b)
    la      r10, lo16(vfilter_b)(r9)
    lvx     v20, r6, r10

    addi    r6,  r6, 16
    lvx     v21, r6, r10

    vmuleub v22, v0, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v0, v20
    vadduhm v23, v18, v23

    vmuleub v24, v1, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v1, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v0, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v0, v0, v23       ;# P0 = 8-bit result
    vmuleub v22, v1, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v1, v20
    vadduhm v23, v18, v23

    vmuleub v24, v2, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v2, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v1, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v1, v1, v23       ;# P0 = 8-bit result
    vmuleub v22, v2, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v2, v20
    vadduhm v23, v18, v23

    vmuleub v24, v3, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v3, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v2, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v2, v2, v23       ;# P0 = 8-bit result
    vmuleub v22, v3, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v3, v20
    vadduhm v23, v18, v23

    vmuleub v24, v4, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v4, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v3, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v3, v3, v23       ;# P0 = 8-bit result
    vmuleub v22, v4, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v4, v20
    vadduhm v23, v18, v23

    vmuleub v24, v5, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v5, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v4, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v4, v4, v23       ;# P0 = 8-bit result
    vmuleub v22, v5, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v5, v20
    vadduhm v23, v18, v23

    vmuleub v24, v6, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v6, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v5, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v5, v5, v23       ;# P0 = 8-bit result
    vmuleub v22, v6, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v6, v20
    vadduhm v23, v18, v23

    vmuleub v24, v7, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v7, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v6, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v6, v6, v23       ;# P0 = 8-bit result
    vmuleub v22, v7, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v7, v20
    vadduhm v23, v18, v23

    vmuleub v24, v8, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v8, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v7, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v7, v7, v23       ;# P0 = 8-bit result

store_out_8x8_b:

    cmpi    cr0, r8, 8
    beq     cr0, store_aligned_8x8_b

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

store_aligned_8x8_b:
    lis     r9, ha16(b_hilo_b)
    la      r10, lo16(b_hilo_b)(r9)
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

exit_8x8:

    addi    r1, r1, 32          ;# recover stack
    mtspr   256, r11            ;# reset old VRSAVE

    blr

;# Filters a horizontal line
;# expects:
;#  r3  src_ptr
;#  r4  pitch
;#  r10 16
;#  r12 32
;#  v17 perm intput
;#  v18 rounding
;#  v19 shift
;#  v20 filter taps
;#  v21 tmp
;#  v22 tmp
;#  v23 tmp
;#  v24 tmp
;#  v25 tmp
;#  v26 tmp
;#  v27 tmp
;#  v28 perm output
;#



    .align 2
;# r3 unsigned char * src
;# r4 int src_pitch
;# r5 int x_offset
;# r6 int y_offset
;# r7 unsigned char * dst
;# r8 int dst_pitch
_bilinear_predict16x16_ppc:
    mfspr   r11, 256            ;# get old VRSAVE
    oris    r12, r11, 0xffff
    ori     r12, r12, 0xfff8
    mtspr   256, r12            ;# set VRSAVE

    ;# load up horizontal filter
    slwi.   r5, r5, 4           ;# index into horizontal filter array

    ;# index to the next set of vectors in the row.
    li      r10, 16
    li      r12, 32

    ;# downshift by 7 ( divide by 128 ) at the end
    vspltish v19, 7

    ;# If there isn't any filtering to be done for the horizontal, then
    ;#  just skip to the second pass.
    beq     second_pass_16x16_pre_copy_b

    lis     r9, ha16(hfilter_b)
    la      r0, lo16(hfilter_b)(r9)
    lvx     v20, r5, r0

    ;# setup constants
    ;# v14 permutation value for alignment
    lis     r9, ha16(b_hperm_b)
    la      r0, lo16(b_hperm_b)(r9)
    lvx     v28, 0, r0

    ;# rounding added in on the multiply
    vspltisw v21, 8
    vspltisw v18, 3
    vslw    v18, v21, v18       ;# 0x00000040000000400000004000000040

    slwi.   r6, r6, 5           ;# index into vertical filter array


    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v0, v24, v25        ;# v0 = scrambled 8-bit result
    vperm   v0, v0, v0, v28     ;# v0 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v1, v24, v25        ;# v1 = scrambled 8-bit result
    vperm   v1, v1, v0, v28     ;# v1 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v2, v24, v25        ;# v2 = scrambled 8-bit result
    vperm   v2, v2, v0, v28     ;# v2 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v3, v24, v25        ;# v3 = scrambled 8-bit result
    vperm   v3, v3, v0, v28     ;# v3 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v4, v24, v25        ;# v4 = scrambled 8-bit result
    vperm   v4, v4, v0, v28     ;# v4 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v5, v24, v25        ;# v5 = scrambled 8-bit result
    vperm   v5, v5, v0, v28     ;# v5 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v6, v24, v25        ;# v6 = scrambled 8-bit result
    vperm   v6, v6, v0, v28     ;# v6 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v7, v24, v25        ;# v7 = scrambled 8-bit result
    vperm   v7, v7, v0, v28     ;# v7 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v8, v24, v25        ;# v8 = scrambled 8-bit result
    vperm   v8, v8, v0, v28     ;# v8 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v9, v24, v25        ;# v9 = scrambled 8-bit result
    vperm   v9, v9, v0, v28     ;# v9 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v10, v24, v25        ;# v10 = scrambled 8-bit result
    vperm   v10, v10, v0, v28     ;# v10 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v11, v24, v25        ;# v11 = scrambled 8-bit result
    vperm   v11, v11, v0, v28     ;# v11 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v12, v24, v25        ;# v12 = scrambled 8-bit result
    vperm   v12, v12, v0, v28     ;# v12 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v13, v24, v25        ;# v13 = scrambled 8-bit result
    vperm   v13, v13, v0, v28     ;# v13 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v14, v24, v25        ;# v14 = scrambled 8-bit result
    vperm   v14, v14, v0, v28     ;# v14 = correctly-ordered result

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    add     r3, r3, r4
    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v15, v24, v25        ;# v15 = scrambled 8-bit result
    vperm   v15, v15, v0, v28     ;# v15 = correctly-ordered result

    ;# Finished filtering main horizontal block.  If there is no
    ;#  vertical filtering, jump to storing the data.  Otherwise
    ;#  load up and filter the additional line that is needed
    ;#  for the vertical filter.
    beq     store_out_16x16_b


    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3
    lvx     v23, r12, r3

    vperm   v21, v21, v22, v17
    vperm   v22, v22, v23, v17  ;# v8 v9 = 21 input pixels left-justified

    ;# set 0
    vmsummbm v24, v20, v21, v18 ;# taps times elements

    ;# set 1
    vsldoi  v23, v21, v22, 1
    vmsummbm v25, v20, v23, v18

    ;# set 2
    vsldoi  v23, v21, v22, 2
    vmsummbm v26, v20, v23, v18

    ;# set 3
    vsldoi  v23, v21, v22, 3
    vmsummbm v27, v20, v23, v18

    vpkswus v24, v24, v25       ;# v24 = 0 4 8 C 1 5 9 D (16-bit)
    vpkswus v25, v26, v27       ;# v25 = 2 6 A E 3 7 B F

    vsrh    v24, v24, v19       ;# divide v0, v1 by 128
    vsrh    v25, v25, v19

    vpkuhus v16, v24, v25        ;# v16 = scrambled 8-bit result
    vperm   v16, v16, v0, v28     ;# v16 = correctly-ordered result

    b   second_pass_16x16_b

second_pass_16x16_pre_copy_b:
    slwi    r6, r6, 5           ;# index into vertical filter array

    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v0, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v1, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v2, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v3, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v4, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v5, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v6, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v7, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v8, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v9, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v10, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v11, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v12, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v13, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v14, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3

    add     r3, r3, r4

    vperm   v15, v21, v22, v17
    lvsl    v17,  0, r3         ;# permutate value for alignment

    ;# input to filter is 21 bytes wide, output is 16 bytes.
    ;#  input will can span three vectors if not aligned correctly.
    lvx     v21,   0, r3
    lvx     v22, r10, r3


    vperm   v16, v21, v22, v17

second_pass_16x16_b:
    vspltish v20, 8
    vspltish v18, 3
    vslh    v18, v20, v18   ;# 0x0040 0040 0040 0040 0040 0040 0040 0040

    lis     r9, ha16(vfilter_b)
    la      r10, lo16(vfilter_b)(r9)
    lvx     v20, r6, r10

    addi    r6,  r6, 16
    lvx     v21, r6, r10

    vmuleub v22, v0, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v0, v20
    vadduhm v23, v18, v23

    vmuleub v24, v1, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v1, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v0, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v0, v0, v23       ;# P0 = 8-bit result
    vmuleub v22, v1, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v1, v20
    vadduhm v23, v18, v23

    vmuleub v24, v2, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v2, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v1, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v1, v1, v23       ;# P0 = 8-bit result
    vmuleub v22, v2, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v2, v20
    vadduhm v23, v18, v23

    vmuleub v24, v3, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v3, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v2, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v2, v2, v23       ;# P0 = 8-bit result
    vmuleub v22, v3, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v3, v20
    vadduhm v23, v18, v23

    vmuleub v24, v4, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v4, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v3, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v3, v3, v23       ;# P0 = 8-bit result
    vmuleub v22, v4, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v4, v20
    vadduhm v23, v18, v23

    vmuleub v24, v5, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v5, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v4, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v4, v4, v23       ;# P0 = 8-bit result
    vmuleub v22, v5, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v5, v20
    vadduhm v23, v18, v23

    vmuleub v24, v6, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v6, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v5, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v5, v5, v23       ;# P0 = 8-bit result
    vmuleub v22, v6, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v6, v20
    vadduhm v23, v18, v23

    vmuleub v24, v7, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v7, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v6, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v6, v6, v23       ;# P0 = 8-bit result
    vmuleub v22, v7, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v7, v20
    vadduhm v23, v18, v23

    vmuleub v24, v8, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v8, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v7, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v7, v7, v23       ;# P0 = 8-bit result
    vmuleub v22, v8, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v8, v20
    vadduhm v23, v18, v23

    vmuleub v24, v9, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v9, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v8, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v8, v8, v23       ;# P0 = 8-bit result
    vmuleub v22, v9, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v9, v20
    vadduhm v23, v18, v23

    vmuleub v24, v10, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v10, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v9, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v9, v9, v23       ;# P0 = 8-bit result
    vmuleub v22, v10, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v10, v20
    vadduhm v23, v18, v23

    vmuleub v24, v11, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v11, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v10, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v10, v10, v23       ;# P0 = 8-bit result
    vmuleub v22, v11, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v11, v20
    vadduhm v23, v18, v23

    vmuleub v24, v12, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v12, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v11, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v11, v11, v23       ;# P0 = 8-bit result
    vmuleub v22, v12, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v12, v20
    vadduhm v23, v18, v23

    vmuleub v24, v13, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v13, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v12, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v12, v12, v23       ;# P0 = 8-bit result
    vmuleub v22, v13, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v13, v20
    vadduhm v23, v18, v23

    vmuleub v24, v14, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v14, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v13, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v13, v13, v23       ;# P0 = 8-bit result
    vmuleub v22, v14, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v14, v20
    vadduhm v23, v18, v23

    vmuleub v24, v15, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v15, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v14, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v14, v14, v23       ;# P0 = 8-bit result
    vmuleub v22, v15, v20       ;# 64 + 4 positive taps
    vadduhm v22, v18, v22
    vmuloub v23, v15, v20
    vadduhm v23, v18, v23

    vmuleub v24, v16, v21
    vadduhm v22, v22, v24       ;# Re = evens, saturation unnecessary
    vmuloub v25, v16, v21
    vadduhm v23, v23, v25       ;# Ro = odds

    vsrh    v22, v22, v19       ;# divide by 128
    vsrh    v23, v23, v19       ;# v16 v17 = evens, odds
    vmrghh  v15, v22, v23       ;# v18 v19 = 16-bit result in order
    vmrglh  v23, v22, v23
    vpkuhus v15, v15, v23       ;# P0 = 8-bit result

store_out_16x16_b:

    stvx    v0,  0, r7

    add     r7, r7, r8
    stvx    v1,  0, r7

    add     r7, r7, r8
    stvx    v2,  0, r7

    add     r7, r7, r8
    stvx    v3,  0, r7

    add     r7, r7, r8
    stvx    v4,  0, r7

    add     r7, r7, r8
    stvx    v5,  0, r7

    add     r7, r7, r8
    stvx    v6,  0, r7

    add     r7, r7, r8
    stvx    v7,  0, r7

    add     r7, r7, r8
    stvx    v8,  0, r7

    add     r7, r7, r8
    stvx    v9,  0, r7

    add     r7, r7, r8
    stvx    v10,  0, r7

    add     r7, r7, r8
    stvx    v11,  0, r7

    add     r7, r7, r8
    stvx    v12,  0, r7

    add     r7, r7, r8
    stvx    v13,  0, r7

    add     r7, r7, r8
    stvx    v14,  0, r7

    add     r7, r7, r8
    stvx    v15,  0, r7


    mtspr   256, r11            ;# reset old VRSAVE

    blr

    .data

    .align 4
hfilter_b:
    .byte   128,  0,  0,  0,128,  0,  0,  0,128,  0,  0,  0,128,  0,  0,  0
    .byte   112, 16,  0,  0,112, 16,  0,  0,112, 16,  0,  0,112, 16,  0,  0
    .byte    96, 32,  0,  0, 96, 32,  0,  0, 96, 32,  0,  0, 96, 32,  0,  0
    .byte    80, 48,  0,  0, 80, 48,  0,  0, 80, 48,  0,  0, 80, 48,  0,  0
    .byte    64, 64,  0,  0, 64, 64,  0,  0, 64, 64,  0,  0, 64, 64,  0,  0
    .byte    48, 80,  0,  0, 48, 80,  0,  0, 48, 80,  0,  0, 48, 80,  0,  0
    .byte    32, 96,  0,  0, 32, 96,  0,  0, 32, 96,  0,  0, 32, 96,  0,  0
    .byte    16,112,  0,  0, 16,112,  0,  0, 16,112,  0,  0, 16,112,  0,  0

    .align 4
vfilter_b:
    .byte   128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128
    .byte     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    .byte   112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112
    .byte    16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
    .byte    96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96
    .byte    32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
    .byte    80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80
    .byte    48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48
    .byte    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
    .byte    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
    .byte    48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48
    .byte    80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80
    .byte    32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
    .byte    96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96, 96
    .byte    16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16
    .byte   112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112

    .align 4
b_hperm_b:
    .byte     0,  4,  8, 12,  1,  5,  9, 13,  2,  6, 10, 14,  3,  7, 11, 15

    .align 4
b_0123_b:
    .byte     0,  1,  2,  3,  1,  2,  3,  4,  2,  3,  4,  5,  3,  4,  5,  6

    .align 4
b_4567_b:
    .byte     4,  5,  6,  7,  5,  6,  7,  8,  6,  7,  8,  9,  7,  8,  9, 10

b_hilo_b:
    .byte     0,  1,  2,  3,  4,  5,  6,  7, 16, 17, 18, 19, 20, 21, 22, 23
.text
