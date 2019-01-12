
; VMX version of strchr in assembly
;
; Does not make stack frames or update the stack pointer.
;
; It uses Darwin's red zone to load/store vector values,
; and part of the code assumes memory loads are BE ordered.
;
; r3: const void *p (input param)
; r4: int ch        (input param)
;
; All GPRs used are volatile.

#define VRSAVE      256
#define VMX_ALL_NE  26
#define VMX_ALL_EQ  24
  
#ifdef _PPC970_

#warning using 64-bit code

    .machine ppc970
    
    
#else

    .machine ppc7400 
    
#endif
  
    .text
    
    .align  4
    
    .globl _vmx_strchr
  
_vmx_strchr:

    ;truncate value to 8bit, update CR0
    clrlwi.   r4,r4,24
    
    neg       r6,r3
    
    mfspr     r12,VRSAVE          ;get old VRSAVE
    
    li        r11,-16
    stb       r4,-16(r1)
    
    ;prefix length in r6
    clrlwi    r6,r6,28            ;logical AND 0xF
    
    oris      r9,r12,0xFE00       ;VR0-VR6 = 0xFE000000
    
    mtspr     VRSAVE,r9
    
    vspltisb  v0,0
    vspltisb  v6,7
    
    addi      r6,r6,1
    mtctr     r6
    
    ;If we search for NULL, use specific code
    beq       cr0,L_NULL_ONLY
  
    lvebx     v3,r1,r11
    vspltb    v3,v3,0
    
    ;check if there is a prefix first
    bdz       L_prefix_end
  
    lbz       r5,0(r3)
    
    .align 4
  
L_prefix_loop:

    addi      r3,r3,1
  
    cmpw      cr0,r4,r5
    cmpwi     cr1,r5,0
    beq       cr0,L_found
    beq       cr1,L_notfound_1
    lbz       r5,0(r3)
  
    bdnz      L_prefix_loop 
  
;The end-of-string and searchByte vectors
;are compared against memory. Both result vectors are
;then compared together. If there's no end-of-string
;or searchByte found, both result vectors should be
;filled with 0's.
;
;If anything is found there will be an inequality between
;the two.
;
;(Not applicable if the searchByte in question is NULL)
  
L_prefix_end:
  
    lvx       v1,0,r3
    vcmpequb  v4,v1,v0
    vcmpequb  v2,v1,v3
    li        r10,16
    vcmpequb. v5,v2,v4
    bf        24,L_foundsomething
  
    .align 4
    
L_vmx_loop:   

    lvx       v1,r3,r10
    vcmpequb  v4,v1,v0
    vcmpequb  v2,v1,v3
    la        r10,16(r10)
    vcmpequb. v5,v2,v4
    bf        VMX_ALL_EQ,L_foundsomething    

    lvx       v1,r3,r10
    vcmpequb  v4,v1,v0
    vcmpequb  v2,v1,v3
    la        r10,16(r10)
    vcmpequb. v5,v2,v4
    bf        VMX_ALL_EQ,L_foundsomething
    
    lvx       v1,r3,r10
    vcmpequb  v4,v1,v0
    vcmpequb  v2,v1,v3
    la        r10,16(r10)
    vcmpequb. v5,v2,v4
    bf        VMX_ALL_EQ,L_foundsomething

    lvx       v1,r3,r10
    vcmpequb  v4,v1,v0
    vcmpequb  v2,v1,v3
    la        r10,16(r10)
    vcmpequb. v5,v2,v4
    bf        VMX_ALL_EQ,L_foundsomething
    
    lvx       v1,r3,r10
    vcmpequb  v4,v1,v0
    vcmpequb  v2,v1,v3
    la        r10,16(r10)
    vcmpequb. v5,v2,v4
    bt        VMX_ALL_EQ,L_vmx_loop
    
L_foundsomething:

    ;end-of-string bytes will have a 0x07 pattern
    ;in case of equality instead of 0xFF.
    vand      v4,v4,v6
    
    ;OR the two result vectors together.
    vor       v2,v2,v4
    
L_found_NULL:

    stvx      v2,r1,r11
    add       r3,r3,r10
    subi      r3,r3,16
    mtspr     VRSAVE,r12
    
;both result vectors OR'd together are stored at -16(r1).
;load the vector in GPRs and stop at the first nonzero GPR.
;Count leading 0'; If the result is odd it's end-of-string.
;Otherwise it's the "good" byte.
;
;If we searched for NULL then it'll always be the good byte.
  
#ifdef _PPC970_
  
    ld        r5,-16(r1) 
    ld        r6,-8(r1)
    
    cmpldi    cr0,r5,0
    cntlzd    r4,r5
    
    bne       cr0,L_bytefound      ;0-7
    
    addi      r3,r3,8              ;8-15
    cntlzd    r4,r6
  
#else
  
    ;PPC32
  
    lwz       r5,-16(r1)
    lwz       r6,-12(r1)
    
    cmplwi    cr0,r5,0
    cntlzw    r4,r5
    
    cmplwi    cr1,r6,0
    
    lwz       r7,-8(r1)
    
    bne       cr0,L_bytefound      ;0-3
    
    addi      r3,r3,4
    cntlzw    r4,r6
    
    bne       cr1,L_bytefound      ;4-7
  
    cmplwi    cr0,r7,0
    
    addi      r3,r3,4
    cntlzw    r4,r7
    lwz       r8,-4(r1)
    
    bne       cr0,L_bytefound      ;8-11
    
    cntlzw    r4,r8                ;12-15
    addi      r3,r3,4
    
#endif
    
L_bytefound:

    clrlwi    r7,r4,31             ;look if it's an odd number
    srwi      r6,r4,3
    cmplwi    cr0,r7,0
    nop
    
    bne       cr0,L_notfound
    
    add       r3,r6,r3             ;update r3 to point to the good byte
    blr
  
    .align 4
    
    
    
;Code to execute when searching for NULL

L_NULL_ONLY:

    bdz       L_NULLVMX
    lbz       r5,0(r3)
    addi      r3,r3,1
    cmplwi    cr0,r5,0
    
    bne       cr0,L_NULL_ONLY    ;prefix loop
    
    la        r3,-1(r3)
    mtspr     VRSAVE,r12
    
    blr
  
  
L_NULLVMX:

    lvx       v1,0,r3
    vcmpequb. v2,v1,v0
    li        r10,16
    bc        4,26,L_found_NULL
    
L_NULL_LOOP:

    lvx       v1,r3,r10
    vcmpequb. v2,v1,v0
    la        r10,16(r10)
    bc        4,26,L_found_NULL
    
    lvx       v1,r3,r10
    vcmpequb. v2,v1,v0
    la        r10,16(r10)
    bc        4,26,L_found_NULL
    
    lvx       v1,r3,r10
    vcmpequb. v2,v1,v0
    la        r10,16(r10)
    bc        4,26,L_found_NULL
    
    lvx       v1,r3,r10
    vcmpequb. v2,v1,v0
    la        r10,16(r10)
    bc        4,26,L_found_NULL
    
    lvx       v1,r3,r10
    vcmpequb. v2,v1,v0
    la        r10,16(r10)
    bc        4,26,L_found_NULL
    
    lvx       v1,r3,r10
    vcmpequb. v2,v1,v0
    la        r10,16(r10)
    bc+       12,26,L_NULL_LOOP
    
    b	        L_found_NULL
    
L_notfound_1:

    mtspr     VRSAVE,r12
    
L_notfound:

    li        r3,0 
    blr
    
L_found:
  
    mtspr     VRSAVE,r12
    la        r3,-1(r3)
    blr
    
    .subsections_via_symbols
  
