/*
 *  Copyright (c) 2017 Cameron Kaiser and Contributors to TenFourFox
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

// Basic notion. Guaranteed to work at any offset.
#define _unaligned_load128(v,s) { v=vec_perm(vec_ld(0,s),vec_ld(16,s),vec_lvsl(0,s)); }

// Equivalent for _mm_cvtsi32_si128. (Upper 96 bits undefined.) However,
// this may have issues loading at really weird addresses if they're not
// minimally word-aligned.
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

/* 4x4 */

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
	
	// This is faster than a whole bunch of _unaligned_store32s because we
	// already splatted the vector, so it's the same at all positions.
	vec_ste((vector unsigned int)c0, 0, (uint32_t *)dst);
	vec_ste((vector unsigned int)c0, y_stride, (uint32_t *)dst);
	vec_ste((vector unsigned int)c0, y_stride + y_stride, (uint32_t *)dst);
	vec_ste((vector unsigned int)c0, y_stride + y_stride + y_stride, (uint32_t *)dst);
}

inline void _common_top_or_left_4x4_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *what)
{
	// Similar idea to the standard predictor, but one column only.
	vector unsigned int m0, m1, m2, m3;
	vector unsigned short s0, s1;
	vector unsigned char c0;

	vector unsigned int vzero = vec_splat_u32(0);
	vector unsigned int vtwo = vec_splat_u32(2);
	
	_unaligned_load32(m1, (uint32_t *)what);
	// Interpolate zero to clear out the upper bits so that we get a
	// proper cross-sum over the full range.
	m0 = vec_mergeh(m1, vzero);
	m2 = vec_sum4s((vector unsigned char)m0, vzero);
	m3 = (vector unsigned int)vec_sum2s((vector signed int)m2, (vector signed int)vzero);
	m0 = vec_add(m3, vtwo);
	m1 = vec_sra(m0, vtwo);
	
	s0 = vec_packsu(m1, m1);
	s1 = vec_splat(s0, 1);
	c0 = vec_packsu(s1, s1);
	
	vec_ste((vector unsigned int)c0, 0, (uint32_t *)dst);
	vec_ste((vector unsigned int)c0, y_stride, (uint32_t *)dst);
	vec_ste((vector unsigned int)c0, y_stride + y_stride, (uint32_t *)dst);
	vec_ste((vector unsigned int)c0, y_stride + y_stride + y_stride, (uint32_t *)dst);
}

void vp9_dc_top_predictor_4x4_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	_common_top_or_left_4x4_vmx(dst, y_stride, above);
}
void vp9_dc_left_predictor_4x4_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left) 
{
	_common_top_or_left_4x4_vmx(dst, y_stride, left);
}

void vp9_dc_128_predictor_4x4_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Pretty much just blit 128s.
	// Splatting to a char vector doesn't store properly, so splat
	// to int.
	vector unsigned int m0 = (vector unsigned int)vec_sl(vec_splat_u8(2), vec_splat_u8(6));
	vec_ste(m0, 0, (uint32_t *)dst);
	vec_ste(m0, y_stride, (uint32_t *)dst);
	vec_ste(m0, y_stride + y_stride, (uint32_t *)dst);
	vec_ste(m0, y_stride + y_stride + y_stride, (uint32_t *)dst);
}

void vp9_v_predictor_4x4_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Pretty much just copy.
		
	vector unsigned int m0, m1;
	_unaligned_load32(m1, (uint32_t *)above);
	m0 = vec_splat(m1, 0);
	vec_ste(m0, 0, (uint32_t *)dst);
	vec_ste(m0, y_stride, (uint32_t *)dst);
	vec_ste(m0, y_stride + y_stride, (uint32_t *)dst);
	vec_ste(m0, y_stride + y_stride + y_stride, (uint32_t *)dst);
}

void vp9_h_predictor_4x4_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Expand sequence
	// aa bb cc dd -- -- -- -- -- ....
	// to
	// aa aa aa aa bb bb bb bb cc ....
	// This can be done with just splats.

	vector unsigned char c0;
	vector unsigned int m0, m1, m2, m3;
	vector unsigned char vzero = vec_splat_u8(0);
	
	_unaligned_load32(c0, (uint32_t *)left);

	m0 = (vector unsigned int)vec_splat(c0, 0);
	m1 = (vector unsigned int)vec_splat(c0, 1);
	vec_ste(m0, 0, (uint32_t *)dst);
	m2 = (vector unsigned int)vec_splat(c0, 2);
	vec_ste(m1, y_stride, (uint32_t *)dst);
	m3 = (vector unsigned int)vec_splat(c0, 3);
	vec_ste(m2, y_stride + y_stride, (uint32_t *)dst);
	vec_ste(m3, y_stride + y_stride + y_stride, (uint32_t *)dst);
}

