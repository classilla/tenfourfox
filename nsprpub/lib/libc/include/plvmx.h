#include <stdlib.h>
#include <sys/types.h>

/* In general, you should include "mozilla-config.h" or the equivalent
   before including this file to choose the proper macro. */

#ifndef _nspr_plvmx_h
#define _nspr_plvmx_h

#if TENFOURFOX_VMX

#if defined (__cplusplus)
extern "C" {
#endif

void *vmx_memchr(const void *b, int c, size_t len);

#if defined (__cplusplus)
}
#endif

#define VMX_MEMCHR vmx_memchr
#else
#define VMX_MEMCHR memchr
#endif

#endif
