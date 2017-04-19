/*
 *  Copyright (c) 2012 The WebM project authors. All Rights Reserved.
 *  Copyright (c) 2016 Cameron Kaiser and Contributors to TenFourFox
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

/* AltiVec accelerated VP9 IDCTs for big-endian 32-bit PowerPC.
   This is largely patterned off the SSE2 versions, since they are the
   most similar to our instruction set. */

#include "./vp9_rtcd.h"
#include "vpx_ports/mem.h"
#include "vp9/common/vp9_idct.h"

#ifndef __ALTIVEC__
#error VMX being compiled on non-VMX platform
#else
#include <altivec.h>
#endif
#include <assert.h>

// v = vector, s = *uint32_t, vv = temporary vector (unsigned int)

// Basic notion.
#define _unaligned_load128(v,s) { v=vec_perm(vec_ld(0,s),vec_ld(16,s),vec_lvsl(0,s)); }

// Equivalent for _mm_cvtsi32_si128. (Other 96 bits undefined.)
#define _unaligned_load32(v,s) { v=vec_lde(0,s); v=vec_perm(v,v,vec_lvsl(0,s)); }
// Equivalent for _mm_cvtsi128_si32.
#define _unaligned_store32(v,vv,s) { vv=vec_splat((vector unsigned int)v,0); vec_ste(vv,0,s); }
// Equivalent for _mm_loadl_epi64. Simplest just to make this a full load right now.
#define _unaligned_load64(v,s) _unaligned_load128(v,s)
// Equivalent for _mm_storel_epi64. Essentially acts as two store32s on different elements.
#define _unaligned_store64(v,vv,s) {\
	vv = vec_splat((vector unsigned int)v, 0); vec_ste(vv,0,s);\
	vv = vec_splat((vector unsigned int)v, 1); vec_ste(vv,4,s);\
}

#define ALIGN16 __attribute__((aligned(16)))
#define short_pair_a(b, a) \
  { (int16_t)(b), (int16_t)(a), (int16_t)(b), (int16_t)(a), \
                (int16_t)(b), (int16_t)(a), (int16_t)(b), (int16_t)(a) }

// Constant vectors we end up constructing a lot.
// If the compiler has any brains, these will just be vec_ld()s directly on them.

// These constants are used heavily in the IDCT/IADST round-and-shift operations.
vector signed int dct_rounding_vec ALIGN16 = {
	DCT_CONST_ROUNDING, DCT_CONST_ROUNDING, DCT_CONST_ROUNDING, DCT_CONST_ROUNDING
};
vector unsigned int dct_bitshift_vec ALIGN16 = {
	DCT_CONST_BITS, DCT_CONST_BITS, DCT_CONST_BITS, DCT_CONST_BITS
};
vector unsigned char perm4416_vec0 ALIGN16 = {
	0, 1, 4, 5, 0, 1, 4, 5, 2, 3, 6, 7, 2, 3, 6, 7
};
vector unsigned char perm4416_vec1 ALIGN16 = {
	8, 9,12,13, 8, 9,12,13,10,11,14,15,10,11,14,15
};
// The merge64_?vec vectors emulate _mm_unpack??_epi64.
vector unsigned char merge64_hvec ALIGN16 = {
	0, 1, 2, 3, 4, 5, 6, 7, 16, 17, 18, 19, 20, 21, 22, 23
};
vector unsigned char merge64_lvec ALIGN16 = {
	8, 9,10,11,12,13,14,15, 24, 25, 26, 27, 28, 29, 30, 31
}; 

// Handy notes:
// _mm_unpacklo/hi is exactly equivalent to vec_mergeh/l (note endian switch).
// _mm_shuffle_epi32(x, 0x4e) is exactly equivalent to vec_sld(x, x, 8).

// DCT utility function to splat an arbitrary signed short. Can work
// for other unit sizes.
vector signed short ss_splat(signed short *what) {
	vector signed short result = vec_ld(0, what);
	vector signed short temp = vec_ld(sizeof(*what) - 1, what);
	vector unsigned char mover = vec_lvsl(0, what);
	result = vec_perm(result, temp, mover);
	return vec_splat(result, 0);
}

void vp9_idct4x4_1_add_vmx(const int16_t *input, uint8_t *dest, int stride) {
	vector signed short dc_value, i0, i1, i2, i3;
	vector unsigned char p0, p1, p2, p3;
	vector unsigned char zero = vec_splat_s8(0);
	vector unsigned int ltemp;
	int a;
	signed short a_s;
	
	a = dct_const_round_shift(input[0] * cospi_16_64);
	a = dct_const_round_shift(a * cospi_16_64);
	a_s = ROUND_POWER_OF_TWO(a, 4);
	dc_value = ss_splat(&a_s);
	
	// I chose to interleave the vector calls to see if we can
	// get better parallelism rather than a macro like SSE2's.	
	
	_unaligned_load32(p0, (uint32_t *)(dest + 0 * stride));
	// SSE unpacklo(x,y) becomes vec_mergeh(y,x)
	i0 = (vector signed short)vec_mergeh(zero, p0);
	_unaligned_load32(p1, (uint32_t *)(dest + 1 * stride));
	i0 = vec_add(i0, dc_value);
	i1 = (vector signed short)vec_mergeh(zero, p1);
	_unaligned_load32(p2, (uint32_t *)(dest + 2 * stride));
	p0 = vec_packsu(i0, i0);
	i1 = vec_add(i1, dc_value);
	_unaligned_load32(p3, (uint32_t *)(dest + 3 * stride));
	i2 = (vector signed short)vec_mergeh(zero, p2);
	p1 = vec_packsu(i1, i1);
	_unaligned_store32(p0, ltemp, (uint32_t *)(dest + 0 * stride));
	i2 = vec_add(i2, dc_value);
	i3 = (vector signed short)vec_mergeh(zero, p3);
	_unaligned_store32(p1, ltemp, (uint32_t *)(dest + 1 * stride));
	p2 = vec_packsu(i2, i2);
	i3 = vec_add(i3, dc_value);
	_unaligned_store32(p2, ltemp, (uint32_t *)(dest + 2 * stride));
	p3 = vec_packsu(i3, i3);
	_unaligned_store32(p3, ltemp, (uint32_t *)(dest + 3 * stride));
}

void vp9_idct4x4_16_add_vmx(const int16_t *input, uint8_t *dest, int stride) {
	vector unsigned char zero = vec_splat_s8(0);
	vector unsigned char one = vec_splat_s8(1);
	vector unsigned short four = vec_splat_s16(4);
	vector signed short eight = vec_splat_s16(8);
	vector signed short input0, input1, input2, input3;
	vector signed int wnput0, wnput1, wnput2, wnput3;
	vector unsigned char result;
	vector unsigned int ltemp;

	// gcc doesn't like this as a constant, grumpf.
	vector signed short cst4416_vec = {
		(int16_t)cospi_16_64, (int16_t)cospi_16_64, (int16_t)cospi_16_64,
		(int16_t)-cospi_16_64, (int16_t)cospi_24_64, (int16_t)-cospi_8_64,
		(int16_t)cospi_8_64, (int16_t)cospi_24_64
	};

	// The Intel intrinsics used imply the input is aligned.
	input0 = vec_ld(0, (uint32_t *)input);
	input2 = vec_ld(16, (uint32_t *)input);

	// ALL HAIL THE ALTIVEC PERMUTE UNIT!
	// SUCK IT, INTEL!
	// Combine the SSE2 unpack and shuffle into one op.
	// a a c c b b d d e e g g f f h h =>
	//     a a c c a a c c b b d d b b d d (0)
	//     0 1 4 5 0 1 4 5 2 3 6 7 2 3 6 7     (perm)
	//     e e g g e e g g f f h h f f h h (1) 
	//     8 9 c d 8 9 c d a b e f a b e f     (perm)
	input1 = vec_perm(input0, input0, perm4416_vec1);
	input0 = vec_perm(input0, input0, perm4416_vec0);
	input3 = vec_perm(input2, input2, perm4416_vec1);
	input2 = vec_perm(input2, input2, perm4416_vec0);

	// Stage 1.
	// (int32_t)r0 := (a0 * b0) + (a1 * b1)
	// (int32_t)r1 := (a2 * b2) + (a3 * b3), etc.
	// This is the very confusingly named vec_msum,
	// when it's really an integer multiply-add-add.
	// We can toss the dct_rounding_vec step in here too.
	// Damn, we're good.
	// We do this a lot in these IDCTs. One might think that someone
	// at Motorola was thinking about this very application.
	wnput0 = vec_msum(input0, cst4416_vec, dct_rounding_vec);
	wnput1 = vec_msum(input1, cst4416_vec, dct_rounding_vec);
	wnput2 = vec_msum(input2, cst4416_vec, dct_rounding_vec);
	wnput3 = vec_msum(input3, cst4416_vec, dct_rounding_vec);

	wnput0 = vec_sra(wnput0, dct_bitshift_vec);
	wnput1 = vec_sra(wnput1, dct_bitshift_vec);
	wnput2 = vec_sra(wnput2, dct_bitshift_vec);
	wnput3 = vec_sra(wnput3, dct_bitshift_vec);

	// Stage 2. Pack back to short.
	input0 = vec_packs(wnput0, wnput1);
	input1 = vec_packs(wnput2, wnput3);

	// Transpose.
	input2 = vec_mergeh(input0, input1);
	input3 = vec_mergel(input0, input1);
	// Time for fancy pants with fancy casts
	// to simulate unpacklo_epi32.
	input0 = (vector signed short)vec_mergeh((vector signed int)input2, (vector signed int)input3);
	input1 = (vector signed short)vec_mergel((vector signed int)input2, (vector signed int)input3);

	// Rotate columns.
	// a a b b c c d d e e f f g g h h => e e f f g g h h a a b b c c d d
	input1 = vec_sld(input1, input1, 8);
	input2 = vec_add(input0, input1);
	input3 = vec_sub(input0, input1);

	// Expand back out.
	// a a b b c c d d e e f f g g h h =>
	//     a a b b a a b b c c d d c c d d (0)
	//     e e f f e e f f g g h h g g h h (1)
	// Do this with a merge and more fancy casts.
	input0 = (vector signed short)vec_mergeh((vector signed int)input2, (vector signed int)input2);
	input1 = (vector signed short)vec_mergel((vector signed int)input2, (vector signed int)input2);
	input2 = (vector signed short)vec_mergel((vector signed int)input3, (vector signed int)input3);
	input3 = (vector signed short)vec_mergeh((vector signed int)input3, (vector signed int)input3);

	// Stage 1 again.
	wnput0 = vec_msum(input0, cst4416_vec, dct_rounding_vec);
	wnput1 = vec_msum(input1, cst4416_vec, dct_rounding_vec);
	wnput2 = vec_msum(input2, cst4416_vec, dct_rounding_vec);
	wnput3 = vec_msum(input3, cst4416_vec, dct_rounding_vec);

	wnput0 = vec_sra(wnput0, dct_bitshift_vec);
	wnput1 = vec_sra(wnput1, dct_bitshift_vec);
	wnput2 = vec_sra(wnput2, dct_bitshift_vec);
	wnput3 = vec_sra(wnput3, dct_bitshift_vec);

	// Stage 2 again. Pack back to short.
	input0 = vec_packs(wnput0, wnput2);
	input1 = vec_packs(wnput1, wnput3);

	// Transpose again.
	input2 = vec_mergeh(input0, input1);
	input3 = vec_mergel(input0, input1);
	input0 = (vector signed short)vec_mergeh((vector signed int)input2, (vector signed int)input3);
	input1 = (vector signed short)vec_mergel((vector signed int)input2, (vector signed int)input3);

	// Rotate columns again.
	input1 = vec_sld(input1, input1, 8);
	input2 = vec_add(input0, input1);
	input3 = vec_sub(input0, input1);

	// Finally, add and shift.
	input2 = vec_add(input2, eight);
	input3 = vec_add(input3, eight);
	input2 = vec_sra(input2, four);
	input3 = vec_sra(input3, four);

	// This next part is tricky. To accomodate variable strides, we need
	// to load and store in 32-bit pieces. Yuck.
	// This is kind of a bass-ackwards merged unaligned store, really.
	//
	// Get the destination values we're going to merge with.
	_unaligned_load32(wnput0, (uint32_t *)dest);
	_unaligned_load32(wnput1, (uint32_t *)(dest + stride));
	wnput0 = vec_mergeh(wnput0, wnput1);
	_unaligned_load32(wnput2, (uint32_t *)(dest + stride + stride));
	wnput0 = (vector signed int)vec_mergeh(zero, (vector unsigned char)wnput0);
	_unaligned_load32(wnput3, (uint32_t *)(dest + stride + stride + stride));
	wnput2 = vec_mergeh(wnput3, wnput2);
	wnput2 = (vector signed int)vec_mergeh(zero, (vector unsigned char)wnput2);

	// Reconstruct and pack.
	input0 = vec_add((vector signed short)wnput0, input2);
	input1 = vec_add((vector signed short)wnput2, input3);
	result = vec_packsu(input0, input1);

	// Store, 32 bits at a time, shifting the vector down.
	// This is gross but I don't see a better way since stride might not be 4
	// and we have a single transposition anyway.
	_unaligned_store32(result, ltemp, (uint32_t *)dest);
	result = vec_sld(result, zero, 4);
	_unaligned_store32(result, ltemp, (uint32_t *)(dest + stride));
	result = vec_sld(result, zero, 4);
	_unaligned_store32(result, ltemp, (uint32_t *)(dest + stride + stride + stride)); // yes, really
	result = vec_sld(result, zero, 4);
	_unaligned_store32(result, ltemp, (uint32_t *)(dest + stride + stride));
}

void vp9_idct8x8_1_add_vmx(const int16_t *input, uint8_t *dest, int stride) {
	vector signed short dc_value, i0, i1, i2, i3, i4, i5, i6, i7;
	vector unsigned char p0, p1, p2, p3, p4, p5, p6, p7;
	vector unsigned char zero = vec_splat_s8(0);
	vector unsigned int ltemp;
	int a;
	signed short a_s;
	
	a = dct_const_round_shift(input[0] * cospi_16_64);
	a = dct_const_round_shift(a * cospi_16_64);
	a_s = ROUND_POWER_OF_TWO(a, 5);
	dc_value = ss_splat(&a_s);
	
	// AltiVec does not natively handle 64 bit values, but we can
	// simulate it by dealing in "half vectors." We load all 128 bits
	// and merely operate on 64 of them.
	// Again, interleave calls. This is exactly the same as the above
	// except we use a 64-bit set and iterate for 8 stride lengths.	
	
	// XXX: Would we spend more time constructing the optimized vectors
	// to store than simply taking the hit for being unaligned?
	
	_unaligned_load64(p0, (uint32_t *)(dest + 0 * stride));
	i0 = (vector signed short)vec_mergeh(zero, p0);
	_unaligned_load64(p1, (uint32_t *)(dest + 1 * stride));
	i4 = vec_add(i0, dc_value);
	i1 = (vector signed short)vec_mergeh(zero, p1);
	_unaligned_load64(p2, (uint32_t *)(dest + 2 * stride));
	p0 = vec_packsu(i4, i4);
	i5 = vec_add(i1, dc_value);
	_unaligned_load64(p3, (uint32_t *)(dest + 3 * stride));
	i2 = (vector signed short)vec_mergeh(zero, p2);
	p1 = vec_packsu(i5, i5);
	_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 0 * stride));
	i6 = vec_add(i2, dc_value);
	i3 = (vector signed short)vec_mergeh(zero, p3);
	_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 1 * stride));
	p2 = vec_packsu(i6, i6);
	i7 = vec_add(i3, dc_value);
	_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 2 * stride));
	p3 = vec_packsu(i7, i7);
	_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 3 * stride));
	
	_unaligned_load64(p0, (uint32_t *)(dest + 4 * stride));
	// SSE unpacklo(x,y) becomes vec_mergeh(y,x)
	i0 = (vector signed short)vec_mergeh(zero, p0);
	_unaligned_load64(p1, (uint32_t *)(dest + 5 * stride));
	i4 = vec_add(i0, dc_value);
	i1 = (vector signed short)vec_mergeh(zero, p1);
	_unaligned_load64(p2, (uint32_t *)(dest + 6 * stride));
	p0 = vec_packsu(i4, i4);
	i5 = vec_add(i1, dc_value);
	_unaligned_load64(p3, (uint32_t *)(dest + 7 * stride));
	i2 = (vector signed short)vec_mergeh(zero, p2);
	p1 = vec_packsu(i5, i5);
	_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 4 * stride));
	i6 = vec_add(i2, dc_value);
	i3 = (vector signed short)vec_mergeh(zero, p3);
	_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 5 * stride));
	p2 = vec_packsu(i6, i6);
	i7 = vec_add(i3, dc_value);
	_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 6 * stride));
	p3 = vec_packsu(i7, i7);
	_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 7 * stride));
}

void vp9_idct16x16_1_add_vmx(const int16_t *input, uint8_t *dest, int stride) {
	vector signed short dc_value, i0, i1, i2, i3, i4, i5, i6, i7;
	vector unsigned char p0, p1, p2, p3, p4, p5, p6, p7;
	vector unsigned char zero = vec_splat_s8(0);
	vector unsigned int ltemp;
	int a, i;
	signed short a_s;
	
	a = dct_const_round_shift(input[0] * cospi_16_64);
	a = dct_const_round_shift(a * cospi_16_64);
	a_s = ROUND_POWER_OF_TWO(a, 6);
	dc_value = ss_splat(&a_s);
	
	// Massively unrolled. This is probably the limit for that.
	
	for(i=0; i<2; ++i) {
		_unaligned_load64(p0, (uint32_t *)(dest + 0 * stride));
		i0 = (vector signed short)vec_mergeh(zero, p0);
		_unaligned_load64(p1, (uint32_t *)(dest + 1 * stride));
		i4 = vec_add(i0, dc_value);
		i1 = (vector signed short)vec_mergeh(zero, p1);
		_unaligned_load64(p2, (uint32_t *)(dest + 2 * stride));
		p0 = vec_packsu(i4, i4);
		i5 = vec_add(i1, dc_value);
		_unaligned_load64(p3, (uint32_t *)(dest + 3 * stride));
		i2 = (vector signed short)vec_mergeh(zero, p2);
		p1 = vec_packsu(i5, i5);
		_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 0 * stride));
		i6 = vec_add(i2, dc_value);
		i3 = (vector signed short)vec_mergeh(zero, p3);
		_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 1 * stride));
		p2 = vec_packsu(i6, i6);
		i7 = vec_add(i3, dc_value);
		_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 2 * stride));
		p3 = vec_packsu(i7, i7);
		_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 3 * stride));
	
		_unaligned_load64(p0, (uint32_t *)(dest + 4 * stride));
		// SSE unpacklo(x,y) becomes vec_mergeh(y,x)
		i0 = (vector signed short)vec_mergeh(zero, p0);
		_unaligned_load64(p1, (uint32_t *)(dest + 5 * stride));
		i4 = vec_add(i0, dc_value);
		i1 = (vector signed short)vec_mergeh(zero, p1);
		_unaligned_load64(p2, (uint32_t *)(dest + 6 * stride));
		p0 = vec_packsu(i4, i4);
		i5 = vec_add(i1, dc_value);
		_unaligned_load64(p3, (uint32_t *)(dest + 7 * stride));
		i2 = (vector signed short)vec_mergeh(zero, p2);
		p1 = vec_packsu(i5, i5);
		_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 4 * stride));
		i6 = vec_add(i2, dc_value);
		i3 = (vector signed short)vec_mergeh(zero, p3);
		_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 5 * stride));
		p2 = vec_packsu(i6, i6);
		i7 = vec_add(i3, dc_value);
		_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 6 * stride));
		p3 = vec_packsu(i7, i7);
		_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 7 * stride));
	
		_unaligned_load64(p0, (uint32_t *)(dest + 8 * stride));
		i0 = (vector signed short)vec_mergeh(zero, p0);
		_unaligned_load64(p1, (uint32_t *)(dest + 9 * stride));
		i4 = vec_add(i0, dc_value);
		i1 = (vector signed short)vec_mergeh(zero, p1);
		_unaligned_load64(p2, (uint32_t *)(dest + 10 * stride));
		p0 = vec_packsu(i4, i4);
		i5 = vec_add(i1, dc_value);
		_unaligned_load64(p3, (uint32_t *)(dest + 11 * stride));
		i2 = (vector signed short)vec_mergeh(zero, p2);
		p1 = vec_packsu(i5, i5);
		_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 8 * stride));
		i6 = vec_add(i2, dc_value);
		i3 = (vector signed short)vec_mergeh(zero, p3);
		_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 9 * stride));
		p2 = vec_packsu(i6, i6);
		i7 = vec_add(i3, dc_value);
		_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 10 * stride));
		p3 = vec_packsu(i7, i7);
		_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 11 * stride));
		
		_unaligned_load64(p0, (uint32_t *)(dest + 12 * stride));
		i0 = (vector signed short)vec_mergeh(zero, p0);
		_unaligned_load64(p1, (uint32_t *)(dest + 13 * stride));
		i4 = vec_add(i0, dc_value);
		i1 = (vector signed short)vec_mergeh(zero, p1);
		_unaligned_load64(p2, (uint32_t *)(dest + 14 * stride));
		p0 = vec_packsu(i4, i4);
		i5 = vec_add(i1, dc_value);
		_unaligned_load64(p3, (uint32_t *)(dest + 15 * stride));
		i2 = (vector signed short)vec_mergeh(zero, p2);
		p1 = vec_packsu(i5, i5);
		_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 12 * stride));
		i6 = vec_add(i2, dc_value);
		i3 = (vector signed short)vec_mergeh(zero, p3);
		_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 13 * stride));
		p2 = vec_packsu(i6, i6);
		i7 = vec_add(i3, dc_value);
		_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 14 * stride));
		p3 = vec_packsu(i7, i7);
		_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 15 * stride));
		
		dest += 8;
	}
}

void vp9_idct32x32_1_add_vmx(const int16_t *input, uint8_t *dest, int stride) {
	vector signed short dc_value, i0, i1;
	vector unsigned char p0;
	vector unsigned char zero = vec_splat_s8(0);
	vector unsigned int ltemp;
	int a, i, j;
	signed short a_s;
	
	a = dct_const_round_shift(input[0] * cospi_16_64);
	a = dct_const_round_shift(a * cospi_16_64);
	a_s = ROUND_POWER_OF_TWO(a, 6);
	dc_value = ss_splat(&a_s);
	
	// Definitely not going to unroll this one, but we will still
	// alternate vectors.
	
	for (i=0; i<4; ++i) {
		for(j=0; j<32; ++j) {
			_unaligned_load64(p0, (uint32_t *)(dest + j * stride));
			i0 = (vector signed short)vec_mergeh(zero, p0);
			i1 = vec_add(i0, dc_value);
			p0 = vec_packsu(i1, i1);
			_unaligned_store64(p0, ltemp, (uint32_t *)(dest + j * stride));
		}
		dest += 8;
	}
}

static void idct4_vmx(vector signed short *in) {
	// gcc doesn't like these as globals, grumpf.
	vector signed short k__cospi_p16_p16 = short_pair_a(cospi_16_64, cospi_16_64);
	vector signed short k__cospi_p16_m16 = short_pair_a(cospi_16_64, -cospi_16_64);
	vector signed short k__cospi_p24_m08 = short_pair_a(cospi_24_64, -cospi_8_64);
	vector signed short k__cospi_p08_p24 = short_pair_a(cospi_8_64, cospi_24_64);
	vector signed short u[4];
	vector signed int w[4];
	// For easier hand modeling I manually inlined the SSE2 transposition function.
	vector signed short tr0_0, tr0_1;
	
	// Transposition.
	tr0_0 = vec_mergeh(in[0], in[1]);
	tr0_1 = vec_mergel(in[0], in[1]);
	// Stage 1.
	in[0] = vec_mergeh(tr0_0, tr0_1);
	in[1] = vec_mergel(tr0_0, tr0_1);

	u[0] = vec_mergeh(in[0], in[1]);
	u[1] = vec_mergel(in[0], in[1]);
	// AltiVec shows its superiority over SSE2 yet again.
	// Mostly the same as idct4x4_16 above.
	w[0] = vec_msum(u[0], k__cospi_p16_p16, dct_rounding_vec);
	w[1] = vec_msum(u[0], k__cospi_p16_m16, dct_rounding_vec);
	w[2] = vec_msum(u[1], k__cospi_p24_m08, dct_rounding_vec);
	w[3] = vec_msum(u[1], k__cospi_p08_p24, dct_rounding_vec);

	w[0] = vec_sra(w[0], dct_bitshift_vec);
	w[1] = vec_sra(w[1], dct_bitshift_vec);
	w[2] = vec_sra(w[2], dct_bitshift_vec);
	w[3] = vec_sra(w[3], dct_bitshift_vec);

	u[0] = vec_packs(w[0], w[1]);
	u[1] = vec_packs(w[3], w[2]);

	// Stage 2.
	in[0] = vec_add(u[0], u[1]);
	in[1] = vec_sub(u[0], u[1]);
	in[1] = vec_sld(in[1], in[1], 8);
}

static void iadst4_vmx(vector signed short *in) {
	vector signed short k__sinpi_p01_p04 = short_pair_a(sinpi_1_9, sinpi_4_9);
	vector signed short k__sinpi_p03_p02 = short_pair_a(sinpi_3_9, sinpi_2_9);
	vector signed short k__sinpi_p02_m01 = short_pair_a(sinpi_2_9, -sinpi_1_9);
	vector signed short k__sinpi_p03_m04 = short_pair_a(sinpi_3_9, -sinpi_4_9);
	vector signed short k__sinpi_p03_p03 = short_pair_a(sinpi_3_9, sinpi_3_9);
	vector signed short zero = vec_splat_s16(0);
	vector unsigned int twoi = vec_splat_s32(2);
	vector signed short u[7], in7;
	vector signed int v[7], w[7];
	// For easier hand modeling I manually inlined the SSE2 transposition function.
	vector signed short tr0_0, tr0_1;

	// Transposition.
	tr0_0 = vec_mergeh(in[0], in[1]);
	tr0_1 = vec_mergel(in[0], in[1]);

	// Transform.
	in[0] = vec_mergeh(tr0_0, tr0_1);
	in[1] = vec_mergel(tr0_0, tr0_1);

	in7 = vec_sld(in[1], zero, 8);
	in7 = vec_add(in7, in[0]);
	in7 = vec_sub(in7, in[1]);

	u[0] = vec_mergeh(in[0], in[1]);
	u[1] = vec_mergel(in[0], in[1]);
	u[2] = vec_mergeh(in7, zero);
	u[3] = vec_mergel(in[0], zero);

	// I've tagged where these came from in the SSE2 version
	// before collapsing them into the multiply-add-add form.
	v[1] = vec_msum(u[1], k__sinpi_p03_p02, (vector signed int)zero);
	w[0] = vec_msum(u[0], k__sinpi_p01_p04, v[1]); // was v[0]
	v[2] = vec_msum(u[2], k__sinpi_p03_p03, dct_rounding_vec);
	v[4] = vec_msum(u[1], k__sinpi_p03_m04, (vector signed int)zero);
	w[1] = vec_msum(u[0], k__sinpi_p02_m01, v[4]); // was v[3]
	v[5] = vec_msum(u[3], k__sinpi_p03_p03, (vector signed int)zero);

	//w[0] = vec_add(v[0], v[1]);
	//w[1] = vec_add(v[3], v[4]);
	//w[2] = v[2];
	w[3] = vec_add(w[0], w[1]);
	w[4] = vec_sl(v[5], twoi);
	w[5] = vec_add(w[3], v[5]);
	w[6] = vec_sub(w[5], w[4]);

	v[0] = vec_add(w[0], dct_rounding_vec);
	v[1] = vec_add(w[1], dct_rounding_vec);
	//v[2] = vec_add(w[2], dct_rounding_vec);
	v[3] = vec_add(w[6], dct_rounding_vec);

	w[0] = vec_sra(v[0], dct_bitshift_vec);
	w[1] = vec_sra(v[1], dct_bitshift_vec);
	w[2] = vec_sra(v[2], dct_bitshift_vec);
	w[3] = vec_sra(v[3], dct_bitshift_vec);

	in[0] = vec_packs(w[0], w[1]);
	in[1] = vec_packs(w[2], w[3]);
}