#if(0)
// This doesn't work properly, and the large amount of unaligned
// memory access in the True Motion predictors makes them a poor
// fit for AltiVec.
void vp9_tm_predictor_4x4_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Get the last top value from above - 1 and splat it ("tl").
	// Using that preceding byte, compute t[i]-tl+l[i] for the
	// appropriate block size where t = top and l = left with our
	// tl vector above.
	
	vector unsigned char c0, c1, c2, c3, c4;
	vector unsigned short s0, s1, s2, s3, s4, s5, s6, tl;
	vector unsigned int m0;
	vector unsigned char vzero = vec_splat_u8(0);
	ptrdiff_t offs = 0;

	// This can load at really weird addresses, so our
	// faster unaligned load32 macro is not sufficient.
	_unaligned_load128(c0, (uint32_t *)(above - 1));
	c1 = vec_splat(c0, 0);
	tl = vec_mergeh(vzero, c1);
	
	// Expand t to short and subtract tl.
	_unaligned_load128(c0, (uint32_t *)above);
	s1 = vec_mergeh(vzero, c0);
	s0 = vec_sub(s1, tl);

#define TM_2X2(x) \
	_unaligned_load128(c2, (uint32_t *)(left + 4 - x)); \
	_unaligned_load128(c3, (uint32_t *)(left + 5 - x)); \
	s2 = vec_mergeh(vzero, c2); \
	s3 = vec_mergeh(vzero, c3); \
	s4 = vec_splat(s2, 0); \
	s5 = vec_splat(s3, 0); \
	s2 = vec_add(s0, s4); \
	s3 = vec_add(s0, s5); \
	c2 = vec_packsu(s2, s2); \
	c3 = vec_packsu(s3, s3); \
	c4 = vec_perm(c2, c2, vec_lvsr(0, (uint32_t *)(dst + offs))); \
	vec_ste(c4, 0, (dst + offs)); \
	vec_ste(c4, 1, (dst + offs)); \
	vec_ste(c4, 2, (dst + offs)); \
	vec_ste(c4, 3, (dst + offs)); \
	c4 = vec_perm(c3, c3, vec_lvsr(0, (uint32_t *)(dst + offs + y_stride))); \
	vec_ste(c4, 0, (dst + offs + y_stride)); \
	vec_ste(c4, 1, (dst + offs + y_stride)); \
	vec_ste(c4, 2, (dst + offs + y_stride)); \
	vec_ste(c4, 3, (dst + offs + y_stride)); \
	offs += y_stride + y_stride;
	
	TM_2X2(4)
	TM_2X2(2)
#undef  TM_2X2
}
#endif

/* 8x8 */

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
	
	// Again, faster than repeated _unaligned_store64s since we
	// already splatted.
#define NEXT vec_ste((vector unsigned int)c0, offs, (uint32_t *)dst); vec_ste((vector unsigned int)c0, 4+offs, (uint32_t *)dst); offs+=y_stride;

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

inline void _common_top_or_left_8x8_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *what)
{
	// Again, single column variant.
	vector unsigned int m0, m1, m2, m3, m4;
	vector unsigned short s0, s1;
	vector unsigned char c0;
	ptrdiff_t offs = 0;

	vector unsigned int vzero = vec_splat_u32(0);
	vector unsigned int vfour = vec_splat_u32(4);
	vector unsigned int vthree = vec_splat_u32(3);

	_unaligned_load64(m0, (uint32_t *)what);
	
	// Since all these functions from here load at least 64 bits, we don't need
	// to interpolate zero anymore to clear out the other half for the SAD.
	m1 = vec_sum4s((vector unsigned char)m0, vzero);
	m2 = (vector unsigned int)vec_sum2s((vector signed int)m1, (vector signed int)vzero);
	m3 = vec_adds(m2, vfour);
	m4 = vec_sra(m3, vthree);

	s0 = vec_packsu(m4, m4);
	s1 = vec_splat(s0, 1);
	c0 = vec_packsu(s1, s1);
	
#define NEXT vec_ste((vector unsigned int)c0, offs, (uint32_t *)dst); vec_ste((vector unsigned int)c0, 4+offs, (uint32_t *)dst); offs+=y_stride;

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

void vp9_dc_top_predictor_8x8_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	_common_top_or_left_8x8_vmx(dst, y_stride, above);
}
void vp9_dc_left_predictor_8x8_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	_common_top_or_left_8x8_vmx(dst, y_stride, left);
}

