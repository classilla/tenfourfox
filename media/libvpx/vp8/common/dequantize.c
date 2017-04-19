/*
 *  Copyright (c) 2010 The WebM project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */


#include "vpx_config.h"
#include "vp8_rtcd.h"
#include "vp8/common/blockd.h"
#include "vpx_mem/vpx_mem.h"

#if HAVE_ALTIVEC
extern void short_idct4x4llm_ppc(short *input, unsigned char *pred_ptr,
                                 int pred_stride, unsigned char *dst_ptr,
                                 int dst_stride);
extern void vp8_short_idct4x4llm_1_c(short *input, unsigned char *pred_ptr,
                                     int pred_stride, unsigned char *dst_ptr,
                                     int dst_stride);
#endif

void vp8_dequantize_b_c(BLOCKD *d, short *DQC)
{
    int i;
    short *DQ  = d->dqcoeff;
    short *Q   = d->qcoeff;

    for (i = 0; i < 16; i++)
    {
        DQ[i] = Q[i] * DQC[i];
    }
}

void vp8_dequant_idct_add_c(short *input, short *dq,
                            unsigned char *dest, int stride)
{
    int i;
#if HAVE_ALTIVEC
    short output[16];
#endif

    for (i = 0; i < 16; i++)
    {
        input[i] = dq[i] * input[i];
    }

#if HAVE_ALTIVEC
    // memset(output, 0, 16); // future-proof
    short_idct4x4llm_ppc(input, output, 8, output, 8);
    vp8_short_idct4x4llm_1_c(output, dest, stride, dest, stride);
#else
    vp8_short_idct4x4llm_c(input, dest, stride, dest, stride);
#endif

    memset(input, 0, 32);

}