void vp9_iht4x4_16_add_vmx(const int16_t *input, uint8_t *dest, int stride, int tx_type) {
	vector signed short in[2];
	vector unsigned int ltemp;
	vector unsigned char result;
	vector signed int wnput0, wnput1, wnput2, wnput3;
	vector unsigned char zero = vec_splat_s8(0);
	vector unsigned char one = vec_splat_s8(1);
	vector unsigned short four = vec_splat_s16(4);
	vector signed short eight = vec_splat_s16(8);

	_unaligned_load128(in[0], (uint32_t *)(input));
	_unaligned_load128(in[1], (uint32_t *)(input + 8));

	switch (tx_type) {
		case 0: { // DCT_DCT
			idct4_vmx(in);
			idct4_vmx(in);
			break;
		}
		case 1: { // ADST_DCT
			idct4_vmx(in);
			iadst4_vmx(in);
			break;
		}
		case 2: { // DCT_ADST
			iadst4_vmx(in);
			idct4_vmx(in);
			break;
		}
		case 3: { // ADST_ADST
			iadst4_vmx(in);
			iadst4_vmx(in);
			break;
		}
		default:
			assert(0);
			break;
	}

	// Final round-shift step.
	in[0] = vec_add(in[0], eight);
	in[1] = vec_add(in[1], eight);
	in[0] = vec_sra(in[0], four);
	in[1] = vec_sra(in[1], four);
	
	// Reconstruct, pack and store (mostly the same as idct4x4_16).
	// Get the destination values we're going to merge with.
	_unaligned_load32(wnput0, (uint32_t *)dest);
	_unaligned_load32(wnput1, (uint32_t *)(dest + stride));
	wnput0 = vec_mergeh(wnput0, wnput1);
	_unaligned_load32(wnput2, (uint32_t *)(dest + stride + stride));
	wnput0 = (vector signed int)vec_mergeh(zero, (vector unsigned char)wnput0);
	_unaligned_load32(wnput3, (uint32_t *)(dest + stride + stride + stride));
	wnput2 = vec_mergeh(wnput2, wnput3);
	wnput2 = (vector signed int)vec_mergeh(zero, (vector unsigned char)wnput2);

	// Reconstruct and pack.
	in[0] = vec_add((vector signed short)wnput0, in[0]);
	in[1] = vec_add((vector signed short)wnput2, in[1]);
	result = vec_packsu(in[0], in[1]);

	// Store, 32 bits at a time, shifting the vector down, feeling gross and wrong.
	_unaligned_store32(result, ltemp, (uint32_t *)dest);
	result = vec_sld(result, zero, 4);
	_unaligned_store32(result, ltemp, (uint32_t *)(dest + stride));
	result = vec_sld(result, zero, 4);
	_unaligned_store32(result, ltemp, (uint32_t *)(dest + stride + stride));
	result = vec_sld(result, zero, 4);
	_unaligned_store32(result, ltemp, (uint32_t *)(dest + stride + stride + stride));
}

// The permute calls are interleaved with the merges to try to make best use of the permute unit on 7450.
#define TRANSPOSE_8X8(in0, in1, in2, in3, in4, in5, in6, in7, \
                      out0, out1, out2, out3, out4, out5, out6, out7) \
  {                                                     \
	vector signed short tr0_0 = vec_mergeh(in0, in1); \
	vector signed short tr0_1 = vec_mergeh(in2, in3); \
	vector signed short tr0_2 = vec_mergel(in0, in1); \
	vector signed short tr0_3 = vec_mergel(in2, in3); \
	vector signed short tr0_4 = vec_mergeh(in4, in5); \
	vector signed short tr0_5 = vec_mergeh(in6, in7); \
	vector signed short tr0_6 = vec_mergel(in4, in5); \
	vector signed short tr0_7 = vec_mergel(in6, in7); \
\
	vector signed int tr1_0 = vec_mergeh((vector signed int)tr0_0, (vector signed int)tr0_1); \
	vector signed int tr1_4 = vec_mergeh((vector signed int)tr0_4, (vector signed int)tr0_5); \
	out0 = (vector signed short)vec_perm(tr1_0, tr1_4, merge64_hvec);\
	vector signed int tr1_2 = vec_mergel((vector signed int)tr0_0, (vector signed int)tr0_1); \
	out1 = (vector signed short)vec_perm(tr1_0, tr1_4, merge64_lvec);\
	vector signed int tr1_6 = vec_mergel((vector signed int)tr0_4, (vector signed int)tr0_5); \
	out2 = (vector signed short)vec_perm(tr1_2, tr1_6, merge64_hvec);\
	vector signed int tr1_1 = vec_mergeh((vector signed int)tr0_2, (vector signed int)tr0_3); \
	out3 = (vector signed short)vec_perm(tr1_2, tr1_6, merge64_lvec);\
	vector signed int tr1_5 = vec_mergeh((vector signed int)tr0_6, (vector signed int)tr0_7); \
	out4 = (vector signed short)vec_perm(tr1_1, tr1_5, merge64_hvec);\
	vector signed int tr1_3 = vec_mergel((vector signed int)tr0_2, (vector signed int)tr0_3); \
	out5 = (vector signed short)vec_perm(tr1_1, tr1_5, merge64_lvec);\
	vector signed int tr1_7 = vec_mergel((vector signed int)tr0_6, (vector signed int)tr0_7); \
	out6 = (vector signed short)vec_perm(tr1_3, tr1_7, merge64_hvec);\
	out7 = (vector signed short)vec_perm(tr1_3, tr1_7, merge64_lvec);\
  }

#define MULTIPLICATION_AND_ADD(lo_0, hi_0, lo_1, hi_1, \
                               cst0, cst1, cst2, cst3, res0, res1, res2, res3) \
  {   \
      tmp0 = vec_msum(lo_0, cst0, dct_rounding_vec); \
      tmp1 = vec_msum(hi_0, cst0, dct_rounding_vec); \
      tmp2 = vec_msum(lo_0, cst1, dct_rounding_vec); \
      tmp3 = vec_msum(hi_0, cst1, dct_rounding_vec); \
      tmp4 = vec_msum(lo_1, cst2, dct_rounding_vec); \
      tmp5 = vec_msum(hi_1, cst2, dct_rounding_vec); \
      tmp6 = vec_msum(lo_1, cst3, dct_rounding_vec); \
      tmp7 = vec_msum(hi_1, cst3, dct_rounding_vec); \
      \
      tmp0 = vec_sra(tmp0, dct_bitshift_vec); \
      tmp1 = vec_sra(tmp1, dct_bitshift_vec); \
      tmp2 = vec_sra(tmp2, dct_bitshift_vec); \
      tmp3 = vec_sra(tmp3, dct_bitshift_vec); \
      tmp4 = vec_sra(tmp4, dct_bitshift_vec); \
      tmp5 = vec_sra(tmp5, dct_bitshift_vec); \
      tmp6 = vec_sra(tmp6, dct_bitshift_vec); \
      tmp7 = vec_sra(tmp7, dct_bitshift_vec); \
      \
      res0 = vec_packs(tmp0, tmp1); \
      res1 = vec_packs(tmp2, tmp3); \
      res2 = vec_packs(tmp4, tmp5); \
      res3 = vec_packs(tmp6, tmp7); \
  }

#define IDCT8(in0, in1, in2, in3, in4, in5, in6, in7, \
                 out0, out1, out2, out3, out4, out5, out6, out7)  \
  { \
  /* Stage 1. Vector names are relative to little endian, ptui */      \
  { \
	vector signed short lo_17 = vec_mergeh(in1, in7); \
	vector signed short hi_17 = vec_mergel(in1, in7); \
	vector signed short lo_35 = vec_mergeh(in3, in5); \
	vector signed short hi_35 = vec_mergel(in3, in5); \
    \
    MULTIPLICATION_AND_ADD(lo_17, hi_17, lo_35, hi_35, stg1_0, \
                          stg1_1, stg1_2, stg1_3, stp1_4,      \
                          stp1_7, stp1_5, stp1_6)              \
  } \
    \
  /* Stage 2. */ \
  { \
	vector signed short lo_04 = vec_mergeh(in0, in4); \
	vector signed short hi_04 = vec_mergel(in0, in4); \
	vector signed short lo_26 = vec_mergeh(in2, in6); \
	vector signed short hi_26 = vec_mergel(in2, in6); \
    \
    MULTIPLICATION_AND_ADD(lo_04, hi_04, lo_26, hi_26, stg2_0, \
                           stg2_1, stg2_2, stg2_3, stp2_0,     \
                           stp2_1, stp2_2, stp2_3)             \
    \
	stp2_4 = vec_adds(stp1_4, stp1_5); \
	stp2_5 = vec_subs(stp1_4, stp1_5); \
	stp2_6 = vec_subs(stp1_7, stp1_6); \
	stp2_7 = vec_adds(stp1_7, stp1_6); \
  } \
    \
  /* Stage 3. */ \
  { \
	vector signed short lo_56 = vec_mergeh(stp2_6, stp2_5); \
	vector signed short hi_56 = vec_mergel(stp2_6, stp2_5); \
    \
	stp1_0 = vec_adds(stp2_0, stp2_3); \
	stp1_1 = vec_adds(stp2_1, stp2_2); \
	stp1_2 = vec_subs(stp2_1, stp2_2); \
	stp1_3 = vec_subs(stp2_0, stp2_3); \
    \
	tmp0 = vec_msum(lo_56, stg2_1, dct_rounding_vec); \
	tmp1 = vec_msum(hi_56, stg2_1, dct_rounding_vec); \
	tmp2 = vec_msum(lo_56, stg2_0, dct_rounding_vec); \
	tmp3 = vec_msum(hi_56, stg2_0, dct_rounding_vec); \
    \
	tmp0 = vec_sra(tmp0, dct_bitshift_vec); \
	tmp1 = vec_sra(tmp1, dct_bitshift_vec); \
	tmp2 = vec_sra(tmp2, dct_bitshift_vec); \
	tmp3 = vec_sra(tmp3, dct_bitshift_vec); \
    \
	stp1_5 = vec_packs(tmp0, tmp1); \
	stp1_6 = vec_packs(tmp2, tmp3); \
  } \
  \
  /* Stage 4.  */ \
	out0 = vec_adds(stp1_0, stp2_7); \
	out1 = vec_adds(stp1_1, stp1_6); \
	out2 = vec_adds(stp1_2, stp1_5); \
	out3 = vec_adds(stp1_3, stp2_4); \
	out4 = vec_subs(stp1_3, stp2_4); \
	out5 = vec_subs(stp1_2, stp1_5); \
	out6 = vec_subs(stp1_1, stp1_6); \
	out7 = vec_subs(stp1_0, stp2_7); \
  }

void vp9_idct8x8_64_add_vmx(const int16_t *input, uint8_t *dest, int stride) {
	vector signed short stg1_0 = short_pair_a(cospi_28_64, -cospi_4_64);
	vector signed short stg1_1 = short_pair_a(cospi_4_64, cospi_28_64);
	vector signed short stg1_2 = short_pair_a(-cospi_20_64, cospi_12_64);
	vector signed short stg1_3 = short_pair_a(cospi_12_64, cospi_20_64);
	vector signed short stg2_0 = short_pair_a(cospi_16_64, cospi_16_64);
	vector signed short stg2_1 = short_pair_a(cospi_16_64, -cospi_16_64);
	vector signed short stg2_2 = short_pair_a(cospi_24_64, -cospi_8_64);
	vector signed short stg2_3 = short_pair_a(cospi_8_64, cospi_24_64);
	
	vector signed short in0, in1, in2, in3, in4, in5, in6, in7;
	vector signed short stp1_0, stp1_1, stp1_2, stp1_3, stp1_4, stp1_5, stp1_6, stp1_7;
	vector signed int tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
	vector signed short stp2_0, stp2_1, stp2_2, stp2_3, stp2_4, stp2_5, stp2_6, stp2_7;
	vector unsigned char zero = vec_splat_s8(0);
	vector unsigned int ltemp;
	vector unsigned char p0, p1, p2, p3, p4, p5, p6, p7;
	vector signed short i0, i1, i2, i3, i4, i5, i6, i7;

	vector unsigned short one = vec_splat_u16(1);
	vector unsigned short four = vec_splat_u16(4);
	vector unsigned short five = vec_splat_u16(5);
	vector signed short final_rounding;
	final_rounding = vec_rl(one, four);
	
	// The Intel mnemonic implies these loads are aligned.
	in0 = vec_ld(0,   (uint32_t *)input);
	in1 = vec_ld(16,  (uint32_t *)input);
	in2 = vec_ld(32,  (uint32_t *)input);
	in3 = vec_ld(48,  (uint32_t *)input);
	in4 = vec_ld(64,  (uint32_t *)input);
	in5 = vec_ld(80,  (uint32_t *)input);
	in6 = vec_ld(96,  (uint32_t *)input);
	in7 = vec_ld(112, (uint32_t *)input);

	TRANSPOSE_8X8(in0, in1, in2, in3, in4, in5, in6, in7,
			in0, in1, in2, in3, in4, in5, in6, in7);

	// 4-stage 1D idct8x8
	IDCT8(in0, in1, in2, in3, in4, in5, in6, in7,
		in0, in1, in2, in3, in4, in5, in6, in7);

	TRANSPOSE_8X8(in0, in1, in2, in3, in4, in5, in6, in7,
			in0, in1, in2, in3, in4, in5, in6, in7);
	IDCT8(in0, in1, in2, in3, in4, in5, in6, in7,
		in0, in1, in2, in3, in4, in5, in6, in7);
		
	// Final rounding and shift.
	in0 = vec_adds(in0, final_rounding);
	in1 = vec_adds(in1, final_rounding);
	in2 = vec_adds(in2, final_rounding);
	in3 = vec_adds(in3, final_rounding);
	in4 = vec_adds(in4, final_rounding);
	in5 = vec_adds(in5, final_rounding);
	in6 = vec_adds(in6, final_rounding);
	in7 = vec_adds(in7, final_rounding);

	in0 = vec_sra(in0, five);
	in1 = vec_sra(in1, five);
	in2 = vec_sra(in2, five);
	in3 = vec_sra(in3, five);
	in4 = vec_sra(in4, five);
	in5 = vec_sra(in5, five);
	in6 = vec_sra(in6, five);
	in7 = vec_sra(in7, five);

	// Unfortunately, these stores are NOT.
	// Borrowed from idct8x8_1.
	_unaligned_load64(p0, (uint32_t *)(dest + 0 * stride));
	i0 = (vector signed short)vec_mergeh(zero, p0);
	_unaligned_load64(p1, (uint32_t *)(dest + 1 * stride));
	i4 = vec_add(i0, in0);
	i1 = (vector signed short)vec_mergeh(zero, p1);
	_unaligned_load64(p2, (uint32_t *)(dest + 2 * stride));
	p0 = vec_packsu(i4, i4);
	i5 = vec_add(i1, in1);
	_unaligned_load64(p3, (uint32_t *)(dest + 3 * stride));
	i2 = (vector signed short)vec_mergeh(zero, p2);
	p1 = vec_packsu(i5, i5);
	_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 0 * stride));
	i6 = vec_add(i2, in2);
	i3 = (vector signed short)vec_mergeh(zero, p3);
	_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 1 * stride));
	p2 = vec_packsu(i6, i6);
	i7 = vec_add(i3, in3);
	_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 2 * stride));
	p3 = vec_packsu(i7, i7);
	_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 3 * stride));
	
	_unaligned_load64(p0, (uint32_t *)(dest + 4 * stride));
	i0 = (vector signed short)vec_mergeh(zero, p0);
	_unaligned_load64(p1, (uint32_t *)(dest + 5 * stride));
	i4 = vec_add(i0, in4);
	i1 = (vector signed short)vec_mergeh(zero, p1);
	_unaligned_load64(p2, (uint32_t *)(dest + 6 * stride));
	p0 = vec_packsu(i4, i4);
	i5 = vec_add(i1, in5);
	_unaligned_load64(p3, (uint32_t *)(dest + 7 * stride));
	i2 = (vector signed short)vec_mergeh(zero, p2);
	p1 = vec_packsu(i5, i5);
	_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 4 * stride));
	i6 = vec_add(i2, in6);
	i3 = (vector signed short)vec_mergeh(zero, p3);
	_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 5 * stride));
	p2 = vec_packsu(i6, i6);
	i7 = vec_add(i3, in7);
	_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 6 * stride));
	p3 = vec_packsu(i7, i7);
	_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 7 * stride));
}

static void idct8_vmx(vector signed short *in) {
	vector signed short stg1_0 = short_pair_a(cospi_28_64, -cospi_4_64);
	vector signed short stg1_1 = short_pair_a(cospi_4_64, cospi_28_64);
	vector signed short stg1_2 = short_pair_a(-cospi_20_64, cospi_12_64);
	vector signed short stg1_3 = short_pair_a(cospi_12_64, cospi_20_64);
	vector signed short stg2_0 = short_pair_a(cospi_16_64, cospi_16_64);
	vector signed short stg2_1 = short_pair_a(cospi_16_64, -cospi_16_64);
	vector signed short stg2_2 = short_pair_a(cospi_24_64, -cospi_8_64);
	vector signed short stg2_3 = short_pair_a(cospi_8_64, cospi_24_64);

	vector signed short in0, in1, in2, in3, in4, in5, in6, in7;
	vector signed short stp1_0, stp1_1, stp1_2, stp1_3, stp1_4, stp1_5, stp1_6, stp1_7;
	vector signed short stp2_0, stp2_1, stp2_2, stp2_3, stp2_4, stp2_5, stp2_6, stp2_7;
	vector signed int tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;

	TRANSPOSE_8X8(in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7],
			in0, in1, in2, in3, in4, in5, in6, in7);
	IDCT8(in0, in1, in2, in3, in4, in5, in6, in7,
			in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7]);
}

static void iadst8_vmx(vector signed short *in) {
	vector signed short k__cospi_p02_p30 = short_pair_a(cospi_2_64, cospi_30_64);
	vector signed short k__cospi_p30_m02 = short_pair_a(cospi_30_64, -cospi_2_64);
	vector signed short k__cospi_p10_p22 = short_pair_a(cospi_10_64, cospi_22_64);
	vector signed short k__cospi_p22_m10 = short_pair_a(cospi_22_64, -cospi_10_64);
	vector signed short k__cospi_p18_p14 = short_pair_a(cospi_18_64, cospi_14_64);
	vector signed short k__cospi_p14_m18 = short_pair_a(cospi_14_64, -cospi_18_64);
	vector signed short k__cospi_p26_p06 = short_pair_a(cospi_26_64, cospi_6_64);
	vector signed short k__cospi_p06_m26 = short_pair_a(cospi_6_64, -cospi_26_64);
	vector signed short k__cospi_p08_p24 = short_pair_a(cospi_8_64, cospi_24_64);
	vector signed short k__cospi_p24_m08 = short_pair_a(cospi_24_64, -cospi_8_64);
	vector signed short k__cospi_m24_p08 = short_pair_a(-cospi_24_64, cospi_8_64);
	vector signed short k__cospi_p16_m16 = short_pair_a(cospi_16_64, -cospi_16_64);
	signed short a_s = (int16_t)cospi_16_64;
	vector signed short k__cospi_p16_p16;
	vector signed short k__const_0 = vec_splat_u16(0);
	vector signed int zero_i = vec_splat_u16(0);
	vector signed int u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15;
	vector signed int v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15;
	vector signed int w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15;
	vector signed short s0, s1, s2, s3, s4, s5, s6, s7;
	vector signed short in0, in1, in2, in3, in4, in5, in6, in7;
	
	k__cospi_p16_p16 = ss_splat(&a_s);
	TRANSPOSE_8X8(in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7],
		in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7]);

	// Align for butterfly input.
	// I don't understand why the Intel version does it this way,
	// but I'll do it the same way for consistency.
	in0 = in[7];
	in1 = in[0];
	in2 = in[5];
	in3 = in[2];
	in4 = in[3];
	in5 = in[4];
	in6 = in[1];
	in7 = in[6];

	// Stage 1
	s0 = vec_mergeh(in0, in1);
	s1 = vec_mergel(in0, in1);
	s2 = vec_mergeh(in2, in3);
	s3 = vec_mergel(in2, in3);
	s4 = vec_mergeh(in4, in5);
	s5 = vec_mergel(in4, in5);
	s6 = vec_mergeh(in6, in7);
	s7 = vec_mergel(in6, in7);

	// We can't take advantage of the third vec_msum
	// argument here since the vectors have to be computed
	// anyway for the differences and sums. But we can
	// hoist up the simpler arithmetic to keep both the
	// VSIU and VCIU busy.
	u0  = vec_msum(s0, k__cospi_p02_p30, zero_i);
	u8  = vec_msum(s4, k__cospi_p18_p14, zero_i);
	u1  = vec_msum(s1, k__cospi_p02_p30, zero_i);
	w0  = vec_add(u0, u8);
	w8  = vec_sub(u0, u8);
	u9  = vec_msum(s5, k__cospi_p18_p14, zero_i);
	u2  = vec_msum(s0, k__cospi_p30_m02, zero_i);
	w1  = vec_add(u1, u9);
	w9  = vec_sub(u1, u9);
	u10 = vec_msum(s4, k__cospi_p14_m18, zero_i);
	u3  = vec_msum(s1, k__cospi_p30_m02, zero_i);
	w2  = vec_add(u2, u10);
	w10 = vec_sub(u2, u10);
	u11 = vec_msum(s5, k__cospi_p14_m18, zero_i);
	u4  = vec_msum(s2, k__cospi_p10_p22, zero_i);
	w3  = vec_add(u3, u11);
	w11 = vec_sub(u3, u11);
	u12 = vec_msum(s6, k__cospi_p26_p06, zero_i);
	u5  = vec_msum(s3, k__cospi_p10_p22, zero_i);
	w4  = vec_add(u4, u12);
	w12 = vec_sub(u4, u12);
	u13 = vec_msum(s7, k__cospi_p26_p06, zero_i);
	u6  = vec_msum(s2, k__cospi_p22_m10, zero_i);
	w5  = vec_add(u5, u13);
	w13 = vec_sub(u5, u13);
	u14 = vec_msum(s6, k__cospi_p06_m26, zero_i);
	u7  = vec_msum(s3, k__cospi_p22_m10, zero_i);
	w6  = vec_add(u6, u14);
	w14 = vec_sub(u6, u14);
	u15 = vec_msum(s7, k__cospi_p06_m26, zero_i);
	w7  = vec_add(u7, u15);
	w15 = vec_sub(u7, u15);

	v0  = vec_add(w0,  dct_rounding_vec);
	v1  = vec_add(w1,  dct_rounding_vec);
	v2  = vec_add(w2,  dct_rounding_vec);
	v3  = vec_add(w3,  dct_rounding_vec);
	v4  = vec_add(w4,  dct_rounding_vec);
	v5  = vec_add(w5,  dct_rounding_vec);
	v6  = vec_add(w6,  dct_rounding_vec);
	v7  = vec_add(w7,  dct_rounding_vec);
	v8  = vec_add(w8,  dct_rounding_vec);
	v9  = vec_add(w9,  dct_rounding_vec);
	v10 = vec_add(w10, dct_rounding_vec);
	v11 = vec_add(w11, dct_rounding_vec);
	v12 = vec_add(w12, dct_rounding_vec);
	v13 = vec_add(w13, dct_rounding_vec);
	v14 = vec_add(w14, dct_rounding_vec);
	v15 = vec_add(w15, dct_rounding_vec);

	u0  = vec_sra(v0,  dct_bitshift_vec);
	u1  = vec_sra(v1,  dct_bitshift_vec);
	u2  = vec_sra(v2,  dct_bitshift_vec);
	u3  = vec_sra(v3,  dct_bitshift_vec);
	u4  = vec_sra(v4,  dct_bitshift_vec);
	u5  = vec_sra(v5,  dct_bitshift_vec);
	u6  = vec_sra(v6,  dct_bitshift_vec);
	u7  = vec_sra(v7,  dct_bitshift_vec);
	u8  = vec_sra(v8,  dct_bitshift_vec);
	u9  = vec_sra(v9,  dct_bitshift_vec);
	u10 = vec_sra(v10, dct_bitshift_vec);
	u11 = vec_sra(v11, dct_bitshift_vec);
	u12 = vec_sra(v12, dct_bitshift_vec);
	u13 = vec_sra(v13, dct_bitshift_vec);
	u14 = vec_sra(v14, dct_bitshift_vec);
	u15 = vec_sra(v15, dct_bitshift_vec);

	// Repack to 16 bits for stage 2.
	in[0] = vec_packs(u0,  u1);
	in[1] = vec_packs(u2,  u3);
	in[2] = vec_packs(u4,  u5);
	in[3] = vec_packs(u6,  u7);
	in[4] = vec_packs(u8,  u9);
	in[5] = vec_packs(u10, u11);
	in[6] = vec_packs(u12, u13);
	in[7] = vec_packs(u14, u15);

	// Stage 2.
	// Interleave the VPERM intrinsics with the VSIUs.
	s0 = vec_add(in[0], in[2]);
	s4 = vec_mergeh(in[4], in[5]);
	s1 = vec_add(in[1], in[3]);
	s5 = vec_mergel(in[4], in[5]);
	s2 = vec_sub(in[0], in[2]);
	s6 = vec_mergeh(in[6], in[7]);
	s3 = vec_sub(in[1], in[3]);
	s7 = vec_mergel(in[6], in[7]);
	// s0, s1, s2 and s3 are used in the result, so
	// we can't clobber them in the repack.

	// Same problem as above, so we interleave here too.
	v0 = vec_msum(s4, k__cospi_p08_p24, zero_i);
	v4 = vec_msum(s6, k__cospi_m24_p08, zero_i);
	v1 = vec_msum(s5, k__cospi_p08_p24, zero_i);
	w0 = vec_add(v0, v4);
	w4 = vec_sub(v0, v4);
	v5 = vec_msum(s7, k__cospi_m24_p08, zero_i);
	v2 = vec_msum(s4, k__cospi_p24_m08, zero_i);
	w1 = vec_add(v1, v5);
	w5 = vec_sub(v1, v5);
	v6 = vec_msum(s6, k__cospi_p08_p24, zero_i);
	v3 = vec_msum(s5, k__cospi_p24_m08, zero_i);
	w2 = vec_add(v2, v6);
	w6 = vec_sub(v2, v6);
	v7 = vec_msum(s7, k__cospi_p08_p24, zero_i);
	w3 = vec_add(v3, v7);
	w7 = vec_sub(v3, v7);

	v0 = vec_add(w0, dct_rounding_vec);
	v1 = vec_add(w1, dct_rounding_vec);
	v2 = vec_add(w2, dct_rounding_vec);
	v3 = vec_add(w3, dct_rounding_vec);
	v4 = vec_add(w4, dct_rounding_vec);
	v5 = vec_add(w5, dct_rounding_vec);
	v6 = vec_add(w6, dct_rounding_vec);
	v7 = vec_add(w7, dct_rounding_vec);

	u0 = vec_sra(v0, dct_bitshift_vec);
	u1 = vec_sra(v1, dct_bitshift_vec);
	u2 = vec_sra(v2, dct_bitshift_vec);
	u3 = vec_sra(v3, dct_bitshift_vec);
	u4 = vec_sra(v4, dct_bitshift_vec);
	u5 = vec_sra(v5, dct_bitshift_vec);
	u6 = vec_sra(v6, dct_bitshift_vec);
	u7 = vec_sra(v7, dct_bitshift_vec);

	// Repack for stage 3.
	s4 = vec_packs(u0, u1);
	s5 = vec_packs(u2, u3);
	s6 = vec_packs(u4, u5);
	s7 = vec_packs(u6, u7);
	// s4 and s5 are also used in the result, so we
	// can't clobber them either.
	
	// Stage 3.
	// Since we're running out of shorts, reuse inx.
	in0 = vec_mergeh(s2, s3);
	in1 = vec_mergel(s2, s3);
	in2 = vec_mergeh(s6, s7);
	in3 = vec_mergel(s6, s7);
	
	// At last we can use vec_msum as intended!
	v0 = vec_msum(in0, k__cospi_p16_p16, dct_rounding_vec);
	v1 = vec_msum(in1, k__cospi_p16_p16, dct_rounding_vec);
	v2 = vec_msum(in0, k__cospi_p16_m16, dct_rounding_vec);
	v3 = vec_msum(in1, k__cospi_p16_m16, dct_rounding_vec);
	v4 = vec_msum(in2, k__cospi_p16_p16, dct_rounding_vec);
	v5 = vec_msum(in3, k__cospi_p16_p16, dct_rounding_vec);
	v6 = vec_msum(in2, k__cospi_p16_m16, dct_rounding_vec);
	v7 = vec_msum(in3, k__cospi_p16_m16, dct_rounding_vec);

	u0 = vec_sra(v0, dct_bitshift_vec);
	u1 = vec_sra(v1, dct_bitshift_vec);
	u2 = vec_sra(v2, dct_bitshift_vec);
	u3 = vec_sra(v3, dct_bitshift_vec);
	u4 = vec_sra(v4, dct_bitshift_vec);
	u5 = vec_sra(v5, dct_bitshift_vec);
	u6 = vec_sra(v6, dct_bitshift_vec);
	u7 = vec_sra(v7, dct_bitshift_vec);

	// Back to shorts and emit final vectors.
	s2 = vec_packs(u0, u1);
	s3 = vec_packs(u2, u3);
	s6 = vec_packs(u4, u5);
	s7 = vec_packs(u6, u7);

	in[0] = s0;
	in[1] = vec_sub(k__const_0, s4);
	in[2] = s6;
	in[3] = vec_sub(k__const_0, s2);
	in[4] = s3;
	in[5] = vec_sub(k__const_0, s7);
	in[6] = s5;
	in[7] = vec_sub(k__const_0, s1);
}