void vp9_dc_128_predictor_8x8_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Yup, blitting 128s again.
	vector unsigned int m0 = (vector unsigned int)vec_sl(vec_splat_u8(2), vec_splat_u8(6));
	ptrdiff_t offs = 0;

#define NEXT vec_ste(m0, offs, (uint32_t *)dst); vec_ste(m0, 4+offs, (uint32_t *)dst); offs+=y_stride;

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

void vp9_v_predictor_8x8_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Yup, copying again.
	vector unsigned int m0, m1;
	ptrdiff_t offs = 0;

	_unaligned_load64(m1, (uint32_t *)above);
	m0 = vec_splat(m1, 0);
	m1 = vec_splat(m1, 1);

#define NEXT vec_ste(m0, offs, (uint32_t *)dst); vec_ste(m1, 4+offs, (uint32_t *)dst); offs+=y_stride;

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

void vp9_h_predictor_8x8_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Expand sequence
	// aa bb cc dd ee ff gg hh -- -- -- -- -- ....
	// to
	// aa aa aa aa bb bb bb bb cc cc cc cc dd ....
	
	vector unsigned char c0;
	vector unsigned int m0, m1, m2;
	ptrdiff_t offs = 0;
	
	_unaligned_load64(c0, (uint32_t *)left);
	
#define STORE(x) vec_ste(x, offs, (uint32_t *)dst); vec_ste(x, 4+offs, (uint32_t *)dst); offs+=y_stride;
	m0 = (vector unsigned int)vec_splat(c0, 0);
	m1 = (vector unsigned int)vec_splat(c0, 1);
	STORE(m0)
	m2 = (vector unsigned int)vec_splat(c0, 2);
	STORE(m1)
	m0 = (vector unsigned int)vec_splat(c0, 3);
	STORE(m2)
	m1 = (vector unsigned int)vec_splat(c0, 4);
	STORE(m0)
	m2 = (vector unsigned int)vec_splat(c0, 5);
	STORE(m1)
	m0 = (vector unsigned int)vec_splat(c0, 6);
	STORE(m2)
	m1 = (vector unsigned int)vec_splat(c0, 7);
	STORE(m0)
	STORE(m1)
#undef STORE
}

/* 16x16 */

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

void _common_top_or_left_16x16_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *what)
{
	vector unsigned int m0, m1, m2, m3;
	vector unsigned short s0, s1;
	vector unsigned char c0;
	ptrdiff_t offs = 0;

	vector unsigned int vzero = vec_splat_u32(0);
	vector unsigned int vfour = vec_splat_u32(4);
	vector unsigned int veight = vec_splat_u32(8);
	
	m0 = vec_ld(0, (uint32_t *)what);
	
	// The Intel version is identical to the full 16x16 except for
	// zeroing out the additional vector; otherwise it does all the
	// same computations. This is clearly wasteful, so I've elided
	// them here. In particular, an SAD of zero against zero will
	// always be zero, so we can just drop one of the SADs right now.
	m1 = vec_sum4s((vector unsigned char)m0, vzero);
	m2 = (vector unsigned int)vec_sum2s((vector signed int)m1, (vector signed int)vzero);

	// Also, we don't need the full movhlps steps because the other vector
	// will always be zero, so only one vector shift is required.
	m3 = vec_sld(m2, vzero, 8);

	m0 = vec_adds(m3, m2);
	m1 = vec_adds(m0, veight);
	m2 = vec_sra(m1, vfour);
	
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

void vp9_dc_top_predictor_16x16_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	_common_top_or_left_16x16_vmx(dst, y_stride, above);
}
void vp9_dc_left_predictor_16x16_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	_common_top_or_left_16x16_vmx(dst, y_stride, left);
}

void vp9_dc_128_predictor_16x16_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Mmmm, 128 splat splat splat.
	vector unsigned char c0 = vec_sl(vec_splat_u8(2), vec_splat_u8(6));
	ptrdiff_t offs = 0;

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

void vp9_v_predictor_16x16_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Mmmm, vector copy copy copy.
	vector unsigned char c0 = vec_ld(0, above);
	ptrdiff_t offs = 0;

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

void vp9_h_predictor_16x16_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Expand an entire 16-byte vector to 16 splatted vectors.
	// Unfortunately, the load is not aligned, but the stores are.
	vector unsigned char c0, c1, c2, c3;
	ptrdiff_t offs = 0;
	
	_unaligned_load128(c0, left);

	// 16 stores
