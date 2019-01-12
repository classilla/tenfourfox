  
; VMX version of memchr in assembly
;
; Does not make stack frames or update the stack pointer.
;
; It uses Darwin's red zone to load/store vector values,
; and part of the code assumes memory loads are BE ordered.
;
; r3: const void *b (input param)
; r4: int c         (input param)
; r5: size_t length (input param)
;
; All GPRs used are volatile.

  
#define VRSAVE      256
#define VMX_ALL_NE  26
#define VMX_ALL_EQ  24
  
#ifdef _PPC970_

#define PADDING nop
  
#warning using 64-bit code
  
    .machine ppc970
    
#else

#define PADDING

    .machine ppc7400 
  
#endif
  
    .text 
    
    .globl _vmx_haschr
  
    .align  4 
    
_vmx_haschr:
  
    mfspr     r12,VRSAVE          ;Get old VRSAVE

    cmplwi    cr0,r5,16

    neg       r11,r3    
    add       r7,r3,r5
    
    ;prefix length in r6, suffix length in r7
    clrlwi    r6,r11,28
    clrlwi    r7,r7,28            ;logical AND 0xF
    
    ;total length - prefix length
    sub       r8,r5,r6
    
    ;prefix/total predecrements in its loop
    addi      r6,r6,1
    addi      r9,r5,1

    ;bytes into quadwords
    srwi      r8,r8,4             ;suffix is < 16bytes, no need to subtract it.
    
    ;if total length is < 16, skip vmx
    blt       cr0,L_novmx
       
    cmplwi    cr1,r8,0

    ;new VRSAVE
    oris      r0,r12,0xE000       ;VR0-VR2 = 0xE0000000
    
    li        r11,-16
    stb       r4,-16(r1)          ;store searchByte in red zone
    
    mtctr     r6
    
    beq       cr1,L_novmx
    
    ;VMX is used
    mtspr     VRSAVE,r0
    
    ;load, splat searchByte in VR0
    lvebx     v0,r1,r11
    vspltb    v0,v0,0
    
    ;truncate int to uchar
    clrlwi    r4,r4,24
  
L_prefix_loop:                    ;prefix loop
  
    ;check for a prefix before actually looping
    bdz       L_prefix_end 
    
    lbz       r9,0(r3)
    addi      r3,r3,1
    cmplw     cr1,r4,r9
    
    bne       cr1,L_prefix_loop
    
    mtspr     VRSAVE,r12          ;found the byte. c'ya ;-)
    li        r3,1
    
    blr
    
    
L_prefix_end:
  
    ;check if there is a suffix
    cmplwi    cr0,r7,0
    
    
    mtctr     r8
    
    ;first VMX iteration is outside the loop
    lvx       v1,0,r3
    li        r10,16
    vcmpequb. v2,v1,v0
    
    bdz       L_vmx_end
  
  .align  4
  
L_vmx_loop:                         ;vector loop
  
    lvx       v1,r3,r10
    la        r10,16(r10)
    PADDING
    bf        VMX_ALL_NE,L_found
    PADDING
    vcmpequb. v2,v1,v0
    bdz       L_vmx_end
    
    lvx       v1,r3,r10
    la        r10,16(r10)
    PADDING
    bf        VMX_ALL_NE,L_found
    PADDING
    vcmpequb. v2,v1,v0
    bdz       L_vmx_end
    
    lvx       v1,r3,r10
    la        r10,16(r10)
    PADDING
    bf        VMX_ALL_NE,L_found
    PADDING
    vcmpequb. v2,v1,v0
    bdz       L_vmx_end
    
    lvx       v1,r3,r10
    la        r10,16(r10)
    PADDING
    bf        VMX_ALL_NE,L_found
    PADDING
    vcmpequb. v2,v1,v0
    bdz       L_vmx_end
    
    lvx       v1,r3,r10
    la        r10,16(r10)
    PADDING
    bf        VMX_ALL_NE,L_found
    PADDING
    vcmpequb. v2,v1,v0
    bdz       L_vmx_end
    
    lvx       v1,r3,r10
    la        r10,16(r10)
    PADDING
    bf        VMX_ALL_NE,L_found
    PADDING
    vcmpequb. v2,v1,v0
    bdnz      L_vmx_loop
  
L_vmx_end:
  
    add       r3,r3,r10
    bf        VMX_ALL_NE,L_found
    
    mtctr     r7
    
    ;skip suffix if nonexistent
    beq       cr0,L_notfound
    
    .align  4
  
L_suffix_loop:                      ;suffix loop
  
    lbz       r5,0(r3)
    addi      r3,r3,1
    cmplw     cr0,r4,r5
    beq       cr0,L_found
    bdnz      L_suffix_loop
  
L_notfound:
  
    mtspr     VRSAVE,r12
    li        r3,0  
    blr
  
L_found:
  
    mtspr     VRSAVE,r12
    li        r3,1
    blr
  
  
    ;Path that skips VMX
  
L_novmx:
  
    mtctr     r9            
    clrlwi    r4,r4,24
  
L_novmx_loop:
    bdz       L_notfound_1
    lbz       r5,0(r3)
    addi      r3,r3,1
    cmpw      cr0,r4,r5
    bne       cr0,L_novmx_loop
  
L_found_1:
    la        r3,-1(r3)
    blr
L_notfound_1:
    li        r3,0
    blr
  
  .subsections_via_symbols
  
