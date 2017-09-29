#include <stdio.h>
#include "plvmx.h"

/* VMX/AltiVec specific libc functions for TenFourFox. */

/* The below is from
https://github.com/ridiculousfish/HexFiend/blob/4d5bcee5715f5f288649f7471d1da5bd06376f46/framework/sources/HFFastMemchr.m
   with some optimizations and fixes. */

int vmx_haschr(const void *b, int c, size_t length) {
    const unsigned char *haystack = (const unsigned char *)b;
    unsigned char needle = (unsigned char)c;

    unsigned prefixLength = (unsigned)((16 - ((unsigned long)haystack) % 16) % 16);
    unsigned suffixLength = (unsigned)(((unsigned long)(haystack + length)) % 16);
    // It is possible for altivecLength to be < 0 for short strings.
    int altivecLength = length - prefixLength - suffixLength;

    if (altivecLength < 16) {
        while (length--) {
            if (*haystack == needle) return 1;
            haystack++;
        }
        return 0;
    }

    size_t numVectors = altivecLength >> 4;
    while (prefixLength--) {
        if (*haystack == needle) return 1;
        haystack++;
    }
    
    unsigned int mashedByte = (needle << 24 ) | (needle << 16) | (needle << 8) | needle;
    const vector unsigned char searchVector = (vector unsigned int){mashedByte, mashedByte, mashedByte, mashedByte};
    while (numVectors--) {
        if (vec_any_eq(*(const vector unsigned char*)haystack, searchVector))
		return 1;
        haystack += 16;
    }
    
    while (suffixLength--) {
        if (*haystack == needle) return 1;
        haystack++;
    }
    
    return 0;
}

void *vmx_memchr(const void *b, int c, size_t length) {
    const unsigned char *haystack = (const unsigned char *)b;
    unsigned char needle = (unsigned char)c;

    unsigned prefixLength = (unsigned)((16 - ((unsigned long)haystack) % 16) % 16);
    unsigned suffixLength = (unsigned)(((unsigned long)(haystack + length)) % 16);
    // It is possible for altivecLength to be < 0 for short strings.
    int altivecLength = length - prefixLength - suffixLength;

    if (altivecLength < 16) {
        while (length--) {
            if (*haystack == needle) return (void *)haystack;
            haystack++;
        }
        return NULL;
    }

    size_t numVectors = altivecLength >> 4;
    while (prefixLength--) {
        if (*haystack == needle) return (void *)haystack;
        haystack++;
    }
    
    unsigned int mashedByte = (needle << 24 ) | (needle << 16) | (needle << 8) | needle;
    const vector unsigned char searchVector = (vector unsigned int){mashedByte, mashedByte, mashedByte, mashedByte};
    while (numVectors--) {
        if (vec_any_eq(*(const vector unsigned char*)haystack, searchVector)) goto foundResult;
        haystack += 16;
    }
    
    while (suffixLength--) {
        if (*haystack == needle) return (void *)haystack;
        haystack++;
    }
    
    return NULL;
    
foundResult:
        ;
    unsigned int val;
    
    // Some byte has the result; look in groups of 4 to find which one.
    // Unroll the loop.
    val = *(unsigned int*)haystack;
    if (((val >> 24) & 0xFF) == needle) return (void *)haystack;
    if (((val >> 16) & 0xFF) == needle) return (void *)(1 + haystack);
    if (((val >> 8) & 0xFF)  == needle) return (void *)(2 + haystack);
    if ((val & 0xFF)         == needle) return (void *)(3 + haystack);
    haystack += 4;
    val = *(unsigned int*)haystack;
    if (((val >> 24) & 0xFF) == needle) return (void *)haystack;
    if (((val >> 16) & 0xFF) == needle) return (void *)(1 + haystack);
    if (((val >> 8) & 0xFF)  == needle) return (void *)(2 + haystack);
    if ((val & 0xFF)         == needle) return (void *)(3 + haystack);
    haystack += 4;
    val = *(unsigned int*)haystack;
    if (((val >> 24) & 0xFF) == needle) return (void *)haystack;
    if (((val >> 16) & 0xFF) == needle) return (void *)(1 + haystack);
    if (((val >> 8) & 0xFF)  == needle) return (void *)(2 + haystack);
    if ((val & 0xFF)         == needle) return (void *)(3 + haystack);
    haystack += 4;
    val = *(unsigned int*)haystack;
    if (((val >> 24) & 0xFF) == needle) return (void *)haystack;
    if (((val >> 16) & 0xFF) == needle) return (void *)(1 + haystack);
    if (((val >> 8) & 0xFF)  == needle) return (void *)(2 + haystack);
    if ((val & 0xFF)         == needle) return (void *)(3 + haystack);
    
    // unreachable
    fprintf(stderr, "failed vmx_memchr()\n");
    return NULL;
}

char *vmx_strchr(const char *p, int ch) {
	unsigned char c = (unsigned char)ch;
	unsigned int val;
	if ((uint32_t)p & 15) {
		for (;((uint32_t)p & 15);++p) {
			if (*p == c)    return ((char *)p);
			if (*p == '\0') return NULL;
		}
	}
	
	unsigned int mashedByte =	(c << 24) |
					(c << 16) |
					(c << 8)  | c;
	const vector unsigned char searchVector = (vector unsigned int){
		mashedByte, mashedByte, mashedByte, mashedByte};
	const vector unsigned char nullVector = vec_splat_u8(0);

	for(; ; p+=16) {
		const vector unsigned char *w = (const vector unsigned char*)p;
		if (vec_any_eq(*w, searchVector)) break;
		if (vec_any_eq(*w, nullVector))   return NULL;
	}

	// Some byte has the result; look in groups of 4 to find which one.
	// Unroll the loop.
	val = *(unsigned int*)p;
	if (((val >> 24) & 0xFF) == c) return (void *)p;
	if (((val >> 16) & 0xFF) == c) return (void *)(1 + p);
	if (((val >> 8) & 0xFF)  == c) return (void *)(2 + p);
	if ((val & 0xFF)         == c) return (void *)(3 + p);
	p += 4;
	val = *(unsigned int*)p;
	if (((val >> 24) & 0xFF) == c) return (void *)p;
	if (((val >> 16) & 0xFF) == c) return (void *)(1 + p);
	if (((val >> 8) & 0xFF)  == c) return (void *)(2 + p);
	if ((val & 0xFF)         == c) return (void *)(3 + p);
	p += 4;
	val = *(unsigned int*)p;
	if (((val >> 24) & 0xFF) == c) return (void *)p;
	if (((val >> 16) & 0xFF) == c) return (void *)(1 + p);
	if (((val >> 8) & 0xFF)  == c) return (void *)(2 + p);
	if ((val & 0xFF)         == c) return (void *)(3 + p);
	p += 4;
	val = *(unsigned int*)p;
	if (((val >> 24) & 0xFF) == c) return (void *)p;
	if (((val >> 16) & 0xFF) == c) return (void *)(1 + p);
	if (((val >> 8) & 0xFF)  == c) return (void *)(2 + p);
	if ((val & 0xFF)         == c) return (void *)(3 + p);

	// unreachable
	fprintf(stderr, "failed vmx_strchr()\n");
	return NULL;
}