void vp9_iht8x8_64_add_vmx(const int16_t *input, uint8_t *dest, int stride,
                            int tx_type) {
	vector signed short in[8];
	vector unsigned char zero = vec_splat_s8(0);
	vector unsigned int ltemp;
	vector unsigned char p0, p1, p2, p3, p4, p5, p6, p7;
	vector signed short i0, i1, i2, i3, i4, i5, i6, i7;

	vector unsigned short one = vec_splat_u16(1);
	vector unsigned short four = vec_splat_u16(4);
	vector unsigned short five = vec_splat_u16(5);
	vector signed short final_rounding;
	final_rounding = vec_rl(one, four);

	// The Intel mnemonic implies these loads are aligned.
	in[0] = vec_ld(0,   (uint32_t *)input);
	in[1] = vec_ld(16,  (uint32_t *)input);
	in[2] = vec_ld(32,  (uint32_t *)input);
	in[3] = vec_ld(48,  (uint32_t *)input);
	in[4] = vec_ld(64,  (uint32_t *)input);
	in[5] = vec_ld(80,  (uint32_t *)input);
	in[6] = vec_ld(96,  (uint32_t *)input);
	in[7] = vec_ld(112, (uint32_t *)input);

	switch (tx_type) {
		case 0:  // DCT_DCT
			idct8_vmx(in);
			idct8_vmx(in);
		break;
		case 1:  // ADST_DCT
			idct8_vmx(in);
			iadst8_vmx(in);
		break;
		case 2:  // DCT_ADST
			iadst8_vmx(in);
			idct8_vmx(in);
		break;
		case 3:  // ADST_ADST
			iadst8_vmx(in);
			iadst8_vmx(in);
		break;
		default:
			assert(0);
		break;
	}

	// Final rounding and shift, and unaligned recon.
	// Mostly the same as the straight IDCT.
	in[0] = vec_adds(in[0], final_rounding);
	in[1] = vec_adds(in[1], final_rounding);
	in[2] = vec_adds(in[2], final_rounding);
	in[3] = vec_adds(in[3], final_rounding);
	in[4] = vec_adds(in[4], final_rounding);
	in[5] = vec_adds(in[5], final_rounding);
	in[6] = vec_adds(in[6], final_rounding);
	in[7] = vec_adds(in[7], final_rounding);

	in[0] = vec_sra(in[0], five);
	in[1] = vec_sra(in[1], five);
	in[2] = vec_sra(in[2], five);
	in[3] = vec_sra(in[3], five);
	in[4] = vec_sra(in[4], five);
	in[5] = vec_sra(in[5], five);
	in[6] = vec_sra(in[6], five);
	in[7] = vec_sra(in[7], five);

	_unaligned_load64(p0, (uint32_t *)(dest + 0 * stride));
	i0 = (vector signed short)vec_mergeh(zero, p0);
	_unaligned_load64(p1, (uint32_t *)(dest + 1 * stride));
	i4 = vec_add(i0, in[0]);
	i1 = (vector signed short)vec_mergeh(zero, p1);
	_unaligned_load64(p2, (uint32_t *)(dest + 2 * stride));
	p0 = vec_packsu(i4, i4);
	i5 = vec_add(i1, in[1]);
	_unaligned_load64(p3, (uint32_t *)(dest + 3 * stride));
	i2 = (vector signed short)vec_mergeh(zero, p2);
	p1 = vec_packsu(i5, i5);
	_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 0 * stride));
	i6 = vec_add(i2, in[2]);
	i3 = (vector signed short)vec_mergeh(zero, p3);
	_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 1 * stride));
	p2 = vec_packsu(i6, i6);
	i7 = vec_add(i3, in[3]);
	_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 2 * stride));
	p3 = vec_packsu(i7, i7);
	_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 3 * stride));
	
	_unaligned_load64(p0, (uint32_t *)(dest + 4 * stride));
	i0 = (vector signed short)vec_mergeh(zero, p0);
	_unaligned_load64(p1, (uint32_t *)(dest + 5 * stride));
	i4 = vec_add(i0, in[4]);
	i1 = (vector signed short)vec_mergeh(zero, p1);
	_unaligned_load64(p2, (uint32_t *)(dest + 6 * stride));
	p0 = vec_packsu(i4, i4);
	i5 = vec_add(i1, in[5]);
	_unaligned_load64(p3, (uint32_t *)(dest + 7 * stride));
	i2 = (vector signed short)vec_mergeh(zero, p2);
	p1 = vec_packsu(i5, i5);
	_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 4 * stride));
	i6 = vec_add(i2, in[6]);
	i3 = (vector signed short)vec_mergeh(zero, p3);
	_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 5 * stride));
	p2 = vec_packsu(i6, i6);
	i7 = vec_add(i3, in[7]);
	_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 6 * stride));
	p3 = vec_packsu(i7, i7);
	_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 7 * stride));
}

// There isn't a whole lot we can do here to make the permute unit usage optimal.
#define TRANSPOSE_4X8_10(tmp0, tmp1, tmp2, tmp3, \
                         out0, out1, out2, out3) \
  {                                              \
	vector signed short tr0_0 = vec_mergel(tmp0, tmp1); \
 	vector signed short tr0_1 = vec_mergeh(tmp1, tmp0); \
	vector signed short tr0_4 = vec_mergeh(tmp2, tmp3); \
	vector signed short tr0_5 = vec_mergel(tmp3, tmp2); \
    \
	vector signed int tr1_0 = vec_mergeh((vector signed int)tr0_0, (vector signed int)tr0_1); \
	vector signed int tr1_4 = vec_mergeh((vector signed int)tr0_4, (vector signed int)tr0_5); \
	vector signed int tr1_2 = vec_mergel((vector signed int)tr0_0, (vector signed int)tr0_1); \
	out0 = (vector signed short)vec_perm(tr1_0, tr1_4, merge64_hvec);\
	vector signed int tr1_6 = vec_mergel((vector signed int)tr0_4, (vector signed int)tr0_5); \
	out1 = (vector signed short)vec_perm(tr1_0, tr1_4, merge64_lvec);\
	out2 = (vector signed short)vec_perm(tr1_2, tr1_6, merge64_hvec);\
	out3 = (vector signed short)vec_perm(tr1_2, tr1_6, merge64_lvec);\
  }

#define TRANSPOSE_8X8_10(in0, in1, in2, in3, out0, out1) \
  {                                            \
	vector signed short tr0_0 = vec_mergeh(in0, in1); \
	vector signed short tr0_1 = vec_mergeh(in2, in3); \
	out0 = vec_mergeh((vector signed int)tr0_0, (vector signed int)tr0_1); \
	out1 = vec_mergel((vector signed int)tr0_0, (vector signed int)tr0_1); \
  }

void vp9_idct8x8_12_add_vmx(const int16_t *input, uint8_t *dest, int stride) {
	vector signed short zero_s = vec_splat_u16(0);
	vector unsigned char zero = vec_splat_u8(0);
	vector signed short stg1_0 = short_pair_a(cospi_28_64, -cospi_4_64);
	vector signed short stg1_1 = short_pair_a(cospi_4_64, cospi_28_64);
	vector signed short stg1_2 = short_pair_a(-cospi_20_64, cospi_12_64);
	vector signed short stg1_3 = short_pair_a(cospi_12_64, cospi_20_64);
	vector signed short stg2_0 = short_pair_a(cospi_16_64, cospi_16_64);
	vector signed short stg2_1 = short_pair_a(cospi_16_64, -cospi_16_64);
	vector signed short stg2_2 = short_pair_a(cospi_24_64, -cospi_8_64);
	vector signed short stg2_3 = short_pair_a(cospi_8_64, cospi_24_64);
	vector signed short stg3_0 = short_pair_a(-cospi_16_64, cospi_16_64);

	vector signed short in0, in1, in2, in3, in4, in5, in6, in7;
	vector signed short stp1_0, stp1_1, stp1_2, stp1_3, stp1_4, stp1_5, stp1_6, stp1_7;
	vector signed short stp2_0, stp2_1, stp2_2, stp2_3, stp2_4, stp2_5, stp2_6, stp2_7;
	vector signed int tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;

	vector unsigned int ltemp;
	vector unsigned char p0, p1, p2, p3, p4, p5, p6, p7;
	vector signed short i0, i1, i2, i3, i4, i5, i6, i7;

	vector unsigned short one = vec_splat_u16(1);
	vector unsigned short four = vec_splat_u16(4);
	vector unsigned short five = vec_splat_u16(5);
	vector signed short final_rounding;
	final_rounding = vec_rl(one, four);

	// Rows. Load 4-row input data.
	// Praise the Lord it's still aligned, yes?
	in0 = vec_ld(0,  (uint32_t *)input);
	in1 = vec_ld(16, (uint32_t *)input);
	in2 = vec_ld(32, (uint32_t *)input);
	in3 = vec_ld(48, (uint32_t *)input);

	// 8x4 transpose.
	TRANSPOSE_8X8_10(in0, in1, in2, in3, in0, in1);

	// Stage 1.
	// (Variable names are according to the inferior little-endian convention
	// in the following bloques.)
	{
		vector signed short lo_17 = vec_mergel(in0, zero_s);
		vector signed short lo_35 = vec_mergel(in1, zero_s);

		// Do I have to point out how much more awesome AltiVec is
		// than SSE? Well ... yes!
		tmp0 = vec_msum(lo_17, stg1_0, dct_rounding_vec);
		tmp2 = vec_msum(lo_17, stg1_1, dct_rounding_vec);
		tmp4 = vec_msum(lo_35, stg1_2, dct_rounding_vec);
		tmp6 = vec_msum(lo_35, stg1_3, dct_rounding_vec);

		tmp0 = vec_sra(tmp0, dct_bitshift_vec);
		tmp2 = vec_sra(tmp2, dct_bitshift_vec);
		tmp4 = vec_sra(tmp4, dct_bitshift_vec);
		tmp6 = vec_sra(tmp6, dct_bitshift_vec);

		stp1_4 = vec_packs(tmp0, tmp2);
		stp1_5 = vec_packs(tmp4, tmp6);
	}

	// Stage 2.
	{
		vector signed short lo_04 = vec_mergeh(in0, zero_s);
		vector signed short lo_26 = vec_mergeh(in1, zero_s);

		// More awesome. I'm basking in awesome.
		// Awesome dripping from every orifice.
		tmp0 = vec_msum(lo_04, stg2_0, dct_rounding_vec);
		tmp2 = vec_msum(lo_04, stg2_1, dct_rounding_vec);
		tmp4 = vec_msum(lo_26, stg2_2, dct_rounding_vec);
		tmp6 = vec_msum(lo_26, stg2_3, dct_rounding_vec);

		tmp0 = vec_sra(tmp0, dct_bitshift_vec);
		tmp2 = vec_sra(tmp2, dct_bitshift_vec);
		tmp4 = vec_sra(tmp4, dct_bitshift_vec);
		tmp6 = vec_sra(tmp6, dct_bitshift_vec);

		in7 = vec_subs(stp1_4, stp1_5);

		stp2_0 = vec_packs(tmp0, tmp2);
		stp2_2 = vec_packs(tmp6, tmp4);
		stp2_4 = vec_adds(stp1_4, stp1_5);
		stp2_5 = (vector signed short)vec_perm(in7, zero_s, merge64_hvec);
		stp2_6 = (vector signed short)vec_perm(in7, zero_s, merge64_lvec);
	}

	// Stage 3.
	{
		vector signed short lo_56 = vec_mergeh(stp2_5, stp2_6);

		in4 = vec_adds(stp2_0, stp2_2);
		in6 = vec_subs(stp2_0, stp2_2);

		stp1_2 = (vector signed short)vec_perm(in6, in4, merge64_lvec);
		stp1_3 = (vector signed short)vec_perm(in6, in4, merge64_hvec);

		// The awesome would burn, except it's awesome.
		// And PowerPC is awesome.
		tmp0 = vec_msum(lo_56, stg3_0, dct_rounding_vec);
		tmp2 = vec_msum(lo_56, stg2_0, dct_rounding_vec);  // stg3_1 = stg2_0

		tmp0 = vec_sra(tmp0, dct_bitshift_vec);
		tmp2 = vec_sra(tmp2, dct_bitshift_vec);

		stp1_5 = vec_packs(tmp0, tmp2);
	}
	
	// Stage 4.
	in0 = vec_adds(stp1_3, stp2_4);
	in1 = vec_adds(stp1_2, stp1_5);
	in2 = vec_subs(stp1_3, stp2_4);
	in3 = vec_subs(stp1_2, stp1_5);
	TRANSPOSE_4X8_10(in0, in1, in2, in3, in0, in1, in2, in3);
	IDCT8(in0, in1, in2, in3, zero_s, zero_s, zero_s, zero_s,
		in0, in1, in2, in3, in4, in5, in6, in7);

	// Round, shift, and reconstitute as above.
	in0 = vec_adds(in0, final_rounding);
	in1 = vec_adds(in1, final_rounding);
	in2 = vec_adds(in2, final_rounding);
	in3 = vec_adds(in3, final_rounding);
	in4 = vec_adds(in4, final_rounding);
	in5 = vec_adds(in5, final_rounding);
	in6 = vec_adds(in6, final_rounding);
	in7 = vec_adds(in7, final_rounding);

	in0 = vec_sra(in0, five);
	in1 = vec_sra(in1, five);
	in2 = vec_sra(in2, five);
	in3 = vec_sra(in3, five);
	in4 = vec_sra(in4, five);
	in5 = vec_sra(in5, five);
	in6 = vec_sra(in6, five);
	in7 = vec_sra(in7, five);

	_unaligned_load64(p0, (uint32_t *)(dest + 0 * stride));
	i0 = (vector signed short)vec_mergeh(zero, p0);
	_unaligned_load64(p1, (uint32_t *)(dest + 1 * stride));
	i4 = vec_add(i0, in0);
	i1 = (vector signed short)vec_mergeh(zero, p1);
	_unaligned_load64(p2, (uint32_t *)(dest + 2 * stride));
	p0 = vec_packsu(i4, i4);
	i5 = vec_add(i1, in1);
	_unaligned_load64(p3, (uint32_t *)(dest + 3 * stride));
	i2 = (vector signed short)vec_mergeh(zero, p2);
	p1 = vec_packsu(i5, i5);
	_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 0 * stride));
	i6 = vec_add(i2, in2);
	i3 = (vector signed short)vec_mergeh(zero, p3);
	_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 1 * stride));
	p2 = vec_packsu(i6, i6);
	i7 = vec_add(i3, in3);
	_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 2 * stride));
	p3 = vec_packsu(i7, i7);
	_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 3 * stride));
	
	_unaligned_load64(p0, (uint32_t *)(dest + 4 * stride));
	i0 = (vector signed short)vec_mergeh(zero, p0);
	_unaligned_load64(p1, (uint32_t *)(dest + 5 * stride));
	i4 = vec_add(i0, in4);
	i1 = (vector signed short)vec_mergeh(zero, p1);
	_unaligned_load64(p2, (uint32_t *)(dest + 6 * stride));
	p0 = vec_packsu(i4, i4);
	i5 = vec_add(i1, in5);
	_unaligned_load64(p3, (uint32_t *)(dest + 7 * stride));
	i2 = (vector signed short)vec_mergeh(zero, p2);
	p1 = vec_packsu(i5, i5);
	_unaligned_store64(p0, ltemp, (uint32_t *)(dest + 4 * stride));
	i6 = vec_add(i2, in6);
	i3 = (vector signed short)vec_mergeh(zero, p3);
	_unaligned_store64(p1, ltemp, (uint32_t *)(dest + 5 * stride));
	p2 = vec_packsu(i6, i6);
	i7 = vec_add(i3, in7);
	_unaligned_store64(p2, ltemp, (uint32_t *)(dest + 6 * stride));
	p3 = vec_packsu(i7, i7);
	_unaligned_store64(p3, ltemp, (uint32_t *)(dest + 7 * stride));
}

#define IDCT16 \
  /* Stage 2. */ \
  { \
	vector signed short lo_1_15 = vec_mergeh(in[1],  in[15]); \
	vector signed short hi_1_15 = vec_mergel(in[1],  in[15]); \
	vector signed short lo_9_7  = vec_mergeh(in[9],  in[7]);   \
	vector signed short hi_9_7  = vec_mergel(in[9],  in[7]);   \
	vector signed short lo_5_11 = vec_mergeh(in[5],  in[11]); \
	vector signed short hi_5_11 = vec_mergel(in[5],  in[11]); \
	vector signed short lo_13_3 = vec_mergeh(in[13], in[3]); \
	vector signed short hi_13_3 = vec_mergel(in[13], in[3]); \
    \
    MULTIPLICATION_AND_ADD(lo_1_15, hi_1_15, lo_9_7, hi_9_7, \
                           stg2_0, stg2_1, stg2_2, stg2_3, \
                           stp2_8, stp2_15, stp2_9, stp2_14) \
    \
    MULTIPLICATION_AND_ADD(lo_5_11, hi_5_11, lo_13_3, hi_13_3, \
                           stg2_4, stg2_5, stg2_6, stg2_7, \
                           stp2_10, stp2_13, stp2_11, stp2_12) \
  } \
    \
  /* Stage 3. */ \
  { \
	vector signed short lo_2_14 = vec_mergeh(in[2],  in[14]); \
	vector signed short hi_2_14 = vec_mergel(in[2],  in[14]); \
	vector signed short lo_10_6 = vec_mergeh(in[10], in[6]); \
	vector signed short hi_10_6 = vec_mergel(in[10], in[6]); \
    \
    MULTIPLICATION_AND_ADD(lo_2_14, hi_2_14, lo_10_6, hi_10_6, \
                           stg3_0, stg3_1, stg3_2, stg3_3, \
                           stp1_4, stp1_7, stp1_5, stp1_6) \
    \
	stp1_8_0 = vec_add(stp2_8, stp2_9);  \
	stp1_9 = vec_sub(stp2_8, stp2_9);    \
	stp1_10 = vec_sub(stp2_11, stp2_10); \
	stp1_11 = vec_add(stp2_11, stp2_10); \
    \
	stp1_12_0 = vec_add(stp2_12, stp2_13); \
	stp1_13 = vec_sub(stp2_12, stp2_13); \
	stp1_14 = vec_sub(stp2_15, stp2_14); \
	stp1_15 = vec_add(stp2_15, stp2_14); \
  } \
  \
  /* Stage 4. */ \
  { \
	vector signed short lo_0_8  = vec_mergeh(in[0], in[8]); \
	vector signed short hi_0_8  = vec_mergel(in[0], in[8]); \
	vector signed short lo_4_12 = vec_mergeh(in[4], in[12]); \
	vector signed short hi_4_12 = vec_mergel(in[4], in[12]); \
    \
	vector signed short lo_9_14  = vec_mergeh(stp1_9,  stp1_14); \
	vector signed short hi_9_14  = vec_mergel(stp1_9,  stp1_14); \
	vector signed short lo_10_13 = vec_mergeh(stp1_10, stp1_13); \
	vector signed short hi_10_13 = vec_mergel(stp1_10, stp1_13); \
    \
    MULTIPLICATION_AND_ADD(lo_0_8, hi_0_8, lo_4_12, hi_4_12, \
                           stg4_0, stg4_1, stg4_2, stg4_3, \
                           stp2_0, stp2_1, stp2_2, stp2_3) \
    \
	stp2_4 = vec_add(stp1_4, stp1_5); \
	stp2_5 = vec_sub(stp1_4, stp1_5); \
	stp2_6 = vec_sub(stp1_7, stp1_6); \
	stp2_7 = vec_add(stp1_7, stp1_6); \
    \
    MULTIPLICATION_AND_ADD(lo_9_14, hi_9_14, lo_10_13, hi_10_13, \
                           stg4_4, stg4_5, stg4_6, stg4_7, \
                           stp2_9, stp2_14, stp2_10, stp2_13) \
  } \
    \
  /* Stage 5. */ \
  { \
	vector signed short lo_6_5 = vec_mergeh(stp2_6, stp2_5); \
	vector signed short hi_6_5 = vec_mergel(stp2_6, stp2_5); \
    \
	stp1_0 = vec_add(stp2_0, stp2_3); \
	stp1_1 = vec_add(stp2_1, stp2_2); \
	stp1_2 = vec_sub(stp2_1, stp2_2); \
	stp1_3 = vec_sub(stp2_0, stp2_3); \
    \
	tmp0 = vec_msum(lo_6_5, stg4_1, dct_rounding_vec); \
	tmp1 = vec_msum(hi_6_5, stg4_1, dct_rounding_vec); \
	tmp2 = vec_msum(lo_6_5, stg4_0, dct_rounding_vec); \
	tmp3 = vec_msum(hi_6_5, stg4_0, dct_rounding_vec); \
    \
	tmp0 = vec_sra(tmp0, dct_bitshift_vec); \
	tmp1 = vec_sra(tmp1, dct_bitshift_vec); \
	tmp2 = vec_sra(tmp2, dct_bitshift_vec); \
	tmp3 = vec_sra(tmp3, dct_bitshift_vec); \
    \
	stp1_5 = vec_packs(tmp0, tmp1); \
	stp1_6 = vec_packs(tmp2, tmp3); \
    \
	stp1_8 = vec_add(stp1_8_0, stp1_11);  \
	stp1_9 = vec_add(stp2_9, stp2_10);    \
	stp1_10 = vec_sub(stp2_9, stp2_10);   \
	stp1_11 = vec_sub(stp1_8_0, stp1_11); \
    \
	stp1_12 = vec_sub(stp1_15, stp1_12_0); \
	stp1_13 = vec_sub(stp2_14, stp2_13);   \
	stp1_14 = vec_add(stp2_14, stp2_13);   \
	stp1_15 = vec_add(stp1_15, stp1_12_0); \
  } \
    \
  /* Stage 6. */ \
  { \
	vector signed short lo_10_13 = vec_mergeh(stp1_10, stp1_13); \
	vector signed short hi_10_13 = vec_mergel(stp1_10, stp1_13); \
	vector signed short lo_11_12 = vec_mergeh(stp1_11, stp1_12); \
	vector signed short hi_11_12 = vec_mergel(stp1_11, stp1_12); \
    \
	stp2_0 = vec_add(stp1_0, stp2_7); \
	stp2_1 = vec_add(stp1_1, stp1_6); \
	stp2_2 = vec_add(stp1_2, stp1_5); \
	stp2_3 = vec_add(stp1_3, stp2_4); \
	stp2_4 = vec_sub(stp1_3, stp2_4); \
	stp2_5 = vec_sub(stp1_2, stp1_5); \
	stp2_6 = vec_sub(stp1_1, stp1_6); \
	stp2_7 = vec_sub(stp1_0, stp2_7); \
    \
    MULTIPLICATION_AND_ADD(lo_10_13, hi_10_13, lo_11_12, hi_11_12, \
                           stg6_0, stg4_0, stg6_0, stg4_0, \
                           stp2_10, stp2_13, stp2_11, stp2_12) \
  }

// Same as TRANSPOSE_8X8 but for lazy programmers. The Intel guys are lazy.
// They also smell funny and have neckbeards and reverse their words around.
// Freaks.
//
// Try interleaving perms with merges to see if this helps on 7450 here too.
static inline void array_transpose_8x8(vector signed short *in, vector signed short *res) {
	vector signed short tr0_0 = vec_mergeh(in[0], in[1]);
	vector signed short tr0_1 = vec_mergeh(in[2], in[3]);
	vector signed short tr0_2 = vec_mergel(in[0], in[1]);
	vector signed short tr0_3 = vec_mergel(in[2], in[3]);
	vector signed short tr0_4 = vec_mergeh(in[4], in[5]);
	vector signed short tr0_5 = vec_mergeh(in[6], in[7]);
	vector signed short tr0_6 = vec_mergel(in[4], in[5]);
	vector signed short tr0_7 = vec_mergel(in[6], in[7]);

	// Annoyingly, the indices are different here, but it's the same
	// vectors being merged as before.
	vector signed int tr1_0 = vec_mergeh((vector signed int)tr0_0, (vector signed int)tr0_1);
	vector signed int tr1_1 = vec_mergeh((vector signed int)tr0_4, (vector signed int)tr0_5);
	res[0] = (vector signed short)vec_perm(tr1_0, tr1_1, merge64_hvec);
	vector signed int tr1_2 = vec_mergel((vector signed int)tr0_0, (vector signed int)tr0_1);
	res[1] = (vector signed short)vec_perm(tr1_0, tr1_1, merge64_lvec);
	vector signed int tr1_3 = vec_mergel((vector signed int)tr0_4, (vector signed int)tr0_5);
	res[2] = (vector signed short)vec_perm(tr1_2, tr1_3, merge64_hvec);
	vector signed int tr1_4 = vec_mergeh((vector signed int)tr0_2, (vector signed int)tr0_3);
	res[3] = (vector signed short)vec_perm(tr1_2, tr1_3, merge64_lvec);
	vector signed int tr1_5 = vec_mergeh((vector signed int)tr0_6, (vector signed int)tr0_7);
	res[4] = (vector signed short)vec_perm(tr1_4, tr1_5, merge64_hvec);
	vector signed int tr1_6 = vec_mergel((vector signed int)tr0_2, (vector signed int)tr0_3);
	res[5] = (vector signed short)vec_perm(tr1_4, tr1_5, merge64_lvec);
	vector signed int tr1_7 = vec_mergel((vector signed int)tr0_6, (vector signed int)tr0_7);
	res[6] = (vector signed short)vec_perm(tr1_6, tr1_7, merge64_hvec);
	res[7] = (vector signed short)vec_perm(tr1_6, tr1_7, merge64_lvec);
}

