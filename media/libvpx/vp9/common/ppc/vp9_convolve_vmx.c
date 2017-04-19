/*
 *  Copyright (c) 2016 Cameron Kaiser and Contributors to TenFourFox
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

void vp9_convolve_copy_vmx(const uint8_t *src, ptrdiff_t src_stride,
                         uint8_t *dst, ptrdiff_t dst_stride,
                         const int16_t *filter_x, int filter_x_stride,
                         const int16_t *filter_y, int filter_y_stride,
                         int w, int h) {
	int r;
	vector unsigned char m0, m1, m2, m3;

	(void)filter_x;  (void)filter_x_stride;
	(void)filter_y;  (void)filter_y_stride;
	
	// The Intel SSE2 copy uses movdqu for loads and movdqa for
	// stores, implying that *dst is aligned.

	if (w == 4) {
		// Just copy, dammit.
		for (r = h; r > 0; --r) {
			*(uint32_t *)dst = *(uint32_t *)src;
			src += src_stride;
			dst += dst_stride;
		}
	} else if (w == 8) {
		// Just copy, dammit.
		for (r = h; r > 0; --r) {
			*(double *)dst = *(double *)src;
			src += src_stride;
			dst += dst_stride;
		}
	} else if (w == 16) {
		for (r = h; r > 0; --r) {
			_unaligned_load128(m0, (uint32_t *)src);
			vec_st(m0, 0, dst);
			
			src += src_stride;
			dst += dst_stride;
		}
	} else if (w == 32) {
		for (r = h; r > 0; --r) {
			_unaligned_load128(m0, (uint32_t *)src);
			_unaligned_load128(m1, (uint32_t *)(src + 16));
			vec_st(m0, 0,  dst);
			vec_st(m1, 16, dst);
			
			src += src_stride;
			dst += dst_stride;
		}
	} else {
		// Assume 64.
		for (r = h; r > 0; --r) {
			_unaligned_load128(m0, (uint32_t *)src);
			_unaligned_load128(m1, (uint32_t *)(src + 16));
			vec_st(m0, 0,  dst);
			_unaligned_load128(m2, (uint32_t *)(src + 32));
			vec_st(m1, 16, dst);
			_unaligned_load128(m3, (uint32_t *)(src + 48));
			vec_st(m2, 32, dst);
			vec_st(m3, 48, dst);
			
			src += src_stride;
			dst += dst_stride;
		}
	}
}

void vp9_convolve_avg_vmx(const uint8_t *src, ptrdiff_t src_stride,
                        uint8_t *dst, ptrdiff_t dst_stride,
                        const int16_t *filter_x, int filter_x_stride,
                        const int16_t *filter_y, int filter_y_stride,
                        int w, int h) {
	int r;
	vector unsigned char m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11;
	vector unsigned int ltemp;

	(void)filter_x;  (void)filter_x_stride;
	(void)filter_y;  (void)filter_y_stride;

	// Roughly the same as copy except for the averaging.
	if (w == 4 || w == 8) {
		// Oh, screw it. The gyrations aren't worth the piddling speedup.
		vp9_convolve_avg_c(src, src_stride, dst, dst_stride,
			filter_x, filter_x_stride,
			filter_y, filter_y_stride, w, h);
	} else if (w == 16) {
		int src_stride2 = src_stride + src_stride ;
		int dst_stride2 = dst_stride + dst_stride ;
		int src_stride3 = src_stride + src_stride2;
		int dst_stride3 = dst_stride + dst_stride2;
		int src_stride_ = src_stride + src_stride3;
		int dst_stride_ = dst_stride + dst_stride3;
		for (r = h; r > 0; r-=4) {
			// Because we store aligned to dest, we can load aligned from it too.
			_unaligned_load128(m0,    (uint32_t *)src);
			m4 = vec_ld(0,            (uint32_t *)dst);
			_unaligned_load128(m1,    (uint32_t *)(src + src_stride));
			m8  = vec_avg(m0, m4);
			m5  = vec_ld(dst_stride,  (uint32_t *)dst);
			vec_st(m8,  0,            dst);
			_unaligned_load128(m2,    (uint32_t *)(src + src_stride2));
			m9  = vec_avg(m1, m5);
			m6  = vec_ld(dst_stride2, (uint32_t *)dst);
			vec_st(m9,  0,            (uint8_t  *)(dst + dst_stride));
			_unaligned_load128(m3,    (uint32_t *)(src + src_stride3));
			m10 = vec_avg(m2, m6);
			m7 = vec_ld(dst_stride3,  (uint32_t *)dst);
			vec_st(m10, 0,            (uint8_t  *)(dst + dst_stride2));
			m11 = vec_avg(m3, m7);
			vec_st(m11, 0,            (uint8_t  *)(dst + dst_stride3));
			
			src += src_stride_;
			dst += dst_stride_;
		}
	} else if (w == 32) {
		int src_stride_ = src_stride + src_stride;
		int dst_stride_ = dst_stride + dst_stride;
		for (r = h; r > 0; r-=2) {
			// Because we store aligned to dest, we can load aligned from it too.
			_unaligned_load128(m0, (uint32_t *)src);
			m4  = vec_ld(0,  (uint32_t *)dst);
			_unaligned_load128(m1, (uint32_t *)(src + 16));
			m8  = vec_avg(m0, m4);
			m5  = vec_ld(16, (uint32_t *)dst);
			_unaligned_load128(m2, (uint32_t *)(src + src_stride));
			vec_st(m8,  0,   dst);
			m9  = vec_avg(m1, m5);
			m6 = vec_ld(dst_stride, (uint32_t *)dst);
			_unaligned_load128(m3,  (uint32_t *)(src + src_stride + 16));
			vec_st(m9,  16,  dst);
			m10 = vec_avg(m2, m6);
			m7  = vec_ld(dst_stride + 16, (uint32_t *)dst);
			vec_st(m10, 0,   (uint8_t *)(dst + dst_stride));
			m11 = vec_avg(m3, m7);
			vec_st(m11, 16,  (uint8_t *)(dst + dst_stride));
			
			src += src_stride_;
			dst += dst_stride_;
		}
	} else {
		// Assume 64.
		for (r = h; r > 0; --r) {
			_unaligned_load128(m0, (uint32_t *)src);
			m4  = vec_ld(0,  (uint32_t *)dst);
			_unaligned_load128(m1, (uint32_t *)(src + 16));
			m8  = vec_avg(m0, m4);
			m5  = vec_ld(16, (uint32_t *)dst);
			vec_st(m8,  0, dst);
			_unaligned_load128(m2, (uint32_t *)(src + 32));
			m9  = vec_avg(m1, m5);
			m6  = vec_ld(32, (uint32_t *)dst);
			vec_st(m9,  16, dst);
			_unaligned_load128(m3, (uint32_t *)(src + 48));
			m10 = vec_avg(m2, m6);
			m7  = vec_ld(48, (uint32_t *)dst);
			vec_st(m10, 32, dst);
			m11 = vec_avg(m3, m7);
			vec_st(m11, 48, dst);
			
			src += src_stride;
			dst += dst_stride;
		}
	}
}