#define SPLAT(n,x) x = vec_splat(c0, n);
#define STORE(x) vec_st(x, offs, dst); offs += y_stride;

	SPLAT(0,c1)
	SPLAT(1,c2)
	STORE(c1)
	SPLAT(2,c3)
	STORE(c2)
	SPLAT(3,c1)
	STORE(c3)
	SPLAT(4,c2)
	STORE(c1)
	SPLAT(5,c3)
	STORE(c2)
	SPLAT(6,c1)
	STORE(c3)
	SPLAT(7,c2)
	STORE(c1)
	SPLAT(8,c3)
	STORE(c2)
	SPLAT(9,c1)
	STORE(c3)
	SPLAT(10,c2)
	STORE(c1)
	SPLAT(11,c3)
	STORE(c2)
	SPLAT(12,c1)
	STORE(c3)
	SPLAT(13,c2)
	STORE(c1)
	SPLAT(14,c3)
	STORE(c2)
	SPLAT(15,c1)
	STORE(c3)
	STORE(c1)

#undef STORE
#undef SPLAT
}

/* 32x32 */

void vp9_dc_predictor_32x32_vmx(uint8_t *dst, ptrdiff_t y_stride,
				const uint8_t *above, const uint8_t *left)
{
	// Also aligned.
	// Approximately the same routine, but double-pumped.

	vector unsigned int m0, m1, m2, m3, m4, m5, m6, m7, m8;
	vector unsigned short s0, s1;
	vector unsigned char c0;
	ptrdiff_t offs = 0;

	vector unsigned int v32 = vec_splat_u32(8); // Computed momentarily
	vector unsigned int vtwo = vec_splat_u32(2);
	vector unsigned int vsix = vec_splat_u32(6);
	vector unsigned int vzero = vec_splat_u32(0);

	m1 = vec_ld(0,  (uint32_t *)above);
	m2 = vec_ld(16, (uint32_t *)above);
	m3 = vec_ld(0,  (uint32_t *)left);
	m4 = vec_ld(16, (uint32_t *)left);
	
	v32 = vec_sl(v32, vtwo);
	
	m5 = vec_sum4s((vector unsigned char)m1, vzero);
	m6 = vec_sum4s((vector unsigned char)m2, vzero);
	m7 = vec_sum4s((vector unsigned char)m3, vzero);
	m8 = vec_sum4s((vector unsigned char)m4, vzero);
	
	m1 = (vector unsigned int)vec_sum2s((vector signed int)m5, (vector signed int)vzero);
	m2 = (vector unsigned int)vec_sum2s((vector signed int)m6, (vector signed int)vzero);
	m3 = (vector unsigned int)vec_sum2s((vector signed int)m7, (vector signed int)vzero);
	m4 = (vector unsigned int)vec_sum2s((vector signed int)m8, (vector signed int)vzero);

	m5 = vec_adds(m1, m2);
	m6 = vec_adds(m3, m4);
	m0 = vec_adds(m5, m6);
	
	m1 = vec_sld(m2, m2, 8);
	m3 = vec_sld(m0, m1, 8);
	
	m4 = vec_adds(m3, m0);
	m1 = vec_adds(m4, v32);
	m2 = vec_sra(m1, vsix);
	
	s0 = vec_packsu(m2, m2);
	s1 = vec_splat(s0, 1);
	c0 = vec_packsu(s1, s1);
	
	// 32 stores
#define NEXT vec_st(c0, offs, dst); vec_st(c0, offs+16, dst); offs += y_stride;

	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT

#undef  NEXT
}

void _common_top_or_left_32x32_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *what)
{
	// This actually has slightly different logic.
	vector unsigned int m0, m1, m2, m3, m4, m5, m6;
	vector unsigned short s0, s1;
	vector unsigned char c0;
	ptrdiff_t offs = 0;

	vector unsigned int v16 = vec_splat_u32(8); // Computed momentarily
	vector unsigned int vfive = vec_splat_u32(5);
	vector unsigned int vzero = vec_splat_u32(0);

	m0 = vec_ld(0,  (uint32_t *)what);
	m2 = vec_ld(16, (uint32_t *)what);
	
	v16 = vec_add(v16, v16);
	
	m5 = vec_sum4s((vector unsigned char)m0, vzero);
	m6 = vec_sum4s((vector unsigned char)m2, vzero);	
	m4 = (vector unsigned int)vec_sum2s((vector signed int)m5, (vector signed int)vzero);
	m2 = (vector unsigned int)vec_sum2s((vector signed int)m6, (vector signed int)vzero);

	m0 = vec_adds(m4, m2);
	
	m1 = vec_sld(m2, m2, 8);
	m3 = vec_sld(m0, m1, 8);
	
	m4 = vec_adds(m3, m0);
	m1 = vec_adds(m4, v16);
	m2 = vec_sra(m1, vfive);
	
	s0 = vec_packsu(m2, m2);
	s1 = vec_splat(s0, 1);
	c0 = vec_packsu(s1, s1);
	
	// 32 stores
#define NEXT vec_st(c0, offs, dst); vec_st(c0, offs+16, dst); offs += y_stride;

	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT

#undef  NEXT
}