void vp9_idct16x16_256_add_vmx(const int16_t *input, uint8_t *dest,
                                int stride) {
	vector signed short stg2_0 = short_pair_a(cospi_30_64, -cospi_2_64);
	vector signed short stg2_1 = short_pair_a(cospi_2_64, cospi_30_64);
	vector signed short stg2_2 = short_pair_a(cospi_14_64, -cospi_18_64);
	vector signed short stg2_3 = short_pair_a(cospi_18_64, cospi_14_64);
	vector signed short stg2_4 = short_pair_a(cospi_22_64, -cospi_10_64);
	vector signed short stg2_5 = short_pair_a(cospi_10_64, cospi_22_64);
	vector signed short stg2_6 = short_pair_a(cospi_6_64, -cospi_26_64);
	vector signed short stg2_7 = short_pair_a(cospi_26_64, cospi_6_64);

	vector signed short stg3_0 = short_pair_a(cospi_28_64, -cospi_4_64);
	vector signed short stg3_1 = short_pair_a(cospi_4_64, cospi_28_64);
	vector signed short stg3_2 = short_pair_a(cospi_12_64, -cospi_20_64);
	vector signed short stg3_3 = short_pair_a(cospi_20_64, cospi_12_64);

	vector signed short stg4_0 = short_pair_a(cospi_16_64, cospi_16_64);
	vector signed short stg4_1 = short_pair_a(cospi_16_64, -cospi_16_64);
	vector signed short stg4_2 = short_pair_a(cospi_24_64, -cospi_8_64);
	vector signed short stg4_3 = short_pair_a(cospi_8_64, cospi_24_64);
	vector signed short stg4_4 = short_pair_a(-cospi_8_64, cospi_24_64);
	vector signed short stg4_5 = short_pair_a(cospi_24_64, cospi_8_64);
	vector signed short stg4_6 = short_pair_a(-cospi_24_64, -cospi_8_64);
	vector signed short stg4_7 = short_pair_a(-cospi_8_64, cospi_24_64);

	vector signed short stg6_0 = short_pair_a(-cospi_16_64, cospi_16_64);

	vector signed short in[16], l[16], r[16], *curr1, i0;
	vector signed short stp1_0, stp1_1, stp1_2, stp1_3, stp1_4, stp1_5, stp1_6, stp1_7,
		stp1_8, stp1_9, stp1_10, stp1_11, stp1_12, stp1_13, stp1_14, stp1_15,
		stp1_8_0, stp1_12_0;
	vector signed short stp2_0, stp2_1, stp2_2, stp2_3, stp2_4, stp2_5, stp2_6, stp2_7,
		stp2_8, stp2_9, stp2_10, stp2_11, stp2_12, stp2_13, stp2_14, stp2_15;
	vector signed int tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
	
	vector unsigned char p0;
	vector unsigned char zero = vec_splat_u8(0);
	vector unsigned short one = vec_splat_u16(1);
	vector unsigned short five = vec_splat_u8(5);
	vector unsigned short six = vec_splat_u8(6);
	vector signed short final_rounding;
	vector unsigned int ltemp;
	int i, j;

	final_rounding = vec_rl(one, five);

	// Part I.
	// Little benefit to unrolling these loops since we alternate
	// vectors a lot.
	curr1 = l;
	for(i=0; i<2; i++) {
		// 1-D IDCT.
		// Load (aligned) input.
		
		in[0]  = vec_ld(0,   (uint32_t *)input);
		in[8]  = vec_ld(16,  (uint32_t *)input);
		in[1]  = vec_ld(32,  (uint32_t *)input);
		in[9]  = vec_ld(48,  (uint32_t *)input);
		in[2]  = vec_ld(64,  (uint32_t *)input);
		in[10] = vec_ld(80,  (uint32_t *)input);
		in[3]  = vec_ld(96,  (uint32_t *)input);
		in[11] = vec_ld(112, (uint32_t *)input);
		in[4]  = vec_ld(128, (uint32_t *)input);
		in[12] = vec_ld(144, (uint32_t *)input);
		in[5]  = vec_ld(160, (uint32_t *)input);
		in[13] = vec_ld(176, (uint32_t *)input);
		in[6]  = vec_ld(192, (uint32_t *)input);
		in[14] = vec_ld(208, (uint32_t *)input);
		in[7]  = vec_ld(224, (uint32_t *)input);
		in[15] = vec_ld(240, (uint32_t *)input);
		array_transpose_8x8(in, in);
		array_transpose_8x8(in + 8, in + 8);

		IDCT16
		
		// Stage 7.
		curr1[0]  = vec_add(stp2_0, stp1_15);
		curr1[1]  = vec_add(stp2_1, stp1_14);
		curr1[2]  = vec_add(stp2_2, stp2_13);
		curr1[3]  = vec_add(stp2_3, stp2_12);
		curr1[4]  = vec_add(stp2_4, stp2_11);
		curr1[5]  = vec_add(stp2_5, stp2_10);
		curr1[6]  = vec_add(stp2_6, stp1_9);
		curr1[7]  = vec_add(stp2_7, stp1_8);
		curr1[8]  = vec_sub(stp2_7, stp1_8);
		curr1[9]  = vec_sub(stp2_6, stp1_9);
		curr1[10] = vec_sub(stp2_5, stp2_10);
		curr1[11] = vec_sub(stp2_4, stp2_11);
		curr1[12] = vec_sub(stp2_3, stp2_12);
		curr1[13] = vec_sub(stp2_2, stp2_13);
		curr1[14] = vec_sub(stp2_1, stp1_14);
		curr1[15] = vec_sub(stp2_0, stp1_15);

		curr1 = r;
		input += 128;
	}
	
	// Part II.
	for(i=0; i<2; i++) {
		// 1-D IDCT on the results of Part I.
		array_transpose_8x8(l + i * 8, in);
		array_transpose_8x8(r + i * 8, in + 8);
		
		IDCT16
		
		// Compute 2-D.
		in[0]  = vec_add(stp2_0, stp1_15);
		in[1]  = vec_add(stp2_1, stp1_14);
		in[2]  = vec_add(stp2_2, stp2_13);
		in[3]  = vec_add(stp2_3, stp2_12);
		in[4]  = vec_add(stp2_4, stp2_11);
		in[5]  = vec_add(stp2_5, stp2_10);
		in[6]  = vec_add(stp2_6, stp1_9);
		in[7]  = vec_add(stp2_7, stp1_8);
		in[8]  = vec_sub(stp2_7, stp1_8);
		in[9]  = vec_sub(stp2_6, stp1_9);
		in[10] = vec_sub(stp2_5, stp2_10);
		in[11] = vec_sub(stp2_4, stp2_11);
		in[12] = vec_sub(stp2_3, stp2_12);
		in[13] = vec_sub(stp2_2, stp2_13);
		in[14] = vec_sub(stp2_1, stp1_14);
		in[15] = vec_sub(stp2_0, stp1_15);

		for(j=0;j<16;j++) {
			// Final rounding and shift.
			in[j] = vec_adds(in[j], final_rounding);
			in[j] = vec_sra(in[j], six);
			
			// Reconstitute and store.
			_unaligned_load64(p0, (uint32_t *)(dest + j * stride));
			i0 = (vector signed short)vec_mergeh(zero, p0);
			i0 = vec_add(in[j], i0);
			p0 = vec_packsu(i0, i0);
			_unaligned_store64(p0, ltemp, (uint32_t *)(dest + j * stride));
		}
		dest += 8;
	}
}

// As written in the SSE2 version, this macro is actually wrong:
// they have in0 and in1 receive the output of the 32-bit merge instead
// of out0 and out1. But since they just overwrite the same vectors
// the bug never actually manifests. Sloppy! I corrected it here just
// to be petty and mean.
#define TRANSPOSE_8X4(in0, in1, in2, in3, out0, out1) \
  {                                                     \
	vector signed short tr0_0 = vec_mergeh(in0, in1); \
	vector signed short tr0_1 = vec_mergeh(in2, in3); \
                                                        \
	out0 = vec_mergeh((vector signed int)tr0_0, (vector signed int)tr0_1);  /* i1 i0 */  \
	out1 = vec_mergel((vector signed int)tr0_0, (vector signed int)tr0_1);  /* i3 i2 */  \
  }

// However, *this* is correct.
static inline void array_transpose_4X8(vector signed short *in, vector signed short *out) {
	vector signed short tr0_0 = vec_mergeh(in[0], in[1]);
	vector signed short tr0_1 = vec_mergeh(in[2], in[3]);
	vector signed short tr0_4 = vec_mergeh(in[4], in[5]);
	vector signed short tr0_5 = vec_mergeh(in[6], in[7]);

	vector signed int tr1_0 = vec_mergeh((vector signed int)tr0_0, (vector signed int)tr0_1);
	vector signed int tr1_4 = vec_mergeh((vector signed int)tr0_4, (vector signed int)tr0_5);
	vector signed int tr1_2 = vec_mergel((vector signed int)tr0_0, (vector signed int)tr0_1);
	vector signed int tr1_6 = vec_mergel((vector signed int)tr0_4, (vector signed int)tr0_5);

	out[0] = (vector signed short)vec_perm(tr1_0, tr1_4, merge64_hvec);
	out[1] = (vector signed short)vec_perm(tr1_0, tr1_4, merge64_lvec);
	out[2] = (vector signed short)vec_perm(tr1_2, tr1_6, merge64_hvec);
	out[3] = (vector signed short)vec_perm(tr1_2, tr1_6, merge64_lvec);
}

// Another great day in PowerPC msum land, doing more per cycle than slovenly SSE.
#define MULTIPLICATION_AND_ADD_2(lo_0, hi_0, cst0, cst1, res0, res1) \
  {   \
	tmp0 = vec_msum(lo_0, cst0, dct_rounding_vec); \
	tmp1 = vec_msum(hi_0, cst0, dct_rounding_vec); \
	tmp2 = vec_msum(lo_0, cst1, dct_rounding_vec); \
	tmp3 = vec_msum(hi_0, cst1, dct_rounding_vec); \
      \
	tmp0 = vec_sra(tmp0, dct_bitshift_vec); \
	tmp1 = vec_sra(tmp1, dct_bitshift_vec); \
	tmp2 = vec_sra(tmp2, dct_bitshift_vec); \
	tmp3 = vec_sra(tmp3, dct_bitshift_vec); \
      \
	res0 = vec_packs(tmp0, tmp1); \
	res1 = vec_packs(tmp2, tmp3); \
  }

#define IDCT16_10 \
    /* Stage 2. */ \
    { \
	vector signed short lo_1_15 = vec_mergeh(in[1], zero); \
	vector signed short hi_1_15 = vec_mergel(in[1], zero); \
	vector signed short lo_13_3 = vec_mergeh(zero, in[3]); \
	vector signed short hi_13_3 = vec_mergel(zero, in[3]); \
      \
	MULTIPLICATION_AND_ADD(lo_1_15, hi_1_15, lo_13_3, hi_13_3, \
				stg2_0, stg2_1, stg2_6, stg2_7, \
				stp1_8_0, stp1_15, stp1_11, stp1_12_0) \
    } \
      \
    /* Stage 3. */ \
    { \
	vector signed short lo_2_14 = vec_mergeh(in[2], zero); \
	vector signed short hi_2_14 = vec_mergel(in[2], zero); \
      \
	MULTIPLICATION_AND_ADD_2(lo_2_14, hi_2_14, \
				stg3_0, stg3_1,  \
				stp2_4, stp2_7) \
      \
	stp1_9  =  stp1_8_0; \
	stp1_10 =  stp1_11;  \
      \
	stp1_13 = stp1_12_0; \
	stp1_14 = stp1_15;   \
    } \
    \
    /* Stage 4. */ \
    { \
	vector signed short lo_0_8 = vec_mergeh(in[0], zero); \
	vector signed short hi_0_8 = vec_mergel(in[0], zero); \
      \
	vector signed short lo_9_14  = vec_mergeh(stp1_9,  stp1_14); \
	vector signed short hi_9_14  = vec_mergel(stp1_9,  stp1_14); \
	vector signed short lo_10_13 = vec_mergeh(stp1_10, stp1_13); \
	vector signed short hi_10_13 = vec_mergel(stp1_10, stp1_13); \
      \
	MULTIPLICATION_AND_ADD_2(lo_0_8, hi_0_8, \
				stg4_0, stg4_1, \
				stp1_0, stp1_1) \
	stp2_5 = stp2_4; \
	stp2_6 = stp2_7; \
      \
	MULTIPLICATION_AND_ADD(lo_9_14, hi_9_14, lo_10_13, hi_10_13, \
				stg4_4, stg4_5, stg4_6, stg4_7, \
				stp2_9, stp2_14, stp2_10, stp2_13) \
    } \
      \
    /* Stage 5. */ \
    { \
	vector signed short lo_6_5 = vec_mergeh(stp2_6, stp2_5); \
	vector signed short hi_6_5 = vec_mergel(stp2_6, stp2_5); \
      \
	stp1_2 = stp1_1; \
	stp1_3 = stp1_0; \
      \
	tmp0 = vec_msum(lo_6_5, stg4_1, dct_rounding_vec); \
	tmp1 = vec_msum(hi_6_5, stg4_1, dct_rounding_vec); \
	tmp2 = vec_msum(lo_6_5, stg4_0, dct_rounding_vec); \
	tmp3 = vec_msum(hi_6_5, stg4_0, dct_rounding_vec); \
      \
	tmp0 = vec_sra(tmp0, dct_bitshift_vec); \
	tmp1 = vec_sra(tmp1, dct_bitshift_vec); \
	tmp2 = vec_sra(tmp2, dct_bitshift_vec); \
	tmp3 = vec_sra(tmp3, dct_bitshift_vec); \
      \
	stp1_5 = vec_packs(tmp0, tmp1); \
	stp1_6 = vec_packs(tmp2, tmp3); \
      \
	stp1_8 = vec_add(stp1_8_0, stp1_11);  \
	stp1_9 = vec_add(stp2_9, stp2_10);    \
	stp1_10 = vec_sub(stp2_9, stp2_10);   \
	stp1_11 = vec_sub(stp1_8_0, stp1_11); \
      \
	stp1_12 = vec_sub(stp1_15, stp1_12_0); \
	stp1_13 = vec_sub(stp2_14, stp2_13);   \
	stp1_14 = vec_add(stp2_14, stp2_13);   \
	stp1_15 = vec_add(stp1_15, stp1_12_0); \
    } \
      \
    /* Stage 6. */ \
    { \
	vector signed short lo_10_13 = vec_mergeh(stp1_10, stp1_13); \
	vector signed short hi_10_13 = vec_mergel(stp1_10, stp1_13); \
	vector signed short lo_11_12 = vec_mergeh(stp1_11, stp1_12); \
	vector signed short hi_11_12 = vec_mergel(stp1_11, stp1_12); \
      \
	stp2_0 = vec_add(stp1_0, stp2_7); \
	stp2_1 = vec_add(stp1_1, stp1_6); \
	stp2_2 = vec_add(stp1_2, stp1_5); \
	stp2_3 = vec_add(stp1_3, stp2_4); \
	stp2_4 = vec_sub(stp1_3, stp2_4); \
	stp2_5 = vec_sub(stp1_2, stp1_5); \
	stp2_6 = vec_sub(stp1_1, stp1_6); \
	stp2_7 = vec_sub(stp1_0, stp2_7); \
      \
	MULTIPLICATION_AND_ADD(lo_10_13, hi_10_13, lo_11_12, hi_11_12, \
				stg6_0, stg4_0, stg6_0, stg4_0, \
				stp2_10, stp2_13, stp2_11, stp2_12) \
    }

void vp9_idct16x16_10_add_vmx(const int16_t *input, uint8_t *dest,
                               int stride) {
	vector signed short stg2_0 = short_pair_a(cospi_30_64, -cospi_2_64);
	vector signed short stg2_1 = short_pair_a(cospi_2_64, cospi_30_64);
	vector signed short stg2_6 = short_pair_a(cospi_6_64, -cospi_26_64);
	vector signed short stg2_7 = short_pair_a(cospi_26_64, cospi_6_64);

	vector signed short stg3_0 = short_pair_a(cospi_28_64, -cospi_4_64);
	vector signed short stg3_1 = short_pair_a(cospi_4_64, cospi_28_64);

	vector signed short stg4_0 = short_pair_a(cospi_16_64, cospi_16_64);
	vector signed short stg4_1 = short_pair_a(cospi_16_64, -cospi_16_64);
	vector signed short stg4_4 = short_pair_a(-cospi_8_64, cospi_24_64);
	vector signed short stg4_5 = short_pair_a(cospi_24_64, cospi_8_64);
	vector signed short stg4_6 = short_pair_a(-cospi_24_64, -cospi_8_64);
	vector signed short stg4_7 = short_pair_a(-cospi_8_64, cospi_24_64);

	vector signed short stg6_0 = short_pair_a(-cospi_16_64, cospi_16_64);
	vector signed short in[16], l[16], i0;
	vector signed short stp1_0, stp1_1, stp1_2, stp1_3, stp1_4, stp1_5, stp1_6,
		stp1_8, stp1_9, stp1_10, stp1_11, stp1_12, stp1_13, stp1_14, stp1_15,
		stp1_8_0, stp1_12_0;
	vector signed short stp2_0, stp2_1, stp2_2, stp2_3, stp2_4, stp2_5, stp2_6, stp2_7,
		stp2_8, stp2_9, stp2_10, stp2_11, stp2_12, stp2_13, stp2_14;
	vector signed short smp0, smp1, smp2, smp3;
	vector signed int tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
	vector unsigned char p0;
	vector signed short zero = vec_splat_u16(0);
	vector unsigned char zero_c = vec_splat_u8(0);
	vector unsigned short one = vec_splat_u16(1);
	vector unsigned short five = vec_splat_u16(5);
	vector unsigned short six = vec_splat_u16(6);
	vector signed short final_rounding;
	vector unsigned int ltemp;
	int i, j;

	final_rounding = vec_rl(one, five);

	// First 1-D inverse DCT.
	// Stage 1: load input data (aligned).
	in[0] = vec_ld(0,  (uint32_t *)input);
	in[1] = vec_ld(32, (uint32_t *)input); // Yes, really. We're skipping every other.
	in[2] = vec_ld(64, (uint32_t *)input);
	in[3] = vec_ld(96, (uint32_t *)input);

	TRANSPOSE_8X4(in[0], in[1], in[2], in[3], in[0], in[1]);

	// Stage 2.
	{
		vector signed short lo_1_15 = vec_mergel(in[0], zero);
		vector signed short lo_13_3 = vec_mergel(zero, in[1]);

		tmp0 = vec_msum(lo_1_15, stg2_0, dct_rounding_vec);
		tmp2 = vec_msum(lo_1_15, stg2_1, dct_rounding_vec);
		tmp5 = vec_msum(lo_13_3, stg2_6, dct_rounding_vec);
		tmp7 = vec_msum(lo_13_3, stg2_7, dct_rounding_vec);

		tmp0 = vec_sra(tmp0, dct_bitshift_vec);
		tmp2 = vec_sra(tmp2, dct_bitshift_vec);
		tmp5 = vec_sra(tmp5, dct_bitshift_vec);
		tmp7 = vec_sra(tmp7, dct_bitshift_vec);

		stp2_8  = vec_packs(tmp0, tmp2);
		stp2_11 = vec_packs(tmp5, tmp7);
	}

	// Stage 3.
	{
		vector signed short lo_2_14 = vec_mergeh(in[1], zero);

		tmp0 = vec_msum(lo_2_14, stg3_0, dct_rounding_vec);
		tmp2 = vec_msum(lo_2_14, stg3_1, dct_rounding_vec);

		tmp0 = vec_sra(tmp0, dct_bitshift_vec);
		tmp2 = vec_sra(tmp2, dct_bitshift_vec);

		stp1_13 = vec_perm(stp2_11, zero, merge64_lvec);
		stp1_14 = vec_perm(stp2_8, zero, merge64_lvec);
		stp1_4  = vec_packs(tmp0, tmp2);
	}

	// Stage 4.
	{
		vector signed short lo_0_8   = vec_mergeh(in[0], zero);
		vector signed short lo_9_14  = vec_mergeh(stp2_8, stp1_14);
		vector signed short lo_10_13 = vec_mergeh(stp2_11, stp1_13);

		tmp0 = vec_msum(lo_0_8,   stg4_0, dct_rounding_vec);
		tmp2 = vec_msum(lo_0_8,   stg4_1, dct_rounding_vec);
		tmp1 = vec_msum(lo_9_14,  stg4_4, dct_rounding_vec);
		tmp3 = vec_msum(lo_9_14,  stg4_5, dct_rounding_vec);
		tmp5 = vec_msum(lo_10_13, stg4_6, dct_rounding_vec);
		tmp7 = vec_msum(lo_10_13, stg4_7, dct_rounding_vec);

		tmp0 = vec_sra(tmp0, dct_bitshift_vec);
		tmp2 = vec_sra(tmp2, dct_bitshift_vec);
		tmp1 = vec_sra(tmp1, dct_bitshift_vec);
		tmp3 = vec_sra(tmp3, dct_bitshift_vec);
		tmp5 = vec_sra(tmp5, dct_bitshift_vec);
		tmp7 = vec_sra(tmp7, dct_bitshift_vec);

		stp1_0  = vec_packs(tmp0, tmp0);
		stp1_1  = vec_packs(tmp2, tmp2);
		stp2_9  = vec_packs(tmp1, tmp3);
		stp2_10 = vec_packs(tmp5, tmp7);
		stp2_6  = vec_perm(stp1_4, zero, merge64_lvec);
	}

	// Stages 5 and 6.
	{
		tmp0 = vec_add(stp2_8, stp2_11);
		tmp1 = vec_sub(stp2_8, stp2_11);
		tmp2 = vec_add(stp2_9, stp2_10);
		tmp3 = vec_sub(stp2_9, stp2_10);

		stp1_9  = (vector signed short)vec_perm(tmp2, (vector signed int)zero, merge64_hvec);
		stp1_10 = (vector signed short)vec_perm(tmp3, (vector signed int)zero, merge64_hvec);
		stp1_8  = (vector signed short)vec_perm(tmp0, (vector signed int)zero, merge64_hvec);
		stp1_11 = (vector signed short)vec_perm(tmp1, (vector signed int)zero, merge64_hvec);
		stp1_13 = (vector signed short)vec_perm(tmp3, (vector signed int)zero, merge64_lvec);
		stp1_14 = (vector signed short)vec_perm(tmp2, (vector signed int)zero, merge64_lvec);
		stp1_12 = (vector signed short)vec_perm(tmp1, (vector signed int)zero, merge64_lvec);
		stp1_15 = (vector signed short)vec_perm(tmp0, (vector signed int)zero, merge64_lvec);
	}

	// Stage 6 (continued).
	{
		vector signed short lo_6_5   = vec_mergeh(stp2_6,  stp1_4);
		vector signed short lo_10_13 = vec_mergeh(stp1_10, stp1_13);
		vector signed short lo_11_12 = vec_mergeh(stp1_11, stp1_12);

		tmp1 = vec_msum(lo_6_5,   stg4_1, dct_rounding_vec);
		tmp3 = vec_msum(lo_6_5,   stg4_0, dct_rounding_vec);
		tmp0 = vec_msum(lo_10_13, stg6_0, dct_rounding_vec);
		tmp2 = vec_msum(lo_10_13, stg4_0, dct_rounding_vec);
		tmp4 = vec_msum(lo_11_12, stg6_0, dct_rounding_vec);
		tmp6 = vec_msum(lo_11_12, stg4_0, dct_rounding_vec);

		tmp1 = vec_sra(tmp1, dct_bitshift_vec);
		tmp3 = vec_sra(tmp3, dct_bitshift_vec);
		tmp0 = vec_sra(tmp0, dct_bitshift_vec);
		tmp2 = vec_sra(tmp2, dct_bitshift_vec);
		tmp4 = vec_sra(tmp4, dct_bitshift_vec);
		tmp6 = vec_sra(tmp6, dct_bitshift_vec);

		stp1_6  = vec_packs(tmp3, tmp1);
		stp2_10 = vec_packs(tmp0, (vector signed int)zero);
		stp2_13 = vec_packs(tmp2, (vector signed int)zero);
		stp2_11 = vec_packs(tmp4, (vector signed int)zero);
		stp2_12 = vec_packs(tmp6, (vector signed int)zero);

		smp0 = vec_add(stp1_0, stp1_4);
		smp1 = vec_sub(stp1_0, stp1_4);
		smp2 = vec_add(stp1_1, stp1_6);
		smp3 = vec_sub(stp1_1, stp1_6);

		stp2_0 = vec_perm(smp0, zero, merge64_lvec);
		stp2_1 = vec_perm(smp2, zero, merge64_hvec);
		stp2_2 = vec_perm(smp2, zero, merge64_lvec);
		stp2_3 = vec_perm(smp0, zero, merge64_hvec);
		stp2_4 = vec_perm(smp1, zero, merge64_hvec);
		stp2_5 = vec_perm(smp3, zero, merge64_lvec);
		stp2_6 = vec_perm(smp3, zero, merge64_hvec);
		stp2_7 = vec_perm(smp1, zero, merge64_lvec);
	}

	// Stage 7, only on the left 8x16.
	l[0]  = vec_add(stp2_0, stp1_15);
	l[1]  = vec_add(stp2_1, stp1_14);
	l[2]  = vec_add(stp2_2, stp2_13);
	l[3]  = vec_add(stp2_3, stp2_12);
	l[4]  = vec_add(stp2_4, stp2_11);
	l[5]  = vec_add(stp2_5, stp2_10);
	l[6]  = vec_add(stp2_6, stp1_9);
	l[7]  = vec_add(stp2_7, stp1_8);
	l[8]  = vec_sub(stp2_7, stp1_8);
	l[9]  = vec_sub(stp2_6, stp1_9);
	l[10] = vec_sub(stp2_5, stp2_10);
	l[11] = vec_sub(stp2_4, stp2_11);
	l[12] = vec_sub(stp2_3, stp2_12);
	l[13] = vec_sub(stp2_2, stp2_13);
	l[14] = vec_sub(stp2_1, stp1_14);
	l[15] = vec_sub(stp2_0, stp1_15);

	// Second 1-D inverse transform, performed per 8x16 block.
	for(i=0;i<2;i++) {
		array_transpose_4X8(l + 8 * i, in);
		IDCT16_10
		
		// Stage 7, continued.
		in[0]  = vec_add(stp2_0, stp1_15);
		in[1]  = vec_add(stp2_1, stp1_14);
		in[2]  = vec_add(stp2_2, stp2_13);
		in[3]  = vec_add(stp2_3, stp2_12);
		in[4]  = vec_add(stp2_4, stp2_11);
		in[5]  = vec_add(stp2_5, stp2_10);
		in[6]  = vec_add(stp2_6, stp1_9);
		in[7]  = vec_add(stp2_7, stp1_8);
		in[8]  = vec_sub(stp2_7, stp1_8);
		in[9]  = vec_sub(stp2_6, stp1_9);
		in[10] = vec_sub(stp2_5, stp2_10);
		in[11] = vec_sub(stp2_4, stp2_11);
		in[12] = vec_sub(stp2_3, stp2_12);
		in[13] = vec_sub(stp2_2, stp2_13);
		in[14] = vec_sub(stp2_1, stp1_14);
		in[15] = vec_sub(stp2_0, stp1_15);

		for(j=0;j<16;j++) {
			// Final rounding and shift.
			in[j] = vec_adds(in[j], final_rounding);
			in[j] = vec_sra(in[j], six);
			
			// Reconstitute and store.
			_unaligned_load64(p0, (uint32_t *)(dest + j * stride));
			i0 = (vector signed short)vec_mergeh(zero_c, p0);
			i0 = vec_add(in[j], i0);
			p0 = vec_packsu(i0, i0);
			_unaligned_store64(p0, ltemp, (uint32_t *)(dest + j * stride));
		}
		dest += 8;
	}
}

