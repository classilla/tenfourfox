// Modified from the SSE2 version to AltiVec/VMX for TenFourFox
// Cameron Kaiser <classilla@floodgap.com>
// MPL

#ifdef TENFOURFOX_VMX

#include <altivec.h>
#include "yuv_row.h"
#include <stdio.h>

namespace mozilla {
namespace gfx {

// FilterRows combines two rows of the image using linear interpolation.
// VMX version does 16 pixels at a time.
void FilterRows_VMX(uint8* ybuf, const uint8* y0_ptr, const uint8* y1_ptr,
                     int source_width, int source_y_fraction) {
  register vector unsigned short vector_zero = vec_splat_u16(0);
  register vector unsigned char r0, c0, c1;
  register vector unsigned short y0, y1, y2, y3;

  uint8 *end = ybuf + source_width;
  
  // Although you'd think using a version with vec_avg for 50% would
  // be profitable to write, in practice it doesn't seem to be used
  // much if at all, so this doesn't implement one.

  // Splat the multiplicands. AltiVec makes this unnecessarily difficult.
  unsigned short __attribute__ ((aligned(16))) syf = source_y_fraction;
  unsigned short __attribute__ ((aligned(16))) syf2 = (256 - source_y_fraction);
  register vector unsigned short y1_fraction = vec_lde(0, &syf);
  y1_fraction = vec_splat(y1_fraction, 0);
  register vector unsigned short y0_fraction = vec_lde(0, &syf2);
  y0_fraction = vec_splat(y0_fraction, 0);
  
  // Permute vector for combining shift and pack in one operation.
  // This effectively shifts each vector down by 8 bits and packs.
  register vector unsigned char vector_sh8pak =
    { 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30 };

  // Compute a weighted average.
  do {
    c0 = vec_ld(0, y0_ptr);
    c1 = vec_ld(0, y1_ptr);

    // Expand to short, since vec_mladd does not exist for char (damn).
    y0 = vec_mergeh((vector unsigned char)vector_zero, c0);
    y1 = vec_mergeh((vector unsigned char)vector_zero, c1);
    y2 = vec_mergel((vector unsigned char)vector_zero, c0);
    y3 = vec_mergel((vector unsigned char)vector_zero, c1);

    // FUSED MULTIPLY ADD, BEYOTCHES! INTEL SUX!
    // Interleave the operations.
    y1 = vec_mladd(y1, y1_fraction, vector_zero);
    y3 = vec_mladd(y3, y1_fraction, vector_zero);
    y0 = vec_mladd(y0, y0_fraction, y1);
    y2 = vec_mladd(y2, y0_fraction, y3);

    // Turn vec_sr on y0/y2 and a vec_pack into a single op.
    r0 = vec_perm((vector unsigned char)y0, (vector unsigned char)y2, vector_sh8pak);

    vec_st(r0, 0, (unsigned char *)ybuf);
    ybuf += 16;
    y0_ptr += 16;
    y1_ptr += 16;
  } while (ybuf < end);
}


}
}

#endif // TENFOURFOX_VMX