void vp9_dc_top_predictor_32x32_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	_common_top_or_left_32x32_vmx(dst, y_stride, above);
}
void vp9_dc_left_predictor_32x32_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	_common_top_or_left_32x32_vmx(dst, y_stride, left);
}

void vp9_dc_128_predictor_32x32_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Oh baby, I love to feel those creamy 128s ru... um, sorry.
	// What were we doing again?
	vector unsigned char c0 = vec_sl(vec_splat_u8(2), vec_splat_u8(6));
	ptrdiff_t offs = 0;

	// 32 stores
#define NEXT vec_st(c0, offs, dst); vec_st(c0, offs+16, dst); offs += y_stride;

	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT

#undef  NEXT
}

void vp9_v_predictor_32x32_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Is it hot in here or is it just me?
	// Oh, right, copying even more data.
	vector unsigned char c0 = vec_ld(0,  above);
	vector unsigned char c1 = vec_ld(16, above);
	ptrdiff_t offs = 0;

	// 32 stores
#define NEXT vec_st(c0, offs, dst); vec_st(c1, offs+16, dst); offs += y_stride;

	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT
	NEXT NEXT

#undef  NEXT
}

void vp9_h_predictor_32x32_vmx(uint8_t *dst, ptrdiff_t y_stride, const uint8_t *above, const uint8_t *left)
{
	// Two 16-byte vectors to 32 splatted vectors.
	// Again, the load doesn't seem to be aligned :(
	// Simplest to run this as a double-pumped 16x16 routine.
	vector unsigned char c0, c1, c2, c3;
	ptrdiff_t offs = 0;
	
	_unaligned_load128(c0, left);

	// 32 stores
#define SPLAT(n,x) x = vec_splat(c0, n);
#define STORE(x) vec_st(x, offs, dst); vec_st(x, 16+offs, dst); offs += y_stride;

	SPLAT(0,c1)
	SPLAT(1,c2)
	STORE(c1)
	SPLAT(2,c3)
	STORE(c2)
	SPLAT(3,c1)
	STORE(c3)
	SPLAT(4,c2)
	STORE(c1)
	SPLAT(5,c3)
	STORE(c2)
	SPLAT(6,c1)
	STORE(c3)
	SPLAT(7,c2)
	STORE(c1)
	SPLAT(8,c3)
	STORE(c2)
	SPLAT(9,c1)
	STORE(c3)
	SPLAT(10,c2)
	STORE(c1)
	SPLAT(11,c3)
	STORE(c2)
	SPLAT(12,c1)
	STORE(c3)
	SPLAT(13,c2)
	STORE(c1)
	SPLAT(14,c3)
	STORE(c2)
	SPLAT(15,c1)
	STORE(c3)
	_unaligned_load128(c0, left + 16);
	STORE(c1)
	
	// 32 more stores
	SPLAT(0,c1)
	SPLAT(1,c2)
	STORE(c1)
	SPLAT(2,c3)
	STORE(c2)
	SPLAT(3,c1)
	STORE(c3)
	SPLAT(4,c2)
	STORE(c1)
	SPLAT(5,c3)
	STORE(c2)
	SPLAT(6,c1)
	STORE(c3)
	SPLAT(7,c2)
	STORE(c1)
	SPLAT(8,c3)
	STORE(c2)
	SPLAT(9,c1)
	STORE(c3)
	SPLAT(10,c2)
	STORE(c1)
	SPLAT(11,c3)
	STORE(c2)
	SPLAT(12,c1)
	STORE(c3)
	SPLAT(13,c2)
	STORE(c1)
	SPLAT(14,c3)
	STORE(c2)
	SPLAT(15,c1)
	STORE(c3)
	STORE(c1)

#undef STORE
#undef SPLAT
}