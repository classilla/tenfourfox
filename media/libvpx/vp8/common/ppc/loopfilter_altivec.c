/*
 *  Copyright (c) 2010 The WebM project authors. All Rights Reserved.
 *  Copyright (c) 2012 Cameron Kaiser.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#include "vpx_config.h"
#include "vp8/common/loopfilter.h"
#include "vp8/common/onyxc_int.h"

/*
 * The actual declarations of these C routines are in ../loopfilter.h.
 */

typedef void loop_filter_function_y_ppc
(
    unsigned char *s,   // source pointer
    int p,              // pitch
    const unsigned char *flimit,
    const unsigned char *limit,
    const unsigned char *thresh
);

typedef void loop_filter_function_uv_ppc
(
    unsigned char *u,   // source pointer
    unsigned char *v,   // source pointer
    int p,              // pitch
    const unsigned char *flimit,
    const unsigned char *limit,
    const unsigned char *thresh
);

typedef void loop_filter_function_s_ppc
(
    unsigned char *s,   // source pointer
    int p,              // pitch
    const unsigned char *flimit
);

// We can't use the regular prototypes for these, they're too old.
loop_filter_function_y_ppc mbloop_filter_horizontal_edge_y_ppc;
loop_filter_function_y_ppc mbloop_filter_vertical_edge_y_ppc;
loop_filter_function_y_ppc loop_filter_horizontal_edge_y_ppc;
loop_filter_function_y_ppc loop_filter_vertical_edge_y_ppc;

loop_filter_function_uv_ppc mbloop_filter_horizontal_edge_uv_ppc;
loop_filter_function_uv_ppc mbloop_filter_vertical_edge_uv_ppc;
loop_filter_function_uv_ppc loop_filter_horizontal_edge_uv_ppc;
loop_filter_function_uv_ppc loop_filter_vertical_edge_uv_ppc;

/*
loop_filter_function_s_ppc loop_filter_simple_horizontal_edge_ppc;
loop_filter_function_s_ppc loop_filter_simple_vertical_edge_ppc;
*/

// Horizontal MB filtering
void vp8_loop_filter_mbh_ppc(unsigned char *y_ptr, unsigned char *u_ptr, unsigned char *v_ptr,
                         int y_stride, int uv_stride, loop_filter_info *lfi)
{
    mbloop_filter_horizontal_edge_y_ppc(y_ptr, y_stride, lfi->mblim, lfi->lim, lfi->hev_thr);

    if (u_ptr || v_ptr)
        mbloop_filter_horizontal_edge_uv_ppc(u_ptr, v_ptr, uv_stride, lfi->mblim, lfi->lim, lfi->hev_thr);
}

// Vertical MB Filtering
void vp8_loop_filter_mbv_ppc(unsigned char *y_ptr, unsigned char *u_ptr, unsigned char *v_ptr,
                         int y_stride, int uv_stride, loop_filter_info *lfi)
{
    mbloop_filter_vertical_edge_y_ppc(y_ptr, y_stride, lfi->mblim, lfi->lim, lfi->hev_thr);

    if (u_ptr || v_ptr)
        mbloop_filter_vertical_edge_uv_ppc(u_ptr, v_ptr, uv_stride, lfi->mblim, lfi->lim, lfi->hev_thr);
}

// Horizontal B Filtering
void vp8_loop_filter_bh_ppc(unsigned char *y_ptr, unsigned char *u_ptr, unsigned char *v_ptr,
                        int y_stride, int uv_stride, loop_filter_info *lfi)
{
    // These should all be done at once with one call, instead of 3
    loop_filter_horizontal_edge_y_ppc(y_ptr + 4 * y_stride, y_stride, lfi->blim, lfi->lim, lfi->hev_thr);
    loop_filter_horizontal_edge_y_ppc(y_ptr + 8 * y_stride, y_stride, lfi->blim, lfi->lim, lfi->hev_thr);
    loop_filter_horizontal_edge_y_ppc(y_ptr + 12 * y_stride, y_stride, lfi->blim, lfi->lim, lfi->hev_thr);

    if (u_ptr || v_ptr)
        loop_filter_horizontal_edge_uv_ppc(u_ptr + 4 * uv_stride, v_ptr + 4 * uv_stride, uv_stride, lfi->blim, lfi->lim, lfi->hev_thr);
}

void vp8_loop_filter_bhs_ppc(unsigned char *y_ptr, int y_stride, const unsigned char *blimit)
{
    loop_filter_simple_horizontal_edge_ppc(y_ptr + 4 * y_stride, y_stride, blimit);
    loop_filter_simple_horizontal_edge_ppc(y_ptr + 8 * y_stride, y_stride, blimit);
    loop_filter_simple_horizontal_edge_ppc(y_ptr + 12 * y_stride, y_stride, blimit);
}

// Vertical B Filtering
void vp8_loop_filter_bv_ppc(unsigned char *y_ptr, unsigned char *u_ptr, unsigned char *v_ptr,
                        int y_stride, int uv_stride, loop_filter_info *lfi)
{
    loop_filter_vertical_edge_y_ppc(y_ptr, y_stride, lfi->blim, lfi->lim, lfi->hev_thr);

    if (u_ptr || v_ptr)
        loop_filter_vertical_edge_uv_ppc(u_ptr + 4, v_ptr + 4, uv_stride, lfi->blim, lfi->lim, lfi->hev_thr);
}

void vp8_loop_filter_bvs_ppc(unsigned char *y_ptr, int y_stride, const unsigned char *blimit)
{
    loop_filter_simple_vertical_edge_ppc(y_ptr + 4,  y_stride, blimit);
    loop_filter_simple_vertical_edge_ppc(y_ptr + 8,  y_stride, blimit);
    loop_filter_simple_vertical_edge_ppc(y_ptr + 12, y_stride, blimit);
}

// Miscellaneous simple filters

void vp8_loop_filter_mbhs_ppc(unsigned char *y_ptr, int y_stride, const unsigned char *blimit)
{
    loop_filter_simple_horizontal_edge_ppc(y_ptr, y_stride, blimit);
}

void vp8_loop_filter_mbvs_ppc(unsigned char *y_ptr, int y_stride, const unsigned char *blimit)
{
    loop_filter_simple_vertical_edge_ppc(y_ptr, y_stride, blimit);
}