#define IDCT32_34 \
/* Stage 1. */ \
{ \
	vector signed short lo_1_31 = vec_mergeh(in[1], zero); \
	vector signed short hi_1_31 = vec_mergel(in[1], zero); \
  \
	vector signed short lo_25_7 = vec_mergeh(zero, in[7]); \
	vector signed short hi_25_7 = vec_mergel(zero, in[7]); \
  \
	vector signed short lo_5_27 = vec_mergeh(in[5], zero); \
	vector signed short hi_5_27 = vec_mergel(in[5], zero); \
  \
	vector signed short lo_29_3 = vec_mergeh(zero, in[3]); \
	vector signed short hi_29_3 = vec_mergel(zero, in[3]); \
  \
	MULTIPLICATION_AND_ADD_2(lo_1_31, hi_1_31, stg1_0, \
				stg1_1, stp1_16, stp1_31); \
	MULTIPLICATION_AND_ADD_2(lo_25_7, hi_25_7, stg1_6, \
				stg1_7, stp1_19, stp1_28); \
	MULTIPLICATION_AND_ADD_2(lo_5_27, hi_5_27, stg1_8, \
				stg1_9, stp1_20, stp1_27); \
	MULTIPLICATION_AND_ADD_2(lo_29_3, hi_29_3, stg1_14, \
				stg1_15, stp1_23, stp1_24); \
} \
\
/* Stage 2. */ \
{ \
	vector signed short lo_2_30 = vec_mergeh(in[2], zero); \
	vector signed short hi_2_30 = vec_mergel(in[2], zero); \
  \
	vector signed short lo_26_6 = vec_mergeh(zero, in[6]); \
	vector signed short hi_26_6 = vec_mergel(zero, in[6]); \
  \
	MULTIPLICATION_AND_ADD_2(lo_2_30, hi_2_30, stg2_0, \
				stg2_1, stp2_8, stp2_15); \
	MULTIPLICATION_AND_ADD_2(lo_26_6, hi_26_6, stg2_6, \
				stg2_7, stp2_11, stp2_12); \
  \
	stp2_16 = stp1_16; \
	stp2_19 = stp1_19; \
  \
	stp2_20 = stp1_20; \
	stp2_23 = stp1_23; \
  \
	stp2_24 = stp1_24; \
	stp2_27 = stp1_27; \
  \
	stp2_28 = stp1_28; \
	stp2_31 = stp1_31; \
} \
\
/* Stage 3. */ \
{ \
	vector signed short lo_4_28 = vec_mergeh(in[4], zero); \
	vector signed short hi_4_28 = vec_mergel(in[4], zero); \
  \
	vector signed short lo_17_30 = vec_mergeh(stp1_16, stp1_31); \
	vector signed short hi_17_30 = vec_mergel(stp1_16, stp1_31); \
	vector signed short lo_18_29 = vec_mergeh(stp1_19, stp1_28); \
	vector signed short hi_18_29 = vec_mergel(stp1_19, stp1_28); \
  \
	vector signed short lo_21_26 = vec_mergeh(stp1_20, stp1_27); \
	vector signed short hi_21_26 = vec_mergel(stp1_20, stp1_27); \
	vector signed short lo_22_25 = vec_mergeh(stp1_23, stp1_24); \
	vector signed short hi_22_25 = vec_mergel(stp1_23, stp2_24); \
  \
	MULTIPLICATION_AND_ADD_2(lo_4_28, hi_4_28, stg3_0, \
				stg3_1, stp1_4, stp1_7); \
  \
	stp1_8  = stp2_8; \
	stp1_11 = stp2_11; \
	stp1_12 = stp2_12; \
	stp1_15 = stp2_15; \
  \
	MULTIPLICATION_AND_ADD(lo_17_30, hi_17_30, lo_18_29, hi_18_29, stg3_4, \
				stg3_5, stg3_6, stg3_4, stp1_17, stp1_30, \
				stp1_18, stp1_29) \
	MULTIPLICATION_AND_ADD(lo_21_26, hi_21_26, lo_22_25, hi_22_25, stg3_8, \
				stg3_9, stg3_10, stg3_8, stp1_21, stp1_26, \
				stp1_22, stp1_25) \
  \
	stp1_16 = stp2_16; \
	stp1_31 = stp2_31; \
	stp1_19 = stp2_19; \
	stp1_20 = stp2_20; \
	stp1_23 = stp2_23; \
	stp1_24 = stp2_24; \
	stp1_27 = stp2_27; \
	stp1_28 = stp2_28; \
} \
\
/* Stage 4. */ \
{ \
	vector signed short lo_0_16 = vec_mergeh(in[0], zero); \
	vector signed short hi_0_16 = vec_mergel(in[0], zero); \
  \
	vector signed short lo_9_14  = vec_mergeh(stp2_8,  stp2_15); \
	vector signed short hi_9_14  = vec_mergel(stp2_8,  stp2_15); \
	vector signed short lo_10_13 = vec_mergeh(stp2_11, stp2_12); \
	vector signed short hi_10_13 = vec_mergel(stp2_11, stp2_12); \
  \
	MULTIPLICATION_AND_ADD_2(lo_0_16, hi_0_16, stg4_0, \
				stg4_1, stp2_0, stp2_1); \
  \
	stp2_4 = stp1_4; \
	stp2_5 = stp1_4; \
	stp2_6 = stp1_7; \
	stp2_7 = stp1_7; \
  \
	MULTIPLICATION_AND_ADD(lo_9_14, hi_9_14, lo_10_13, hi_10_13, stg4_4, \
				stg4_5, stg4_6, stg4_4, stp2_9, stp2_14, \
				stp2_10, stp2_13) \
  \
	stp2_8  = stp1_8; \
	stp2_15 = stp1_15; \
	stp2_11 = stp1_11; \
	stp2_12 = stp1_12; \
  \
	stp2_16 = vec_add(stp1_16, stp1_19); \
	stp2_17 = vec_add(stp1_17, stp1_18); \
	stp2_18 = vec_sub(stp1_17, stp1_18); \
	stp2_19 = vec_sub(stp1_16, stp1_19); \
	stp2_20 = vec_sub(stp1_23, stp1_20); \
	stp2_21 = vec_sub(stp1_22, stp1_21); \
	stp2_22 = vec_add(stp1_22, stp1_21); \
	stp2_23 = vec_add(stp1_23, stp1_20); \
  \
	stp2_24 = vec_add(stp1_24, stp1_27); \
	stp2_25 = vec_add(stp1_25, stp1_26); \
	stp2_26 = vec_sub(stp1_25, stp1_26); \
	stp2_27 = vec_sub(stp1_24, stp1_27); \
	stp2_28 = vec_sub(stp1_31, stp1_28); \
	stp2_29 = vec_sub(stp1_30, stp1_29); \
	stp2_30 = vec_add(stp1_29, stp1_30); \
	stp2_31 = vec_add(stp1_28, stp1_31); \
} \
\
/* Stage 5. */ \
{ \
	vector signed short lo_6_5   = vec_mergeh(stp2_6,  stp2_5); \
	vector signed short hi_6_5   = vec_mergel(stp2_6,  stp2_5); \
	vector signed short lo_18_29 = vec_mergeh(stp2_18, stp2_29); \
	vector signed short hi_18_29 = vec_mergel(stp2_18, stp2_29); \
  \
	vector signed short lo_19_28 = vec_mergeh(stp2_19, stp2_28); \
	vector signed short hi_19_28 = vec_mergel(stp2_19, stp2_28); \
	vector signed short lo_20_27 = vec_mergeh(stp2_20, stp2_27); \
	vector signed short hi_20_27 = vec_mergel(stp2_20, stp2_27); \
  \
	vector signed short lo_21_26 = vec_mergeh(stp2_21, stp2_26); \
	vector signed short hi_21_26 = vec_mergel(stp2_21, stp2_26); \
  \
	stp1_0 = stp2_0; \
	stp1_1 = stp2_1; \
	stp1_2 = stp2_1; \
	stp1_3 = stp2_0; \
  \
	tmp0 = vec_msum(lo_6_5, stg4_1, dct_rounding_vec); \
	tmp1 = vec_msum(hi_6_5, stg4_1, dct_rounding_vec); \
	tmp2 = vec_msum(lo_6_5, stg4_0, dct_rounding_vec); \
	tmp3 = vec_msum(hi_6_5, stg4_0, dct_rounding_vec); \
  \
	tmp0 = vec_sra(tmp0, dct_bitshift_vec); \
	tmp1 = vec_sra(tmp1, dct_bitshift_vec); \
	tmp2 = vec_sra(tmp2, dct_bitshift_vec); \
	tmp3 = vec_sra(tmp3, dct_bitshift_vec); \
  \
	stp1_5 = vec_packs(tmp0, tmp1); \
	stp1_6 = vec_packs(tmp2, tmp3); \
  \
	stp1_4 = stp2_4; \
	stp1_7 = stp2_7; \
  \
	stp1_8  = vec_add(stp2_8, stp2_11); \
	stp1_9  = vec_add(stp2_9, stp2_10); \
	stp1_10 = vec_sub(stp2_9, stp2_10); \
	stp1_11 = vec_sub(stp2_8, stp2_11); \
	stp1_12 = vec_sub(stp2_15, stp2_12); \
	stp1_13 = vec_sub(stp2_14, stp2_13); \
	stp1_14 = vec_add(stp2_14, stp2_13); \
	stp1_15 = vec_add(stp2_15, stp2_12); \
  \
	stp1_16 = stp2_16; \
	stp1_17 = stp2_17; \
  \
	MULTIPLICATION_AND_ADD(lo_18_29, hi_18_29, lo_19_28, hi_19_28, stg4_4, \
				stg4_5, stg4_4, stg4_5, stp1_18, stp1_29, \
				stp1_19, stp1_28) \
	MULTIPLICATION_AND_ADD(lo_20_27, hi_20_27, lo_21_26, hi_21_26, stg4_6, \
				stg4_4, stg4_6, stg4_4, stp1_20, stp1_27, \
				stp1_21, stp1_26) \
  \
	stp1_22 = stp2_22; \
	stp1_23 = stp2_23; \
	stp1_24 = stp2_24; \
	stp1_25 = stp2_25; \
	stp1_30 = stp2_30; \
	stp1_31 = stp2_31; \
} \
\
/* Stage 6. */ \
{ \
	vector signed short lo_10_13 = vec_mergeh(stp1_10, stp1_13); \
	vector signed short hi_10_13 = vec_mergel(stp1_10, stp1_13); \
	vector signed short lo_11_12 = vec_mergeh(stp1_11, stp1_12); \
	vector signed short hi_11_12 = vec_mergel(stp1_11, stp1_12); \
  \
	stp2_0 = vec_add(stp1_0, stp1_7); \
	stp2_1 = vec_add(stp1_1, stp1_6); \
	stp2_2 = vec_add(stp1_2, stp1_5); \
	stp2_3 = vec_add(stp1_3, stp1_4); \
	stp2_4 = vec_sub(stp1_3, stp1_4); \
	stp2_5 = vec_sub(stp1_2, stp1_5); \
	stp2_6 = vec_sub(stp1_1, stp1_6); \
	stp2_7 = vec_sub(stp1_0, stp1_7); \
  \
	stp2_8  = stp1_8; \
	stp2_9  = stp1_9; \
	stp2_14 = stp1_14; \
	stp2_15 = stp1_15; \
  \
	MULTIPLICATION_AND_ADD(lo_10_13, hi_10_13, lo_11_12, hi_11_12, \
				stg6_0, stg4_0, stg6_0, stg4_0, stp2_10, \
				stp2_13, stp2_11, stp2_12) \
  \
	stp2_16 = vec_add(stp1_16, stp1_23); \
	stp2_17 = vec_add(stp1_17, stp1_22); \
	stp2_18 = vec_add(stp1_18, stp1_21); \
	stp2_19 = vec_add(stp1_19, stp1_20); \
	stp2_20 = vec_sub(stp1_19, stp1_20); \
	stp2_21 = vec_sub(stp1_18, stp1_21); \
	stp2_22 = vec_sub(stp1_17, stp1_22); \
	stp2_23 = vec_sub(stp1_16, stp1_23); \
  \
	stp2_24 = vec_sub(stp1_31, stp1_24); \
	stp2_25 = vec_sub(stp1_30, stp1_25); \
	stp2_26 = vec_sub(stp1_29, stp1_26); \
	stp2_27 = vec_sub(stp1_28, stp1_27); \
	stp2_28 = vec_add(stp1_27, stp1_28); \
	stp2_29 = vec_add(stp1_26, stp1_29); \
	stp2_30 = vec_add(stp1_25, stp1_30); \
	stp2_31 = vec_add(stp1_24, stp1_31); \
} \
\
/* Stage 7. */ \
{ \
	vector signed short lo_20_27 = vec_mergeh(stp2_20, stp2_27); \
	vector signed short hi_20_27 = vec_mergel(stp2_20, stp2_27); \
	vector signed short lo_21_26 = vec_mergeh(stp2_21, stp2_26); \
	vector signed short hi_21_26 = vec_mergel(stp2_21, stp2_26); \
  \
	vector signed short lo_22_25 = vec_mergeh(stp2_22, stp2_25); \
	vector signed short hi_22_25 = vec_mergel(stp2_22, stp2_25); \
	vector signed short lo_23_24 = vec_mergeh(stp2_23, stp2_24); \
	vector signed short hi_23_24 = vec_mergel(stp2_23, stp2_24); \
  \
	stp1_0  = vec_add(stp2_0, stp2_15); \
	stp1_1  = vec_add(stp2_1, stp2_14); \
	stp1_2  = vec_add(stp2_2, stp2_13); \
	stp1_3  = vec_add(stp2_3, stp2_12); \
	stp1_4  = vec_add(stp2_4, stp2_11); \
	stp1_5  = vec_add(stp2_5, stp2_10); \
	stp1_6  = vec_add(stp2_6, stp2_9); \
	stp1_7  = vec_add(stp2_7, stp2_8); \
	stp1_8  = vec_sub(stp2_7, stp2_8); \
	stp1_9  = vec_sub(stp2_6, stp2_9); \
	stp1_10 = vec_sub(stp2_5, stp2_10); \
	stp1_11 = vec_sub(stp2_4, stp2_11); \
	stp1_12 = vec_sub(stp2_3, stp2_12); \
	stp1_13 = vec_sub(stp2_2, stp2_13); \
	stp1_14 = vec_sub(stp2_1, stp2_14); \
	stp1_15 = vec_sub(stp2_0, stp2_15); \
  \
	stp1_16 = stp2_16; \
	stp1_17 = stp2_17; \
	stp1_18 = stp2_18; \
	stp1_19 = stp2_19; \
  \
	MULTIPLICATION_AND_ADD(lo_20_27, hi_20_27, lo_21_26, hi_21_26, stg6_0, \
				stg4_0, stg6_0, stg4_0, stp1_20, stp1_27, \
				stp1_21, stp1_26) \
	MULTIPLICATION_AND_ADD(lo_22_25, hi_22_25, lo_23_24, hi_23_24, stg6_0, \
				stg4_0, stg6_0, stg4_0, stp1_22, stp1_25, \
				stp1_23, stp1_24) \
  \
	stp1_28 = stp2_28; \
	stp1_29 = stp2_29; \
	stp1_30 = stp2_30; \
	stp1_31 = stp2_31; \
}

void vp9_idct32x32_34_add_vmx(const int16_t *input, uint8_t *dest,
                               int stride) {
	vector signed short stg1_0  = short_pair_a(cospi_31_64, -cospi_1_64);
	vector signed short stg1_1  = short_pair_a(cospi_1_64, cospi_31_64);
	vector signed short stg1_6  = short_pair_a(cospi_7_64, -cospi_25_64);
	vector signed short stg1_7  = short_pair_a(cospi_25_64, cospi_7_64);
	vector signed short stg1_8  = short_pair_a(cospi_27_64, -cospi_5_64);
	vector signed short stg1_9  = short_pair_a(cospi_5_64, cospi_27_64);
	vector signed short stg1_14 = short_pair_a(cospi_3_64, -cospi_29_64);
	vector signed short stg1_15 = short_pair_a(cospi_29_64, cospi_3_64);

	vector signed short stg2_0 = short_pair_a(cospi_30_64, -cospi_2_64);
	vector signed short stg2_1 = short_pair_a(cospi_2_64, cospi_30_64);
	vector signed short stg2_6 = short_pair_a(cospi_6_64, -cospi_26_64);
	vector signed short stg2_7 = short_pair_a(cospi_26_64, cospi_6_64);

	vector signed short stg3_0  = short_pair_a(cospi_28_64, -cospi_4_64);
	vector signed short stg3_1  = short_pair_a(cospi_4_64, cospi_28_64);
	vector signed short stg3_4  = short_pair_a(-cospi_4_64, cospi_28_64);
	vector signed short stg3_5  = short_pair_a(cospi_28_64, cospi_4_64);
	vector signed short stg3_6  = short_pair_a(-cospi_28_64, -cospi_4_64);
	vector signed short stg3_8  = short_pair_a(-cospi_20_64, cospi_12_64);
	vector signed short stg3_9  = short_pair_a(cospi_12_64, cospi_20_64);
	vector signed short stg3_10 = short_pair_a(-cospi_12_64, -cospi_20_64);

	vector signed short stg4_0 = short_pair_a(cospi_16_64, cospi_16_64);
	vector signed short stg4_1 = short_pair_a(cospi_16_64, -cospi_16_64);
	vector signed short stg4_4 = short_pair_a(-cospi_8_64, cospi_24_64);
	vector signed short stg4_5 = short_pair_a(cospi_24_64, cospi_8_64);
	vector signed short stg4_6 = short_pair_a(-cospi_24_64, -cospi_8_64);

	vector signed short stg6_0 = short_pair_a(-cospi_16_64, cospi_16_64);
	vector signed short zero = vec_splat_u16(0);
	vector unsigned char zero_c = vec_splat_u8(0);
	vector unsigned short one = vec_splat_u16(1);
	vector unsigned short five = vec_splat_u16(5);
	vector unsigned short six = vec_splat_u16(6);
	vector signed short final_rounding;
	vector unsigned int ltemp;
	vector unsigned char p0;

	vector signed short in[32], col[32], i0;
	vector signed short stp1_0, stp1_1, stp1_2, stp1_3, stp1_4, stp1_5, stp1_6, stp1_7,
		stp1_8, stp1_9, stp1_10, stp1_11, stp1_12, stp1_13, stp1_14, stp1_15,
		stp1_16, stp1_17, stp1_18, stp1_19, stp1_20, stp1_21, stp1_22,
		stp1_23, stp1_24, stp1_25, stp1_26, stp1_27, stp1_28, stp1_29,
		stp1_30, stp1_31;
	vector signed short stp2_0, stp2_1, stp2_2, stp2_3, stp2_4, stp2_5, stp2_6, stp2_7,
		stp2_8, stp2_9, stp2_10, stp2_11, stp2_12, stp2_13, stp2_14, stp2_15,
		stp2_16, stp2_17, stp2_18, stp2_19, stp2_20, stp2_21, stp2_22,
		stp2_23, stp2_24, stp2_25, stp2_26, stp2_27, stp2_28, stp2_29,
		stp2_30, stp2_31;
	vector signed int tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
	int i, j;

	final_rounding = vec_rl(one, five);
	
	// Load vectors from top left 8x8 block.
	in[0] = vec_ld(0,   (uint32_t *)input);
	in[1] = vec_ld(64,  (uint32_t *)input);
	in[2] = vec_ld(128, (uint32_t *)input);
	in[3] = vec_ld(192, (uint32_t *)input);
	in[4] = vec_ld(256, (uint32_t *)input);
	in[5] = vec_ld(320, (uint32_t *)input);
	in[6] = vec_ld(384, (uint32_t *)input);
	in[7] = vec_ld(448, (uint32_t *)input);

	// 1-D IDCT.
	// Store intermediate results for each 8x32 block.
	array_transpose_8x8(in, in);
	IDCT32_34

	col[0]  = vec_add(stp1_0,  stp1_31);
	col[1]  = vec_add(stp1_1,  stp1_30);
	col[2]  = vec_add(stp1_2,  stp1_29);
	col[3]  = vec_add(stp1_3,  stp1_28);
	col[4]  = vec_add(stp1_4,  stp1_27);
	col[5]  = vec_add(stp1_5,  stp1_26);
	col[6]  = vec_add(stp1_6,  stp1_25);
	col[7]  = vec_add(stp1_7,  stp1_24);
	col[8]  = vec_add(stp1_8,  stp1_23);
	col[9]  = vec_add(stp1_9,  stp1_22);
	col[10] = vec_add(stp1_10, stp1_21);
	col[11] = vec_add(stp1_11, stp1_20);
	col[12] = vec_add(stp1_12, stp1_19);
	col[13] = vec_add(stp1_13, stp1_18);
	col[14] = vec_add(stp1_14, stp1_17);
	col[15] = vec_add(stp1_15, stp1_16);
	col[16] = vec_sub(stp1_15, stp1_16);
	col[17] = vec_sub(stp1_14, stp1_17);
	col[18] = vec_sub(stp1_13, stp1_18);
	col[19] = vec_sub(stp1_12, stp1_19);
	col[20] = vec_sub(stp1_11, stp1_20);
	col[21] = vec_sub(stp1_10, stp1_21);
	col[22] = vec_sub(stp1_9,  stp1_22);
	col[23] = vec_sub(stp1_8,  stp1_23);
	col[24] = vec_sub(stp1_7,  stp1_24);
	col[25] = vec_sub(stp1_6,  stp1_25);
	col[26] = vec_sub(stp1_5,  stp1_26);
	col[27] = vec_sub(stp1_4,  stp1_27);
	col[28] = vec_sub(stp1_3,  stp1_28);
	col[29] = vec_sub(stp1_2,  stp1_29);
	col[30] = vec_sub(stp1_1,  stp1_30);
	col[31] = vec_sub(stp1_0,  stp1_31);

	// Compute the 2-D result for each descendant.
	for(i=0;i<4;i++) {
		array_transpose_8x8(col+i*8, in);
		IDCT32_34

		in[0]  = vec_add(stp1_0,  stp1_31);
		in[1]  = vec_add(stp1_1,  stp1_30);
		in[2]  = vec_add(stp1_2,  stp1_29);
		in[3]  = vec_add(stp1_3,  stp1_28);
		in[4]  = vec_add(stp1_4,  stp1_27);
		in[5]  = vec_add(stp1_5,  stp1_26);
		in[6]  = vec_add(stp1_6,  stp1_25);
		in[7]  = vec_add(stp1_7,  stp1_24);
		in[8]  = vec_add(stp1_8,  stp1_23);
		in[9]  = vec_add(stp1_9,  stp1_22);
		in[10] = vec_add(stp1_10, stp1_21);
		in[11] = vec_add(stp1_11, stp1_20);
		in[12] = vec_add(stp1_12, stp1_19);
		in[13] = vec_add(stp1_13, stp1_18);
		in[14] = vec_add(stp1_14, stp1_17);
		in[15] = vec_add(stp1_15, stp1_16);
		in[16] = vec_sub(stp1_15, stp1_16);
		in[17] = vec_sub(stp1_14, stp1_17);
		in[18] = vec_sub(stp1_13, stp1_18);
		in[19] = vec_sub(stp1_12, stp1_19);
		in[20] = vec_sub(stp1_11, stp1_20);
		in[21] = vec_sub(stp1_10, stp1_21);
		in[22] = vec_sub(stp1_9,  stp1_22);
		in[23] = vec_sub(stp1_8,  stp1_23);
		in[24] = vec_sub(stp1_7,  stp1_24);
		in[25] = vec_sub(stp1_6,  stp1_25);
		in[26] = vec_sub(stp1_5,  stp1_26);
		in[27] = vec_sub(stp1_4,  stp1_27);
		in[28] = vec_sub(stp1_3,  stp1_28);
		in[29] = vec_sub(stp1_2,  stp1_29);
		in[30] = vec_sub(stp1_1,  stp1_30);
		in[31] = vec_sub(stp1_0,  stp1_31);
		
		// Round, shift, reconstitute and store.
		for(j=0;j<32;++j) {
			in[j] = vec_adds(in[j], final_rounding);
			in[j] = vec_sra(in[j], six);
			
			_unaligned_load64(p0, (uint32_t *)(dest + j * stride));
			i0 = (vector signed short)vec_mergeh(zero_c, p0);
			i0 = vec_add(in[j], i0);
			p0 = vec_packsu(i0, i0);
			_unaligned_store64(p0, ltemp, (uint32_t *)(dest + j * stride));
		}
		dest += 8;
	}
}

