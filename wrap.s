#include "go_asm.h"
#include "go_tls.h"
#include "funcdata.h"
#include "textflag.h"

// func one() (ret int64)
TEXT main·one(SB),4,$8 // NOSPLIT=4
    MOVQ    $1, AX
    MOVQ    AX, ret+0(FP)
    RET

// Taken from runtime/asm_amd64.s (9b69196958a1ba3eba7a1621894ea9aafaa91648).

// Save state of caller into g->sched. Smashes R8, R9.
TEXT gosave<>(SB),NOSPLIT,$0
    get_tls(R8)
    MOVQ    g(R8), R8
    MOVQ    0(SP), R9
    MOVQ    R9, (g_sched+gobuf_pc)(R8)
    LEAQ    8(SP), R9
    MOVQ    R9, (g_sched+gobuf_sp)(R8)
    MOVQ    $0, (g_sched+gobuf_ret)(R8)
    MOVQ    $0, (g_sched+gobuf_ctxt)(R8)
    MOVQ    BP, (g_sched+gobuf_bp)(R8)
    RET

// asmcgocall(void(*fn)(void*), void *arg)
// Call fn(arg) on the scheduler stack,
// aligned appropriately for the gcc ABI.
// See cgocall.c for more details.
TEXT ·asmcgocall(SB),NOSPLIT,$0-16
    MOVQ    fn+0(FP), AX
    MOVQ    arg+8(FP), BX
    CALL    asmcgocall<>(SB)
    RET

TEXT ·asmcgocall_errno(SB),NOSPLIT,$0-20
    MOVQ    fn+0(FP), AX
    MOVQ    arg+8(FP), BX
    CALL    asmcgocall<>(SB)
    MOVL    AX, ret+16(FP)
    RET

// asmcgocall common code. fn in AX, arg in BX. returns errno in AX.
TEXT asmcgocall<>(SB),NOSPLIT,$0-0
    MOVQ    SP, DX

    // Figure out if we need to switch to m->g0 stack.
    // We get called to create new OS threads too, and those
    // come in on the m->g0 stack already.
    get_tls(CX)
    MOVQ    g(CX), R8
    MOVQ    g_m(R8), R8
    MOVQ    m_g0(R8), SI
    MOVQ    g(CX), DI
    CMPQ    SI, DI
    JEQ nosave
    MOVQ    m_gsignal(R8), SI
    CMPQ    SI, DI
    JEQ nosave
    
    MOVQ    m_g0(R8), SI
    CALL    gosave<>(SB)
    MOVQ    SI, g(CX)
    MOVQ    (g_sched+gobuf_sp)(SI), SP
nosave:

    // Now on a scheduling stack (a pthread-created stack).
    // Make sure we have enough room for 4 stack-backed fast-call
    // registers as per windows amd64 calling convention.
    SUBQ    $64, SP
    ANDQ    $~15, SP    // alignment for gcc ABI
    MOVQ    DI, 48(SP)  // save g
    MOVQ    (g_stack+stack_hi)(DI), DI
    SUBQ    DX, DI
    MOVQ    DI, 40(SP)  // save depth in stack (can't just save SP, as stack might be copied during a callback)
    MOVQ    BX, DI      // DI = first argument in AMD64 ABI
    MOVQ    BX, CX      // CX = first argument in Win64
    CALL    AX

    // Restore registers, g, stack pointer.
    get_tls(CX)
    MOVQ    48(SP), DI
    MOVQ    (g_stack+stack_hi)(DI), SI
    SUBQ    40(SP), SI
    MOVQ    DI, g(CX)
    MOVQ    SI, SP
    RET

// taken from sys_solaris_amd64.s (9b69196958a1ba3eba7a1621894ea9aafaa91648)

// Call a library function with SysV calling conventions.
// The called function can take a maximum of 6 INTEGER class arguments,
// see 
//   Michael Matz, Jan Hubicka, Andreas Jaeger, and Mark Mitchell
//   System V Application Binary Interface 
//   AMD64 Architecture Processor Supplement
// section 3.2.3.
//
// Called by runtime·asmcgocall or runtime·cgocall.
// NOT USING GO CALLING CONVENTION.
TEXT main·asmsysvicall6(SB),NOSPLIT,$0
    // asmcgocall will put first argument into DI.
    PUSHQ   DI          // save for later
    MOVQ    libcall_fn(DI), AX
    MOVQ    libcall_args(DI), R11
    MOVQ    libcall_n(DI), R10

    get_tls(CX)
    MOVQ    g(CX), BX
    MOVQ    g_m(BX), BX
    MOVQ    m_perrno(BX), DX
    CMPQ    DX, $0
    JEQ skiperrno1
    MOVL    $0, 0(DX)

skiperrno1:
    CMPQ    R11, $0
    JEQ skipargs
    // Load 6 args into correspondent registers.
    MOVQ    0(R11), DI
    MOVQ    8(R11), SI
    MOVQ    16(R11), DX
    MOVQ    24(R11), CX
    MOVQ    32(R11), R8
    MOVQ    40(R11), R9
skipargs:

    // Call SysV function
    CALL    AX

    // Return result
    POPQ    DI
    MOVQ    AX, libcall_r1(DI)
    MOVQ    DX, libcall_r2(DI)

    get_tls(CX)
    MOVQ    g(CX), BX
    MOVQ    g_m(BX), BX
    MOVQ    m_perrno(BX), AX
    CMPQ    AX, $0
    JEQ skiperrno2
    MOVL    0(AX), AX
    MOVQ    AX, libcall_err(DI)

skiperrno2: 
    RET
