
/* powerpc_vmx_init.c - PowerPC optimised filter functions
 * for original AltiVec/VMX
 *
 * This is a simple stub dispatch for TenFourFox; it isn't
 * intended to be upstreamed.
 * Copyright 2017-8 Cameron Kaiser and Contributors to TenFourFox.
 * All rights reserved. */

#ifdef PNG_READ_SUPPORTED
#if PNG_POWERPC_VMX_OPT > 0

void
png_init_filter_functions_vmx(png_structp pp, unsigned int bpp)
{
   /* If VMX is turned on, then we enable at compile time. 
      moz.build sets PNG_POWERPC_VMX_IMPLEMENTATION and
      PNG_POWERPC_VMX_OPT based on TENFOURFOX_VMX. */

   /* IMPORTANT: any new internal functions used here must be declared using
    * PNG_INTERNAL_FUNCTION in ../pngpriv.h.  This is required so that the
    * 'prefix' option to configure works:
    *
    *    ./configure --with-libpng-prefix=foobar_
    *
    * Verify you have got this right by running the above command, doing a build
    * and examining pngprefix.h; it must contain a #define for every external
    * function you add.  (Notice that this happens automatically for the
    * initialization function.)
    */
   pp->read_filter[PNG_FILTER_VALUE_UP-1] = png_read_filter_row_up_vmx;

   if (bpp == 3)
   {
      pp->read_filter[PNG_FILTER_VALUE_SUB-1] = png_read_filter_row_sub3_vmx;
      pp->read_filter[PNG_FILTER_VALUE_AVG-1] = png_read_filter_row_avg3_vmx;
      pp->read_filter[PNG_FILTER_VALUE_PAETH-1] = png_read_filter_row_paeth3_vmx;
   }

   else if (bpp == 4)
   {
      pp->read_filter[PNG_FILTER_VALUE_SUB-1] = png_read_filter_row_sub4_vmx;
      pp->read_filter[PNG_FILTER_VALUE_AVG-1] = png_read_filter_row_avg4_vmx;
      pp->read_filter[PNG_FILTER_VALUE_PAETH-1] = png_read_filter_row_paeth4_vmx;
   }
}

#endif
#endif

