// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "yuv_row.h"
#include "mozilla/SSE.h"
#ifdef TENFOURFOX_VMX
#include <altivec.h>
#endif

#define DCHECK(a)

extern "C" {

#if defined(ARCH_CPU_X86_64)

// We don't need CPUID guards here, since x86-64 implies SSE2.

// AMD64 ABI uses register paremters.
void FastConvertYUVToRGB32Row(const uint8* y_buf,  // rdi
                              const uint8* u_buf,  // rsi
                              const uint8* v_buf,  // rdx
                              uint8* rgb_buf,      // rcx
                              int width) {         // r8
  asm(
  "jmp    1f\n"
"0:"
  "movzb  (%1),%%r10\n"
  "add    $0x1,%1\n"
  "movzb  (%2),%%r11\n"
  "add    $0x1,%2\n"
  "movq   2048(%5,%%r10,8),%%xmm0\n"
  "movzb  (%0),%%r10\n"
  "movq   4096(%5,%%r11,8),%%xmm1\n"
  "movzb  0x1(%0),%%r11\n"
  "paddsw %%xmm1,%%xmm0\n"
  "movq   (%5,%%r10,8),%%xmm2\n"
  "add    $0x2,%0\n"
  "movq   (%5,%%r11,8),%%xmm3\n"
  "paddsw %%xmm0,%%xmm2\n"
  "paddsw %%xmm0,%%xmm3\n"
  "shufps $0x44,%%xmm3,%%xmm2\n"
  "psraw  $0x6,%%xmm2\n"
  "packuswb %%xmm2,%%xmm2\n"
  "movq   %%xmm2,0x0(%3)\n"
  "add    $0x8,%3\n"
"1:"
  "sub    $0x2,%4\n"
  "jns    0b\n"

"2:"
  "add    $0x1,%4\n"
  "js     3f\n"

  "movzb  (%1),%%r10\n"
  "movq   2048(%5,%%r10,8),%%xmm0\n"
  "movzb  (%2),%%r10\n"
  "movq   4096(%5,%%r10,8),%%xmm1\n"
  "paddsw %%xmm1,%%xmm0\n"
  "movzb  (%0),%%r10\n"
  "movq   (%5,%%r10,8),%%xmm1\n"
  "paddsw %%xmm0,%%xmm1\n"
  "psraw  $0x6,%%xmm1\n"
  "packuswb %%xmm1,%%xmm1\n"
  "movd   %%xmm1,0x0(%3)\n"
"3:"
  :
  : "r"(y_buf),  // %0
    "r"(u_buf),  // %1
    "r"(v_buf),  // %2
    "r"(rgb_buf),  // %3
    "r"(width),  // %4
    "r" (kCoefficientsRgbY)  // %5
  : "memory", "r10", "r11", "xmm0", "xmm1", "xmm2", "xmm3"
);
}

void ScaleYUVToRGB32Row(const uint8* y_buf,  // rdi
                        const uint8* u_buf,  // rsi
                        const uint8* v_buf,  // rdx
                        uint8* rgb_buf,      // rcx
                        int width,           // r8
                        int source_dx) {     // r9
  asm(
  "xor    %%r11,%%r11\n"
  "sub    $0x2,%4\n"
  "js     1f\n"

"0:"
  "mov    %%r11,%%r10\n"
  "sar    $0x11,%%r10\n"
  "movzb  (%1,%%r10,1),%%rax\n"
  "movq   2048(%5,%%rax,8),%%xmm0\n"
  "movzb  (%2,%%r10,1),%%rax\n"
  "movq   4096(%5,%%rax,8),%%xmm1\n"
  "lea    (%%r11,%6),%%r10\n"
  "sar    $0x10,%%r11\n"
  "movzb  (%0,%%r11,1),%%rax\n"
  "paddsw %%xmm1,%%xmm0\n"
  "movq   (%5,%%rax,8),%%xmm1\n"
  "lea    (%%r10,%6),%%r11\n"
  "sar    $0x10,%%r10\n"
  "movzb  (%0,%%r10,1),%%rax\n"
  "movq   (%5,%%rax,8),%%xmm2\n"
  "paddsw %%xmm0,%%xmm1\n"
  "paddsw %%xmm0,%%xmm2\n"
  "shufps $0x44,%%xmm2,%%xmm1\n"
  "psraw  $0x6,%%xmm1\n"
  "packuswb %%xmm1,%%xmm1\n"
  "movq   %%xmm1,0x0(%3)\n"
  "add    $0x8,%3\n"
  "sub    $0x2,%4\n"
  "jns    0b\n"

"1:"
  "add    $0x1,%4\n"
  "js     2f\n"

  "mov    %%r11,%%r10\n"
  "sar    $0x11,%%r10\n"
  "movzb  (%1,%%r10,1),%%rax\n"
  "movq   2048(%5,%%rax,8),%%xmm0\n"
  "movzb  (%2,%%r10,1),%%rax\n"
  "movq   4096(%5,%%rax,8),%%xmm1\n"
  "paddsw %%xmm1,%%xmm0\n"
  "sar    $0x10,%%r11\n"
  "movzb  (%0,%%r11,1),%%rax\n"
  "movq   (%5,%%rax,8),%%xmm1\n"
  "paddsw %%xmm0,%%xmm1\n"
  "psraw  $0x6,%%xmm1\n"
  "packuswb %%xmm1,%%xmm1\n"
  "movd   %%xmm1,0x0(%3)\n"

"2:"
  :
  : "r"(y_buf),  // %0
    "r"(u_buf),  // %1
    "r"(v_buf),  // %2
    "r"(rgb_buf),  // %3
    "r"(width),  // %4
    "r" (kCoefficientsRgbY),  // %5
    "r"(static_cast<long>(source_dx))  // %6
  : "memory", "r10", "r11", "rax", "xmm0", "xmm1", "xmm2"
);
}

void LinearScaleYUVToRGB32Row(const uint8* y_buf,
                              const uint8* u_buf,
                              const uint8* v_buf,
                              uint8* rgb_buf,
                              int width,
                              int source_dx) {
  asm(
  "xor    %%r11,%%r11\n"   // x = 0
  "sub    $0x2,%4\n"
  "js     2f\n"
  "cmp    $0x20000,%6\n"   // if source_dx >= 2.0
  "jl     0f\n"
  "mov    $0x8000,%%r11\n" // x = 0.5 for 1/2 or less
"0:"

"1:"
  "mov    %%r11,%%r10\n"
  "sar    $0x11,%%r10\n"

  "movzb  (%1, %%r10, 1), %%r13 \n"
  "movzb  1(%1, %%r10, 1), %%r14 \n"
  "mov    %%r11, %%rax \n"
  "and    $0x1fffe, %%rax \n"
  "imul   %%rax, %%r14 \n"
  "xor    $0x1fffe, %%rax \n"
  "imul   %%rax, %%r13 \n"
  "add    %%r14, %%r13 \n"
  "shr    $17, %%r13 \n"
  "movq   2048(%5,%%r13,8), %%xmm0\n"

  "movzb  (%2, %%r10, 1), %%r13 \n"
  "movzb  1(%2, %%r10, 1), %%r14 \n"
  "mov    %%r11, %%rax \n"
  "and    $0x1fffe, %%rax \n"
  "imul   %%rax, %%r14 \n"
  "xor    $0x1fffe, %%rax \n"
  "imul   %%rax, %%r13 \n"
  "add    %%r14, %%r13 \n"
  "shr    $17, %%r13 \n"
  "movq   4096(%5,%%r13,8), %%xmm1\n"

  "mov    %%r11, %%rax \n"
  "lea    (%%r11,%6),%%r10\n"
  "sar    $0x10,%%r11\n"
  "paddsw %%xmm1,%%xmm0\n"

  "movzb  (%0, %%r11, 1), %%r13 \n"
  "movzb  1(%0, %%r11, 1), %%r14 \n"
  "and    $0xffff, %%rax \n"
  "imul   %%rax, %%r14 \n"
  "xor    $0xffff, %%rax \n"
  "imul   %%rax, %%r13 \n"
  "add    %%r14, %%r13 \n"
  "shr    $16, %%r13 \n"
  "movq   (%5,%%r13,8),%%xmm1\n"

  "mov    %%r10, %%rax \n"
  "lea    (%%r10,%6),%%r11\n"
  "sar    $0x10,%%r10\n"

  "movzb  (%0,%%r10,1), %%r13 \n"
  "movzb  1(%0,%%r10,1), %%r14 \n"
  "and    $0xffff, %%rax \n"
  "imul   %%rax, %%r14 \n"
  "xor    $0xffff, %%rax \n"
  "imul   %%rax, %%r13 \n"
  "add    %%r14, %%r13 \n"
  "shr    $16, %%r13 \n"
  "movq   (%5,%%r13,8),%%xmm2\n"

  "paddsw %%xmm0,%%xmm1\n"
  "paddsw %%xmm0,%%xmm2\n"
  "shufps $0x44,%%xmm2,%%xmm1\n"
  "psraw  $0x6,%%xmm1\n"
  "packuswb %%xmm1,%%xmm1\n"
  "movq   %%xmm1,0x0(%3)\n"
  "add    $0x8,%3\n"
  "sub    $0x2,%4\n"
  "jns    1b\n"

"2:"
  "add    $0x1,%4\n"
  "js     3f\n"

  "mov    %%r11,%%r10\n"
  "sar    $0x11,%%r10\n"

  "movzb  (%1,%%r10,1), %%r13 \n"
  "movq   2048(%5,%%r13,8),%%xmm0\n"

  "movzb  (%2,%%r10,1), %%r13 \n"
  "movq   4096(%5,%%r13,8),%%xmm1\n"

  "paddsw %%xmm1,%%xmm0\n"
  "sar    $0x10,%%r11\n"

  "movzb  (%0,%%r11,1), %%r13 \n"
  "movq   (%5,%%r13,8),%%xmm1\n"

  "paddsw %%xmm0,%%xmm1\n"
  "psraw  $0x6,%%xmm1\n"
  "packuswb %%xmm1,%%xmm1\n"
  "movd   %%xmm1,0x0(%3)\n"

"3:"
  :
  : "r"(y_buf),  // %0
    "r"(u_buf),  // %1
    "r"(v_buf),  // %2
    "r"(rgb_buf),  // %3
    "r"(width),  // %4
    "r" (kCoefficientsRgbY),  // %5
    "r"(static_cast<long>(source_dx))  // %6
  : "memory", "r10", "r11", "r13", "r14", "rax", "xmm0", "xmm1", "xmm2"
);
}

#elif defined(MOZILLA_MAY_SUPPORT_SSE) && defined(ARCH_CPU_X86_32) && !defined(__PIC__)

// PIC version is slower because less registers are available, so
// non-PIC is used on platforms where it is possible.
void FastConvertYUVToRGB32Row_SSE(const uint8* y_buf,
                                  const uint8* u_buf,
                                  const uint8* v_buf,
                                  uint8* rgb_buf,
                                  int width);
  asm(
  ".text\n"
  ".global FastConvertYUVToRGB32Row_SSE\n"
  ".type FastConvertYUVToRGB32Row_SSE, @function\n"
"FastConvertYUVToRGB32Row_SSE:\n"
  "pusha\n"
  "mov    0x24(%esp),%edx\n"
  "mov    0x28(%esp),%edi\n"
  "mov    0x2c(%esp),%esi\n"
  "mov    0x30(%esp),%ebp\n"
  "mov    0x34(%esp),%ecx\n"
  "jmp    1f\n"

"0:"
  "movzbl (%edi),%eax\n"
  "add    $0x1,%edi\n"
  "movzbl (%esi),%ebx\n"
  "add    $0x1,%esi\n"
  "movq   kCoefficientsRgbY+2048(,%eax,8),%mm0\n"
  "movzbl (%edx),%eax\n"
  "paddsw kCoefficientsRgbY+4096(,%ebx,8),%mm0\n"
  "movzbl 0x1(%edx),%ebx\n"
  "movq   kCoefficientsRgbY(,%eax,8),%mm1\n"
  "add    $0x2,%edx\n"
  "movq   kCoefficientsRgbY(,%ebx,8),%mm2\n"
  "paddsw %mm0,%mm1\n"
  "paddsw %mm0,%mm2\n"
  "psraw  $0x6,%mm1\n"
  "psraw  $0x6,%mm2\n"
  "packuswb %mm2,%mm1\n"
  "movntq %mm1,0x0(%ebp)\n"
  "add    $0x8,%ebp\n"
"1:"
  "sub    $0x2,%ecx\n"
  "jns    0b\n"

  "and    $0x1,%ecx\n"
  "je     2f\n"

  "movzbl (%edi),%eax\n"
  "movq   kCoefficientsRgbY+2048(,%eax,8),%mm0\n"
  "movzbl (%esi),%eax\n"
  "paddsw kCoefficientsRgbY+4096(,%eax,8),%mm0\n"
  "movzbl (%edx),%eax\n"
  "movq   kCoefficientsRgbY(,%eax,8),%mm1\n"
  "paddsw %mm0,%mm1\n"
  "psraw  $0x6,%mm1\n"
  "packuswb %mm1,%mm1\n"
  "movd   %mm1,0x0(%ebp)\n"
"2:"
  "popa\n"
  "ret\n"
#if !defined(XP_MACOSX)
  ".previous\n"
#endif
);

void FastConvertYUVToRGB32Row(const uint8* y_buf,
                              const uint8* u_buf,
                              const uint8* v_buf,
                              uint8* rgb_buf,
                              int width)
{
  if (mozilla::supports_sse()) {
    FastConvertYUVToRGB32Row_SSE(y_buf, u_buf, v_buf, rgb_buf, width);
    return;
  }

  FastConvertYUVToRGB32Row_C(y_buf, u_buf, v_buf, rgb_buf, width, 1);
}


void ScaleYUVToRGB32Row_SSE(const uint8* y_buf,
                            const uint8* u_buf,
                            const uint8* v_buf,
                            uint8* rgb_buf,
                            int width,
                            int source_dx);
  asm(
  ".text\n"
  ".global ScaleYUVToRGB32Row_SSE\n"
  ".type ScaleYUVToRGB32Row_SSE, @function\n"
"ScaleYUVToRGB32Row_SSE:\n"
  "pusha\n"
  "mov    0x24(%esp),%edx\n"
  "mov    0x28(%esp),%edi\n"
  "mov    0x2c(%esp),%esi\n"
  "mov    0x30(%esp),%ebp\n"
  "mov    0x34(%esp),%ecx\n"
  "xor    %ebx,%ebx\n"
  "jmp    1f\n"

"0:"
  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"
  "movzbl (%edi,%eax,1),%eax\n"
  "movq   kCoefficientsRgbY+2048(,%eax,8),%mm0\n"
  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"
  "movzbl (%esi,%eax,1),%eax\n"
  "paddsw kCoefficientsRgbY+4096(,%eax,8),%mm0\n"
  "mov    %ebx,%eax\n"
  "add    0x38(%esp),%ebx\n"
  "sar    $0x10,%eax\n"
  "movzbl (%edx,%eax,1),%eax\n"
  "movq   kCoefficientsRgbY(,%eax,8),%mm1\n"
  "mov    %ebx,%eax\n"
  "add    0x38(%esp),%ebx\n"
  "sar    $0x10,%eax\n"
  "movzbl (%edx,%eax,1),%eax\n"
  "movq   kCoefficientsRgbY(,%eax,8),%mm2\n"
  "paddsw %mm0,%mm1\n"
  "paddsw %mm0,%mm2\n"
  "psraw  $0x6,%mm1\n"
  "psraw  $0x6,%mm2\n"
  "packuswb %mm2,%mm1\n"
  "movntq %mm1,0x0(%ebp)\n"
  "add    $0x8,%ebp\n"
"1:"
  "sub    $0x2,%ecx\n"
  "jns    0b\n"

  "and    $0x1,%ecx\n"
  "je     2f\n"

  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"
  "movzbl (%edi,%eax,1),%eax\n"
  "movq   kCoefficientsRgbY+2048(,%eax,8),%mm0\n"
  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"
  "movzbl (%esi,%eax,1),%eax\n"
  "paddsw kCoefficientsRgbY+4096(,%eax,8),%mm0\n"
  "mov    %ebx,%eax\n"
  "sar    $0x10,%eax\n"
  "movzbl (%edx,%eax,1),%eax\n"
  "movq   kCoefficientsRgbY(,%eax,8),%mm1\n"
  "paddsw %mm0,%mm1\n"
  "psraw  $0x6,%mm1\n"
  "packuswb %mm1,%mm1\n"
  "movd   %mm1,0x0(%ebp)\n"

"2:"
  "popa\n"
  "ret\n"
#if !defined(XP_MACOSX)
  ".previous\n"
#endif
);

void ScaleYUVToRGB32Row(const uint8* y_buf,
                        const uint8* u_buf,
                        const uint8* v_buf,
                        uint8* rgb_buf,
                        int width,
                        int source_dx)
{
  if (mozilla::supports_sse()) {
    ScaleYUVToRGB32Row_SSE(y_buf, u_buf, v_buf, rgb_buf,
                           width, source_dx);
  }

  ScaleYUVToRGB32Row_C(y_buf, u_buf, v_buf, rgb_buf,
                       width, source_dx);
}

void LinearScaleYUVToRGB32Row_SSE(const uint8* y_buf,
                                  const uint8* u_buf,
                                  const uint8* v_buf,
                                  uint8* rgb_buf,
                                  int width,
                                  int source_dx);
  asm(
  ".text\n"
  ".global LinearScaleYUVToRGB32Row_SSE\n"
  ".type LinearScaleYUVToRGB32Row_SSE, @function\n"
"LinearScaleYUVToRGB32Row_SSE:\n"
  "pusha\n"
  "mov    0x24(%esp),%edx\n"
  "mov    0x28(%esp),%edi\n"
  "mov    0x30(%esp),%ebp\n"

  // source_width = width * source_dx + ebx
  "mov    0x34(%esp), %ecx\n"
  "imull  0x38(%esp), %ecx\n"
  "mov    %ecx, 0x34(%esp)\n"

  "mov    0x38(%esp), %ecx\n"
  "xor    %ebx,%ebx\n"     // x = 0
  "cmp    $0x20000,%ecx\n" // if source_dx >= 2.0
  "jl     1f\n"
  "mov    $0x8000,%ebx\n"  // x = 0.5 for 1/2 or less
  "jmp    1f\n"

"0:"
  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"

  "movzbl (%edi,%eax,1),%ecx\n"
  "movzbl 1(%edi,%eax,1),%esi\n"
  "mov    %ebx,%eax\n"
  "andl   $0x1fffe, %eax \n"
  "imul   %eax, %esi \n"
  "xorl   $0x1fffe, %eax \n"
  "imul   %eax, %ecx \n"
  "addl   %esi, %ecx \n"
  "shrl   $17, %ecx \n"
  "movq   kCoefficientsRgbY+2048(,%ecx,8),%mm0\n"

  "mov    0x2c(%esp),%esi\n"
  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"

  "movzbl (%esi,%eax,1),%ecx\n"
  "movzbl 1(%esi,%eax,1),%esi\n"
  "mov    %ebx,%eax\n"
  "andl   $0x1fffe, %eax \n"
  "imul   %eax, %esi \n"
  "xorl   $0x1fffe, %eax \n"
  "imul   %eax, %ecx \n"
  "addl   %esi, %ecx \n"
  "shrl   $17, %ecx \n"
  "paddsw kCoefficientsRgbY+4096(,%ecx,8),%mm0\n"

  "mov    %ebx,%eax\n"
  "sar    $0x10,%eax\n"
  "movzbl (%edx,%eax,1),%ecx\n"
  "movzbl 1(%edx,%eax,1),%esi\n"
  "mov    %ebx,%eax\n"
  "add    0x38(%esp),%ebx\n"
  "andl   $0xffff, %eax \n"
  "imul   %eax, %esi \n"
  "xorl   $0xffff, %eax \n"
  "imul   %eax, %ecx \n"
  "addl   %esi, %ecx \n"
  "shrl   $16, %ecx \n"
  "movq   kCoefficientsRgbY(,%ecx,8),%mm1\n"

  "cmp    0x34(%esp), %ebx\n"
  "jge    2f\n"

  "mov    %ebx,%eax\n"
  "sar    $0x10,%eax\n"
  "movzbl (%edx,%eax,1),%ecx\n"
  "movzbl 1(%edx,%eax,1),%esi\n"
  "mov    %ebx,%eax\n"
  "add    0x38(%esp),%ebx\n"
  "andl   $0xffff, %eax \n"
  "imul   %eax, %esi \n"
  "xorl   $0xffff, %eax \n"
  "imul   %eax, %ecx \n"
  "addl   %esi, %ecx \n"
  "shrl   $16, %ecx \n"
  "movq   kCoefficientsRgbY(,%ecx,8),%mm2\n"

  "paddsw %mm0,%mm1\n"
  "paddsw %mm0,%mm2\n"
  "psraw  $0x6,%mm1\n"
  "psraw  $0x6,%mm2\n"
  "packuswb %mm2,%mm1\n"
  "movntq %mm1,0x0(%ebp)\n"
  "add    $0x8,%ebp\n"

"1:"
  "cmp    0x34(%esp), %ebx\n"
  "jl     0b\n"
  "popa\n"
  "ret\n"

"2:"
  "paddsw %mm0, %mm1\n"
  "psraw $6, %mm1\n"
  "packuswb %mm1, %mm1\n"
  "movd %mm1, (%ebp)\n"
  "popa\n"
  "ret\n"
#if !defined(XP_MACOSX)
  ".previous\n"
#endif
);

void LinearScaleYUVToRGB32Row(const uint8* y_buf,
                              const uint8* u_buf,
                              const uint8* v_buf,
                              uint8* rgb_buf,
                              int width,
                              int source_dx)
{
  if (mozilla::supports_sse()) {
    LinearScaleYUVToRGB32Row_SSE(y_buf, u_buf, v_buf, rgb_buf,
                                 width, source_dx);
  }

  LinearScaleYUVToRGB32Row_C(y_buf, u_buf, v_buf, rgb_buf,
                             width, source_dx);
}

#elif defined(MOZILLA_MAY_SUPPORT_SSE) && defined(ARCH_CPU_X86_32) && defined(__PIC__)

void PICConvertYUVToRGB32Row_SSE(const uint8* y_buf,
                                 const uint8* u_buf,
                                 const uint8* v_buf,
                                 uint8* rgb_buf,
                                 int width,
                                 int16 *kCoefficientsRgbY);

  asm(
  ".text\n"
#if defined(XP_MACOSX)
"_PICConvertYUVToRGB32Row_SSE:\n"
#else
"PICConvertYUVToRGB32Row_SSE:\n"
#endif
  "pusha\n"
  "mov    0x24(%esp),%edx\n"
  "mov    0x28(%esp),%edi\n"
  "mov    0x2c(%esp),%esi\n"
  "mov    0x30(%esp),%ebp\n"
  "mov    0x38(%esp),%ecx\n"

  "jmp    1f\n"

"0:"
  "movzbl (%edi),%eax\n"
  "add    $0x1,%edi\n"
  "movzbl (%esi),%ebx\n"
  "add    $0x1,%esi\n"
  "movq   2048(%ecx,%eax,8),%mm0\n"
  "movzbl (%edx),%eax\n"
  "paddsw 4096(%ecx,%ebx,8),%mm0\n"
  "movzbl 0x1(%edx),%ebx\n"
  "movq   0(%ecx,%eax,8),%mm1\n"
  "add    $0x2,%edx\n"
  "movq   0(%ecx,%ebx,8),%mm2\n"
  "paddsw %mm0,%mm1\n"
  "paddsw %mm0,%mm2\n"
  "psraw  $0x6,%mm1\n"
  "psraw  $0x6,%mm2\n"
  "packuswb %mm2,%mm1\n"
  "movntq %mm1,0x0(%ebp)\n"
  "add    $0x8,%ebp\n"
"1:"
  "subl   $0x2,0x34(%esp)\n"
  "jns    0b\n"

  "andl   $0x1,0x34(%esp)\n"
  "je     2f\n"

  "movzbl (%edi),%eax\n"
  "movq   2048(%ecx,%eax,8),%mm0\n"
  "movzbl (%esi),%eax\n"
  "paddsw 4096(%ecx,%eax,8),%mm0\n"
  "movzbl (%edx),%eax\n"
  "movq   0(%ecx,%eax,8),%mm1\n"
  "paddsw %mm0,%mm1\n"
  "psraw  $0x6,%mm1\n"
  "packuswb %mm1,%mm1\n"
  "movd   %mm1,0x0(%ebp)\n"
"2:"
  "popa\n"
  "ret\n"
#if !defined(XP_MACOSX)
  ".previous\n"
#endif
);

void FastConvertYUVToRGB32Row(const uint8* y_buf,
                              const uint8* u_buf,
                              const uint8* v_buf,
                              uint8* rgb_buf,
                              int width)
{
  if (mozilla::supports_sse()) {
    PICConvertYUVToRGB32Row_SSE(y_buf, u_buf, v_buf, rgb_buf, width,
                                &kCoefficientsRgbY[0][0]);
    return;
  }

  FastConvertYUVToRGB32Row_C(y_buf, u_buf, v_buf, rgb_buf, width, 1);
}

void PICScaleYUVToRGB32Row_SSE(const uint8* y_buf,
                               const uint8* u_buf,
                               const uint8* v_buf,
                               uint8* rgb_buf,
                               int width,
                               int source_dx,
                               int16 *kCoefficientsRgbY);

  asm(
  ".text\n"
#if defined(XP_MACOSX)
"_PICScaleYUVToRGB32Row_SSE:\n"
#else
"PICScaleYUVToRGB32Row_SSE:\n"
#endif
  "pusha\n"
  "mov    0x24(%esp),%edx\n"
  "mov    0x28(%esp),%edi\n"
  "mov    0x2c(%esp),%esi\n"
  "mov    0x30(%esp),%ebp\n"
  "mov    0x3c(%esp),%ecx\n"
  "xor    %ebx,%ebx\n"
  "jmp    1f\n"

"0:"
  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"
  "movzbl (%edi,%eax,1),%eax\n"
  "movq   2048(%ecx,%eax,8),%mm0\n"
  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"
  "movzbl (%esi,%eax,1),%eax\n"
  "paddsw 4096(%ecx,%eax,8),%mm0\n"
  "mov    %ebx,%eax\n"
  "add    0x38(%esp),%ebx\n"
  "sar    $0x10,%eax\n"
  "movzbl (%edx,%eax,1),%eax\n"
  "movq   0(%ecx,%eax,8),%mm1\n"
  "mov    %ebx,%eax\n"
  "add    0x38(%esp),%ebx\n"
  "sar    $0x10,%eax\n"
  "movzbl (%edx,%eax,1),%eax\n"
  "movq   0(%ecx,%eax,8),%mm2\n"
  "paddsw %mm0,%mm1\n"
  "paddsw %mm0,%mm2\n"
  "psraw  $0x6,%mm1\n"
  "psraw  $0x6,%mm2\n"
  "packuswb %mm2,%mm1\n"
  "movntq %mm1,0x0(%ebp)\n"
  "add    $0x8,%ebp\n"
"1:"
  "subl   $0x2,0x34(%esp)\n"
  "jns    0b\n"

  "andl   $0x1,0x34(%esp)\n"
  "je     2f\n"

  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"
  "movzbl (%edi,%eax,1),%eax\n"
  "movq   2048(%ecx,%eax,8),%mm0\n"
  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"
  "movzbl (%esi,%eax,1),%eax\n"
  "paddsw 4096(%ecx,%eax,8),%mm0\n"
  "mov    %ebx,%eax\n"
  "sar    $0x10,%eax\n"
  "movzbl (%edx,%eax,1),%eax\n"
  "movq   0(%ecx,%eax,8),%mm1\n"
  "paddsw %mm0,%mm1\n"
  "psraw  $0x6,%mm1\n"
  "packuswb %mm1,%mm1\n"
  "movd   %mm1,0x0(%ebp)\n"

"2:"
  "popa\n"
  "ret\n"
#if !defined(XP_MACOSX)
  ".previous\n"
#endif
);

void ScaleYUVToRGB32Row(const uint8* y_buf,
                        const uint8* u_buf,
                        const uint8* v_buf,
                        uint8* rgb_buf,
                        int width,
                        int source_dx)
{
  if (mozilla::supports_sse()) {
    PICScaleYUVToRGB32Row_SSE(y_buf, u_buf, v_buf, rgb_buf, width, source_dx,
                              &kCoefficientsRgbY[0][0]);
    return;
  }

  ScaleYUVToRGB32Row_C(y_buf, u_buf, v_buf, rgb_buf, width, source_dx);
}

void PICLinearScaleYUVToRGB32Row_SSE(const uint8* y_buf,
                                     const uint8* u_buf,
                                     const uint8* v_buf,
                                     uint8* rgb_buf,
                                     int width,
                                     int source_dx,
                                     int16 *kCoefficientsRgbY);

  asm(
  ".text\n"
#if defined(XP_MACOSX)
"_PICLinearScaleYUVToRGB32Row_SSE:\n"
#else
"PICLinearScaleYUVToRGB32Row_SSE:\n"
#endif
  "pusha\n"
  "mov    0x24(%esp),%edx\n"
  "mov    0x30(%esp),%ebp\n"
  "mov    0x34(%esp),%ecx\n"
  "mov    0x3c(%esp),%edi\n"
  "xor    %ebx,%ebx\n"

  // source_width = width * source_dx + ebx
  "mov    0x34(%esp), %ecx\n"
  "imull  0x38(%esp), %ecx\n"
  "mov    %ecx, 0x34(%esp)\n"

  "mov    0x38(%esp), %ecx\n"
  "xor    %ebx,%ebx\n"     // x = 0
  "cmp    $0x20000,%ecx\n" // if source_dx >= 2.0
  "jl     1f\n"
  "mov    $0x8000,%ebx\n"  // x = 0.5 for 1/2 or less
  "jmp    1f\n"

"0:"
  "mov    0x28(%esp),%esi\n"
  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"

  "movzbl (%esi,%eax,1),%ecx\n"
  "movzbl 1(%esi,%eax,1),%esi\n"
  "mov    %ebx,%eax\n"
  "andl   $0x1fffe, %eax \n"
  "imul   %eax, %esi \n"
  "xorl   $0x1fffe, %eax \n"
  "imul   %eax, %ecx \n"
  "addl   %esi, %ecx \n"
  "shrl   $17, %ecx \n"
  "movq   2048(%edi,%ecx,8),%mm0\n"

  "mov    0x2c(%esp),%esi\n"
  "mov    %ebx,%eax\n"
  "sar    $0x11,%eax\n"

  "movzbl (%esi,%eax,1),%ecx\n"
  "movzbl 1(%esi,%eax,1),%esi\n"
  "mov    %ebx,%eax\n"
  "andl   $0x1fffe, %eax \n"
  "imul   %eax, %esi \n"
  "xorl   $0x1fffe, %eax \n"
  "imul   %eax, %ecx \n"
  "addl   %esi, %ecx \n"
  "shrl   $17, %ecx \n"
  "paddsw 4096(%edi,%ecx,8),%mm0\n"

  "mov    %ebx,%eax\n"
  "sar    $0x10,%eax\n"
  "movzbl (%edx,%eax,1),%ecx\n"
  "movzbl 1(%edx,%eax,1),%esi\n"
  "mov    %ebx,%eax\n"
  "add    0x38(%esp),%ebx\n"
  "andl   $0xffff, %eax \n"
  "imul   %eax, %esi \n"
  "xorl   $0xffff, %eax \n"
  "imul   %eax, %ecx \n"
  "addl   %esi, %ecx \n"
  "shrl   $16, %ecx \n"
  "movq   (%edi,%ecx,8),%mm1\n"

  "cmp    0x34(%esp), %ebx\n"
  "jge    2f\n"

  "mov    %ebx,%eax\n"
  "sar    $0x10,%eax\n"
  "movzbl (%edx,%eax,1),%ecx\n"
  "movzbl 1(%edx,%eax,1),%esi\n"
  "mov    %ebx,%eax\n"
  "add    0x38(%esp),%ebx\n"
  "andl   $0xffff, %eax \n"
  "imul   %eax, %esi \n"
  "xorl   $0xffff, %eax \n"
  "imul   %eax, %ecx \n"
  "addl   %esi, %ecx \n"
  "shrl   $16, %ecx \n"
  "movq   (%edi,%ecx,8),%mm2\n"

  "paddsw %mm0,%mm1\n"
  "paddsw %mm0,%mm2\n"
  "psraw  $0x6,%mm1\n"
  "psraw  $0x6,%mm2\n"
  "packuswb %mm2,%mm1\n"
  "movntq %mm1,0x0(%ebp)\n"
  "add    $0x8,%ebp\n"

"1:"
  "cmp    %ebx, 0x34(%esp)\n"
  "jg     0b\n"
  "popa\n"
  "ret\n"

"2:"
  "paddsw %mm0, %mm1\n"
  "psraw $6, %mm1\n"
  "packuswb %mm1, %mm1\n"
  "movd %mm1, (%ebp)\n"
  "popa\n"
  "ret\n"
#if !defined(XP_MACOSX)
  ".previous\n"
#endif
);


void LinearScaleYUVToRGB32Row(const uint8* y_buf,
                              const uint8* u_buf,
                              const uint8* v_buf,
                              uint8* rgb_buf,
                              int width,
                              int source_dx)
{
  if (mozilla::supports_sse()) {
    PICLinearScaleYUVToRGB32Row_SSE(y_buf, u_buf, v_buf, rgb_buf, width,
                                    source_dx, &kCoefficientsRgbY[0][0]);
    return;
  }

  LinearScaleYUVToRGB32Row_C(y_buf, u_buf, v_buf, rgb_buf, width, source_dx);
}
#elif defined TENFOURFOX_VMX
/* for TenFourFox, by Cameron Kaiser */

void FastConvertYUVToRGB32Row(const uint8 *y_buf,
                                const uint8* u_buf,
                                const uint8* v_buf,
                                uint8* rgb_buf,
                                int width) {
	register vector unsigned char r0;
	
	// splat a vector for 6 for the bit shifts
	register vector unsigned short splat6 = vec_splat_u16(6);

	int edi = 0;
	int esi = 0;
	int edx = 0;
	unsigned int __attribute__ ((aligned(16))) parkit[4];
	unsigned int *stufit = (unsigned int *)rgb_buf;
	register vector short mm0, mm0a, mm1, mm2;
	register vector short mm01, mm0a1, mm11, mm21;
	register vector unsigned char msq, mask;
	register vector unsigned char snarf = 
{ 3, 2, 1, 0, 11, 10, 9, 8, 0, 0, 0, 0, 0, 0, 0, 0 };
	register vector unsigned char snarf8 =
{ 3, 2, 1, 0, 11, 10, 9, 8, 7, 6, 5, 4, 15, 14, 13, 12 };
	register vector unsigned char mergehalf =
{ 0, 1, 2, 3, 4, 5, 6, 7, 16, 17, 18, 19, 20, 21, 22, 23 };

#define LOADC(x,y,z) \
	x = (vector short)vec_ld(0, (unsigned char*)&(kCoefficientsRgbY[z+y]));

	while(width >= 4) {
                uint8 u = u_buf[edi++];
                uint8 v = v_buf[esi++];
                uint8 y0 = y_buf[edx++];
                uint8 y1 = y_buf[edx++];

                LOADC(mm0, u, 256);
                LOADC(mm0a, v, 512);
                LOADC(mm1, y0, 0);
                LOADC(mm2, y1, 0);

                u = u_buf[edi++];
                v = v_buf[esi++];
                y0 = y_buf[edx++];
                y1 = y_buf[edx++];

                LOADC(mm01, u, 256);
                LOADC(mm0a1, v, 512);
                LOADC(mm11, y0, 0);
                LOADC(mm21, y1, 0);

                mm0 = (vector short)vec_perm(mm0, mm01, mergehalf);
                mm0a = (vector short)vec_perm(mm0a, mm0a1, mergehalf);
                mm1 = (vector short)vec_perm(mm1, mm11, mergehalf);
                mm2 = (vector short)vec_perm(mm2, mm21, mergehalf);

                mm0 = vec_adds(mm0, mm0a);
                mm1 = vec_adds(mm0, mm1);
                mm2 = vec_adds(mm0, mm2);

                mm1 = vec_sra(mm1, splat6);
                mm2 = vec_sra(mm2, splat6);

		r0 = vec_packsu(mm1, mm2);

		// because we're big endian, we have to permute our
		// bytes into bgra because we output argb (see YuvPixel
		// in the C version). at the same time we smush everything
		// together for a reason you'll see in a minute.
		r0 = vec_perm(r0, r0, snarf8);

                // there has GOT to be a better way.
                vec_st(r0, 0, (unsigned char *)parkit);
                stufit[0] = parkit[0];
                stufit[1] = parkit[1];
                stufit[2] = parkit[2];
                stufit[3] = parkit[3];
                stufit += 4;
                width -= 4;
	}

	while(width >= 2) {
    		uint8 u = u_buf[edi++];
    		uint8 v = v_buf[esi++];
		uint8 y0 = y_buf[edx++];
		uint8 y1 = y_buf[edx++];

		LOADC(mm0, u, 256);
		LOADC(mm0a, v, 512);
		LOADC(mm1, y0, 0);
		LOADC(mm2, y1, 0);

		mm0 = vec_adds(mm0, mm0a);

		mm1 = vec_adds(mm0, mm1);
		mm2 = vec_adds(mm0, mm2);

		mm1 = vec_sra(mm1, splat6);
		mm2 = vec_sra(mm2, splat6);

		r0 = vec_packsu(mm1, mm2);

		r0 = vec_perm(r0, r0, snarf);

		// there has GOT to be a better way to write a half vector.
		vec_st(r0, 0, (unsigned char *)parkit);
		stufit[0] = parkit[0];
		stufit[1] = parkit[1];
		stufit += 2;
		width -= 2;
	}

	if (width) {
    		uint8 u = u_buf[edi];
    		uint8 v = v_buf[esi];
		uint8 y0 = y_buf[edx];

		LOADC(mm0, u, 256);
		LOADC(mm0a, v, 512);
		LOADC(mm1, y0, 0);

		mm0 = vec_adds(mm0, mm0a);
		mm1 = vec_adds(mm1, mm0);
		mm1 = vec_sra(mm1, splat6);
		r0 = vec_packsu(mm1, mm1);
		r0 = vec_perm(r0, r0, snarf);
		vec_st(r0, 0, (unsigned char *)parkit);
		stufit[0] = parkit[0];
	}
}

void ScaleYUVToRGB32Row(const uint8* y_buf,
                        const uint8* u_buf,
                        const uint8* v_buf,
                        uint8* rgb_buf,
                        int width,
                        int source_dx) {
	// Another simpleminded port of the SSE version.
	// This is roughly the same as the Fast transform, but with some
	// extra sexy bits for scaling.
	register vector unsigned char r0;
	
	// splat a vector for 6 for the bit shifts
	register vector unsigned short splat6 = vec_splat_u16(6);

	unsigned int __attribute__ ((aligned(16))) parkit[4];
	unsigned int *stufit = (unsigned int *)rgb_buf;
	register vector short mm0, mm0a, mm1, mm2;
	register vector short mm01, mm0a1, mm11, mm21;
	register vector unsigned char msq, mask;
	register vector unsigned char snarf = 
{ 3, 2, 1, 0, 11, 10, 9, 8, 0, 0, 0, 0, 0, 0, 0, 0 };
	register vector unsigned char snarf8 =
{ 3, 2, 1, 0, 11, 10, 9, 8, 7, 6, 5, 4, 15, 14, 13, 12 };
	register vector unsigned char mergehalf =
{ 0, 1, 2, 3, 4, 5, 6, 7, 16, 17, 18, 19, 20, 21, 22, 23 };

	// 16.16 fixed point math is used, so we account for it (see C version)
	int x = 0;
	while(width >= 4) {
    		uint8 u = u_buf[x >> 17];
    		uint8 v = v_buf[x >> 17];
		uint8 y0 = y_buf[x >> 16];
		uint8 y1 = y_buf[(x + source_dx) >> 16];

		x += source_dx + source_dx;

                LOADC(mm0, u, 256);
                LOADC(mm0a, v, 512);
                LOADC(mm1, y0, 0);
                LOADC(mm2, y1, 0);

    		u = u_buf[x >> 17];
    		v = v_buf[x >> 17];
		y0 = y_buf[x >> 16];
		y1 = y_buf[(x + source_dx) >> 16];

		x += source_dx + source_dx;

                LOADC(mm01, u, 256);
                LOADC(mm0a1, v, 512);
                LOADC(mm11, y0, 0);
                LOADC(mm21, y1, 0);

                mm0 = (vector short)vec_perm(mm0, mm01, mergehalf);
                mm0a = (vector short)vec_perm(mm0a, mm0a1, mergehalf);
                mm1 = (vector short)vec_perm(mm1, mm11, mergehalf);
                mm2 = (vector short)vec_perm(mm2, mm21, mergehalf);

                mm0 = vec_adds(mm0, mm0a);
                mm1 = vec_adds(mm0, mm1);
                mm2 = vec_adds(mm0, mm2);

                mm1 = vec_sra(mm1, splat6);
                mm2 = vec_sra(mm2, splat6);

		r0 = vec_packsu(mm1, mm2);

		// because we're big endian, we have to permute our
		// bytes into bgra because we output argb (see YuvPixel
		// in the C version). at the same time we smush everything
		// together for a reason you'll see in a minute.
		r0 = vec_perm(r0, r0, snarf8);

                // there has GOT to be a better way.
                vec_st(r0, 0, (unsigned char *)parkit);
                stufit[0] = parkit[0];
                stufit[1] = parkit[1];
                stufit[2] = parkit[2];
                stufit[3] = parkit[3];
                stufit += 4;
                width -= 4;
	}

	while(width >= 2) {
    		uint8 u = u_buf[x >> 17];
    		uint8 v = v_buf[x >> 17];
		uint8 y0 = y_buf[x >> 16];
		uint8 y1 = y_buf[(x + source_dx) >> 16];

		x += source_dx + source_dx;

		LOADC(mm0, u, 256);
		LOADC(mm0a, v, 512);
		LOADC(mm1, y0, 0);
		LOADC(mm2, y1, 0);

		mm0 = vec_adds(mm0, mm0a);

		mm1 = vec_adds(mm0, mm1);
		mm2 = vec_adds(mm0, mm2);

		mm1 = vec_sra(mm1, splat6);
		mm2 = vec_sra(mm2, splat6);

		r0 = vec_packsu(mm1, mm2);
		r0 = vec_perm(r0, r0, snarf);

		// there has GOT to be a better way.
		vec_st(r0, 0, (unsigned char *)parkit);
		stufit[0] = parkit[0];
		stufit[1] = parkit[1];
		stufit += 2;
		width -= 2;
	}

	if (width) {
    		uint8 u = u_buf[x >> 17];
    		uint8 v = v_buf[x >> 17];
		uint8 y0 = y_buf[x >> 16];
		LOADC(mm0, u, 256);
		LOADC(mm0a, v, 512);
		LOADC(mm1, y0, 0);
		mm0 = vec_adds(mm0, mm0a);
		mm1 = vec_adds(mm1, mm0);
		mm1 = vec_sra(mm1, splat6);
		r0 = vec_packsu(mm1, mm1);
		r0 = vec_perm(r0, r0, snarf);
		vec_st(r0, 0, (unsigned char *)parkit);
		stufit[0] = parkit[0];
	}
}

void LinearScaleYUVToRGB32Row(const uint8* y_buf,
                              const uint8* u_buf,
                              const uint8* v_buf,
                              uint8* rgb_buf,
                              int width,
                              int source_dx) {
	// Aaaaand another one. This one is rather harder to translate
	// to AltiVec, but we'll give it a go.
	// Tobias gets a beer here.
        register vector unsigned char r0;
        
        // splat a vector for 6 for the bit shifts
        register vector unsigned short splat6 = vec_splat_u16(6);

        unsigned int __attribute__ ((aligned(16))) parkit[4];
        unsigned int *stufit = (unsigned int *)rgb_buf;
        register vector short mm0, mm0a, mm1, mm2;
        register vector short mm01, mm0a1, mm11, mm21;
        register vector unsigned char msq, mask;
        register vector unsigned char snarf = 
{ 3, 2, 1, 0, 11, 10, 9, 8, 0, 0, 0, 0, 0, 0, 0, 0 };
        register vector unsigned char snarf8 =
{ 3, 2, 1, 0, 11, 10, 9, 8, 7, 6, 5, 4, 15, 14, 13, 12 };
        register vector unsigned char mergehalf =
{ 0, 1, 2, 3, 4, 5, 6, 7, 16, 17, 18, 19, 20, 21, 22, 23 };

        // 16.16 fixed point math is used, so we account for it (see C version)
        int x = 0;
        if (source_dx >= 0x20000) {
                x = 32768;
        }
        while(width >= 4) {
                int u0 = u_buf[x >> 17];
                int u1 = u_buf[(x >> 17) + 1];
                int v0 = v_buf[x >> 17];
                int v1 = v_buf[(x >> 17) + 1];
                int y0 = y_buf[x >> 16];
                int y1 = y_buf[(x >> 16) + 1];
                int yy0 = y_buf[(x + source_dx) >> 16];
                int yy1 = y_buf[((x + source_dx) >> 16) + 1];

                int y_frac = (x & 65535);
                int uv_frac = ((x >> 1) & 65535);
                int y = (y_frac * y1 + (y_frac ^ 65535) * y0) >> 16;
                int yy = (y_frac * yy1 + (y_frac ^ 65535) * yy0) >> 16;
                int u = (uv_frac * u1 + (uv_frac ^ 65535) * u0) >> 16;
                int v = (uv_frac * v1 + (uv_frac ^ 65535) * v0) >> 16;

                x += source_dx + source_dx;

                LOADC(mm0, u, 256);
                LOADC(mm0a, v, 512);
                LOADC(mm1, y, 0);
                LOADC(mm2, yy, 0);

                u0 = u_buf[x >> 17];
                u1 = u_buf[(x >> 17) + 1];
                v0 = v_buf[x >> 17];
                v1 = v_buf[(x >> 17) + 1];
                y0 = y_buf[x >> 16];
                y1 = y_buf[(x >> 16) + 1];
                yy0 = y_buf[(x + source_dx) >> 16];
                yy1 = y_buf[((x + source_dx) >> 16) + 1];

                y_frac = (x & 65535);
                uv_frac = ((x >> 1) & 65535);
                y = (y_frac * y1 + (y_frac ^ 65535) * y0) >> 16;
                yy = (y_frac * yy1 + (y_frac ^ 65535) * yy0) >> 16;
                u = (uv_frac * u1 + (uv_frac ^ 65535) * u0) >> 16;
                v = (uv_frac * v1 + (uv_frac ^ 65535) * v0) >> 16;

                x += source_dx + source_dx;

                LOADC(mm01, u, 256);
                LOADC(mm0a1, v, 512);
                LOADC(mm11, y, 0);
                LOADC(mm21, yy, 0);

                mm0 = (vector short)vec_perm(mm0, mm01, mergehalf);
                mm0a = (vector short)vec_perm(mm0a, mm0a1, mergehalf);
                mm1 = (vector short)vec_perm(mm1, mm11, mergehalf);
                mm2 = (vector short)vec_perm(mm2, mm21, mergehalf);

                mm0 = vec_adds(mm0, mm0a);
                mm1 = vec_adds(mm0, mm1);
                mm2 = vec_adds(mm0, mm2);

                mm1 = vec_sra(mm1, splat6);
                mm2 = vec_sra(mm2, splat6);

                r0 = vec_packsu(mm1, mm2);

                // because we're big endian, we have to permute our
                // bytes into bgra because we output argb (see YuvPixel
                // in the C version). at the same time we smush everything
                // together for a reason you'll see in a minute.
                r0 = vec_perm(r0, r0, snarf8);

                // there has GOT to be a better way.
                vec_st(r0, 0, (unsigned char *)parkit);
                stufit[0] = parkit[0];
                stufit[1] = parkit[1];
                stufit[2] = parkit[2];
                stufit[3] = parkit[3];
                stufit += 4;
                width -= 4;
        }

        while(width >= 2) {
                int u0 = u_buf[x >> 17];
                int u1 = u_buf[(x >> 17) + 1];
                int v0 = v_buf[x >> 17];
                int v1 = v_buf[(x >> 17) + 1];
                int y0 = y_buf[x >> 16];
                int y1 = y_buf[(x >> 16) + 1];
                int yy0 = y_buf[(x + source_dx) >> 16];
                int yy1 = y_buf[((x + source_dx) >> 16) + 1];

                int y_frac = (x & 65535);
                int uv_frac = ((x >> 1) & 65535);
                int y = (y_frac * y1 + (y_frac ^ 65535) * y0) >> 16;
                int yy = (y_frac * yy1 + (y_frac ^ 65535) * yy0) >> 16;
                int u = (uv_frac * u1 + (uv_frac ^ 65535) * u0) >> 16;
                int v = (uv_frac * v1 + (uv_frac ^ 65535) * v0) >> 16;

                x += source_dx + source_dx;

                LOADC(mm0, u, 256);
                LOADC(mm0a, v, 512);
                LOADC(mm1, y, 0);
                LOADC(mm2, yy, 0);

                mm0 = vec_adds(mm0, mm0a);

                mm1 = vec_adds(mm0, mm1);
                mm2 = vec_adds(mm0, mm2);

                mm1 = vec_sra(mm1, splat6);
                mm2 = vec_sra(mm2, splat6);

                r0 = vec_packsu(mm1, mm2);
                r0 = vec_perm(r0, r0, snarf);

                // there has GOT to be a better way.
                vec_st(r0, 0, (unsigned char *)parkit);
                stufit[0] = parkit[0];
                stufit[1] = parkit[1];
                stufit += 2;
                width -= 2;
        }

        if (width) {
                int u0 = u_buf[x >> 17];
                int u1 = u_buf[(x >> 17) + 1];
                int v0 = v_buf[x >> 17];
                int v1 = v_buf[(x >> 17) + 1];
                int y0 = y_buf[x >> 16];
                int y1 = y_buf[(x >> 16) + 1];

                int y_frac = (x & 65535);
                int uv_frac = ((x >> 1) & 65535);
                int y = (y_frac * y1 + (y_frac ^ 65535) * y0) >> 16;
                int u = (uv_frac * u1 + (uv_frac ^ 65535) * u0) >> 16;
                int v = (uv_frac * v1 + (uv_frac ^ 65535) * v0) >> 16;
                LOADC(mm0, u, 256);
                LOADC(mm0a, v, 512);
                LOADC(mm1, y, 0);
                mm0 = vec_adds(mm0, mm0a);
                mm1 = vec_adds(mm1, mm0);
                mm1 = vec_sra(mm1, splat6);
                r0 = vec_packsu(mm1, mm1);
                r0 = vec_perm(r0, r0, snarf);
                vec_st(r0, 0, (unsigned char *)parkit);
                stufit[0] = parkit[0];
        }
}
#else
void FastConvertYUVToRGB32Row(const uint8* y_buf,
                              const uint8* u_buf,
                              const uint8* v_buf,
                              uint8* rgb_buf,
                              int width) {
  FastConvertYUVToRGB32Row_C(y_buf, u_buf, v_buf, rgb_buf, width, 1);
}

void ScaleYUVToRGB32Row(const uint8* y_buf,
                        const uint8* u_buf,
                        const uint8* v_buf,
                        uint8* rgb_buf,
                        int width,
                        int source_dx) {
  ScaleYUVToRGB32Row_C(y_buf, u_buf, v_buf, rgb_buf, width, source_dx);
}

void LinearScaleYUVToRGB32Row(const uint8* y_buf,
                              const uint8* u_buf,
                              const uint8* v_buf,
                              uint8* rgb_buf,
                              int width,
                              int source_dx) {
  LinearScaleYUVToRGB32Row_C(y_buf, u_buf, v_buf, rgb_buf, width, source_dx);
}
#endif

}