#define IDCT32 \
/* Stage 1. */ \
{ \
	vector signed short lo_1_31  = vec_mergeh(in[1], in[31]); \
	vector signed short hi_1_31  = vec_mergel(in[1], in[31]); \
	vector signed short lo_17_15 = vec_mergeh(in[17], in[15]); \
	vector signed short hi_17_15 = vec_mergel(in[17], in[15]); \
  \
	vector signed short lo_9_23  = vec_mergeh(in[9], in[23]); \
	vector signed short hi_9_23  = vec_mergel(in[9], in[23]); \
	vector signed short lo_25_7  = vec_mergeh(in[25], in[7]); \
	vector signed short hi_25_7  = vec_mergel(in[25], in[7]); \
  \
	vector signed short lo_5_27  = vec_mergeh(in[5], in[27]); \
	vector signed short hi_5_27  = vec_mergel(in[5], in[27]); \
	vector signed short lo_21_11 = vec_mergeh(in[21], in[11]); \
	vector signed short hi_21_11 = vec_mergel(in[21], in[11]); \
  \
	vector signed short lo_13_19 = vec_mergeh(in[13], in[19]); \
	vector signed short hi_13_19 = vec_mergel(in[13], in[19]); \
	vector signed short lo_29_3  = vec_mergeh(in[29], in[3]); \
	vector signed short hi_29_3  = vec_mergel(in[29], in[3]); \
  \
	MULTIPLICATION_AND_ADD(lo_1_31, hi_1_31, lo_17_15, hi_17_15, stg1_0, \
				stg1_1, stg1_2, stg1_3, stp1_16, stp1_31, \
				stp1_17, stp1_30) \
	MULTIPLICATION_AND_ADD(lo_9_23, hi_9_23, lo_25_7, hi_25_7, stg1_4, \
				stg1_5, stg1_6, stg1_7, stp1_18, stp1_29, \
				stp1_19, stp1_28) \
	MULTIPLICATION_AND_ADD(lo_5_27, hi_5_27, lo_21_11, hi_21_11, stg1_8, \
				stg1_9, stg1_10, stg1_11, stp1_20, stp1_27, \
				stp1_21, stp1_26) \
	MULTIPLICATION_AND_ADD(lo_13_19, hi_13_19, lo_29_3, hi_29_3, stg1_12, \
				stg1_13, stg1_14, stg1_15, stp1_22, stp1_25, \
				stp1_23, stp1_24) \
} \
\
/* Stage 2. */ \
{ \
	vector signed short lo_2_30  = vec_mergeh(in[2], in[30]); \
	vector signed short hi_2_30  = vec_mergel(in[2], in[30]); \
	vector signed short lo_18_14 = vec_mergeh(in[18], in[14]); \
	vector signed short hi_18_14 = vec_mergel(in[18], in[14]); \
  \
	vector signed short lo_10_22 = vec_mergeh(in[10], in[22]); \
	vector signed short hi_10_22 = vec_mergel(in[10], in[22]); \
	vector signed short lo_26_6  = vec_mergeh(in[26], in[6]); \
	vector signed short hi_26_6  = vec_mergel(in[26], in[6]); \
  \
	MULTIPLICATION_AND_ADD(lo_2_30, hi_2_30, lo_18_14, hi_18_14, stg2_0, \
				stg2_1, stg2_2, stg2_3, stp2_8, stp2_15, stp2_9, \
				stp2_14) \
	MULTIPLICATION_AND_ADD(lo_10_22, hi_10_22, lo_26_6, hi_26_6, stg2_4, \
				stg2_5, stg2_6, stg2_7, stp2_10, stp2_13, \
				stp2_11, stp2_12) \
  \
	stp2_16 = vec_add(stp1_16, stp1_17); \
	stp2_17 = vec_sub(stp1_16, stp1_17); \
	stp2_18 = vec_sub(stp1_19, stp1_18); \
	stp2_19 = vec_add(stp1_19, stp1_18); \
  \
	stp2_20 = vec_add(stp1_20, stp1_21); \
	stp2_21 = vec_sub(stp1_20, stp1_21); \
	stp2_22 = vec_sub(stp1_23, stp1_22); \
	stp2_23 = vec_add(stp1_23, stp1_22); \
  \
	stp2_24 = vec_add(stp1_24, stp1_25); \
	stp2_25 = vec_sub(stp1_24, stp1_25); \
	stp2_26 = vec_sub(stp1_27, stp1_26); \
	stp2_27 = vec_add(stp1_27, stp1_26); \
  \
	stp2_28 = vec_add(stp1_28, stp1_29); \
	stp2_29 = vec_sub(stp1_28, stp1_29); \
	stp2_30 = vec_sub(stp1_31, stp1_30); \
	stp2_31 = vec_add(stp1_31, stp1_30); \
} \
\
/* Stage 3. */ \
{ \
	vector signed short lo_4_28  = vec_mergeh(in[4], in[28]); \
	vector signed short hi_4_28  = vec_mergel(in[4], in[28]); \
	vector signed short lo_20_12 = vec_mergeh(in[20], in[12]); \
	vector signed short hi_20_12 = vec_mergel(in[20], in[12]); \
  \
	vector signed short lo_17_30 = vec_mergeh(stp2_17, stp2_30); \
	vector signed short hi_17_30 = vec_mergel(stp2_17, stp2_30); \
	vector signed short lo_18_29 = vec_mergeh(stp2_18, stp2_29); \
	vector signed short hi_18_29 = vec_mergel(stp2_18, stp2_29); \
  \
	vector signed short lo_21_26 = vec_mergeh(stp2_21, stp2_26); \
	vector signed short hi_21_26 = vec_mergel(stp2_21, stp2_26); \
	vector signed short lo_22_25 = vec_mergeh(stp2_22, stp2_25); \
	vector signed short hi_22_25 = vec_mergel(stp2_22, stp2_25); \
  \
	MULTIPLICATION_AND_ADD(lo_4_28, hi_4_28, lo_20_12, hi_20_12, stg3_0, \
				stg3_1, stg3_2, stg3_3, stp1_4, stp1_7, stp1_5, \
				stp1_6) \
  \
	stp1_8  = vec_add(stp2_8, stp2_9); \
	stp1_9  = vec_sub(stp2_8, stp2_9); \
	stp1_10 = vec_sub(stp2_11, stp2_10); \
	stp1_11 = vec_add(stp2_11, stp2_10); \
  \
	stp1_12 = vec_add(stp2_12, stp2_13); \
	stp1_13 = vec_sub(stp2_12, stp2_13); \
	stp1_14 = vec_sub(stp2_15, stp2_14); \
	stp1_15 = vec_add(stp2_15, stp2_14); \
  \
	MULTIPLICATION_AND_ADD(lo_17_30, hi_17_30, lo_18_29, hi_18_29, stg3_4, \
				stg3_5, stg3_6, stg3_4, stp1_17, stp1_30, \
				stp1_18, stp1_29) \
	MULTIPLICATION_AND_ADD(lo_21_26, hi_21_26, lo_22_25, hi_22_25, stg3_8, \
				stg3_9, stg3_10, stg3_8, stp1_21, stp1_26, \
				stp1_22, stp1_25) \
  \
	stp1_16 = stp2_16; \
	stp1_31 = stp2_31; \
	stp1_19 = stp2_19; \
	stp1_20 = stp2_20; \
	stp1_23 = stp2_23; \
	stp1_24 = stp2_24; \
	stp1_27 = stp2_27; \
	stp1_28 = stp2_28; \
} \
\
/* Stage 4. */ \
{ \
	vector signed short lo_0_16  = vec_mergeh(in[0], in[16]); \
	vector signed short hi_0_16  = vec_mergel(in[0], in[16]); \
	vector signed short lo_8_24  = vec_mergeh(in[8], in[24]); \
	vector signed short hi_8_24  = vec_mergel(in[8], in[24]); \
  \
	vector signed short lo_9_14  = vec_mergeh(stp1_9, stp1_14); \
	vector signed short hi_9_14  = vec_mergel(stp1_9, stp1_14); \
	vector signed short lo_10_13 = vec_mergeh(stp1_10, stp1_13); \
	vector signed short hi_10_13 = vec_mergel(stp1_10, stp1_13); \
  \
	MULTIPLICATION_AND_ADD(lo_0_16, hi_0_16, lo_8_24, hi_8_24, stg4_0, \
				stg4_1, stg4_2, stg4_3, stp2_0, stp2_1, \
				stp2_2, stp2_3) \
  \
	stp2_4 = vec_add(stp1_4, stp1_5); \
	stp2_5 = vec_sub(stp1_4, stp1_5); \
	stp2_6 = vec_sub(stp1_7, stp1_6); \
	stp2_7 = vec_add(stp1_7, stp1_6); \
  \
	MULTIPLICATION_AND_ADD(lo_9_14, hi_9_14, lo_10_13, hi_10_13, stg4_4, \
				stg4_5, stg4_6, stg4_4, stp2_9, stp2_14, \
				stp2_10, stp2_13) \
  \
	stp2_8  = stp1_8; \
	stp2_15 = stp1_15; \
	stp2_11 = stp1_11; \
	stp2_12 = stp1_12; \
  \
	stp2_16 = vec_add(stp1_16, stp1_19); \
	stp2_17 = vec_add(stp1_17, stp1_18); \
	stp2_18 = vec_sub(stp1_17, stp1_18); \
	stp2_19 = vec_sub(stp1_16, stp1_19); \
	stp2_20 = vec_sub(stp1_23, stp1_20); \
	stp2_21 = vec_sub(stp1_22, stp1_21); \
	stp2_22 = vec_add(stp1_22, stp1_21); \
	stp2_23 = vec_add(stp1_23, stp1_20); \
  \
	stp2_24 = vec_add(stp1_24, stp1_27); \
	stp2_25 = vec_add(stp1_25, stp1_26); \
	stp2_26 = vec_sub(stp1_25, stp1_26); \
	stp2_27 = vec_sub(stp1_24, stp1_27); \
	stp2_28 = vec_sub(stp1_31, stp1_28); \
	stp2_29 = vec_sub(stp1_30, stp1_29); \
	stp2_30 = vec_add(stp1_29, stp1_30); \
	stp2_31 = vec_add(stp1_28, stp1_31); \
} \
\
/* Stage 5. */ \
{ \
	vector signed short lo_6_5   = vec_mergeh(stp2_6, stp2_5); \
	vector signed short hi_6_5   = vec_mergel(stp2_6, stp2_5); \
	vector signed short lo_18_29 = vec_mergeh(stp2_18, stp2_29); \
	vector signed short hi_18_29 = vec_mergel(stp2_18, stp2_29); \
  \
	vector signed short lo_19_28 = vec_mergeh(stp2_19, stp2_28); \
	vector signed short hi_19_28 = vec_mergel(stp2_19, stp2_28); \
	vector signed short lo_20_27 = vec_mergeh(stp2_20, stp2_27); \
	vector signed short hi_20_27 = vec_mergel(stp2_20, stp2_27); \
  \
	vector signed short lo_21_26 = vec_mergeh(stp2_21, stp2_26); \
	vector signed short hi_21_26 = vec_mergel(stp2_21, stp2_26); \
  \
	stp1_0 = vec_add(stp2_0, stp2_3); \
	stp1_1 = vec_add(stp2_1, stp2_2); \
	stp1_2 = vec_sub(stp2_1, stp2_2); \
	stp1_3 = vec_sub(stp2_0, stp2_3); \
  \
	tmp0 = vec_msum(lo_6_5, stg4_1, dct_rounding_vec); \
	tmp1 = vec_msum(hi_6_5, stg4_1, dct_rounding_vec); \
	tmp2 = vec_msum(lo_6_5, stg4_0, dct_rounding_vec); \
	tmp3 = vec_msum(hi_6_5, stg4_0, dct_rounding_vec); \
  \
	tmp0 = vec_sra(tmp0, dct_bitshift_vec); \
	tmp1 = vec_sra(tmp1, dct_bitshift_vec); \
	tmp2 = vec_sra(tmp2, dct_bitshift_vec); \
	tmp3 = vec_sra(tmp3, dct_bitshift_vec); \
  \
	stp1_5 = vec_packs(tmp0, tmp1); \
	stp1_6 = vec_packs(tmp2, tmp3); \
  \
	stp1_4 = stp2_4; \
	stp1_7 = stp2_7; \
  \
	stp1_8  = vec_add(stp2_8, stp2_11); \
	stp1_9  = vec_add(stp2_9, stp2_10); \
	stp1_10 = vec_sub(stp2_9, stp2_10); \
	stp1_11 = vec_sub(stp2_8, stp2_11); \
	stp1_12 = vec_sub(stp2_15, stp2_12); \
	stp1_13 = vec_sub(stp2_14, stp2_13); \
	stp1_14 = vec_add(stp2_14, stp2_13); \
	stp1_15 = vec_add(stp2_15, stp2_12); \
  \
	stp1_16 = stp2_16; \
	stp1_17 = stp2_17; \
  \
	MULTIPLICATION_AND_ADD(lo_18_29, hi_18_29, lo_19_28, hi_19_28, stg4_4, \
				stg4_5, stg4_4, stg4_5, stp1_18, stp1_29, \
				stp1_19, stp1_28) \
	MULTIPLICATION_AND_ADD(lo_20_27, hi_20_27, lo_21_26, hi_21_26, stg4_6, \
				stg4_4, stg4_6, stg4_4, stp1_20, stp1_27, \
				stp1_21, stp1_26) \
  \
	stp1_22 = stp2_22; \
	stp1_23 = stp2_23; \
	stp1_24 = stp2_24; \
	stp1_25 = stp2_25; \
	stp1_30 = stp2_30; \
	stp1_31 = stp2_31; \
} \
\
/* Stage 6. */ \
{ \
	vector signed short lo_10_13 = vec_mergeh(stp1_10, stp1_13); \
	vector signed short hi_10_13 = vec_mergel(stp1_10, stp1_13); \
	vector signed short lo_11_12 = vec_mergeh(stp1_11, stp1_12); \
	vector signed short hi_11_12 = vec_mergel(stp1_11, stp1_12); \
  \
	stp2_0 = vec_add(stp1_0, stp1_7); \
	stp2_1 = vec_add(stp1_1, stp1_6); \
	stp2_2 = vec_add(stp1_2, stp1_5); \
	stp2_3 = vec_add(stp1_3, stp1_4); \
	stp2_4 = vec_sub(stp1_3, stp1_4); \
	stp2_5 = vec_sub(stp1_2, stp1_5); \
	stp2_6 = vec_sub(stp1_1, stp1_6); \
	stp2_7 = vec_sub(stp1_0, stp1_7); \
  \
	stp2_8 = stp1_8; \
	stp2_9 = stp1_9; \
	stp2_14 = stp1_14; \
	stp2_15 = stp1_15; \
  \
	MULTIPLICATION_AND_ADD(lo_10_13, hi_10_13, lo_11_12, hi_11_12, \
				stg6_0, stg4_0, stg6_0, stg4_0, stp2_10, \
				stp2_13, stp2_11, stp2_12) \
  \
	stp2_16 = vec_add(stp1_16, stp1_23); \
	stp2_17 = vec_add(stp1_17, stp1_22); \
	stp2_18 = vec_add(stp1_18, stp1_21); \
	stp2_19 = vec_add(stp1_19, stp1_20); \
	stp2_20 = vec_sub(stp1_19, stp1_20); \
	stp2_21 = vec_sub(stp1_18, stp1_21); \
	stp2_22 = vec_sub(stp1_17, stp1_22); \
	stp2_23 = vec_sub(stp1_16, stp1_23); \
  \
	stp2_24 = vec_sub(stp1_31, stp1_24); \
	stp2_25 = vec_sub(stp1_30, stp1_25); \
	stp2_26 = vec_sub(stp1_29, stp1_26); \
	stp2_27 = vec_sub(stp1_28, stp1_27); \
	stp2_28 = vec_add(stp1_27, stp1_28); \
	stp2_29 = vec_add(stp1_26, stp1_29); \
	stp2_30 = vec_add(stp1_25, stp1_30); \
	stp2_31 = vec_add(stp1_24, stp1_31); \
} \
\
/* Stage 7. */ \
{ \
	vector signed short lo_20_27 = vec_mergeh(stp2_20, stp2_27); \
	vector signed short hi_20_27 = vec_mergel(stp2_20, stp2_27); \
	vector signed short lo_21_26 = vec_mergeh(stp2_21, stp2_26); \
	vector signed short hi_21_26 = vec_mergel(stp2_21, stp2_26); \
  \
	vector signed short lo_22_25 = vec_mergeh(stp2_22, stp2_25); \
	vector signed short hi_22_25 = vec_mergel(stp2_22, stp2_25); \
	vector signed short lo_23_24 = vec_mergeh(stp2_23, stp2_24); \
	vector signed short hi_23_24 = vec_mergel(stp2_23, stp2_24); \
  \
	stp1_0  = vec_add(stp2_0, stp2_15); \
	stp1_1  = vec_add(stp2_1, stp2_14); \
	stp1_2  = vec_add(stp2_2, stp2_13); \
	stp1_3  = vec_add(stp2_3, stp2_12); \
	stp1_4  = vec_add(stp2_4, stp2_11); \
	stp1_5  = vec_add(stp2_5, stp2_10); \
	stp1_6  = vec_add(stp2_6, stp2_9); \
	stp1_7  = vec_add(stp2_7, stp2_8); \
	stp1_8  = vec_sub(stp2_7, stp2_8); \
	stp1_9  = vec_sub(stp2_6, stp2_9); \
	stp1_10 = vec_sub(stp2_5, stp2_10); \
	stp1_11 = vec_sub(stp2_4, stp2_11); \
	stp1_12 = vec_sub(stp2_3, stp2_12); \
	stp1_13 = vec_sub(stp2_2, stp2_13); \
	stp1_14 = vec_sub(stp2_1, stp2_14); \
	stp1_15 = vec_sub(stp2_0, stp2_15); \
  \
	stp1_16 = stp2_16; \
	stp1_17 = stp2_17; \
	stp1_18 = stp2_18; \
	stp1_19 = stp2_19; \
  \
	MULTIPLICATION_AND_ADD(lo_20_27, hi_20_27, lo_21_26, hi_21_26, stg6_0, \
				stg4_0, stg6_0, stg4_0, stp1_20, stp1_27, \
				stp1_21, stp1_26) \
	MULTIPLICATION_AND_ADD(lo_22_25, hi_22_25, lo_23_24, hi_23_24, stg6_0, \
				stg4_0, stg6_0, stg4_0, stp1_22, stp1_25, \
				stp1_23, stp1_24) \
  \
	stp1_28 = stp2_28; \
	stp1_29 = stp2_29; \
	stp1_30 = stp2_30; \
	stp1_31 = stp2_31; \
}

void vp9_idct32x32_1024_add_vmx(const int16_t *input, uint8_t *dest,
                                 int stride) {
	vector signed short stg1_0 = short_pair_a(cospi_31_64, -cospi_1_64);
	vector signed short stg1_1 = short_pair_a(cospi_1_64, cospi_31_64);
	vector signed short stg1_2 = short_pair_a(cospi_15_64, -cospi_17_64);
	vector signed short stg1_3 = short_pair_a(cospi_17_64, cospi_15_64);
	vector signed short stg1_4 = short_pair_a(cospi_23_64, -cospi_9_64);
	vector signed short stg1_5 = short_pair_a(cospi_9_64, cospi_23_64);
	vector signed short stg1_6 = short_pair_a(cospi_7_64, -cospi_25_64);
	vector signed short stg1_7 = short_pair_a(cospi_25_64, cospi_7_64);
	vector signed short stg1_8 = short_pair_a(cospi_27_64, -cospi_5_64);
	vector signed short stg1_9 = short_pair_a(cospi_5_64, cospi_27_64);
	vector signed short stg1_10 = short_pair_a(cospi_11_64, -cospi_21_64);
	vector signed short stg1_11 = short_pair_a(cospi_21_64, cospi_11_64);
	vector signed short stg1_12 = short_pair_a(cospi_19_64, -cospi_13_64);
	vector signed short stg1_13 = short_pair_a(cospi_13_64, cospi_19_64);
	vector signed short stg1_14 = short_pair_a(cospi_3_64, -cospi_29_64);
	vector signed short stg1_15 = short_pair_a(cospi_29_64, cospi_3_64);

	vector signed short stg2_0 = short_pair_a(cospi_30_64, -cospi_2_64);
	vector signed short stg2_1 = short_pair_a(cospi_2_64, cospi_30_64);
	vector signed short stg2_2 = short_pair_a(cospi_14_64, -cospi_18_64);
	vector signed short stg2_3 = short_pair_a(cospi_18_64, cospi_14_64);
	vector signed short stg2_4 = short_pair_a(cospi_22_64, -cospi_10_64);
	vector signed short stg2_5 = short_pair_a(cospi_10_64, cospi_22_64);
	vector signed short stg2_6 = short_pair_a(cospi_6_64, -cospi_26_64);
	vector signed short stg2_7 = short_pair_a(cospi_26_64, cospi_6_64);

	vector signed short stg3_0 = short_pair_a(cospi_28_64, -cospi_4_64);
	vector signed short stg3_1 = short_pair_a(cospi_4_64, cospi_28_64);
	vector signed short stg3_2 = short_pair_a(cospi_12_64, -cospi_20_64);
	vector signed short stg3_3 = short_pair_a(cospi_20_64, cospi_12_64);
	vector signed short stg3_4 = short_pair_a(-cospi_4_64, cospi_28_64);
	vector signed short stg3_5 = short_pair_a(cospi_28_64, cospi_4_64);
	vector signed short stg3_6 = short_pair_a(-cospi_28_64, -cospi_4_64);
	vector signed short stg3_8 = short_pair_a(-cospi_20_64, cospi_12_64);
	vector signed short stg3_9 = short_pair_a(cospi_12_64, cospi_20_64);
	vector signed short stg3_10 = short_pair_a(-cospi_12_64, -cospi_20_64);

	vector signed short stg4_0 = short_pair_a(cospi_16_64, cospi_16_64);
	vector signed short stg4_1 = short_pair_a(cospi_16_64, -cospi_16_64);
	vector signed short stg4_2 = short_pair_a(cospi_24_64, -cospi_8_64);
	vector signed short stg4_3 = short_pair_a(cospi_8_64, cospi_24_64);
	vector signed short stg4_4 = short_pair_a(-cospi_8_64, cospi_24_64);
	vector signed short stg4_5 = short_pair_a(cospi_24_64, cospi_8_64);
	vector signed short stg4_6 = short_pair_a(-cospi_24_64, -cospi_8_64);

	vector signed short stg6_0 = short_pair_a(-cospi_16_64, cospi_16_64);
	vector signed short in[32], col[128], zero_idx[16], i0;
	vector signed short stp1_0, stp1_1, stp1_2, stp1_3, stp1_4, stp1_5, stp1_6, stp1_7,
		stp1_8, stp1_9, stp1_10, stp1_11, stp1_12, stp1_13, stp1_14, stp1_15,
		stp1_16, stp1_17, stp1_18, stp1_19, stp1_20, stp1_21, stp1_22,
		stp1_23, stp1_24, stp1_25, stp1_26, stp1_27, stp1_28, stp1_29,
		stp1_30, stp1_31;
	vector signed short stp2_0, stp2_1, stp2_2, stp2_3, stp2_4, stp2_5, stp2_6, stp2_7,
		stp2_8, stp2_9, stp2_10, stp2_11, stp2_12, stp2_13, stp2_14, stp2_15,
		stp2_16, stp2_17, stp2_18, stp2_19, stp2_20, stp2_21, stp2_22,
		stp2_23, stp2_24, stp2_25, stp2_26, stp2_27, stp2_28, stp2_29,
		stp2_30, stp2_31;
	vector signed int tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
	int i, j, i32;
	vector signed short zero = vec_splat_u16(0);
	vector unsigned char zero_c = vec_splat_u8(0);
	vector unsigned short one = vec_splat_u16(1);
	vector unsigned short five = vec_splat_u16(5);
	vector unsigned short six = vec_splat_u16(6);
	vector signed short final_rounding;
	vector unsigned int ltemp;
	vector unsigned char p0;

	final_rounding = vec_rl(one, five);
	
	for(i=0;i<4;i++) {
		// 1-D IDCT.
		// Load next block.
		i32 = (i << 5);
		
		in[0]  = vec_ld(0,   (uint32_t *)input);
		in[8]  = vec_ld(16,  (uint32_t *)input);
		in[16] = vec_ld(32,  (uint32_t *)input);
		in[24] = vec_ld(48,  (uint32_t *)input);
		in[1]  = vec_ld(64,  (uint32_t *)input);
		in[9]  = vec_ld(80,  (uint32_t *)input);
		in[17] = vec_ld(96,  (uint32_t *)input);
		in[25] = vec_ld(112, (uint32_t *)input);
		in[2]  = vec_ld(128, (uint32_t *)input);
		in[10] = vec_ld(144, (uint32_t *)input);
		in[18] = vec_ld(160, (uint32_t *)input);
		in[26] = vec_ld(176, (uint32_t *)input);
		in[3]  = vec_ld(192, (uint32_t *)input);
		in[11] = vec_ld(208, (uint32_t *)input);
		in[19] = vec_ld(224, (uint32_t *)input);
		in[27] = vec_ld(240, (uint32_t *)input);
		in[4]  = vec_ld(256, (uint32_t *)input);
		in[12] = vec_ld(272, (uint32_t *)input);
		in[20] = vec_ld(288, (uint32_t *)input);
		in[28] = vec_ld(304, (uint32_t *)input);
		in[5]  = vec_ld(320, (uint32_t *)input);
		in[13] = vec_ld(336, (uint32_t *)input);
		in[21] = vec_ld(352, (uint32_t *)input);
		in[29] = vec_ld(368, (uint32_t *)input);
		in[6]  = vec_ld(384, (uint32_t *)input);
		in[14] = vec_ld(400, (uint32_t *)input);
		in[22] = vec_ld(416, (uint32_t *)input);
		in[30] = vec_ld(432, (uint32_t *)input);
		in[7]  = vec_ld(448, (uint32_t *)input);
		in[15] = vec_ld(464, (uint32_t *)input);
		in[23] = vec_ld(480, (uint32_t *)input);
		in[31] = vec_ld(496, (uint32_t *)input);
		input += 256;
		
		// Are all entries zero? If so, the result is zero.
		// (Just |or| everything together and test for zero vector equality.)
		// To consider: how often does this happen? Is this check worth it?
		zero_idx[0]  = vec_or(in[0],  in[1]);
		zero_idx[1]  = vec_or(in[2],  in[3]);
		zero_idx[2]  = vec_or(in[4],  in[5]);
		zero_idx[3]  = vec_or(in[6],  in[7]);
		zero_idx[4]  = vec_or(in[8],  in[9]);
		zero_idx[5]  = vec_or(in[10], in[11]);
		zero_idx[6]  = vec_or(in[12], in[13]);
		zero_idx[7]  = vec_or(in[14], in[15]);
		zero_idx[8]  = vec_or(in[16], in[17]);
		zero_idx[9]  = vec_or(in[18], in[19]);
		zero_idx[10] = vec_or(in[20], in[21]);
		zero_idx[11] = vec_or(in[22], in[23]);
		zero_idx[12] = vec_or(in[24], in[25]);
		zero_idx[13] = vec_or(in[26], in[27]);
		zero_idx[14] = vec_or(in[28], in[29]);
		zero_idx[15] = vec_or(in[30], in[31]);

		zero_idx[0]  = vec_or(zero_idx[0],  zero_idx[1]);
		zero_idx[1]  = vec_or(zero_idx[2],  zero_idx[3]);
		zero_idx[2]  = vec_or(zero_idx[4],  zero_idx[5]);
		zero_idx[3]  = vec_or(zero_idx[6],  zero_idx[7]);
		zero_idx[4]  = vec_or(zero_idx[8],  zero_idx[9]);
		zero_idx[5]  = vec_or(zero_idx[10], zero_idx[11]);
		zero_idx[6]  = vec_or(zero_idx[12], zero_idx[13]);
		zero_idx[7]  = vec_or(zero_idx[14], zero_idx[15]);
		
		zero_idx[8]  = vec_or(zero_idx[0],  zero_idx[1]);
		zero_idx[9]  = vec_or(zero_idx[2],  zero_idx[3]);
		zero_idx[10] = vec_or(zero_idx[4],  zero_idx[5]);
		zero_idx[11] = vec_or(zero_idx[6],  zero_idx[7]);
		zero_idx[12] = vec_or(zero_idx[8],  zero_idx[9]);
		zero_idx[13] = vec_or(zero_idx[10], zero_idx[11]);
		zero_idx[14] = vec_or(zero_idx[12], zero_idx[13]);

		if(vec_all_eq(zero_idx[14], zero)) {
			col[i32 +  0] = vec_splat_u16(0);
			col[i32 +  1] = vec_splat_u16(0);
			col[i32 +  2] = vec_splat_u16(0);
			col[i32 +  3] = vec_splat_u16(0);
			col[i32 +  4] = vec_splat_u16(0);
			col[i32 +  5] = vec_splat_u16(0);
			col[i32 +  6] = vec_splat_u16(0);
			col[i32 +  7] = vec_splat_u16(0);
			col[i32 +  8] = vec_splat_u16(0);
			col[i32 +  9] = vec_splat_u16(0);
			col[i32 + 10] = vec_splat_u16(0);
			col[i32 + 11] = vec_splat_u16(0);
			col[i32 + 12] = vec_splat_u16(0);
			col[i32 + 13] = vec_splat_u16(0);
			col[i32 + 14] = vec_splat_u16(0);
			col[i32 + 15] = vec_splat_u16(0);
			col[i32 + 16] = vec_splat_u16(0);
			col[i32 + 17] = vec_splat_u16(0);
			col[i32 + 18] = vec_splat_u16(0);
			col[i32 + 19] = vec_splat_u16(0);
			col[i32 + 20] = vec_splat_u16(0);
			col[i32 + 21] = vec_splat_u16(0);
			col[i32 + 22] = vec_splat_u16(0);
			col[i32 + 23] = vec_splat_u16(0);
			col[i32 + 24] = vec_splat_u16(0);
			col[i32 + 25] = vec_splat_u16(0);
			col[i32 + 26] = vec_splat_u16(0);
			col[i32 + 27] = vec_splat_u16(0);
			col[i32 + 28] = vec_splat_u16(0);
			col[i32 + 29] = vec_splat_u16(0);
			col[i32 + 30] = vec_splat_u16(0);
			col[i32 + 31] = vec_splat_u16(0);
			continue;
		}
		
		// Transposition and computation.
		array_transpose_8x8(in,    in);
		array_transpose_8x8(in+8,  in+8);
		array_transpose_8x8(in+16, in+16);
		array_transpose_8x8(in+24, in+24);
		IDCT32
		
		// Store 2-D intermediates.
		col[i32 +  0] = vec_add(stp1_0,  stp1_31);
		col[i32 +  1] = vec_add(stp1_1,  stp1_30);
		col[i32 +  2] = vec_add(stp1_2,  stp1_29);
		col[i32 +  3] = vec_add(stp1_3,  stp1_28);
		col[i32 +  4] = vec_add(stp1_4,  stp1_27);
		col[i32 +  5] = vec_add(stp1_5,  stp1_26);
		col[i32 +  6] = vec_add(stp1_6,  stp1_25);
		col[i32 +  7] = vec_add(stp1_7,  stp1_24);
		col[i32 +  8] = vec_add(stp1_8,  stp1_23);
		col[i32 +  9] = vec_add(stp1_9,  stp1_22);
		col[i32 + 10] = vec_add(stp1_10, stp1_21);
		col[i32 + 11] = vec_add(stp1_11, stp1_20);
		col[i32 + 12] = vec_add(stp1_12, stp1_19);
		col[i32 + 13] = vec_add(stp1_13, stp1_18);
		col[i32 + 14] = vec_add(stp1_14, stp1_17);
		col[i32 + 15] = vec_add(stp1_15, stp1_16);
		col[i32 + 16] = vec_sub(stp1_15, stp1_16);
		col[i32 + 17] = vec_sub(stp1_14, stp1_17);
		col[i32 + 18] = vec_sub(stp1_13, stp1_18);
		col[i32 + 19] = vec_sub(stp1_12, stp1_19);
		col[i32 + 20] = vec_sub(stp1_11, stp1_20);
		col[i32 + 21] = vec_sub(stp1_10, stp1_21);
		col[i32 + 22] = vec_sub(stp1_9,  stp1_22);
		col[i32 + 23] = vec_sub(stp1_8,  stp1_23);
		col[i32 + 24] = vec_sub(stp1_7,  stp1_24);
		col[i32 + 25] = vec_sub(stp1_6,  stp1_25);
		col[i32 + 26] = vec_sub(stp1_5,  stp1_26);
		col[i32 + 27] = vec_sub(stp1_4,  stp1_27);
		col[i32 + 28] = vec_sub(stp1_3,  stp1_28);
		col[i32 + 29] = vec_sub(stp1_2,  stp1_29);
		col[i32 + 30] = vec_sub(stp1_1,  stp1_30);
		col[i32 + 31] = vec_sub(stp1_0,  stp1_31);
	}
	// Second 1-D IDCT.
	for(i=0;i<4;i++) {
		j = i << 3;
		
		// Transposition and computation from intermediates.
		array_transpose_8x8(col+j,    in);
		array_transpose_8x8(col+j+32, in+8);
		array_transpose_8x8(col+j+64, in+16);
		array_transpose_8x8(col+j+96, in+24);
		IDCT32
		
		// Compute 2-D results.
		in[0]  = vec_add(stp1_0,  stp1_31);
		in[1]  = vec_add(stp1_1,  stp1_30);
		in[2]  = vec_add(stp1_2,  stp1_29);
		in[3]  = vec_add(stp1_3,  stp1_28);
		in[4]  = vec_add(stp1_4,  stp1_27);
		in[5]  = vec_add(stp1_5,  stp1_26);
		in[6]  = vec_add(stp1_6,  stp1_25);
		in[7]  = vec_add(stp1_7,  stp1_24);
		in[8]  = vec_add(stp1_8,  stp1_23);
		in[9]  = vec_add(stp1_9,  stp1_22);
		in[10] = vec_add(stp1_10, stp1_21);
		in[11] = vec_add(stp1_11, stp1_20);
		in[12] = vec_add(stp1_12, stp1_19);
		in[13] = vec_add(stp1_13, stp1_18);
		in[14] = vec_add(stp1_14, stp1_17);
		in[15] = vec_add(stp1_15, stp1_16);
		in[16] = vec_sub(stp1_15, stp1_16);
		in[17] = vec_sub(stp1_14, stp1_17);
		in[18] = vec_sub(stp1_13, stp1_18);
		in[19] = vec_sub(stp1_12, stp1_19);
		in[20] = vec_sub(stp1_11, stp1_20);
		in[21] = vec_sub(stp1_10, stp1_21);
		in[22] = vec_sub(stp1_9,  stp1_22);
		in[23] = vec_sub(stp1_8,  stp1_23);
		in[24] = vec_sub(stp1_7,  stp1_24);
		in[25] = vec_sub(stp1_6,  stp1_25);
		in[26] = vec_sub(stp1_5,  stp1_26);
		in[27] = vec_sub(stp1_4,  stp1_27);
		in[28] = vec_sub(stp1_3,  stp1_28);
		in[29] = vec_sub(stp1_2,  stp1_29);
		in[30] = vec_sub(stp1_1,  stp1_30);
		in[31] = vec_sub(stp1_0,  stp1_31);
		
		// Round, shift, reconstitute and store.
		for(j=0;j<32;++j) {
			in[j] = vec_adds(in[j], final_rounding);
			in[j] = vec_sra(in[j], six);
			
			_unaligned_load64(p0, (uint32_t *)(dest + j * stride));
			i0 = (vector signed short)vec_mergeh(zero_c, p0);
			i0 = vec_add(in[j], i0);
			p0 = vec_packsu(i0, i0);
			_unaligned_store64(p0, ltemp, (uint32_t *)(dest + j * stride));
		}
		dest += 8;
	}
}

