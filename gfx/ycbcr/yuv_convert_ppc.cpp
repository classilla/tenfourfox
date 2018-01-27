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
  // splat the multiplicands. AltiVec makes this unnecessarily difficult.
  unsigned short __attribute__ ((aligned(16))) syf = source_y_fraction;
  unsigned short __attribute__ ((aligned(16))) syf2 = (256 - source_y_fraction);
  register vector unsigned short y1_fraction = vec_lde(0, &syf);
  y1_fraction = vec_splat(y1_fraction, 0);
  register vector unsigned short y0_fraction = vec_lde(0, &syf2);
  y0_fraction = vec_splat(y0_fraction, 0);

  register vector unsigned short vector_eight = vec_splat_u16(8);
  register vector unsigned short vector_zero = vec_splat_u16(0);
  register vector unsigned char vector_c_zero = vec_splat_u8(0);

  uint8 *end = ybuf + source_width;

  // Compute a weighted average.
  do {
    vector unsigned char r0;
    vector unsigned char c0 = vec_ld(0, y0_ptr);
    vector unsigned char c1 = vec_ld(0, y1_ptr);

        // another VMX annoyance: unpackh/l are SIGNED. bastard Motorola.
        register vector unsigned short y0 = vec_mergeh(vector_c_zero, c0);
        register vector unsigned short y1 = vec_mergeh(vector_c_zero, c1);
        register vector unsigned short y2 = vec_mergel(vector_c_zero, c0);
        register vector unsigned short y3 = vec_mergel(vector_c_zero, c1);

        // FUSED MULTIPLY ADD, BEYOTCHES! INTEL SUX!
        y1 = vec_mladd(y1, y1_fraction, vector_zero);
        y0 = vec_mladd(y0, y0_fraction, y1);
        y0 = vec_sr(y0, vector_eight);

        y3 = vec_mladd(y3, y1_fraction, vector_zero);
        y2 = vec_mladd(y2, y0_fraction, y3);
        y2 = vec_sr(y2, vector_eight);

        r0 = vec_pack(y0, y2);

    vec_st(r0, 0, (unsigned char *)ybuf);
    ybuf += 16;
    y0_ptr += 16;
    y1_ptr += 16;
  } while (ybuf < end);
}


}
}

#endif // TENFOURFOX_VMX
