/*
 *  Copyright (c) 2018 Cameron Kaiser and Contributors to TenFourFox
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#include "./vp9_rtcd.h"
#include "vpx_ports/mem.h"

#ifndef __ALTIVEC__
#error VMX being compiled on non-VMX platform
#else
#include <altivec.h>
#endif

/* AltiVec-accelerated VP9 intra frame prediction for big-endian 32-bit PowerPC. */

// v = vector, s = *uint32_t, vv = temporary vector (unsigned int)

// Basic notion.
#define _unaligned_load128(v,s) { v=vec_perm(vec_ld(0,s),vec_ld(16,s),vec_lvsl(0,s)); }

// Equivalent for _mm_cvtsi32_si128. (Upper 96 bits undefined.)
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

void vp9_dc_predictor_4x4_vmx(uint8_t *dst, ptrdiff_t y_stride,
				const uint8_t *above, const uint8_t *left)
{
	// Descended from the MMX version, so unaligned. :(

	vector unsigned int m0, m1, m2, m3, m4, m5;
	vector unsigned short s0, s1;
	vector unsigned char c0;

	vector unsigned int vzero = vec_splat_u32(0);
	vector unsigned int vfour = vec_splat_u32(4);
	vector unsigned int vthree = vec_splat_u32(3);
	
	_unaligned_load32(m0, (uint32_t *)above);
	_unaligned_load32(m1, (uint32_t *)left);
	m2 = vec_mergeh(m0, m1); // punpckldq
	
	// The Intel MMX version computes a sum of absolute differences
	// against a vector of zero, so this is really just a cross sum.

	m3 = vec_sum4s((vector unsigned char)m2, vzero);
	m4 = (vector unsigned int)vec_sum2s((vector signed int)m3, (vector signed int)vzero);
	// Leave as 32-bit. Compute on that.
	m0 = vec_add(m4, vfour);
	m5 = vec_sra(m0, vthree);
	
	// Pack to 16 bits, splat the short, and pack again to yield 8 bits.
	s0 = vec_packsu(m5, m5);
	// ENDIAN NOTE!
	// We splat position *1* because we were working on the low-order 64 bits.
	// Since our 32-bit result was in the higher word of the low 64 bits, it's
	// index 1, and since we just shifted down, it's *still* index 1.
	s1 = vec_splat(s0, 1);
	c0 = vec_packsu(s1, s1);
	
	_unaligned_store32(c0, m0, (uint32_t *)dst);
	_unaligned_store32(c0, m0, (uint32_t *)(dst + y_stride));
	_unaligned_store32(c0, m0, (uint32_t *)(dst + y_stride + y_stride));
	_unaligned_store32(c0, m0, (uint32_t *)(dst + y_stride + y_stride + y_stride));
}

void vp9_dc_predictor_8x8_vmx(uint8_t *dst, ptrdiff_t y_stride,
				const uint8_t *above, const uint8_t *left)
{
	// Descended from the MMX version, so unaligned. :(

	vector unsigned int m0, m1, m2, m3, m4, m5, m6;
	vector unsigned short s0, s1;
	vector unsigned char c0;
	ptrdiff_t offs = 0;

	vector unsigned int vzero = vec_splat_u32(0);
	vector unsigned int vfour = vec_splat_u32(4);
	vector unsigned int veight = vec_splat_u32(8);

	_unaligned_load64(m0, (uint32_t *)above);
	_unaligned_load64(m1, (uint32_t *)left);
	
	// Same as above, an SAD calculation against a zero vector, but twice.
	m3 = vec_sum4s((vector unsigned char)m0, vzero);
	m5 = vec_sum4s((vector unsigned char)m1, vzero);
	m4 = (vector unsigned int)vec_sum2s((vector signed int)m3, (vector signed int)vzero);
	m6 = (vector unsigned int)vec_sum2s((vector signed int)m5, (vector signed int)vzero);
	// Continue computations in 32-bit pending pack/splat/pack.
	m1 = vec_adds(m4, m6);
	m0 = vec_adds(m1, veight);
	m5 = vec_sra(m0, vfour);
	
	// Pack to 16 bits, splat the short, and pack again to yield 8 bits.
	s0 = vec_packsu(m5, m5);
	s1 = vec_splat(s0, 1);
	c0 = vec_packsu(s1, s1);
	
#define NEXT _unaligned_store64(c0, m0, (uint32_t *)(dst+offs)); offs+=y_stride;

	NEXT
	NEXT
	NEXT
	NEXT
	NEXT
	NEXT
	NEXT
	NEXT

#undef  NEXT
}

void vp9_dc_predictor_16x16_vmx(uint8_t *dst, ptrdiff_t y_stride,
				const uint8_t *above, const uint8_t *left)
{
	// Finally, alignment! The use of movdqa in the Intel SSE2 version
	// for both loads and stores implies we can safely use aligned 
	// loads and stores here as well.

	vector unsigned int m0, m1, m2, m3, m4, m5, m6;
	vector unsigned short s0, s1;
	vector unsigned char c0;
	ptrdiff_t offs = 0;

	vector unsigned int v16 = vec_splat_u32(8); // Computed momentarily
	vector unsigned int vone = vec_splat_u32(1);
	vector unsigned int vzero = vec_splat_u32(0);
	vector unsigned int vfive = vec_splat_u32(5);
	
	m0 = vec_ld(0, (uint32_t *)above);
	m1 = vec_ld(0, (uint32_t *)left);
	
	// The SSE2 version starts using 32-bit words, as we do.
	m2 = vec_sum4s((vector unsigned char)m0, vzero);
	m3 = vec_sum4s((vector unsigned char)m1, vzero);
	m2 = (vector unsigned int)vec_sum2s((vector signed int)m2, (vector signed int)vzero);
	m3 = (vector unsigned int)vec_sum2s((vector signed int)m3, (vector signed int)vzero);

	v16 = vec_sl(v16, vone);
	m4 = vec_adds(m2, m3);

	// Combine 64 bits of m3 with m4 (equivalent to movhlps).
	m5 = vec_sld(m3, m3, 8);
	m6 = vec_sld(m4, m5, 8);

	m0 = vec_adds(m4, m6);
	m1 = vec_adds(m0, v16);
	m2 = vec_sra(m1, vfive);
	
	// Pack to 16 bits, splat the short, and pack again to yield 8 bits.
	s0 = vec_packsu(m2, m2);
	s1 = vec_splat(s0, 1);
	c0 = vec_packsu(s1, s1);

	// 16 stores
#define NEXT vec_st(c0, offs, dst); offs += y_stride;

	NEXT
	NEXT
	NEXT
	NEXT
	
	NEXT
	NEXT
	NEXT
	NEXT
	
	NEXT
	NEXT
	NEXT
	NEXT
	
	NEXT
	NEXT
	NEXT
	NEXT

#undef  NEXT
}