static inline void array_transpose_16x16(vector signed short *res0, vector signed short *res1) {
	vector signed short tbuf[8];
	array_transpose_8x8(res0,   res0);
	array_transpose_8x8(res1,   tbuf);
	array_transpose_8x8(res0+8, res1);
	array_transpose_8x8(res1+8, res1 + 8);

	res0[8]  = tbuf[0];
	res0[9]  = tbuf[1];
	res0[10] = tbuf[2];
	res0[11] = tbuf[3];
	res0[12] = tbuf[4];
	res0[13] = tbuf[5];
	res0[14] = tbuf[6];
	res0[15] = tbuf[7];
}

static inline void load_buffer_8x16(const int16_t *input, vector signed short *in) {
  	in[0]  = vec_ld(0,   (uint32_t *)input);
  	in[1]  = vec_ld(32,  (uint32_t *)input);
  	in[2]  = vec_ld(64,  (uint32_t *)input);
  	in[3]  = vec_ld(96,  (uint32_t *)input);
  	in[4]  = vec_ld(128, (uint32_t *)input);
  	in[5]  = vec_ld(160, (uint32_t *)input);
  	in[6]  = vec_ld(192, (uint32_t *)input);
  	in[7]  = vec_ld(224, (uint32_t *)input);
  	in[8]  = vec_ld(256, (uint32_t *)input);
  	in[9]  = vec_ld(288, (uint32_t *)input);
  	in[10] = vec_ld(320, (uint32_t *)input);
  	in[11] = vec_ld(352, (uint32_t *)input);
  	in[12] = vec_ld(384, (uint32_t *)input);
  	in[13] = vec_ld(416, (uint32_t *)input);
  	in[14] = vec_ld(448, (uint32_t *)input);
  	in[15] = vec_ld(480, (uint32_t *)input);
}

static inline void write_buffer_8x16(uint8_t *dest, vector signed short *in, int stride) {
	vector unsigned char zero_c = vec_splat_u8(0);
	vector unsigned short one = vec_splat_u16(1);
	vector unsigned short five = vec_splat_u16(5);
	vector unsigned short six = vec_splat_u16(6);
	vector signed short final_rounding, i0;
	vector unsigned int ltemp;
	vector unsigned char p0;
	int i;
	
	final_rounding = vec_rl(one, five);
	
	// Round, shift, reconstitute and store, again.
	for(i=0;i<16;i++) {
		in[i] = vec_adds(in[i], final_rounding);
		in[i] = vec_sra(in[i], six);

		_unaligned_load64(p0, (uint32_t *)(dest + i * stride));
		i0 = (vector signed short)vec_mergeh(zero_c, p0);
		i0 = vec_add(in[i], i0);
		p0 = vec_packsu(i0, i0);
		_unaligned_store64(p0, ltemp, (uint32_t *)(dest + i * stride));
	}
}	

// It's time for INTRINSIC HELL.
// First tarpit: performing an 16x16 1-D inverse ADST on eight columns.
static void iadst16_8col(vector signed short *in) {
	vector signed short s[16], x[16], u[32];
	vector signed int v[32], w[32];
	vector signed short k__cospi_p01_p31 = short_pair_a(cospi_1_64, cospi_31_64);
	vector signed short k__cospi_p31_m01 = short_pair_a(cospi_31_64, -cospi_1_64);
	vector signed short k__cospi_p05_p27 = short_pair_a(cospi_5_64, cospi_27_64);
	vector signed short k__cospi_p27_m05 = short_pair_a(cospi_27_64, -cospi_5_64);
	vector signed short k__cospi_p09_p23 = short_pair_a(cospi_9_64, cospi_23_64);
	vector signed short k__cospi_p23_m09 = short_pair_a(cospi_23_64, -cospi_9_64);
	vector signed short k__cospi_p13_p19 = short_pair_a(cospi_13_64, cospi_19_64);
	vector signed short k__cospi_p19_m13 = short_pair_a(cospi_19_64, -cospi_13_64);
	vector signed short k__cospi_p17_p15 = short_pair_a(cospi_17_64, cospi_15_64);
	vector signed short k__cospi_p15_m17 = short_pair_a(cospi_15_64, -cospi_17_64);
	vector signed short k__cospi_p21_p11 = short_pair_a(cospi_21_64, cospi_11_64);
	vector signed short k__cospi_p11_m21 = short_pair_a(cospi_11_64, -cospi_21_64);
	vector signed short k__cospi_p25_p07 = short_pair_a(cospi_25_64, cospi_7_64);
	vector signed short k__cospi_p07_m25 = short_pair_a(cospi_7_64, -cospi_25_64);
	vector signed short k__cospi_p29_p03 = short_pair_a(cospi_29_64, cospi_3_64);
	vector signed short k__cospi_p03_m29 = short_pair_a(cospi_3_64, -cospi_29_64);
	vector signed short k__cospi_p04_p28 = short_pair_a(cospi_4_64, cospi_28_64);
	vector signed short k__cospi_p28_m04 = short_pair_a(cospi_28_64, -cospi_4_64);
	vector signed short k__cospi_p20_p12 = short_pair_a(cospi_20_64, cospi_12_64);
	vector signed short k__cospi_p12_m20 = short_pair_a(cospi_12_64, -cospi_20_64);
	vector signed short k__cospi_m28_p04 = short_pair_a(-cospi_28_64, cospi_4_64);
	vector signed short k__cospi_m12_p20 = short_pair_a(-cospi_12_64, cospi_20_64);
	vector signed short k__cospi_p08_p24 = short_pair_a(cospi_8_64, cospi_24_64);
	vector signed short k__cospi_p24_m08 = short_pair_a(cospi_24_64, -cospi_8_64);
	vector signed short k__cospi_m24_p08 = short_pair_a(-cospi_24_64, cospi_8_64);
	vector signed short k__cospi_m16_m16;
	vector signed short k__cospi_p16_p16;
	vector signed short k__cospi_p16_m16 = short_pair_a(cospi_16_64, -cospi_16_64);
	vector signed short k__cospi_m16_p16 = short_pair_a(-cospi_16_64, cospi_16_64);
	vector signed short kZero = vec_splat_u16(0);
	vector signed int mzero = vec_splat_u16(0);
	
	signed short a_s = ((int16_t)-cospi_16_64);
	signed short b_s = ((int16_t)cospi_16_64);
	k__cospi_m16_m16 = ss_splat(&a_s);
	k__cospi_p16_p16 = ss_splat(&b_s);

	// Stage 1.
	u[0]  = vec_mergeh(in[15], in[0]);
	u[1]  = vec_mergel(in[15], in[0]);
	u[2]  = vec_mergeh(in[13], in[2]);
	u[3]  = vec_mergel(in[13], in[2]);
	u[4]  = vec_mergeh(in[11], in[4]);
	u[5]  = vec_mergel(in[11], in[4]);
	u[6]  = vec_mergeh(in[9],  in[6]);
	u[7]  = vec_mergel(in[9],  in[6]);
	u[8]  = vec_mergeh(in[7],  in[8]);
	u[9]  = vec_mergel(in[7],  in[8]);
	u[10] = vec_mergeh(in[5],  in[10]);
	u[11] = vec_mergel(in[5],  in[10]);
	u[12] = vec_mergeh(in[3],  in[12]);
	u[13] = vec_mergel(in[3],  in[12]);
	u[14] = vec_mergeh(in[1],  in[14]);
	u[15] = vec_mergel(in[1],  in[14]);

	// Unfortunately no post-add is possible.
	v[0]  = vec_msum(u[0],  k__cospi_p01_p31, mzero);
	v[1]  = vec_msum(u[1],  k__cospi_p01_p31, mzero);
	v[2]  = vec_msum(u[0],  k__cospi_p31_m01, mzero);
	v[3]  = vec_msum(u[1],  k__cospi_p31_m01, mzero);
	v[4]  = vec_msum(u[2],  k__cospi_p05_p27, mzero);
	v[5]  = vec_msum(u[3],  k__cospi_p05_p27, mzero);
	v[6]  = vec_msum(u[2],  k__cospi_p27_m05, mzero);
	v[7]  = vec_msum(u[3],  k__cospi_p27_m05, mzero);
	v[8]  = vec_msum(u[4],  k__cospi_p09_p23, mzero);
	v[9]  = vec_msum(u[5],  k__cospi_p09_p23, mzero);
	v[10] = vec_msum(u[4],  k__cospi_p23_m09, mzero);
	v[11] = vec_msum(u[5],  k__cospi_p23_m09, mzero);
	v[12] = vec_msum(u[6],  k__cospi_p13_p19, mzero);
	v[13] = vec_msum(u[7],  k__cospi_p13_p19, mzero);
	v[14] = vec_msum(u[6],  k__cospi_p19_m13, mzero);
	v[15] = vec_msum(u[7],  k__cospi_p19_m13, mzero);
	v[16] = vec_msum(u[8],  k__cospi_p17_p15, mzero);
	v[17] = vec_msum(u[9],  k__cospi_p17_p15, mzero);
	v[18] = vec_msum(u[8],  k__cospi_p15_m17, mzero);
	v[19] = vec_msum(u[9],  k__cospi_p15_m17, mzero);
	v[20] = vec_msum(u[10], k__cospi_p21_p11, mzero);
	v[21] = vec_msum(u[11], k__cospi_p21_p11, mzero);
	v[22] = vec_msum(u[10], k__cospi_p11_m21, mzero);
	v[23] = vec_msum(u[11], k__cospi_p11_m21, mzero);
	v[24] = vec_msum(u[12], k__cospi_p25_p07, mzero);
	v[25] = vec_msum(u[13], k__cospi_p25_p07, mzero);
	v[26] = vec_msum(u[12], k__cospi_p07_m25, mzero);
	v[27] = vec_msum(u[13], k__cospi_p07_m25, mzero);
	v[28] = vec_msum(u[14], k__cospi_p29_p03, mzero);
	v[29] = vec_msum(u[15], k__cospi_p29_p03, mzero);
	v[30] = vec_msum(u[14], k__cospi_p03_m29, mzero);
	v[31] = vec_msum(u[15], k__cospi_p03_m29, mzero);

	w[0]  = vec_add(v[0],  v[16]);
	w[1]  = vec_add(v[1],  v[17]);
	w[2]  = vec_add(v[2],  v[18]);
	w[3]  = vec_add(v[3],  v[19]);
	w[4]  = vec_add(v[4],  v[20]);
	w[5]  = vec_add(v[5],  v[21]);
	w[6]  = vec_add(v[6],  v[22]);
	w[7]  = vec_add(v[7],  v[23]);
	w[8]  = vec_add(v[8],  v[24]);
	w[9]  = vec_add(v[9],  v[25]);
	w[10] = vec_add(v[10], v[26]);
	w[11] = vec_add(v[11], v[27]);
	w[12] = vec_add(v[12], v[28]);
	w[13] = vec_add(v[13], v[29]);
	w[14] = vec_add(v[14], v[30]);
	w[15] = vec_add(v[15], v[31]);
	w[16] = vec_sub(v[0],  v[16]);
	w[17] = vec_sub(v[1],  v[17]);
	w[18] = vec_sub(v[2],  v[18]);
	w[19] = vec_sub(v[3],  v[19]);
	w[20] = vec_sub(v[4],  v[20]);
	w[21] = vec_sub(v[5],  v[21]);
	w[22] = vec_sub(v[6],  v[22]);
	w[23] = vec_sub(v[7],  v[23]);
	w[24] = vec_sub(v[8],  v[24]);
	w[25] = vec_sub(v[9],  v[25]);
	w[26] = vec_sub(v[10], v[26]);
	w[27] = vec_sub(v[11], v[27]);
	w[28] = vec_sub(v[12], v[28]);
	w[29] = vec_sub(v[13], v[29]);
	w[30] = vec_sub(v[14], v[30]);
	w[31] = vec_sub(v[15], v[31]);

	v[0]  = vec_add(w[0],  dct_rounding_vec);
	v[1]  = vec_add(w[1],  dct_rounding_vec);
	v[2]  = vec_add(w[2],  dct_rounding_vec);
	v[3]  = vec_add(w[3],  dct_rounding_vec);
	v[4]  = vec_add(w[4],  dct_rounding_vec);
	v[5]  = vec_add(w[5],  dct_rounding_vec);
	v[6]  = vec_add(w[6],  dct_rounding_vec);
	v[7]  = vec_add(w[7],  dct_rounding_vec);
	v[8]  = vec_add(w[8],  dct_rounding_vec);
	v[9]  = vec_add(w[9],  dct_rounding_vec);
	v[10] = vec_add(w[10], dct_rounding_vec);
	v[11] = vec_add(w[11], dct_rounding_vec);
	v[12] = vec_add(w[12], dct_rounding_vec);
	v[13] = vec_add(w[13], dct_rounding_vec);
	v[14] = vec_add(w[14], dct_rounding_vec);
	v[15] = vec_add(w[15], dct_rounding_vec);
	v[16] = vec_add(w[16], dct_rounding_vec);
	v[17] = vec_add(w[17], dct_rounding_vec);
	v[18] = vec_add(w[18], dct_rounding_vec);
	v[19] = vec_add(w[19], dct_rounding_vec);
	v[20] = vec_add(w[20], dct_rounding_vec);
	v[21] = vec_add(w[21], dct_rounding_vec);
	v[22] = vec_add(w[22], dct_rounding_vec);
	v[23] = vec_add(w[23], dct_rounding_vec);
	v[24] = vec_add(w[24], dct_rounding_vec);
	v[25] = vec_add(w[25], dct_rounding_vec);
	v[26] = vec_add(w[26], dct_rounding_vec);
	v[27] = vec_add(w[27], dct_rounding_vec);
	v[28] = vec_add(w[28], dct_rounding_vec);
	v[29] = vec_add(w[29], dct_rounding_vec);
	v[30] = vec_add(w[30], dct_rounding_vec);
	v[31] = vec_add(w[31], dct_rounding_vec);

	w[0]  = vec_sra(v[0],  dct_bitshift_vec);
	w[1]  = vec_sra(v[1],  dct_bitshift_vec);
	w[2]  = vec_sra(v[2],  dct_bitshift_vec);
	w[3]  = vec_sra(v[3],  dct_bitshift_vec);
	w[4]  = vec_sra(v[4],  dct_bitshift_vec);
	w[5]  = vec_sra(v[5],  dct_bitshift_vec);
	w[6]  = vec_sra(v[6],  dct_bitshift_vec);
	w[7]  = vec_sra(v[7],  dct_bitshift_vec);
	w[8]  = vec_sra(v[8],  dct_bitshift_vec);
	w[9]  = vec_sra(v[9],  dct_bitshift_vec);
	w[10] = vec_sra(v[10], dct_bitshift_vec);
	w[11] = vec_sra(v[11], dct_bitshift_vec);
	w[12] = vec_sra(v[12], dct_bitshift_vec);
	w[13] = vec_sra(v[13], dct_bitshift_vec);
	w[14] = vec_sra(v[14], dct_bitshift_vec);
	w[15] = vec_sra(v[15], dct_bitshift_vec);
	w[16] = vec_sra(v[16], dct_bitshift_vec);
	w[17] = vec_sra(v[17], dct_bitshift_vec);
	w[18] = vec_sra(v[18], dct_bitshift_vec);
	w[19] = vec_sra(v[19], dct_bitshift_vec);
	w[20] = vec_sra(v[20], dct_bitshift_vec);
	w[21] = vec_sra(v[21], dct_bitshift_vec);
	w[22] = vec_sra(v[22], dct_bitshift_vec);
	w[23] = vec_sra(v[23], dct_bitshift_vec);
	w[24] = vec_sra(v[24], dct_bitshift_vec);
	w[25] = vec_sra(v[25], dct_bitshift_vec);
	w[26] = vec_sra(v[26], dct_bitshift_vec);
	w[27] = vec_sra(v[27], dct_bitshift_vec);
	w[28] = vec_sra(v[28], dct_bitshift_vec);
	w[29] = vec_sra(v[29], dct_bitshift_vec);
	w[30] = vec_sra(v[30], dct_bitshift_vec);
	w[31] = vec_sra(v[31], dct_bitshift_vec);

	s[0]  = vec_packs(w[0],  w[1]);
	s[1]  = vec_packs(w[2],  w[3]);
	s[2]  = vec_packs(w[4],  w[5]);
	s[3]  = vec_packs(w[6],  w[7]);
	s[4]  = vec_packs(w[8],  w[9]);
	s[5]  = vec_packs(w[10], w[11]);
	s[6]  = vec_packs(w[12], w[13]);
	s[7]  = vec_packs(w[14], w[15]);
	s[8]  = vec_packs(w[16], w[17]);
	s[9]  = vec_packs(w[18], w[19]);
	s[10] = vec_packs(w[20], w[21]);
	s[11] = vec_packs(w[22], w[23]);
	s[12] = vec_packs(w[24], w[25]);
	s[13] = vec_packs(w[26], w[27]);
	s[14] = vec_packs(w[28], w[29]);
	s[15] = vec_packs(w[30], w[31]);

	// Stage 2.
	u[0] = vec_mergeh(s[8],  s[9]);
	u[1] = vec_mergel(s[8],  s[9]);
	u[2] = vec_mergeh(s[10], s[11]);
	u[3] = vec_mergel(s[10], s[11]);
	u[4] = vec_mergeh(s[12], s[13]);
	u[5] = vec_mergel(s[12], s[13]);
	u[6] = vec_mergeh(s[14], s[15]);
	u[7] = vec_mergel(s[14], s[15]);

	v[0]  = vec_msum(u[0], k__cospi_p04_p28, mzero);
	v[1]  = vec_msum(u[1], k__cospi_p04_p28, mzero);
	v[2]  = vec_msum(u[0], k__cospi_p28_m04, mzero);
	v[3]  = vec_msum(u[1], k__cospi_p28_m04, mzero);
	v[4]  = vec_msum(u[2], k__cospi_p20_p12, mzero);
	v[5]  = vec_msum(u[3], k__cospi_p20_p12, mzero);
	v[6]  = vec_msum(u[2], k__cospi_p12_m20, mzero);
	v[7]  = vec_msum(u[3], k__cospi_p12_m20, mzero);
	v[8]  = vec_msum(u[4], k__cospi_m28_p04, mzero);
	v[9]  = vec_msum(u[5], k__cospi_m28_p04, mzero);
	v[10] = vec_msum(u[4], k__cospi_p04_p28, mzero);
	v[11] = vec_msum(u[5], k__cospi_p04_p28, mzero);
	v[12] = vec_msum(u[6], k__cospi_m12_p20, mzero);
	v[13] = vec_msum(u[7], k__cospi_m12_p20, mzero);
	v[14] = vec_msum(u[6], k__cospi_p20_p12, mzero);
	v[15] = vec_msum(u[7], k__cospi_p20_p12, mzero);

	w[0]  = vec_add(v[0], v[8]);
	w[1]  = vec_add(v[1], v[9]);
	w[2]  = vec_add(v[2], v[10]);
	w[3]  = vec_add(v[3], v[11]);
	w[4]  = vec_add(v[4], v[12]);
	w[5]  = vec_add(v[5], v[13]);
	w[6]  = vec_add(v[6], v[14]);
	w[7]  = vec_add(v[7], v[15]);
	w[8]  = vec_sub(v[0], v[8]);
	w[9]  = vec_sub(v[1], v[9]);
	w[10] = vec_sub(v[2], v[10]);
	w[11] = vec_sub(v[3], v[11]);
	w[12] = vec_sub(v[4], v[12]);
	w[13] = vec_sub(v[5], v[13]);
	w[14] = vec_sub(v[6], v[14]);
	w[15] = vec_sub(v[7], v[15]);

	v[0]  = vec_add(w[0],  dct_rounding_vec);
	v[1]  = vec_add(w[1],  dct_rounding_vec);
	v[2]  = vec_add(w[2],  dct_rounding_vec);
	v[3]  = vec_add(w[3],  dct_rounding_vec);
	v[4]  = vec_add(w[4],  dct_rounding_vec);
	v[5]  = vec_add(w[5],  dct_rounding_vec);
	v[6]  = vec_add(w[6],  dct_rounding_vec);
	v[7]  = vec_add(w[7],  dct_rounding_vec);
	v[8]  = vec_add(w[8],  dct_rounding_vec);
	v[9]  = vec_add(w[9],  dct_rounding_vec);
	v[10] = vec_add(w[10], dct_rounding_vec);
	v[11] = vec_add(w[11], dct_rounding_vec);
	v[12] = vec_add(w[12], dct_rounding_vec);
	v[13] = vec_add(w[13], dct_rounding_vec);
	v[14] = vec_add(w[14], dct_rounding_vec);
	v[15] = vec_add(w[15], dct_rounding_vec);

	w[0]  = vec_sra(v[0],  dct_bitshift_vec);
	w[1]  = vec_sra(v[1],  dct_bitshift_vec);
	w[2]  = vec_sra(v[2],  dct_bitshift_vec);
	w[3]  = vec_sra(v[3],  dct_bitshift_vec);
	w[4]  = vec_sra(v[4],  dct_bitshift_vec);
	w[5]  = vec_sra(v[5],  dct_bitshift_vec);
	w[6]  = vec_sra(v[6],  dct_bitshift_vec);
	w[7]  = vec_sra(v[7],  dct_bitshift_vec);
	w[8]  = vec_sra(v[8],  dct_bitshift_vec);
	w[9]  = vec_sra(v[9],  dct_bitshift_vec);
	w[10] = vec_sra(v[10], dct_bitshift_vec);
	w[11] = vec_sra(v[11], dct_bitshift_vec);
	w[12] = vec_sra(v[12], dct_bitshift_vec);
	w[13] = vec_sra(v[13], dct_bitshift_vec);
	w[14] = vec_sra(v[14], dct_bitshift_vec);
	w[15] = vec_sra(v[15], dct_bitshift_vec);

	x[0]  = vec_add(s[0], s[4]);
	x[1]  = vec_add(s[1], s[5]);
	x[2]  = vec_add(s[2], s[6]);
	x[3]  = vec_add(s[3], s[7]);
	x[4]  = vec_sub(s[0], s[4]);
	x[5]  = vec_sub(s[1], s[5]);
	x[6]  = vec_sub(s[2], s[6]);
	x[7]  = vec_sub(s[3], s[7]);
	
	x[8]  = vec_packs(w[0],  w[1]);
	x[9]  = vec_packs(w[2],  w[3]);
	x[10] = vec_packs(w[4],  w[5]);
	x[11] = vec_packs(w[6],  w[7]);
	x[12] = vec_packs(w[8],  w[9]);
	x[13] = vec_packs(w[10], w[11]);
	x[14] = vec_packs(w[12], w[13]);
	x[15] = vec_packs(w[14], w[15]);

	// Stage 3.
	u[0] = vec_mergeh(x[4],  x[5]);
	u[1] = vec_mergel(x[4],  x[5]);
	u[2] = vec_mergeh(x[6],  x[7]);
	u[3] = vec_mergel(x[6],  x[7]);
	u[4] = vec_mergeh(x[12], x[13]);
	u[5] = vec_mergel(x[12], x[13]);
	u[6] = vec_mergeh(x[14], x[15]);
	u[7] = vec_mergel(x[14], x[15]);

	v[0]  = vec_msum(u[0], k__cospi_p08_p24, mzero);
	v[1]  = vec_msum(u[1], k__cospi_p08_p24, mzero);
	v[2]  = vec_msum(u[0], k__cospi_p24_m08, mzero);
	v[3]  = vec_msum(u[1], k__cospi_p24_m08, mzero);
	v[4]  = vec_msum(u[2], k__cospi_m24_p08, mzero);
	v[5]  = vec_msum(u[3], k__cospi_m24_p08, mzero);
	v[6]  = vec_msum(u[2], k__cospi_p08_p24, mzero);
	v[7]  = vec_msum(u[3], k__cospi_p08_p24, mzero);
	v[8]  = vec_msum(u[4], k__cospi_p08_p24, mzero);
	v[9]  = vec_msum(u[5], k__cospi_p08_p24, mzero);
	v[10] = vec_msum(u[4], k__cospi_p24_m08, mzero);
	v[11] = vec_msum(u[5], k__cospi_p24_m08, mzero);
	v[12] = vec_msum(u[6], k__cospi_m24_p08, mzero);
	v[13] = vec_msum(u[7], k__cospi_m24_p08, mzero);
	v[14] = vec_msum(u[6], k__cospi_p08_p24, mzero);
	v[15] = vec_msum(u[7], k__cospi_p08_p24, mzero);

	w[0]  = vec_add(v[0],  v[4]);
	w[1]  = vec_add(v[1],  v[5]);
	w[2]  = vec_add(v[2],  v[6]);
	w[3]  = vec_add(v[3],  v[7]);
	w[4]  = vec_sub(v[0],  v[4]);
	w[5]  = vec_sub(v[1],  v[5]);
	w[6]  = vec_sub(v[2],  v[6]);
	w[7]  = vec_sub(v[3],  v[7]);
	w[8]  = vec_add(v[8],  v[12]);
	w[9]  = vec_add(v[9],  v[13]);
	w[10] = vec_add(v[10], v[14]);
	w[11] = vec_add(v[11], v[15]);
	w[12] = vec_sub(v[8],  v[12]);
	w[13] = vec_sub(v[9] , v[13]);
	w[14] = vec_sub(v[10], v[14]);
	w[15] = vec_sub(v[11], v[15]);

	w[0]  = vec_add(w[0],  dct_rounding_vec);
	w[1]  = vec_add(w[1],  dct_rounding_vec);
	w[2]  = vec_add(w[2],  dct_rounding_vec);
	w[3]  = vec_add(w[3],  dct_rounding_vec);
	w[4]  = vec_add(w[4],  dct_rounding_vec);
	w[5]  = vec_add(w[5],  dct_rounding_vec);
	w[6]  = vec_add(w[6],  dct_rounding_vec);
	w[7]  = vec_add(w[7],  dct_rounding_vec);
	w[8]  = vec_add(w[8],  dct_rounding_vec);
	w[9]  = vec_add(w[9],  dct_rounding_vec);
	w[10] = vec_add(w[10], dct_rounding_vec);
	w[11] = vec_add(w[11], dct_rounding_vec);
	w[12] = vec_add(w[12], dct_rounding_vec);
	w[13] = vec_add(w[13], dct_rounding_vec);
	w[14] = vec_add(w[14], dct_rounding_vec);
	w[15] = vec_add(w[15], dct_rounding_vec);

	v[0]  = vec_sra(w[0],  dct_bitshift_vec);
	v[1]  = vec_sra(w[1],  dct_bitshift_vec);
	v[2]  = vec_sra(w[2],  dct_bitshift_vec);
	v[3]  = vec_sra(w[3],  dct_bitshift_vec);
	v[4]  = vec_sra(w[4],  dct_bitshift_vec);
	v[5]  = vec_sra(w[5],  dct_bitshift_vec);
	v[6]  = vec_sra(w[6],  dct_bitshift_vec);
	v[7]  = vec_sra(w[7],  dct_bitshift_vec);
	v[8]  = vec_sra(w[8],  dct_bitshift_vec);
	v[9]  = vec_sra(w[9],  dct_bitshift_vec);
	v[10] = vec_sra(w[10], dct_bitshift_vec);
	v[11] = vec_sra(w[11], dct_bitshift_vec);
	v[12] = vec_sra(w[12], dct_bitshift_vec);
	v[13] = vec_sra(w[13], dct_bitshift_vec);
	v[14] = vec_sra(w[14], dct_bitshift_vec);
	v[15] = vec_sra(w[15], dct_bitshift_vec);

	s[0]  = vec_add(x[0], x[2]);
	s[1]  = vec_add(x[1], x[3]);
	s[2]  = vec_sub(x[0], x[2]);
	s[3]  = vec_sub(x[1], x[3]);
	
	s[4]  = vec_packs(v[0], v[1]);
	s[5]  = vec_packs(v[2], v[3]);
	s[6]  = vec_packs(v[4], v[5]);
	s[7]  = vec_packs(v[6], v[7]);
	
	s[8]  = vec_add(x[8], x[10]);
	s[9]  = vec_add(x[9], x[11]);
	s[10] = vec_sub(x[8], x[10]);
	s[11] = vec_sub(x[9], x[11]);
	
	s[12] = vec_packs(v[8],  v[9]);
	s[13] = vec_packs(v[10], v[11]);
	s[14] = vec_packs(v[12], v[13]);
	s[15] = vec_packs(v[14], v[15]);

	// Stage 4.
	u[0] = vec_mergeh(s[2],  s[3]);
	u[1] = vec_mergel(s[2],  s[3]);
	u[2] = vec_mergeh(s[6],  s[7]);
	u[3] = vec_mergel(s[6],  s[7]);
	u[4] = vec_mergeh(s[10], s[11]);
	u[5] = vec_mergel(s[10], s[11]);
	u[6] = vec_mergeh(s[14], s[15]);
	u[7] = vec_mergel(s[14], s[15]);

	v[0]  = vec_msum(u[0], k__cospi_m16_m16, mzero);
	v[1]  = vec_msum(u[1], k__cospi_m16_m16, mzero);
	v[2]  = vec_msum(u[0], k__cospi_p16_m16, mzero);
	v[3]  = vec_msum(u[1], k__cospi_p16_m16, mzero);
	v[4]  = vec_msum(u[2], k__cospi_p16_p16, mzero);
	v[5]  = vec_msum(u[3], k__cospi_p16_p16, mzero);
	v[6]  = vec_msum(u[2], k__cospi_m16_p16, mzero);
	v[7]  = vec_msum(u[3], k__cospi_m16_p16, mzero);
	v[8]  = vec_msum(u[4], k__cospi_p16_p16, mzero);
	v[9]  = vec_msum(u[5], k__cospi_p16_p16, mzero);
	v[10] = vec_msum(u[4], k__cospi_m16_p16, mzero);
	v[11] = vec_msum(u[5], k__cospi_m16_p16, mzero);
	v[12] = vec_msum(u[6], k__cospi_m16_m16, mzero);
	v[13] = vec_msum(u[7], k__cospi_m16_m16, mzero);
	v[14] = vec_msum(u[6], k__cospi_p16_m16, mzero);
	v[15] = vec_msum(u[7], k__cospi_p16_m16, mzero);

	w[0]  = vec_add(v[0],  dct_rounding_vec);
	w[1]  = vec_add(v[1],  dct_rounding_vec);
	w[2]  = vec_add(v[2],  dct_rounding_vec);
	w[3]  = vec_add(v[3],  dct_rounding_vec);
	w[4]  = vec_add(v[4],  dct_rounding_vec);
	w[5]  = vec_add(v[5],  dct_rounding_vec);
	w[6]  = vec_add(v[6],  dct_rounding_vec);
	w[7]  = vec_add(v[7],  dct_rounding_vec);
	w[8]  = vec_add(v[8],  dct_rounding_vec);
	w[9]  = vec_add(v[9],  dct_rounding_vec);
	w[10] = vec_add(v[10], dct_rounding_vec);
	w[11] = vec_add(v[11], dct_rounding_vec);
	w[12] = vec_add(v[12], dct_rounding_vec);
	w[13] = vec_add(v[13], dct_rounding_vec);
	w[14] = vec_add(v[14], dct_rounding_vec);
	w[15] = vec_add(v[15], dct_rounding_vec);

	v[0]  = vec_sra(w[0],  dct_bitshift_vec);
	v[1]  = vec_sra(w[1],  dct_bitshift_vec);
	v[2]  = vec_sra(w[2],  dct_bitshift_vec);
	v[3]  = vec_sra(w[3],  dct_bitshift_vec);
	v[4]  = vec_sra(w[4],  dct_bitshift_vec);
	v[5]  = vec_sra(w[5],  dct_bitshift_vec);
	v[6]  = vec_sra(w[6],  dct_bitshift_vec);
	v[7]  = vec_sra(w[7],  dct_bitshift_vec);
	v[8]  = vec_sra(w[8],  dct_bitshift_vec);
	v[9]  = vec_sra(w[9],  dct_bitshift_vec);
	v[10] = vec_sra(w[10], dct_bitshift_vec);
	v[11] = vec_sra(w[11], dct_bitshift_vec);
	v[12] = vec_sra(w[12], dct_bitshift_vec);
	v[13] = vec_sra(w[13], dct_bitshift_vec);
	v[14] = vec_sra(w[14], dct_bitshift_vec);
	v[15] = vec_sra(w[15], dct_bitshift_vec);

	in[0]  = s[0];
	in[1]  = vec_sub(kZero, s[8]);
	in[2]  = s[12];
	in[3]  = vec_sub(kZero, s[4]);
	in[4]  = vec_packs(v[4], v[5]);
	in[5]  = vec_packs(v[12], v[13]);
	in[6]  = vec_packs(v[8], v[9]);
	in[7]  = vec_packs(v[0], v[1]);
	in[8]  = vec_packs(v[2], v[3]);
	in[9]  = vec_packs(v[10], v[11]);
	in[10] = vec_packs(v[14], v[15]);
	in[11] = vec_packs(v[6], v[7]);
	in[12] = s[5];
	in[13] = vec_sub(kZero, s[13]);
	in[14] = s[9];
	in[15] = vec_sub(kZero, s[1]);
}

