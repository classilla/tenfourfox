#include "nscore.h"
#include "nsAlgorithm.h"
#include <altivec.h>
#include <nsUTF8Utils.h>

// Tobias' VMX lossy converter

// Safe to use with aligned and unaligned addresses
#define LoadUnaligned( return, index, target, MSQ, LSQ , mask) \
{ \
  LSQ = vec_ldl(index + 15, target); \
  return = vec_perm(MSQ, LSQ, mask); \
}

void
LossyConvertEncoding16to8::write_vmx(const char16_t* aSource,
                                      uint32_t aSourceLength)
{
  char* dest = mDestination;

  // Align destination to a 16-byte boundary.
  // We must use unsigned datatypes because aSourceLength is unsigned.
  uint32_t i = 0;
  uint32_t alignLen = XPCOM_MIN(aSourceLength, uint32_t(-NS_PTR_TO_INT32(dest) & 0xf));
  // subtraction result can underflow if aSourceLength < alignLen!!!
  // check for underflow
  if (aSourceLength >= alignLen && aSourceLength - alignLen > 31) {
    for (; i < alignLen; i++) {
      dest[i] = static_cast<unsigned char>(aSource[i]);
    }

    // maxIndex can underflow if aSourceLength < 33!!!
    uint32_t maxIndex = aSourceLength - 33;

    // check for underflow
    if (maxIndex <= aSourceLength && i < maxIndex) {
      const char16_t *aOurSource = &aSource[i];
      char *aOurDest = &dest[i];
      register vector unsigned char packed1, packed2;
      register vector unsigned short source1, source2, source3, source4;
      if ((NS_PTR_TO_UINT32(aOurSource) & 15) == 0) {
        // Walk 64 bytes (four VMX registers) at a time.
        while (1) {
          source1 = vec_ld(0, (unsigned short *)aOurSource);
          source2 = vec_ld(16, (unsigned short *)aOurSource);
          source3 = vec_ld(32, (unsigned short *)aOurSource);
          source4 = vec_ld(48, (unsigned short *)aOurSource);
          packed1 = vec_packsu(source1, source2);
          packed2 = vec_packsu(source3, source4);
          vec_st(packed1, 0, (unsigned char *)aOurDest);
          vec_st(packed2, 16, (unsigned char *)aOurDest);
          i += 32;
          if(i > maxIndex)
           break;
          aOurDest += 32;
          aOurSource += 32;
        }
      }
      else {
        register vector unsigned char mask = vec_lvsl(0, (unsigned short *)aOurSource);
        register vector unsigned short vector1  = vec_ld(0, (unsigned short *)aOurSource);
        register vector unsigned short vector2;
        // Walk 64 bytes (four VMX registers) at a time.
        while (1) {
          LoadUnaligned(source1, 0, (unsigned short *)aOurSource, vector1, vector2, mask);
          LoadUnaligned(source2, 16, (unsigned short *)aOurSource, vector2, vector1, mask);
          LoadUnaligned(source3, 32, (unsigned short *)aOurSource, vector1, vector2, mask);
          LoadUnaligned(source4, 48, (unsigned short *)aOurSource, vector2, vector1, mask);
          packed1 = vec_packsu(source1, source2);
          packed2 = vec_packsu(source3, source4);
          vec_st(packed1, 0, (unsigned char *)aOurDest);
          vec_st(packed2, 16, (unsigned char *)aOurDest);
          i += 32;
          if(i > maxIndex)
            break;
          aOurDest += 32;
          aOurSource += 32;
        }
      }
    }
  }

  // Finish up the rest.
  for (; i < aSourceLength; i++) {
    dest[i] = static_cast<unsigned char>(aSource[i]);
  }

  mDestination += i;
}

void
LossyConvertEncoding8to16::write_vmx(const char* aSource,
                                      uint32_t aSourceLength)
{
  char16_t *dest = mDestination;

  // Align dest destination to a 16-byte boundary.  We choose to align dest rather than
  // source because we can store neither safely nor fast to unaligned addresses.
  // We must use unsigned datatypes because aSourceLength is unsigned.
  uint32_t i = 0;
  uint32_t alignLen = XPCOM_MIN<uint32_t>(aSourceLength, uint32_t(-NS_PTR_TO_INT32(dest) & 0xf) / sizeof(char16_t));
  // subtraction result can underflow if aSourceLength < alignLen!!!
  // check for underflow
  if (aSourceLength >= alignLen && aSourceLength - alignLen > 31) {
    for (; i < alignLen; i++) {
      dest[i] = static_cast<unsigned char>(aSource[i]);
    }

    // maxIndex can underflow if aSourceLength < 33!!!
    uint32_t maxIndex = aSourceLength - 33;

    // check for underflow
    if (maxIndex <= aSourceLength && i < maxIndex) {
      const char *aOurSource = &aSource[i];
      char16_t *aOurDest = &dest[i];
      register const vector unsigned char zeroes = vec_splat_u8( 0 );
      register vector unsigned char source1, source2, lo1, hi1, lo2, hi2;
      if ((NS_PTR_TO_UINT32(aOurSource) & 15) == 0) {
        // Walk 32 bytes (two VMX registers) at a time.
        while (1) {
          source1 = vec_ld(0, (unsigned char *)aOurSource);
          source2 = vec_ld(16, (unsigned char *)aOurSource);

          // Interleave 0s in with the bytes of source to create lo and hi.
          // store lo and hi into dest.
          hi1 = vec_mergeh(zeroes, source1);
          lo1 = vec_mergel(zeroes, source1);
          hi2 = vec_mergeh(zeroes, source2);
          lo2 = vec_mergel(zeroes, source2);

          vec_st(hi1, 0, (unsigned char *)aOurDest);
          vec_st(lo1, 16, (unsigned char *)aOurDest);
          vec_st(hi2, 32, (unsigned char *)aOurDest);
          vec_st(lo2, 48, (unsigned char *)aOurDest);

          i += 32;
          if (i > maxIndex)
            break;
          aOurSource += 32;
          aOurDest += 32;
        }
      }
      else  {
        register vector unsigned char mask = vec_lvsl(0, (unsigned char *)aOurSource);
        register vector unsigned char vector1  = vec_ld(0, (unsigned char *)aOurSource);
        register vector unsigned char vector2;
        // Walk 32 bytes (two VMX registers) at a time.
        while (1) {
          LoadUnaligned(source1, 0, (unsigned char *)aOurSource, vector1, vector2, mask);
          LoadUnaligned(source2, 16, (unsigned char *)aOurSource, vector2, vector1, mask);

          // Interleave 0s in with the bytes of source to create lo and hi.
          // store lo and hi into dest.
          hi1 = vec_mergeh(zeroes, source1);
          lo1 = vec_mergel(zeroes, source1);
          hi2 = vec_mergeh(zeroes, source2);
          lo2 = vec_mergel(zeroes, source2);

          vec_st(hi1, 0, (unsigned char *)aOurDest);
          vec_st(lo1, 16, (unsigned char *)aOurDest);
          vec_st(hi2, 32, (unsigned char *)aOurDest);
          vec_st(lo2, 48, (unsigned char *)aOurDest);

          i += 32;
          if (i > maxIndex)
            break;
          aOurSource += 32;
          aOurDest += 32;
        }
      }
    }
  }

  // Finish up whatever's left.
  for (; i < aSourceLength; i++) {
    dest[i] = static_cast<unsigned char>(aSource[i]);
  }

  mDestination += i;
}
