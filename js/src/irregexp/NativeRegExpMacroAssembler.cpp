/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 4 -*-
 * vim: set ts=8 sts=4 et sw=4 tw=99: */

// Copyright 2012 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "irregexp/NativeRegExpMacroAssembler.h"

#include "irregexp/RegExpStack.h"
#include "jit/Linker.h"
#ifdef JS_ION_PERF
# include "jit/PerfSpewer.h"
#endif
#include "vm/MatchPairs.h"

#include "jit/MacroAssembler-inl.h"

using namespace js;
using namespace js::irregexp;
using namespace js::jit;

/*
 * This assembler uses the following register assignment convention:
 *
 * - current_character :
 *     Must be loaded using LoadCurrentCharacter before using any of the
 *     dispatch methods. Temporarily stores the index of capture start after a
 *     matching pass for a global regexp.
 * - current_position :
 *     Current position in input, as negative offset from end of string.
 *     Please notice that this is the byte offset, not the character offset!
 * - input_end_pointer :
 *     Points to byte after last character in the input.
 * - backtrack_stack_pointer :
 *     Points to tip of the heap allocated backtrack stack
 * - StackPointer :
 *     Points to tip of the native stack, used to access arguments, local
 *     variables and RegExp registers.
 *
 * The tempN registers are free to use for computations.
 */

NativeRegExpMacroAssembler::NativeRegExpMacroAssembler(LifoAlloc* alloc, RegExpShared* shared,
                                                       JSRuntime* rt, Mode mode, int registers_to_save)
  : RegExpMacroAssembler(*alloc, shared, registers_to_save),
    runtime(rt), mode_(mode)
{
    // Find physical registers for each compiler register.
    AllocatableGeneralRegisterSet regs(GeneralRegisterSet::All());

    input_end_pointer = regs.takeAny();
    current_character = regs.takeAny();
    current_position = regs.takeAny();
    backtrack_stack_pointer = regs.takeAny();
    temp0 = regs.takeAny();
    temp1 = regs.takeAny();
    temp2 = regs.takeAny();

    JitSpew(JitSpew_Irregexp,
            "Starting RegExp (input_end_pointer %s) (current_character %s)"
            " (current_position %s) (backtrack_stack_pointer %s) (temp0 %s) temp1 (%s) temp2 (%s)",
            input_end_pointer.name(),
            current_character.name(),
            current_position.name(),
            backtrack_stack_pointer.name(),
            temp0.name(),
            temp1.name(),
            temp2.name());

    savedNonVolatileRegisters = SavedNonVolatileRegisters(regs);

#if defined(JS_CODEGEN_PPC_OSX)
	masm.x_mflr(r0);
	masm.Push(r0);
#endif

    masm.jump(&entry_label_);
    masm.bind(&start_label_);
}

#define SPEW_PREFIX JitSpew_Irregexp, "!!! "