// Second tarpit: 16x16 IDCT, same eight columns.
// Fortunately we have some opportunities for optimization.
static void idct16_8col(vector signed short *in) {
	vector signed short k__cospi_p30_m02 = short_pair_a(cospi_30_64, -cospi_2_64);
	vector signed short k__cospi_p02_p30 = short_pair_a(cospi_2_64, cospi_30_64);
	vector signed short k__cospi_p14_m18 = short_pair_a(cospi_14_64, -cospi_18_64);
	vector signed short k__cospi_p18_p14 = short_pair_a(cospi_18_64, cospi_14_64);
	vector signed short k__cospi_p22_m10 = short_pair_a(cospi_22_64, -cospi_10_64);
	vector signed short k__cospi_p10_p22 = short_pair_a(cospi_10_64, cospi_22_64);
	vector signed short k__cospi_p06_m26 = short_pair_a(cospi_6_64, -cospi_26_64);
	vector signed short k__cospi_p26_p06 = short_pair_a(cospi_26_64, cospi_6_64);
	vector signed short k__cospi_p28_m04 = short_pair_a(cospi_28_64, -cospi_4_64);
	vector signed short k__cospi_p04_p28 = short_pair_a(cospi_4_64, cospi_28_64);
	vector signed short k__cospi_p12_m20 = short_pair_a(cospi_12_64, -cospi_20_64);
	vector signed short k__cospi_p20_p12 = short_pair_a(cospi_20_64, cospi_12_64);
	vector signed short k__cospi_p16_p16;
	vector signed short k__cospi_p16_m16 = short_pair_a(cospi_16_64, -cospi_16_64);
	vector signed short k__cospi_p24_m08 = short_pair_a(cospi_24_64, -cospi_8_64);
	vector signed short k__cospi_p08_p24 = short_pair_a(cospi_8_64, cospi_24_64);
	vector signed short k__cospi_m08_p24 = short_pair_a(-cospi_8_64, cospi_24_64);
	vector signed short k__cospi_p24_p08 = short_pair_a(cospi_24_64, cospi_8_64);
	vector signed short k__cospi_m24_m08 = short_pair_a(-cospi_24_64, -cospi_8_64);
	vector signed short k__cospi_m16_p16 = short_pair_a(-cospi_16_64, cospi_16_64);
	
	vector signed short s[16], t[16], u[16];
	vector signed int v[16], w[16];
	
	signed short a_s = ((int16_t)cospi_16_64); int j;
	k__cospi_p16_p16 = ss_splat(&a_s);

	// Stage 1.
	s[0]  = in[0];
	s[1]  = in[8];
	s[2]  = in[4];
	s[3]  = in[12];
	s[4]  = in[2];
	s[5]  = in[10];
	s[6]  = in[6];
	s[7]  = in[14];
	s[8]  = in[1];
	s[9]  = in[9];
	s[10] = in[5];
	s[11] = in[13];
	s[12] = in[3];
	s[13] = in[11];
	s[14] = in[7];
	s[15] = in[15];
	
	// Stage 2. Finally, msum to its fullest potential again!
	u[0] = vec_mergeh(s[8],  s[15]);
	u[1] = vec_mergel(s[8],  s[15]);
	u[2] = vec_mergeh(s[9],  s[14]);
	u[3] = vec_mergel(s[9],  s[14]);
	u[4] = vec_mergeh(s[10], s[13]);
	u[5] = vec_mergel(s[10], s[13]);
	u[6] = vec_mergeh(s[11], s[12]);
	u[7] = vec_mergel(s[11], s[12]);

	v[0]  = vec_msum(u[0], k__cospi_p30_m02, dct_rounding_vec);
	v[1]  = vec_msum(u[1], k__cospi_p30_m02, dct_rounding_vec);
	v[2]  = vec_msum(u[0], k__cospi_p02_p30, dct_rounding_vec);
	v[3]  = vec_msum(u[1], k__cospi_p02_p30, dct_rounding_vec);
	v[4]  = vec_msum(u[2], k__cospi_p14_m18, dct_rounding_vec);
	v[5]  = vec_msum(u[3], k__cospi_p14_m18, dct_rounding_vec);
	v[6]  = vec_msum(u[2], k__cospi_p18_p14, dct_rounding_vec);
	v[7]  = vec_msum(u[3], k__cospi_p18_p14, dct_rounding_vec);
	v[8]  = vec_msum(u[4], k__cospi_p22_m10, dct_rounding_vec);
	v[9]  = vec_msum(u[5], k__cospi_p22_m10, dct_rounding_vec);
	v[10] = vec_msum(u[4], k__cospi_p10_p22, dct_rounding_vec);
	v[11] = vec_msum(u[5], k__cospi_p10_p22, dct_rounding_vec);
	v[12] = vec_msum(u[6], k__cospi_p06_m26, dct_rounding_vec);
	v[13] = vec_msum(u[7], k__cospi_p06_m26, dct_rounding_vec);
	v[14] = vec_msum(u[6], k__cospi_p26_p06, dct_rounding_vec);
	v[15] = vec_msum(u[7], k__cospi_p26_p06, dct_rounding_vec);

	w[0]  = vec_sra(v[0],  dct_bitshift_vec);
	w[1]  = vec_sra(v[1],  dct_bitshift_vec);
	w[2]  = vec_sra(v[2],  dct_bitshift_vec);
	w[3]  = vec_sra(v[3],  dct_bitshift_vec);
	w[4]  = vec_sra(v[4],  dct_bitshift_vec);
	w[5]  = vec_sra(v[5],  dct_bitshift_vec);
	w[6]  = vec_sra(v[6],  dct_bitshift_vec);
	w[7]  = vec_sra(v[7],  dct_bitshift_vec);
	w[8]  = vec_sra(v[8],  dct_bitshift_vec);
	w[9]  = vec_sra(v[9],  dct_bitshift_vec);
	w[10] = vec_sra(v[10], dct_bitshift_vec);
	w[11] = vec_sra(v[11], dct_bitshift_vec);
	w[12] = vec_sra(v[12], dct_bitshift_vec);
	w[13] = vec_sra(v[13], dct_bitshift_vec);
	w[14] = vec_sra(v[14], dct_bitshift_vec);
	w[15] = vec_sra(v[15], dct_bitshift_vec);

	s[8]  = vec_packs(w[0],  w[1]);
	s[15] = vec_packs(w[2],  w[3]);
	s[9]  = vec_packs(w[4],  w[5]);
	s[14] = vec_packs(w[6],  w[7]);
	s[10] = vec_packs(w[8],  w[9]);
	s[13] = vec_packs(w[10], w[11]);
	s[11] = vec_packs(w[12], w[13]);
	s[12] = vec_packs(w[14], w[15]);

	// Stage 3.
	t[0] = s[0];
	t[1] = s[1];
	t[2] = s[2];
	t[3] = s[3];
	u[0] = vec_mergeh(s[4], s[7]);
	u[1] = vec_mergel(s[4], s[7]);
	u[2] = vec_mergeh(s[5], s[6]);
	u[3] = vec_mergel(s[5], s[6]);

	v[0] = vec_msum(u[0], k__cospi_p28_m04, dct_rounding_vec);
	v[1] = vec_msum(u[1], k__cospi_p28_m04, dct_rounding_vec);
	v[2] = vec_msum(u[0], k__cospi_p04_p28, dct_rounding_vec);
	v[3] = vec_msum(u[1], k__cospi_p04_p28, dct_rounding_vec);
	v[4] = vec_msum(u[2], k__cospi_p12_m20, dct_rounding_vec);
	v[5] = vec_msum(u[3], k__cospi_p12_m20, dct_rounding_vec);
	v[6] = vec_msum(u[2], k__cospi_p20_p12, dct_rounding_vec);
	v[7] = vec_msum(u[3], k__cospi_p20_p12, dct_rounding_vec);

	v[0] = vec_sra(v[0], dct_bitshift_vec);
	v[1] = vec_sra(v[1], dct_bitshift_vec);
	v[2] = vec_sra(v[2], dct_bitshift_vec);
	v[3] = vec_sra(v[3], dct_bitshift_vec);
	v[4] = vec_sra(v[4], dct_bitshift_vec);
	v[5] = vec_sra(v[5], dct_bitshift_vec);
	v[6] = vec_sra(v[6], dct_bitshift_vec);
	v[7] = vec_sra(v[7], dct_bitshift_vec);

	t[4]  = vec_packs(v[0], v[1]);
	t[7]  = vec_packs(v[2], v[3]);
	t[5]  = vec_packs(v[4], v[5]);
	t[6]  = vec_packs(v[6], v[7]);

	t[8]  = vec_add(s[8],  s[9]);
	t[9]  = vec_sub(s[8],  s[9]);
	t[10] = vec_sub(s[11], s[10]);
	t[11] = vec_add(s[10], s[11]);
	t[12] = vec_add(s[12], s[13]);
	t[13] = vec_sub(s[12], s[13]);
	t[14] = vec_sub(s[15], s[14]);
	t[15] = vec_add(s[14], s[15]);

	// Stage 4.
	u[0] = vec_mergeh(t[0],  t[1]);
	u[1] = vec_mergel(t[0],  t[1]);
	u[2] = vec_mergeh(t[2],  t[3]);
	u[3] = vec_mergel(t[2],  t[3]);
	u[4] = vec_mergeh(t[9],  t[14]);
	u[5] = vec_mergel(t[9],  t[14]);
	u[6] = vec_mergeh(t[10], t[13]);
	u[7] = vec_mergel(t[10], t[13]);

	v[0]  = vec_msum(u[0], k__cospi_p16_p16, dct_rounding_vec);
	v[1]  = vec_msum(u[1], k__cospi_p16_p16, dct_rounding_vec);
	v[2]  = vec_msum(u[0], k__cospi_p16_m16, dct_rounding_vec);
	v[3]  = vec_msum(u[1], k__cospi_p16_m16, dct_rounding_vec);
	v[4]  = vec_msum(u[2], k__cospi_p24_m08, dct_rounding_vec);
	v[5]  = vec_msum(u[3], k__cospi_p24_m08, dct_rounding_vec);
	v[6]  = vec_msum(u[2], k__cospi_p08_p24, dct_rounding_vec);
	v[7]  = vec_msum(u[3], k__cospi_p08_p24, dct_rounding_vec);
	v[8]  = vec_msum(u[4], k__cospi_m08_p24, dct_rounding_vec);
	v[9]  = vec_msum(u[5], k__cospi_m08_p24, dct_rounding_vec);
	v[10] = vec_msum(u[4], k__cospi_p24_p08, dct_rounding_vec);
	v[11] = vec_msum(u[5], k__cospi_p24_p08, dct_rounding_vec);
	v[12] = vec_msum(u[6], k__cospi_m24_m08, dct_rounding_vec);
	v[13] = vec_msum(u[7], k__cospi_m24_m08, dct_rounding_vec);
	v[14] = vec_msum(u[6], k__cospi_m08_p24, dct_rounding_vec);
	v[15] = vec_msum(u[7], k__cospi_m08_p24, dct_rounding_vec);

	w[0]  = vec_sra(v[0],  dct_bitshift_vec);
	w[1]  = vec_sra(v[1],  dct_bitshift_vec);
	w[2]  = vec_sra(v[2],  dct_bitshift_vec);
	w[3]  = vec_sra(v[3],  dct_bitshift_vec);
	w[4]  = vec_sra(v[4],  dct_bitshift_vec);
	w[5]  = vec_sra(v[5],  dct_bitshift_vec);
	w[6]  = vec_sra(v[6],  dct_bitshift_vec);
	w[7]  = vec_sra(v[7],  dct_bitshift_vec);
	w[8]  = vec_sra(v[8],  dct_bitshift_vec);
	w[9]  = vec_sra(v[9],  dct_bitshift_vec);
	w[10] = vec_sra(v[10], dct_bitshift_vec);
	w[11] = vec_sra(v[11], dct_bitshift_vec);
	w[12] = vec_sra(v[12], dct_bitshift_vec);
	w[13] = vec_sra(v[13], dct_bitshift_vec);
	w[14] = vec_sra(v[14], dct_bitshift_vec);
	w[15] = vec_sra(v[15], dct_bitshift_vec);

	s[0]  = vec_packs(w[0], w[1]);
	s[1]  = vec_packs(w[2], w[3]);
	s[2]  = vec_packs(w[4], w[5]);
	s[3]  = vec_packs(w[6], w[7]);
	s[4]  = vec_add(t[4], t[5]);
	s[5]  = vec_sub(t[4], t[5]);
	s[6]  = vec_sub(t[7], t[6]);
	s[7]  = vec_add(t[6], t[7]);
	s[8]  = t[8];
	s[15] = t[15];
	s[9]  = vec_packs(w[8],  w[9]);
	s[14] = vec_packs(w[10], w[11]);
	s[10] = vec_packs(w[12], w[13]);
	s[13] = vec_packs(w[14], w[15]);
	s[11] = t[11];
	s[12] = t[12];

	// Stage 5.
	t[0] = vec_add(s[0], s[3]);
	t[1] = vec_add(s[1], s[2]);
	t[2] = vec_sub(s[1], s[2]);
	t[3] = vec_sub(s[0], s[3]);
	t[4] = s[4];
	t[7] = s[7];

	u[0] = vec_mergeh(s[5], s[6]);
	u[1] = vec_mergel(s[5], s[6]);
	v[0] = vec_msum(u[0], k__cospi_m16_p16, dct_rounding_vec);
	v[1] = vec_msum(u[1], k__cospi_m16_p16, dct_rounding_vec);
	v[2] = vec_msum(u[0], k__cospi_p16_p16, dct_rounding_vec);
	v[3] = vec_msum(u[1], k__cospi_p16_p16, dct_rounding_vec);
	w[0] = vec_sra(v[0], dct_bitshift_vec);
	w[1] = vec_sra(v[1], dct_bitshift_vec);
	w[2] = vec_sra(v[2], dct_bitshift_vec);
	w[3] = vec_sra(v[3], dct_bitshift_vec);
	t[5] = vec_packs(w[0], w[1]);
	t[6] = vec_packs(w[2], w[3]);

	t[8]  = vec_add(s[8],  s[11]);
	t[9]  = vec_add(s[9],  s[10]);
	t[10] = vec_sub(s[9],  s[10]);
	t[11] = vec_sub(s[8],  s[11]);
	t[12] = vec_sub(s[15], s[12]);
	t[13] = vec_sub(s[14], s[13]);
	t[14] = vec_add(s[13], s[14]);
	t[15] = vec_add(s[12], s[15]);

	// Stage 6.
	s[0] = vec_add(t[0], t[7]);
	s[1] = vec_add(t[1], t[6]);
	s[2] = vec_add(t[2], t[5]);
	s[3] = vec_add(t[3], t[4]);
	s[4] = vec_sub(t[3], t[4]);
	s[5] = vec_sub(t[2], t[5]);
	s[6] = vec_sub(t[1], t[6]);
	s[7] = vec_sub(t[0], t[7]);
	s[8] = t[8];
	s[9] = t[9];

	u[0] = vec_mergeh(t[10], t[13]);
	u[1] = vec_mergel(t[10], t[13]);
	u[2] = vec_mergeh(t[11], t[12]);
	u[3] = vec_mergel(t[11], t[12]);

	v[0] = vec_msum(u[0], k__cospi_m16_p16, dct_rounding_vec);
	v[1] = vec_msum(u[1], k__cospi_m16_p16, dct_rounding_vec);
	v[2] = vec_msum(u[0], k__cospi_p16_p16, dct_rounding_vec);
	v[3] = vec_msum(u[1], k__cospi_p16_p16, dct_rounding_vec);
	v[4] = vec_msum(u[2], k__cospi_m16_p16, dct_rounding_vec);
	v[5] = vec_msum(u[3], k__cospi_m16_p16, dct_rounding_vec);
	v[6] = vec_msum(u[2], k__cospi_p16_p16, dct_rounding_vec);
	v[7] = vec_msum(u[3], k__cospi_p16_p16, dct_rounding_vec);

	w[0] = vec_sra(v[0], dct_bitshift_vec);
	w[1] = vec_sra(v[1], dct_bitshift_vec);
	w[2] = vec_sra(v[2], dct_bitshift_vec);
	w[3] = vec_sra(v[3], dct_bitshift_vec);
	w[4] = vec_sra(v[4], dct_bitshift_vec);
	w[5] = vec_sra(v[5], dct_bitshift_vec);
	w[6] = vec_sra(v[6], dct_bitshift_vec);
	w[7] = vec_sra(v[7], dct_bitshift_vec);

	s[10] = vec_packs(w[0], w[1]);
	s[13] = vec_packs(w[2], w[3]);
	s[11] = vec_packs(w[4], w[5]);
	s[12] = vec_packs(w[6], w[7]);
	s[14] = t[14];
	s[15] = t[15];

	// Stage 7.
	in[0]  = vec_add(s[0], s[15]);
	in[1]  = vec_add(s[1], s[14]);
	in[2]  = vec_add(s[2], s[13]);
	in[3]  = vec_add(s[3], s[12]);
	in[4]  = vec_add(s[4], s[11]);
	in[5]  = vec_add(s[5], s[10]);
	in[6]  = vec_add(s[6], s[9]);
	in[7]  = vec_add(s[7], s[8]);
	in[8]  = vec_sub(s[7], s[8]);
	in[9]  = vec_sub(s[6], s[9]);
	in[10] = vec_sub(s[5], s[10]);
	in[11] = vec_sub(s[4], s[11]);
	in[12] = vec_sub(s[3], s[12]);
	in[13] = vec_sub(s[2], s[13]);
	in[14] = vec_sub(s[1], s[14]);
	in[15] = vec_sub(s[0], s[15]);
}

static inline void idct16_vmx(vector signed short *in0, vector signed short *in1) {
	array_transpose_16x16(in0, in1);
	idct16_8col(in0);
	idct16_8col(in1);
}

static inline void iadst16_vmx(vector signed short *in0, vector signed short *in1) {
	array_transpose_16x16(in0, in1);
	iadst16_8col(in0);
	iadst16_8col(in1);
}

void vp9_iht16x16_256_add_vmx(const int16_t *input, uint8_t *dest, int stride,
                               int tx_type) {
	vector signed short in0[16], in1[16];

	load_buffer_8x16(input, in0);
	input += 8;
	load_buffer_8x16(input, in1);

	switch (tx_type) {
		case 0:  // DCT_DCT
			idct16_vmx(in0, in1);
			idct16_vmx(in0, in1);
		break;
		case 1:  // ADST_DCT
			idct16_vmx(in0, in1);
			iadst16_vmx(in0, in1);
		break;
		case 2:  // DCT_ADST
			iadst16_vmx(in0, in1);
			idct16_vmx(in0, in1);
		break;
		case 3:  // ADST_ADST
			iadst16_vmx(in0, in1);
			iadst16_vmx(in0, in1);
		break;
		default:
			assert(0);
		break;
	}

	write_buffer_8x16(dest, in0, stride);
	dest += 8;
	write_buffer_8x16(dest, in1, stride);
}

// WHEW!