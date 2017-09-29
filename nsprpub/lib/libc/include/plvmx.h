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

int   vmx_haschr(const void *b, int c, size_t len);
void *vmx_memchr(const void *b, int c, size_t len);
char *vmx_strchr(const char *p, int ch);

#if defined (__cplusplus)
}
#endif

#define VMX_HASCHR vmx_haschr
#define VMX_MEMCHR vmx_memchr
#define VMX_STRCHR vmx_strchr
#else
#if defined (__cplusplus)
#define VMX_HASCHR(a,b,c) (memchr(a,b,c) != nullptr)
#else
#define VMX_HASCHR(a,b,c) (!!memchr(a,b,c))
#endif
#define VMX_MEMCHR memchr
#define VMX_STRCHR strchr
#endif

#endif