// The signature of the code which this generates is:
//
// void execute(InputOutputData*);
RegExpCode
NativeRegExpMacroAssembler::GenerateCode(JSContext* cx, bool match_only)
{
    if (!cx->compartment()->ensureJitCompartmentExists(cx))
        return RegExpCode();

    JitSpew(SPEW_PREFIX "GenerateCode");

    // We need an even number of registers, for stack alignment.
    if (num_registers_ % 2 == 1)
        num_registers_++;

    Label return_temp0;

    // Finalize code - write the entry point code now we know how many
    // registers we need.
    masm.bind(&entry_label_);

#ifdef JS_CODEGEN_ARM64
    // ARM64 communicates stack address via sp, but uses a pseudo-sp for addressing.
    MOZ_ASSERT(!masm.GetStackPointer64().Is(sp));
    masm.Mov(masm.GetStackPointer64(), sp);
#endif

    // Push non-volatile registers which might be modified by jitcode.
    size_t pushedNonVolatileRegisters = 0;
    for (GeneralRegisterForwardIterator iter(savedNonVolatileRegisters); iter.more(); ++iter) {
        masm.Push(*iter);
        pushedNonVolatileRegisters++;
    }

#if defined(XP_IOS) && defined(JS_CODEGEN_ARM)
    // The stack is 4-byte aligned on iOS, force 8-byte alignment.
    masm.movePtr(StackPointer, temp0);
    masm.andPtr(Imm32(~7), StackPointer);
    masm.push(temp0);
    masm.push(temp0);
#endif

#ifndef JS_CODEGEN_X86
    // The InputOutputData* is stored as an argument, save it on the stack
    // above the frame.
    masm.Push(IntArgReg0);
#endif

    size_t frameSize = sizeof(FrameData) + num_registers_ * sizeof(void*);
    frameSize = JS_ROUNDUP(frameSize + masm.framePushed(), ABIStackAlignment) - masm.framePushed();

    // Actually emit code to start a new stack frame.
    masm.reserveStack(frameSize);
    masm.checkStackAlignment();

    // Check if we have space on the stack. Use the *NoInterrupt stack limit to
    // avoid failing repeatedly when the regex code is called from Ion JIT code,
    // see bug 1208819.
    Label stack_ok;
    void* stack_limit = runtime->addressOfJitStackLimitNoInterrupt();
#ifdef JS_CODEGEN_PPC_OSX
#define PPC__B(l) bo_##l = masm._b(0)
#define PPC__BC(l,x,y,z) bo_##l = masm._bc(0, masm.ma_cmp(x, y, Assembler::z))
#define PPC_B(l) BufferOffset PPC__B(l)
#define PPC_BC(l,x,y,z) BufferOffset PPC__BC(l,x,y,z)
#define PPC_BB(l) masm.bindSS(bo_##l)
#define tempRegister r0
#define addressTempRegister r12

    masm.x_li32(addressTempRegister, (uint32_t)stack_limit);
    masm.lwz(tempRegister, addressTempRegister, 0);
    PPC_BC(stack_ok, tempRegister, stackPointerRegister, Below);
#else
    masm.branchStackPtrRhs(Assembler::Below, AbsoluteAddress(stack_limit), &stack_ok);
#endif

    // Exit with an exception. There is not enough space on the stack
    // for our working registers.
    masm.movePtr(ImmWord(RegExpRunStatus_Error), temp0);
    masm.jump(&return_temp0);

#ifdef JS_CODEGEN_PPC_OSX
    PPC_BB(stack_ok);
#else
    masm.bind(&stack_ok);
#endif

#ifdef XP_WIN
    // Ensure that we write to each stack page, in order. Skipping a page
    // on Windows can cause segmentation faults. Assuming page size is 4k.
    const int kPageSize = 4096;
    for (int i = frameSize - sizeof(void*); i >= 0; i -= kPageSize)
        masm.storePtr(temp0, Address(masm.getStackPointer(), i));
#endif // XP_WIN

#ifndef JS_CODEGEN_X86
    // The InputOutputData* is stored on the stack immediately above the frame.
    Address inputOutputAddress(masm.getStackPointer(), frameSize);
#else
    // The InputOutputData* is left in its original on stack location.
    Address inputOutputAddress(masm.getStackPointer(),
                               frameSize + (pushedNonVolatileRegisters + 1) * sizeof(void*));
#endif

    masm.loadPtr(inputOutputAddress, temp0);

    // Copy output registers to FrameData.
    if (!match_only) {
        Register matchPairsRegister = input_end_pointer;
        masm.loadPtr(Address(temp0, offsetof(InputOutputData, matches)), matchPairsRegister);
        masm.loadPtr(Address(matchPairsRegister, MatchPairs::offsetOfPairs()), temp1);
        masm.storePtr(temp1, Address(masm.getStackPointer(), offsetof(FrameData, outputRegisters)));
        masm.load32(Address(matchPairsRegister, MatchPairs::offsetOfPairCount()), temp1);
        masm.lshiftPtr(Imm32(1), temp1);
        masm.store32(temp1, Address(masm.getStackPointer(), offsetof(FrameData, numOutputRegisters)));

#ifdef DEBUG
        // Bounds check numOutputRegisters.
        Label enoughRegisters;
        masm.branchPtr(Assembler::GreaterThanOrEqual,
                       temp1, ImmWord(num_saved_registers_), &enoughRegisters);
        masm.assumeUnreachable("Not enough output registers for RegExp");
        masm.bind(&enoughRegisters);
#endif
    }

    // Load string end pointer.
    masm.loadPtr(Address(temp0, offsetof(InputOutputData, inputEnd)), input_end_pointer);

    // Load input start pointer, and copy to FrameData.
    masm.loadPtr(Address(temp0, offsetof(InputOutputData, inputStart)), current_position);
    masm.storePtr(current_position, Address(masm.getStackPointer(), offsetof(FrameData, inputStart)));

    // Load start index, and copy to FrameData.
    masm.loadPtr(Address(temp0, offsetof(InputOutputData, startIndex)), temp1);
    masm.storePtr(temp1, Address(masm.getStackPointer(), offsetof(FrameData, startIndex)));

    // Set up input position to be negative offset from string end.
    masm.subPtr(input_end_pointer, current_position);

    // Set temp0 to address of char before start of the string.
    // (effectively string position -1).
    masm.computeEffectiveAddress(Address(current_position, -char_size()), temp0);

    // Store this value on the frame, for use when clearing
    // position registers.
    masm.storePtr(temp0, Address(masm.getStackPointer(), offsetof(FrameData, inputStartMinusOne)));

    // Update current position based on start index.
    masm.computeEffectiveAddress(BaseIndex(current_position, temp1, factor()), current_position);

    Label load_char_start_regexp, start_regexp;

#ifndef JS_CODEGEN_PPC_OSX
    // Load newline if index is at start, previous character otherwise.
    masm.branchPtr(Assembler::NotEqual, 
                   Address(masm.getStackPointer(), offsetof(FrameData, startIndex)), ImmWord(0),
                   &load_char_start_regexp);
    masm.movePtr(ImmWord('\n'), current_character);
    masm.jump(&start_regexp);

    // Global regexp restarts matching here.
    masm.bind(&load_char_start_regexp);

    // Load previous char as initial value of current character register.
    LoadCurrentCharacterUnchecked(-1, 1);
#else
    PPC_BC(loadcharsr, Address(masm.getStackPointer(), offsetof(FrameData, startIndex)),
        Imm32(0), NotEqual);
    masm.movePtr(ImmWord('\n'), current_character);
    PPC_B(startregexp);
    PPC_BB(loadcharsr);
    masm.bind(&load_char_start_regexp); // We need this too, some things jump to it.
    LoadCurrentCharacterUnchecked(-1, 1);
    PPC_BB(startregexp);
#endif
    masm.bind(&start_regexp);

    // Initialize on-stack registers.
    MOZ_ASSERT(num_saved_registers_ > 0);

    // Fill saved registers with initial value = start offset - 1
    // Fill in stack push order, to avoid accessing across an unwritten
    // page (a problem on Windows).
#ifndef JS_CODEGEN_PPC_OSX
    if (num_saved_registers_ > 8) {
#else
    // For PowerPC, it's always faster to just do a string of stores.
    if(0) {
#endif
        masm.movePtr(ImmWord(register_offset(0)), temp1);
        Label init_loop;
        masm.bind(&init_loop);
        masm.storePtr(temp0, BaseIndex(masm.getStackPointer(), temp1, TimesOne));
        masm.addPtr(ImmWord(sizeof(void*)), temp1);
        masm.branchPtr(Assembler::LessThan, temp1,
                       ImmWord(register_offset(num_saved_registers_)), &init_loop);
    } else {
        // Unroll the loop.
        for (int i = 0; i < num_saved_registers_; i++)
            masm.storePtr(temp0, register_location(i));
    }

    // Initialize backtrack stack pointer.
    masm.loadPtr(AbsoluteAddress(runtime->regexpStack.addressOfBase()), backtrack_stack_pointer);
    masm.storePtr(backtrack_stack_pointer,
                  Address(masm.getStackPointer(), offsetof(FrameData, backtrackStackBase)));

    masm.jump(&start_label_);

    // Exit code:
    BufferOffset bo_exit1, bo_exit2;
    if (success_label_.used()) {
        MOZ_ASSERT(num_saved_registers_ > 0);

        Address outputRegistersAddress(masm.getStackPointer(), offsetof(FrameData, outputRegisters));

        // Save captures when successful.
        masm.bind(&success_label_);

        if (!match_only) {
            Register outputRegisters = temp1;
            Register inputByteLength = backtrack_stack_pointer;

            masm.loadPtr(outputRegistersAddress, outputRegisters);

            masm.loadPtr(inputOutputAddress, temp0);
            masm.loadPtr(Address(temp0, offsetof(InputOutputData, inputEnd)), inputByteLength);
            masm.subPtr(Address(temp0, offsetof(InputOutputData, inputStart)), inputByteLength);

            // Copy captures to output. Note that registers on the C stack are pointer width
            // so that they might hold pointers, but output registers are int32_t.
            for (int i = 0; i < num_saved_registers_; i++) {
                masm.loadPtr(register_location(i), temp0);
                if (i == 0 && global_with_zero_length_check()) {
                    // Keep capture start in current_character for the zero-length check later.
                    masm.movePtr(temp0, current_character);
                }

                // Convert to index from start of string, not end.
                masm.addPtr(inputByteLength, temp0);

                // Convert byte index to character index.
                if (mode_ == CHAR16)
                    masm.rshiftPtrArithmetic(Imm32(1), temp0);

                masm.store32(temp0, Address(outputRegisters, i * sizeof(int32_t)));
            }
        }

        // Restart matching if the regular expression is flagged as global.
        if (global()) {
            // Increment success counter.
            masm.add32(Imm32(1), Address(masm.getStackPointer(), offsetof(FrameData, successfulCaptures)));

            Address numOutputRegistersAddress(masm.getStackPointer(), offsetof(FrameData, numOutputRegisters));

            // Capture results have been stored, so the number of remaining global
            // output registers is reduced by the number of stored captures.
            masm.load32(numOutputRegistersAddress, temp0);

            masm.sub32(Imm32(num_saved_registers_), temp0);

            // Check whether we have enough room for another set of capture results.
#if JS_CODEGEN_PPC_OSX
            PPC__BC(exit1, temp0, Imm32(num_saved_registers_), LessThan);
#else
            masm.branch32(Assembler::LessThan, temp0, Imm32(num_saved_registers_), &exit_label_);
#endif

            masm.store32(temp0, numOutputRegistersAddress);

            // Advance the location for output.
            masm.add32(Imm32(num_saved_registers_ * sizeof(void*)), outputRegistersAddress);

            // Prepare temp0 to initialize registers with its value in the next run.
            masm.loadPtr(Address(masm.getStackPointer(), offsetof(FrameData, inputStartMinusOne)), temp0);

            if (global_with_zero_length_check()) {
                // Special case for zero-length matches.

                // The capture start index was loaded into current_character above.
                masm.branchPtr(Assembler::NotEqual, current_position, current_character,
                               &load_char_start_regexp);

#if JS_CODEGEN_PPC_OSX
                PPC__BC(exit2, current_position, Imm32(0), Equal);
#else
                // edi (offset from the end) is zero if we already reached the end.
                masm.branchTestPtr(Assembler::Zero, current_position, current_position,
                                   &exit_label_);
#endif

                // Advance current position after a zero-length match.
                masm.addPtr(Imm32(char_size()), current_position);
            }

            masm.jump(&load_char_start_regexp);
        } else {
            masm.movePtr(ImmWord(RegExpRunStatus_Success), temp0);
        }
    }

#if JS_CODEGEN_PPC_OSX
    PPC_BB(exit1);
    PPC_BB(exit2);
#endif
    masm.bind(&exit_label_);

    if (global()) {
        // Return the number of successful captures.
        masm.load32(Address(masm.getStackPointer(), offsetof(FrameData, successfulCaptures)), temp0);
    }

    masm.bind(&return_temp0);

    // Store the result to the input structure.
    masm.loadPtr(inputOutputAddress, temp1);
    masm.storePtr(temp0, Address(temp1, offsetof(InputOutputData, result)));

#ifndef JS_CODEGEN_X86
    // Include the InputOutputData* when adjusting the stack size.
    masm.freeStack(frameSize + sizeof(void*));
#else
    masm.freeStack(frameSize);
#endif

#if defined(XP_IOS) && defined(JS_CODEGEN_ARM)
    masm.pop(temp0);
    masm.movePtr(temp0, StackPointer);
#endif

    // Restore non-volatile registers which were saved on entry.
    for (GeneralRegisterBackwardIterator iter(savedNonVolatileRegisters); iter.more(); ++iter)
        masm.Pop(*iter);

#ifdef JS_CODEGEN_PPC_OSX
    // Restore LR.
    masm.Pop(r0);
    masm.x_mtlr(r0);
#endif

    masm.abiret();

    // Backtrack code (branch target for conditional backtracks).
    if (backtrack_label_.used()) {
        masm.bind(&backtrack_label_);
        Backtrack();
    }

    // Backtrack stack overflow code.
    if (stack_overflow_label_.used()) {
        // Reached if the backtrack-stack limit has been hit. temp2 holds the
        // StackPointer to use for accessing FrameData.
        masm.bind(&stack_overflow_label_);

        Label grow_failed;

        masm.movePtr(ImmPtr(runtime), temp1);

#ifndef JS_CODEGEN_PPC_OSX
        // Save registers before calling C function
        LiveGeneralRegisterSet volatileRegs(GeneralRegisterSet::Volatile());
#if defined(JS_CODEGEN_ARM) || defined(JS_CODEGEN_ARM64)
        volatileRegs.add(Register::FromCode(Registers::lr));
#elif defined(JS_CODEGEN_MIPS32) || defined(JS_CODEGEN_MIPS64)
        volatileRegs.add(Register::FromCode(Registers::ra));
#endif
        volatileRegs.takeUnchecked(temp0);
        volatileRegs.takeUnchecked(temp1);
        masm.PushRegsInMask(volatileRegs);

        masm.setupUnalignedABICall(temp0);
        masm.passABIArg(temp1);
        masm.callWithABI(JS_FUNC_TO_DATA_PTR(void*, GrowBacktrackStack));
        masm.storeCallResult(temp0);

        masm.PopRegsInMask(volatileRegs);

        // If return false, we have failed to grow the stack, and
        // must exit with a stack-overflow exception. Do this in the caller
        // so that the stack is adjusted by our return instruction.
        Label return_from_overflow_handler;
        masm.branchTest32(Assembler::Zero, temp0, temp0, &return_from_overflow_handler);

#else
        // PowerPC specific version, somewhat more efficient
        Register ppc0 = (temp1 == r3) ? r5 : r3;
        Register ppc1 = r4;
        Label return_from_overflow_handler;

        // This is lazy, but only incurs one extra x_subi.
        masm.x_mflr(r0);
        masm.push5(r3, r4, r5, r6, r7);
        masm.push4(r8, r9, r10, r0);
        // Load CTR for call.
        masm.x_li32(tempRegister, (uint32_t)GrowBacktrackStack);
        masm.x_mtctr(tempRegister);
        // Forcibly align the stack and pull down a frame, putting the
        // previous stack pointer there.
        masm.x_mr(ppc1, stackPointerRegister);
        masm.andi_rc(ppc0, stackPointerRegister, 0x04);
        masm.subf(stackPointerRegister, ppc0, stackPointerRegister);
        masm.andi_rc(ppc0, stackPointerRegister, 0x08);
        masm.addi(ppc0, ppc0, 512);
        masm.subf(stackPointerRegister, ppc0, stackPointerRegister);
        masm.stw(ppc1, stackPointerRegister, 0);

        masm.x_mr(r3, temp1);
        masm.bctr(Assembler::LinkB);

        // Restore the stack pointer.
        masm.lwz(stackPointerRegister, stackPointerRegister, 0);
        // Do the comp here before restoring the temps.
        masm.cmpwi(r3, 0);
        masm.pop4(r0, r10, r9, r8);
        masm.pop5(r7, r6, r5, r4, r3);
        masm.x_mtlr(r0);
        masm.bc(Assembler::Equal, &return_from_overflow_handler);
#endif

        // Otherwise, store the new backtrack stack base and recompute the new
        // top of the stack.
        Address backtrackStackBaseAddress(temp2, offsetof(FrameData, backtrackStackBase));
        masm.subPtr(backtrackStackBaseAddress, backtrack_stack_pointer);

        masm.loadPtr(AbsoluteAddress(runtime->regexpStack.addressOfBase()), temp1);
        masm.storePtr(temp1, backtrackStackBaseAddress);
        masm.addPtr(temp1, backtrack_stack_pointer);

        // Resume execution in calling code.
        masm.bind(&return_from_overflow_handler);
#ifdef JS_CODEGEN_PPC_OSX
        masm.ret();
#else
        masm.abiret();
#endif
    }

    if (exit_with_exception_label_.used()) {
        // If any of the code above needed to exit with an exception.
        masm.bind(&exit_with_exception_label_);

        // Exit with an error result to signal thrown exception.
        masm.movePtr(ImmWord(RegExpRunStatus_Error), temp0);
        masm.jump(&return_temp0);
    }

    Linker linker(masm);
    AutoFlushICache afc("RegExp");
    JitCode* code = linker.newCode<NoGC>(cx, REGEXP_CODE);
    if (!code) {
        ReportOutOfMemory(cx);
        return RegExpCode();
    }

#ifdef JS_ION_PERF
    writePerfSpewerJitCodeProfile(code, "RegExp");
#endif

    AutoWritableJitCode awjc(code);

    for (size_t i = 0; i < labelPatches.length(); i++) {
        LabelPatch& v = labelPatches[i];
        MOZ_ASSERT(!v.label);
        Assembler::PatchDataWithValueCheck(CodeLocationLabel(code, v.patchOffset),
                                           ImmPtr(code->raw() + v.labelOffset),
                                           ImmPtr(0));
    }

    JitSpew(JitSpew_Irregexp, "Created RegExp (raw %p length %d)",
            (void*) code->raw(), (int) masm.bytesNeeded());

    RegExpCode res;
    res.jitCode = code;
    return res;
}

int
NativeRegExpMacroAssembler::stack_limit_slack()
{
    return RegExpStack::kStackLimitSlack;
}

void
NativeRegExpMacroAssembler::AdvanceCurrentPosition(int by)
{
    JitSpew(SPEW_PREFIX "AdvanceCurrentPosition(%d)", by);

    if (by != 0)
        masm.addPtr(Imm32(by * char_size()), current_position);
}

void
NativeRegExpMacroAssembler::AdvanceRegister(int reg, int by)
{
    JitSpew(SPEW_PREFIX "AdvanceRegister(%d, %d)", reg, by);

    MOZ_ASSERT(reg >= 0);
    MOZ_ASSERT(reg < num_registers_);
    if (by != 0)
        masm.addPtr(Imm32(by), register_location(reg));
}

void
NativeRegExpMacroAssembler::Backtrack()
{
    JitSpew(SPEW_PREFIX "Backtrack");

#ifndef JS_CODEGEN_PPC_OSX
    // Check for an interrupt.
    Label noInterrupt;
    masm.branch32(Assembler::Equal,
                  AbsoluteAddress(runtime->addressOfInterruptUint32()), Imm32(0),
                  &noInterrupt);
    masm.movePtr(ImmWord(RegExpRunStatus_Error), temp0);
    masm.jump(&exit_label_);
    masm.bind(&noInterrupt);

    // Pop code location from backtrack stack and jump to location.
    PopBacktrack(temp0);
    masm.jump(temp0);
#else
    masm.x_li32(addressTempRegister, (uint32_t)runtime->addressOfInterruptUint32());
    masm.lwz(tempRegister, addressTempRegister, 0);
    PPC_BC(noIRQ, tempRegister, Imm32(0), Equal);
    masm.movePtr(ImmWord(RegExpRunStatus_Error), temp0);
    masm.jump(&exit_label_);
    PPC_BB(noIRQ);
    // Despite the fact we invariably fall through to this, it is actually not faster
    // to do the lwz/mtctr in advance (i.e., before the bc above).
    masm.lwz(temp0, backtrack_stack_pointer, -4);
    masm.x_mtctr(temp0);
    masm.subPtr(Imm32(sizeof(void*)), backtrack_stack_pointer);
 #if _PPC970_
    masm.x_nop();
    masm.x_nop();
 #endif
    masm.bctr();
#endif
}

void
NativeRegExpMacroAssembler::Bind(Label* label)
{
    JitSpew(SPEW_PREFIX "Bind");

    masm.bind(label);
}

void
NativeRegExpMacroAssembler::CheckAtStart(Label* on_at_start)
{
    JitSpew(SPEW_PREFIX "CheckAtStart");

#ifndef JS_CODEGEN_PPC_OSX
    Label not_at_start;

    // Did we start the match at the start of the string at all?
    Address startIndex(masm.getStackPointer(), offsetof(FrameData, startIndex));
    masm.branchPtr(Assembler::NotEqual, startIndex, ImmWord(0), &not_at_start);

    // If we did, are we still at the start of the input?
    masm.computeEffectiveAddress(BaseIndex(input_end_pointer, current_position, TimesOne), temp0);

    Address inputStart(masm.getStackPointer(), offsetof(FrameData, inputStart));
    masm.branchPtr(Assembler::Equal, inputStart, temp0, BranchOrBacktrack(on_at_start));

    masm.bind(&not_at_start);
#else
    Address startIndex(masm.getStackPointer(), offsetof(FrameData, startIndex));
    PPC_BC(notstart, startIndex, Imm32(0), NotEqual);
    masm.computeEffectiveAddress(BaseIndex(input_end_pointer, current_position, TimesOne), temp0);
    Address inputStart(masm.getStackPointer(), offsetof(FrameData, inputStart));
    masm.branchPtr(Assembler::Equal, inputStart, temp0, BranchOrBacktrack(on_at_start));
    PPC_BB(notstart);
#endif
}

void
NativeRegExpMacroAssembler::CheckNotAtStart(Label* on_not_at_start)
{
    JitSpew(SPEW_PREFIX "CheckNotAtStart");

    // Did we start the match at the start of the string at all?
    Address startIndex(masm.getStackPointer(), offsetof(FrameData, startIndex));
    masm.branchPtr(Assembler::NotEqual, startIndex, ImmWord(0), BranchOrBacktrack(on_not_at_start));

    // If we did, are we still at the start of the input?
    masm.computeEffectiveAddress(BaseIndex(input_end_pointer, current_position, TimesOne), temp0);

    Address inputStart(masm.getStackPointer(), offsetof(FrameData, inputStart));
    masm.branchPtr(Assembler::NotEqual, inputStart, temp0, BranchOrBacktrack(on_not_at_start));
}

void
NativeRegExpMacroAssembler::CheckCharacter(unsigned c, Label* on_equal)
{
    JitSpew(SPEW_PREFIX "CheckCharacter(%d)", (int) c);
    masm.branch32(Assembler::Equal, current_character, Imm32(c), BranchOrBacktrack(on_equal));
}

void
NativeRegExpMacroAssembler::CheckNotCharacter(unsigned c, Label* on_not_equal)
{
    JitSpew(SPEW_PREFIX "CheckNotCharacter(%d)", (int) c);
    masm.branch32(Assembler::NotEqual, current_character, Imm32(c), BranchOrBacktrack(on_not_equal));
}

void
NativeRegExpMacroAssembler::CheckCharacterAfterAnd(unsigned c, unsigned and_with,
                                                   Label* on_equal)
{
    JitSpew(SPEW_PREFIX "CheckCharacterAfterAnd(%d, %d)", (int) c, (int) and_with);

    if (c == 0) {
        masm.branchTest32(Assembler::Zero, current_character, Imm32(and_with),
                          BranchOrBacktrack(on_equal));
    } else {
        masm.move32(Imm32(and_with), temp0);
        masm.and32(current_character, temp0);
        masm.branch32(Assembler::Equal, temp0, Imm32(c), BranchOrBacktrack(on_equal));
    }
}

void
NativeRegExpMacroAssembler::CheckNotCharacterAfterAnd(unsigned c, unsigned and_with,
                                                      Label* on_not_equal)
{
    JitSpew(SPEW_PREFIX "CheckNotCharacterAfterAnd(%d, %d)", (int) c, (int) and_with);

    if (c == 0) {
        masm.branchTest32(Assembler::NonZero, current_character, Imm32(and_with),
                          BranchOrBacktrack(on_not_equal));
    } else {
        masm.move32(Imm32(and_with), temp0);
        masm.and32(current_character, temp0);
        masm.branch32(Assembler::NotEqual, temp0, Imm32(c), BranchOrBacktrack(on_not_equal));
    }
}

void
NativeRegExpMacroAssembler::CheckCharacterGT(char16_t c, Label* on_greater)
{
    JitSpew(SPEW_PREFIX "CheckCharacterGT(%d)", (int) c);
    masm.branch32(Assembler::GreaterThan, current_character, Imm32(c),
                  BranchOrBacktrack(on_greater));
}

void
NativeRegExpMacroAssembler::CheckCharacterLT(char16_t c, Label* on_less)
{
    JitSpew(SPEW_PREFIX "CheckCharacterLT(%d)", (int) c);
    masm.branch32(Assembler::LessThan, current_character, Imm32(c), BranchOrBacktrack(on_less));
}

void
NativeRegExpMacroAssembler::CheckGreedyLoop(Label* on_tos_equals_current_position)
{
    JitSpew(SPEW_PREFIX "CheckGreedyLoop");

#ifndef JS_CODEGEN_PPC_OSX
    Label fallthrough;
    masm.branchPtr(Assembler::NotEqual,
                   Address(backtrack_stack_pointer, -int(sizeof(void*))), current_position,
                   &fallthrough);
    masm.subPtr(Imm32(sizeof(void*)), backtrack_stack_pointer);  // Pop.
    JumpOrBacktrack(on_tos_equals_current_position);
    masm.bind(&fallthrough);
#else
    PPC_BC(fallthru, Address(backtrack_stack_pointer, -int(sizeof(void*))), current_position,
        NotEqual);
    masm.subPtr(Imm32(sizeof(void*)), backtrack_stack_pointer);  // Pop.
    JumpOrBacktrack(on_tos_equals_current_position);
    PPC_BB(fallthru);
#endif
}

void
NativeRegExpMacroAssembler::CheckNotBackReference(int start_reg, Label* on_no_match,
                                                  bool unicode)
{
    JitSpew(SPEW_PREFIX "CheckNotBackReferenceIgnoreCase(%d, %d)", start_reg, unicode);

    Label fallthrough;
    Label success;
    Label fail;

    // Find length of back-referenced capture.
    masm.loadPtr(register_location(start_reg), current_character);
    masm.loadPtr(register_location(start_reg + 1), temp0);
    masm.subPtr(current_character, temp0);  // Length to check.

#ifndef JS_CODEGEN_PPC_OSX
    // Fail on partial or illegal capture (start of capture after end of capture).
    masm.branch32(Assembler::LessThan, temp0, ImmWord(0), BranchOrBacktrack(on_no_match));
    // Succeed on empty capture (including no capture).
    masm.branchPtr(Assembler::Equal, temp0, ImmWord(0), &fallthrough);
#else
    PPC_BC(fallthru, temp0, Imm32(0), Equal);
    masm.branch32(Assembler::LessThan, temp0, ImmWord(0), BranchOrBacktrack(on_no_match));
#endif

    // Check that there are sufficient characters left in the input.
    masm.movePtr(current_position, temp1);
    masm.addPtr(temp0, temp1);
    masm.branch32(Assembler::GreaterThan, temp1, ImmWord(0), BranchOrBacktrack(on_no_match));

    // Save register to make it available below.
    masm.push(backtrack_stack_pointer);

    // Compute pointers to match string and capture string
    masm.computeEffectiveAddress(BaseIndex(input_end_pointer, current_position, TimesOne), temp1); // Start of match.
    masm.addPtr(input_end_pointer, current_character); // Start of capture.
    masm.computeEffectiveAddress(BaseIndex(temp0, temp1, TimesOne), backtrack_stack_pointer); // End of match.

    Label loop;
    masm.bind(&loop);
    uint32_t bo_loop = masm.currentOffset();
    if (mode_ == ASCII) {
        masm.load8ZeroExtend(Address(current_character, 0), temp0);
        masm.load8ZeroExtend(Address(temp1, 0), temp2);
    } else {
        MOZ_ASSERT(mode_ == CHAR16);
        masm.load16ZeroExtend(Address(current_character, 0), temp0);
        masm.load16ZeroExtend(Address(temp1, 0), temp2);
    }
#ifndef JS_CODEGEN_PPC_OSX
    masm.branch32(Assembler::NotEqual, temp0, temp2, &fail);
#else
    PPC_BC(fail, temp0, temp2, NotEqual);
#endif

    // Increment pointers into capture and match string.
    masm.addPtr(Imm32(char_size()), current_character);
    masm.addPtr(Imm32(char_size()), temp1);

    // Check if we have reached end of match area.
#ifndef JS_CODEGEN_PPC_OSX
    masm.branchPtr(Assembler::Below, temp1, backtrack_stack_pointer, &loop);
    masm.jump(&success);

    masm.bind(&fail);
#else
    masm._bc((bo_loop - masm.currentOffset() - 4), masm.ma_cmp(temp1, backtrack_stack_pointer,
        Assembler::Below));
    PPC_B(success);
    PPC_BB(fail);
#endif

    // Restore backtrack stack pointer.
    masm.pop(backtrack_stack_pointer);
    JumpOrBacktrack(on_no_match);

#ifndef JS_CODEGEN_PPC_OSX
    masm.bind(&success);
#else
    PPC_BB(success);
#endif

    // Move current character position to position after match.
    masm.movePtr(backtrack_stack_pointer, current_position);
    masm.subPtr(input_end_pointer, current_position);

    // Restore backtrack stack pointer.
    masm.pop(backtrack_stack_pointer);

#ifndef JS_CODEGEN_PPC_OSX
    masm.bind(&fallthrough);
#else
    PPC_BB(fallthru);
#endif
}

void
NativeRegExpMacroAssembler::CheckNotBackReferenceIgnoreCase(int start_reg, Label* on_no_match)
{
    JitSpew(SPEW_PREFIX "CheckNotBackReferenceIgnoreCase(%d)", start_reg);

    Label fallthrough;

    masm.loadPtr(register_location(start_reg), current_character);  // Index of start of capture
    masm.loadPtr(register_location(start_reg + 1), temp1);  // Index of end of capture
    masm.subPtr(current_character, temp1);  // Length of capture.

#ifndef JS_CODEGEN_PPC_OSX
    // The length of a capture should not be negative. This can only happen
    // if the end of the capture is unrecorded, or at a point earlier than
    // the start of the capture.
    masm.branch32(Assembler::LessThan, temp1, ImmWord(0), BranchOrBacktrack(on_no_match));

    // If length is zero, either the capture is empty or it is completely
    // uncaptured. In either case succeed immediately.
    masm.branchPtr(Assembler::Equal, temp1, ImmWord(0), &fallthrough);
#else
    PPC_BC(fallthru, temp1, Imm32(0), Equal);
    masm.branch32(Assembler::LessThan, temp1, ImmWord(0), BranchOrBacktrack(on_no_match));
#endif

    // Check that there are sufficient characters left in the input.
    masm.movePtr(current_position, temp0);
    masm.addPtr(temp1, temp0);
    masm.branch32(Assembler::GreaterThan, temp0, ImmWord(0), BranchOrBacktrack(on_no_match));

    if (mode_ == ASCII) {
        Label success, fail;

        // Save register contents to make the registers available below. After
        // this, the temp0, temp2, and current_position registers are available.
        masm.push(current_position);

        masm.addPtr(input_end_pointer, current_character); // Start of capture.
        masm.addPtr(input_end_pointer, current_position); // Start of text to match against capture.
        masm.addPtr(current_position, temp1); // End of text to match against capture.

        Label loop, loop_increment;
        masm.bind(&loop);
        uint32_t bo_loop = masm.currentOffset();
        masm.load8ZeroExtend(Address(current_position, 0), temp0);
        masm.load8ZeroExtend(Address(current_character, 0), temp2);
#ifndef JS_CODEGEN_PPC_OSX
        masm.branch32(Assembler::Equal, temp0, temp2, &loop_increment);
#else
        PPC_BC(loopinc, temp0, temp2, Equal);
#endif

        // Mismatch, try case-insensitive match (converting letters to lower-case).
        masm.or32(Imm32(0x20), temp0); // Convert match character to lower-case.

        // Is temp0 a lowercase letter?
        Label convert_capture;
        masm.computeEffectiveAddress(Address(temp0, -'a'), temp2);
#ifndef JS_CODEGEN_PPC_OSX
        masm.branch32(Assembler::BelowOrEqual, temp2, Imm32(static_cast<int32_t>('z' - 'a')),
                      &convert_capture);
#else
        PPC_BC(ccapture, temp2, Imm32(static_cast<int32_t>('z' - 'a')), BelowOrEqual);
#endif

        // Latin-1: Check for values in range [224,254] but not 247.
        masm.sub32(Imm32(224 - 'a'), temp2);
#ifndef JS_CODEGEN_PPC_OSX
        masm.branch32(Assembler::Above, temp2, Imm32(254 - 224), &fail);
#else
        PPC_BC(fail1, temp2, Imm32(254 - 224), Above);
#endif

        // Check for 247.
#ifndef JS_CODEGEN_PPC_OSX
        masm.branch32(Assembler::Equal, temp2, Imm32(247 - 224), &fail);
#else
        PPC_BC(fail2, temp2, Imm32(247 - 224), Equal);
#endif

        masm.bind(&convert_capture);
#ifdef JS_CODEGEN_PPC_OSX
        PPC_BB(ccapture);
#endif
        // Also convert capture character.
        masm.load8ZeroExtend(Address(current_character, 0), temp2);
        masm.or32(Imm32(0x20), temp2);

#ifndef JS_CODEGEN_PPC_OSX
        masm.branch32(Assembler::NotEqual, temp0, temp2, &fail);

        masm.bind(&loop_increment);
#else
        PPC_BC(fail3, temp0, temp2, NotEqual);
        PPC_BB(loopinc);
#endif

        // Increment pointers into match and capture strings.
        masm.addPtr(Imm32(1), current_character);
        masm.addPtr(Imm32(1), current_position);

        // Compare to end of match, and loop if not done.
#ifndef JS_CODEGEN_PPC_OSX
        masm.branchPtr(Assembler::Below, current_position, temp1, &loop);
        masm.jump(&success);

        masm.bind(&fail);
#else
        masm._bc((bo_loop - masm.currentOffset() - 4), masm.ma_cmp(current_position,
            temp1, Assembler::Below));
        PPC_B(succeed);
        PPC_BB(fail1);
        PPC_BB(fail2);
        PPC_BB(fail3);
#endif

        // Restore original values before failing.
        masm.pop(current_position);
        JumpOrBacktrack(on_no_match);

        masm.bind(&success);
#ifdef JS_CODEGEN_PPC_OSX
        PPC_BB(succeed);
#endif

        // Drop original character position value.
        masm.addToStackPtr(Imm32(sizeof(uintptr_t)));

        // Compute new value of character position after the matched part.
        masm.subPtr(input_end_pointer, current_position);
    } else {
        MOZ_ASSERT(mode_ == CHAR16);

#ifndef JS_CODEGEN_PPC_OSX
        // Note: temp1 needs to be saved/restored if it is volatile, as it is used after the call.
        LiveGeneralRegisterSet volatileRegs(GeneralRegisterSet::Volatile());
        volatileRegs.takeUnchecked(temp0);
        volatileRegs.takeUnchecked(temp2);
        masm.PushRegsInMask(volatileRegs);

        // Set byte_offset1.
        // Start of capture, where current_character already holds string-end negative offset.
        masm.addPtr(input_end_pointer, current_character);

        // Set byte_offset2.
        // Found by adding negative string-end offset of current position
        // to end of string.
        masm.addPtr(input_end_pointer, current_position);

        // Parameters are
        //   Address byte_offset1 - Address captured substring's start.
        //   Address byte_offset2 - Address of current character position.
        //   size_t byte_length - length of capture in bytes(!)
        masm.setupUnalignedABICall(temp0);
        masm.passABIArg(current_character);
        masm.passABIArg(current_position);
        masm.passABIArg(temp1);
        if (!unicode) {
            int (*fun)(const char16_t*, const char16_t*, size_t) = CaseInsensitiveCompareStrings;
            masm.callWithABI(JS_FUNC_TO_DATA_PTR(void*, fun));
        } else {
            int (*fun)(const char16_t*, const char16_t*, size_t) = CaseInsensitiveCompareUCStrings;
            masm.callWithABI(JS_FUNC_TO_DATA_PTR(void*, fun));
        }
        masm.storeCallResult(temp0);

        masm.PopRegsInMask(volatileRegs);

        // Check if function returned non-zero for success or zero for failure.
        masm.branchTest32(Assembler::Zero, temp0, temp0, BranchOrBacktrack(on_no_match));

#else
        // PowerPC specific version, somewhat more efficient (fixes issue 308)
        Register ppc0 = (temp1 == r6) ? r7 : r6;
        Register ppc1 = (temp1 == r8) ? r9 : r8;
        int (*fun)(const char16_t*, const char16_t*, size_t) = (unicode)
            ? CaseInsensitiveCompareUCStrings
            : CaseInsensitiveCompareStrings   ;

        // This is lazy, but only incurs one extra x_subi.
        masm.x_mflr(r0);
        masm.push5(r3, r4, r5, r6, r7);
        masm.push4(r8, r9, r10, r0);
        // Load CTR for call.
        masm.x_li32(tempRegister, (uint32_t)fun);
        masm.x_mtctr(tempRegister);
        // Do computations. We need a temp register here, but they're all
        // saved, so just clobber any but temp1.
        masm.add(ppc0, r4, r3); // set current character, don't clobber r3 yet
        masm.add(r4, r5, r3);   // set current position
        masm.x_mr(r3, ppc0);    // now, can clobber r3
        masm.x_mr(r5, temp1);   // now, can clobber r5
        // Forcibly align the stack and pull down a frame, putting the
        // previous stack pointer there.
        masm.x_mr(ppc1, stackPointerRegister);
        masm.andi_rc(ppc0, stackPointerRegister, 0x04);
        masm.subf(stackPointerRegister, ppc0, stackPointerRegister);
        masm.andi_rc(ppc0, stackPointerRegister, 0x08);
        masm.addi(ppc0, ppc0, 512);
        masm.subf(stackPointerRegister, ppc0, stackPointerRegister);
        masm.stw(ppc1, stackPointerRegister, 0);

        masm.bctr(Assembler::LinkB);

        // Restore the stack pointer.
        masm.lwz(stackPointerRegister, stackPointerRegister, 0);
        // Do the comp here before restoring the temps.
        masm.cmpwi(r3, 0);
        masm.pop4(r0, r10, r9, r8);
        masm.pop5(r7, r6, r5, r4, r3);
        masm.x_mtlr(r0);
        // Returning zero indicates no match found, so backtrack.
        masm.bc(Assembler::Equal, BranchOrBacktrack(on_no_match));
#endif
        // On success, increment position by length of capture.
        masm.addPtr(temp1, current_position);
    }

    masm.bind(&fallthrough);
#ifdef JS_CODEGEN_PPC_OSX
    PPC_BB(fallthru);
#endif
}

void
NativeRegExpMacroAssembler::CheckNotCharacterAfterMinusAnd(char16_t c, char16_t minus, char16_t and_with,
                                                           Label* on_not_equal)
{
    JitSpew(SPEW_PREFIX "CheckNotCharacterAfterMinusAnd(%d, %d, %d)", (int) c,
            (int) minus, (int) and_with);

    masm.computeEffectiveAddress(Address(current_character, -minus), temp0);
    if (c == 0) {
        masm.branchTest32(Assembler::NonZero, temp0, Imm32(and_with),
                          BranchOrBacktrack(on_not_equal));
    } else {
        masm.and32(Imm32(and_with), temp0);
        masm.branch32(Assembler::NotEqual, temp0, Imm32(c), BranchOrBacktrack(on_not_equal));
    }
}

void
NativeRegExpMacroAssembler::CheckCharacterInRange(char16_t from, char16_t to,
                                                  Label* on_in_range)
{
    JitSpew(SPEW_PREFIX "CheckCharacterInRange(%d, %d)", (int) from, (int) to);

    masm.computeEffectiveAddress(Address(current_character, -from), temp0);
    masm.branch32(Assembler::BelowOrEqual, temp0, Imm32(to - from), BranchOrBacktrack(on_in_range));
}

void
NativeRegExpMacroAssembler::CheckCharacterNotInRange(char16_t from, char16_t to,
                                                     Label* on_not_in_range)
{
    JitSpew(SPEW_PREFIX "CheckCharacterNotInRange(%d, %d)", (int) from, (int) to);

    masm.computeEffectiveAddress(Address(current_character, -from), temp0);
    masm.branch32(Assembler::Above, temp0, Imm32(to - from), BranchOrBacktrack(on_not_in_range));
}

void
NativeRegExpMacroAssembler::CheckBitInTable(uint8_t* table, Label* on_bit_set)
{
    JitSpew(SPEW_PREFIX "CheckBitInTable");

    masm.movePtr(ImmPtr(table), temp0);

    // kTableMask is currently 127, so we need to mask even if the input is
    // Latin1. V8 has the same issue.
    static_assert(JSString::MAX_LATIN1_CHAR > kTableMask,
                  "No need to mask if MAX_LATIN1_CHAR <= kTableMask");
    masm.move32(Imm32(kTableSize - 1), temp1);
    masm.and32(current_character, temp1);

    masm.load8ZeroExtend(BaseIndex(temp0, temp1, TimesOne), temp0);
    masm.branchTest32(Assembler::NonZero, temp0, temp0, BranchOrBacktrack(on_bit_set));
}

void
NativeRegExpMacroAssembler::Fail()
{
    JitSpew(SPEW_PREFIX "Fail");

    if (!global())
        masm.movePtr(ImmWord(RegExpRunStatus_Success_NotFound), temp0);
    masm.jump(&exit_label_);
}

void
NativeRegExpMacroAssembler::IfRegisterGE(int reg, int comparand, Label* if_ge)
{
    JitSpew(SPEW_PREFIX "IfRegisterGE(%d, %d)", reg, comparand);
    masm.branchPtr(Assembler::GreaterThanOrEqual, register_location(reg), ImmWord(comparand),
                   BranchOrBacktrack(if_ge));
}

void
NativeRegExpMacroAssembler::IfRegisterLT(int reg, int comparand, Label* if_lt)
{
    JitSpew(SPEW_PREFIX "IfRegisterLT(%d, %d)", reg, comparand);
    masm.branchPtr(Assembler::LessThan, register_location(reg), ImmWord(comparand),
                   BranchOrBacktrack(if_lt));
}

void
NativeRegExpMacroAssembler::IfRegisterEqPos(int reg, Label* if_eq)
{
    JitSpew(SPEW_PREFIX "IfRegisterEqPos(%d)", reg);
    masm.branchPtr(Assembler::Equal, register_location(reg), current_position,
                   BranchOrBacktrack(if_eq));
}

void
NativeRegExpMacroAssembler::LoadCurrentCharacter(int cp_offset, Label* on_end_of_input,
                                                 bool check_bounds, int characters)
{
    JitSpew(SPEW_PREFIX "LoadCurrentCharacter(%d, %d)", cp_offset, characters);

    MOZ_ASSERT(cp_offset >= -1);      // ^ and \b can look behind one character.
    MOZ_ASSERT(cp_offset < (1<<30));  // Be sane! (And ensure negation works)
    if (check_bounds)
        CheckPosition(cp_offset + characters - 1, on_end_of_input);
    LoadCurrentCharacterUnchecked(cp_offset, characters);
}

void
NativeRegExpMacroAssembler::LoadCurrentCharacterUnchecked(int cp_offset, int characters)
{
    JitSpew(SPEW_PREFIX "LoadCurrentCharacterUnchecked(%d, %d)", cp_offset, characters);

    if (mode_ == ASCII) {
        BaseIndex address(input_end_pointer, current_position, TimesOne, cp_offset);
        if (characters == 4) {
#ifdef IS_BIG_ENDIAN
            masm.load32ByteSwapped(address, current_character);
#else
            masm.load32(address, current_character);
#endif
        } else if (characters == 2) {
#ifdef IS_BIG_ENDIAN
            masm.load16ZeroExtendSwapped(address, current_character);
#else
            masm.load16ZeroExtend(address, current_character);
#endif
        } else {
            MOZ_ASSERT(characters == 1);
            masm.load8ZeroExtend(address, current_character);
        }
    } else {
        MOZ_ASSERT(mode_ == CHAR16);
        MOZ_ASSERT(characters <= 2);
        BaseIndex address(input_end_pointer, current_position, TimesOne, cp_offset * sizeof(char16_t));
        if (characters == 2)
#ifdef IS_BIG_ENDIAN
            masm.load32WordSwapped(address, current_character);
#else
            masm.load32(address, current_character);
#endif
        else
            masm.load16ZeroExtend(address, current_character);
    }
}

void
NativeRegExpMacroAssembler::PopCurrentPosition()
{
    JitSpew(SPEW_PREFIX "PopCurrentPosition");

    PopBacktrack(current_position);
}

void
NativeRegExpMacroAssembler::PopRegister(int register_index)
{
    JitSpew(SPEW_PREFIX "PopRegister(%d)", register_index);

    PopBacktrack(temp0);
    masm.storePtr(temp0, register_location(register_index));
}

void
NativeRegExpMacroAssembler::PushBacktrack(Label* label)
{
    JitSpew(SPEW_PREFIX "PushBacktrack");

    CodeOffset patchOffset = masm.movWithPatch(ImmPtr(nullptr), temp0);

    MOZ_ASSERT(!label->bound());

    {
        AutoEnterOOMUnsafeRegion oomUnsafe;
        if (!labelPatches.append(LabelPatch(label, patchOffset)))
            oomUnsafe.crash("NativeRegExpMacroAssembler::PushBacktrack");
    }

    PushBacktrack(temp0);
    CheckBacktrackStackLimit();
}

void
NativeRegExpMacroAssembler::BindBacktrack(Label* label)
{
    JitSpew(SPEW_PREFIX "BindBacktrack");

    Bind(label);

    for (size_t i = 0; i < labelPatches.length(); i++) {
        LabelPatch& v = labelPatches[i];
        if (v.label == label) {
            v.labelOffset = label->offset();
            v.label = nullptr;
            break;
        }
    }
}

void
NativeRegExpMacroAssembler::PushBacktrack(Register source)
{
    JitSpew(SPEW_PREFIX "PushBacktrack");

    MOZ_ASSERT(source != backtrack_stack_pointer);

    // Notice: This updates flags, unlike normal Push.
    masm.storePtr(source, Address(backtrack_stack_pointer, 0));
    masm.addPtr(Imm32(sizeof(void*)), backtrack_stack_pointer);
}

void
NativeRegExpMacroAssembler::PushBacktrack(int32_t value)
{
    JitSpew(SPEW_PREFIX "PushBacktrack(%d)", (int) value);

    // Notice: This updates flags, unlike normal Push.
    masm.storePtr(ImmWord(value), Address(backtrack_stack_pointer, 0));
    masm.addPtr(Imm32(sizeof(void*)), backtrack_stack_pointer);
}

void
NativeRegExpMacroAssembler::PopBacktrack(Register target)
{
    JitSpew(SPEW_PREFIX "PopBacktrack");

    MOZ_ASSERT(target != backtrack_stack_pointer);

    // Notice: This updates flags, unlike normal Pop.
    masm.subPtr(Imm32(sizeof(void*)), backtrack_stack_pointer);
    masm.loadPtr(Address(backtrack_stack_pointer, 0), target);
}

void
NativeRegExpMacroAssembler::CheckBacktrackStackLimit()
{
    JitSpew(SPEW_PREFIX "CheckBacktrackStackLimit");

    const void* limitAddr = runtime->regexpStack.addressOfLimit();

#ifndef JS_CODEGEN_PPC_OSX
    Label no_stack_overflow;
    masm.branchPtr(Assembler::AboveOrEqual, AbsoluteAddress(limitAddr),
                   backtrack_stack_pointer, &no_stack_overflow);

    // Copy the stack pointer before the call() instruction modifies it.
    masm.moveStackPtrTo(temp2);

    masm.call(&stack_overflow_label_);
    masm.bind(&no_stack_overflow);

    // Exit with an exception if the call failed.
    masm.branchTest32(Assembler::Zero, temp0, temp0, &exit_with_exception_label_);
#else
    // The above actually looks incorrect. We move the exception check into the call
    // block instead.
    masm.x_li32(addressTempRegister, (uint32_t)limitAddr);
    masm.lwz(tempRegister, addressTempRegister, 0);
    PPC_BC(noverflow, tempRegister, backtrack_stack_pointer, AboveOrEqual);
    
    masm.moveStackPtrTo(temp2);
    masm.call(&stack_overflow_label_);
    masm.branch32(Assembler::Equal, temp0, Imm32(0), &exit_with_exception_label_);
    
    PPC_BB(noverflow);
#endif
}

void
NativeRegExpMacroAssembler::PushCurrentPosition()
{
    JitSpew(SPEW_PREFIX "PushCurrentPosition");

    PushBacktrack(current_position);
}

void
NativeRegExpMacroAssembler::PushRegister(int register_index, StackCheckFlag check_stack_limit)
{
    JitSpew(SPEW_PREFIX "PushRegister(%d)", register_index);

    masm.loadPtr(register_location(register_index), temp0);
    PushBacktrack(temp0);
    if (check_stack_limit)
        CheckBacktrackStackLimit();
}

void
NativeRegExpMacroAssembler::ReadCurrentPositionFromRegister(int reg)
{
    JitSpew(SPEW_PREFIX "ReadCurrentPositionFromRegister(%d)", reg);

    masm.loadPtr(register_location(reg), current_position);
}

void
NativeRegExpMacroAssembler::WriteCurrentPositionToRegister(int reg, int cp_offset)
{
    JitSpew(SPEW_PREFIX "WriteCurrentPositionToRegister(%d, %d)", reg, cp_offset);

    if (cp_offset == 0) {
        masm.storePtr(current_position, register_location(reg));
    } else {
        masm.computeEffectiveAddress(Address(current_position, cp_offset * char_size()), temp0);
        masm.storePtr(temp0, register_location(reg));
    }
}

void
NativeRegExpMacroAssembler::ReadBacktrackStackPointerFromRegister(int reg)
{
    JitSpew(SPEW_PREFIX "ReadBacktrackStackPointerFromRegister(%d)", reg);

    masm.loadPtr(register_location(reg), backtrack_stack_pointer);
    masm.addPtr(Address(masm.getStackPointer(),
                offsetof(FrameData, backtrackStackBase)), backtrack_stack_pointer);
}

void
NativeRegExpMacroAssembler::WriteBacktrackStackPointerToRegister(int reg)
{
    JitSpew(SPEW_PREFIX "WriteBacktrackStackPointerToRegister(%d)", reg);

    masm.movePtr(backtrack_stack_pointer, temp0);
    masm.subPtr(Address(masm.getStackPointer(),
                offsetof(FrameData, backtrackStackBase)), temp0);
    masm.storePtr(temp0, register_location(reg));
}

void
NativeRegExpMacroAssembler::SetCurrentPositionFromEnd(int by)
{
    JitSpew(SPEW_PREFIX "SetCurrentPositionFromEnd(%d)", by);

#ifndef JS_CODEGEN_PPC_OSX
    Label after_position;
    masm.branchPtr(Assembler::GreaterThanOrEqual, current_position,
                   ImmWord(-by * char_size()), &after_position);
    masm.movePtr(ImmWord(-by * char_size()), current_position);

    // On RegExp code entry (where this operation is used), the character before
    // the current position is expected to be already loaded.
    // We have advanced the position, so it's safe to read backwards.
    LoadCurrentCharacterUnchecked(-1, 1);
    masm.bind(&after_position);
#else
    masm.x_li32(tempRegister, (uint32_t)(-by * char_size()));
    PPC_BC(afterp, current_position, tempRegister, GreaterThanOrEqual);
    masm.x_mr(current_position, tempRegister);
    LoadCurrentCharacterUnchecked(-1, 1);
    PPC_BB(afterp);
#endif
}

void
NativeRegExpMacroAssembler::SetRegister(int register_index, int to)
{
    JitSpew(SPEW_PREFIX "SetRegister(%d, %d)", register_index, to);

    MOZ_ASSERT(register_index >= num_saved_registers_);  // Reserved for positions!
    masm.storePtr(ImmWord(to), register_location(register_index));
}

bool
NativeRegExpMacroAssembler::Succeed()
{
    JitSpew(SPEW_PREFIX "Succeed");

    masm.jump(&success_label_);
    return global();
}

void
NativeRegExpMacroAssembler::ClearRegisters(int reg_from, int reg_to)
{
    JitSpew(SPEW_PREFIX "ClearRegisters(%d, %d)", reg_from, reg_to);

    MOZ_ASSERT(reg_from <= reg_to);
    masm.loadPtr(Address(masm.getStackPointer(), offsetof(FrameData, inputStartMinusOne)), temp0);
    for (int reg = reg_from; reg <= reg_to; reg++)
        masm.storePtr(temp0, register_location(reg));
}

void
NativeRegExpMacroAssembler::CheckPosition(int cp_offset, Label* on_outside_input)
{
    JitSpew(SPEW_PREFIX "CheckPosition(%d)", cp_offset);
    masm.branch32(Assembler::GreaterThanOrEqual, current_position,
                   ImmWord(-cp_offset * char_size()), BranchOrBacktrack(on_outside_input));
}

Label*
NativeRegExpMacroAssembler::BranchOrBacktrack(Label* branch)
{
    if (branch)
        return branch;
    return &backtrack_label_;
}

void
NativeRegExpMacroAssembler::JumpOrBacktrack(Label* to)
{
    JitSpew(SPEW_PREFIX "JumpOrBacktrack");

    if (to)
        masm.jump(to);
    else
        Backtrack();
}

bool
NativeRegExpMacroAssembler::CheckSpecialCharacterClass(char16_t type, Label* on_no_match)
{
    JitSpew(SPEW_PREFIX "CheckSpecialCharacterClass(%d)", (int) type);

    Label* branch = BranchOrBacktrack(on_no_match);

    // Range checks (c in min..max) are generally implemented by an unsigned
    // (c - min) <= (max - min) check
#ifndef JS_CODEGEN_PPC_OSX
    switch (type) {
      case 's':
        // Match space-characters.
        if (mode_ == ASCII) {
            // One byte space characters are '\t'..'\r', ' ' and \u00a0.
            Label success;
            masm.branch32(Assembler::Equal, current_character, Imm32(' '), &success);

            // Check range 0x09..0x0d.
            masm.computeEffectiveAddress(Address(current_character, -'\t'), temp0);
            masm.branch32(Assembler::BelowOrEqual, temp0, Imm32('\r' - '\t'), &success);

            // \u00a0 (NBSP).
            masm.branch32(Assembler::NotEqual, temp0, Imm32(0x00a0 - '\t'), branch);

            masm.bind(&success);
            return true;
        }
        return false;
      case 'S':
        // The emitted code for generic character classes is good enough.
        return false;
      case 'd':
        // Match ASCII digits ('0'..'9')
        masm.computeEffectiveAddress(Address(current_character, -'0'), temp0);
        masm.branch32(Assembler::Above, temp0, Imm32('9' - '0'), branch);
        return true;
      case 'D':
        // Match non ASCII-digits
        masm.computeEffectiveAddress(Address(current_character, -'0'), temp0);
        masm.branch32(Assembler::BelowOrEqual, temp0, Imm32('9' - '0'), branch);
        return true;
      case '.': {
        // Match non-newlines (not 0x0a('\n'), 0x0d('\r'), 0x2028 and 0x2029)
        masm.move32(current_character, temp0);
        masm.xor32(Imm32(0x01), temp0);

        // See if current character is '\n'^1 or '\r'^1, i.e., 0x0b or 0x0c
        masm.sub32(Imm32(0x0b), temp0);
        masm.branch32(Assembler::BelowOrEqual, temp0, Imm32(0x0c - 0x0b), branch);
        if (mode_ == CHAR16) {
            // Compare original value to 0x2028 and 0x2029, using the already
            // computed (current_char ^ 0x01 - 0x0b). I.e., check for
            // 0x201d (0x2028 - 0x0b) or 0x201e.
            masm.sub32(Imm32(0x2028 - 0x0b), temp0);
            masm.branch32(Assembler::BelowOrEqual, temp0, Imm32(0x2029 - 0x2028), branch);
        }
        return true;
      }
      case 'w': {
        if (mode_ != ASCII) {
            // Table is 128 entries, so all ASCII characters can be tested.
            masm.branch32(Assembler::Above, current_character, Imm32('z'), branch);
        }
        MOZ_ASSERT(0 == word_character_map[0]);  // Character '\0' is not a word char.
        masm.movePtr(ImmPtr(word_character_map), temp0);
        masm.load8ZeroExtend(BaseIndex(temp0, current_character, TimesOne), temp0);
        masm.branchTest32(Assembler::Zero, temp0, temp0, branch);
        return true;
      }
      case 'W': {
        Label done;
        if (mode_ != ASCII) {
            // Table is 128 entries, so all ASCII characters can be tested.
            masm.branch32(Assembler::Above, current_character, Imm32('z'), &done);
        }
        MOZ_ASSERT(0 == word_character_map[0]);  // Character '\0' is not a word char.
        masm.movePtr(ImmPtr(word_character_map), temp0);
        masm.load8ZeroExtend(BaseIndex(temp0, current_character, TimesOne), temp0);
        masm.branchTest32(Assembler::NonZero, temp0, temp0, branch);
        if (mode_ != ASCII)
            masm.bind(&done);
        return true;
      }
        // Non-standard classes (with no syntactic shorthand) used internally.
      case '*':
        // Match any character.
        return true;
      case 'n': {
        // Match newlines (0x0a('\n'), 0x0d('\r'), 0x2028 or 0x2029).
        // The opposite of '.'.
        masm.move32(current_character, temp0);
        masm.xor32(Imm32(0x01), temp0);

        // See if current character is '\n'^1 or '\r'^1, i.e., 0x0b or 0x0c
        masm.sub32(Imm32(0x0b), temp0);

        if (mode_ == ASCII) {
            masm.branch32(Assembler::Above, temp0, Imm32(0x0c - 0x0b), branch);
        } else {
            Label done;
            masm.branch32(Assembler::BelowOrEqual, temp0, Imm32(0x0c - 0x0b), &done);
            MOZ_ASSERT(CHAR16 == mode_);

            // Compare original value to 0x2028 and 0x2029, using the already
            // computed (current_char ^ 0x01 - 0x0b). I.e., check for
            // 0x201d (0x2028 - 0x0b) or 0x201e.
            masm.sub32(Imm32(0x2028 - 0x0b), temp0);
            masm.branch32(Assembler::Above, temp0, Imm32(1), branch);

            masm.bind(&done);
        }
        return true;
      }
        // No custom implementation (yet):
      default:
        return false;
    }

#else
    switch (type) {
      case 's':
        // Match space-characters.
        if (mode_ == ASCII) {
            PPC_BC(succeed1, current_character, Imm32(' '), Equal);
            masm.computeEffectiveAddress(Address(current_character, -'\t'), temp0);
            PPC_BC(succeed2, temp0, Imm32('\r' - '\t'), BelowOrEqual);
            masm.branch32(Assembler::NotEqual, temp0, Imm32(0x00a0 - '\t'), branch);
            PPC_BB(succeed1);
            PPC_BB(succeed2);
            return true;
        }
        // For UCS-2, we also need
        // \u1680\u180e\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff
        return false;
      case 'S':
        // Match non-space characters.
        if (mode_ == ASCII) {
            masm.branch32(Assembler::Equal, current_character, Imm32(' '), branch);
            masm.computeEffectiveAddress(Address(current_character, -'\t'), temp0);
            masm.branch32(Assembler::BelowOrEqual, temp0, Imm32('\r' - '\t'), branch);
            masm.branch32(Assembler::Equal, temp0, Imm32(0x00a0 - '\t'), branch);
            return true;
        }
        return false;
      case 'd':
        // Match ASCII digits ('0'..'9')
        masm.computeEffectiveAddress(Address(current_character, -'0'), temp0);
        masm.branch32(Assembler::Above, temp0, Imm32('9' - '0'), branch);
        return true;
      case 'D':
        // Match non ASCII-digits
        masm.computeEffectiveAddress(Address(current_character, -'0'), temp0);
        masm.branch32(Assembler::BelowOrEqual, temp0, Imm32('9' - '0'), branch);
        return true;
      case '.': {
        // Match non-newlines (not 0x0a('\n'), 0x0d('\r'), 0x2028 and 0x2029)
        masm.move32(current_character, temp0);
        masm.xor32(Imm32(0x01), temp0);

        // See if current character is '\n'^1 or '\r'^1, i.e., 0x0b or 0x0c
        masm.sub32(Imm32(0x0b), temp0);
        masm.branch32(Assembler::BelowOrEqual, temp0, Imm32(0x0c - 0x0b), branch);
        if (mode_ == CHAR16) {
            // Compare original value to 0x2028 and 0x2029, using the already
            // computed (current_char ^ 0x01 - 0x0b). I.e., check for
            // 0x201d (0x2028 - 0x0b) or 0x201e.
            masm.sub32(Imm32(0x2028 - 0x0b), temp0);
            masm.branch32(Assembler::BelowOrEqual, temp0, Imm32(0x2029 - 0x2028), branch);
        }
        return true;
      }
      case 'w': {
        if (mode_ != ASCII) {
            // Table is 128 entries, so all ASCII characters can be tested.
            masm.branch32(Assembler::Above, current_character, Imm32('z'), branch);
        }
        MOZ_ASSERT(0 == word_character_map[0]);  // Character '\0' is not a word char.
        masm.movePtr(ImmPtr(word_character_map), temp0);
        masm.load8ZeroExtend(BaseIndex(temp0, current_character, TimesOne), temp0);
        masm.branchTest32(Assembler::Zero, temp0, temp0, branch);
        return true;
      }
      case 'W': {
        BufferOffset bo_done;
        if (mode_ != ASCII) {
            // Table is 128 entries, so all ASCII characters can be tested.
            PPC__BC(done, current_character, Imm32('z'), Above);
        }
        MOZ_ASSERT(0 == word_character_map[0]);  // Character '\0' is not a word char.
        masm.movePtr(ImmPtr(word_character_map), temp0);
        masm.load8ZeroExtend(BaseIndex(temp0, current_character, TimesOne), temp0);
        masm.branchTest32(Assembler::NonZero, temp0, temp0, branch);
        if (mode_ != ASCII)
            PPC_BB(done);
        return true;
      }
        // Non-standard classes (with no syntactic shorthand) used internally.
      case '*':
        // Match any character.
        return true;
      case 'n': {
        // Match newlines (0x0a('\n'), 0x0d('\r'), 0x2028 or 0x2029).
        // The opposite of '.'.
        masm.move32(current_character, temp0);
        masm.xor32(Imm32(0x01), temp0);

        // See if current character is '\n'^1 or '\r'^1, i.e., 0x0b or 0x0c
        masm.sub32(Imm32(0x0b), temp0);

        if (mode_ == ASCII) {
            masm.branch32(Assembler::Above, temp0, Imm32(0x0c - 0x0b), branch);
        } else {
            MOZ_ASSERT(CHAR16 == mode_);
            PPC_BC(done, temp0, Imm32(0x0c - 0x0b), BelowOrEqual);

            // Compare original value to 0x2028 and 0x2029, using the already
            // computed (current_char ^ 0x01 - 0x0b). I.e., check for
            // 0x201d (0x2028 - 0x0b) or 0x201e.
            masm.sub32(Imm32(0x2028 - 0x0b), temp0);
            masm.branch32(Assembler::Above, temp0, Imm32(1), branch);

            PPC_BB(done);
        }
        return true;
      }
        // No custom implementation (yet):
      default:
        return false;
    }
#endif
}

bool
NativeRegExpMacroAssembler::CanReadUnaligned()
{
#if defined(JS_CODEGEN_ARM)
    return !jit::HasAlignmentFault();
#elif defined(JS_CODEGEN_MIPS32) || defined(JS_CODEGEN_MIPS64)
    return false;
#else
    return true;
#endif
}

const uint8_t
NativeRegExpMacroAssembler::word_character_map[] =
{
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,

    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu,  // '0' - '7'
    0xffu, 0xffu, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,  // '8' - '9'

    0x00u, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu,  // 'A' - 'G'
    0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu,  // 'H' - 'O'
    0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu,  // 'P' - 'W'
    0xffu, 0xffu, 0xffu, 0x00u, 0x00u, 0x00u, 0x00u, 0xffu,  // 'X' - 'Z', '_'

    0x00u, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu,  // 'a' - 'g'
    0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu,  // 'h' - 'o'
    0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu, 0xffu,  // 'p' - 'w'
    0xffu, 0xffu, 0xffu, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,  // 'x' - 'z'

    // Latin-1 range
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,

    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,

    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,

    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u,
};
