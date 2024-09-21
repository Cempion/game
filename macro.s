
.macro PROLOGUE
    push %rbp
    movq %rsp, %rbp
.endm

.macro EPILOGUE
    movq %rbp, %rsp
    pop %rbp
    ret
.endm

# macro for passing parameters following the windows convention

.macro PARAMS1 param1
    movq \param1, %rcx
.endm

.macro PARAMS2 param1, param2
    movq \param1, %rcx
    movq \param2, %rdx
.endm

.macro PARAMS3 param1, param2, param3
    movq \param1, %rcx
    movq \param2, %rdx
    movq \param3, %r8
.endm

.macro PARAMS4 param1, param2, param3, param4
    movq \param1, %rcx
    movq \param2, %rdx
    movq \param3, %r8
    movq \param4, %r9
.endm

.macro PARAMS5 param1, param2, param3, param4, param5
    movq \param1, %rcx
    movq \param2, %rdx
    movq \param3, %r8
    movq \param4, %r9

    # push backwards
    pushq \param5
.endm

.macro PARAMS6 param1, param2, param3, param4, param5, param6
    movq \param1, %rcx
    movq \param2, %rdx
    movq \param3, %r8
    movq \param4, %r9

    # push backwards
    pushq \param6
    pushq \param5
.endm

.macro PARAMS7 param1, param2, param3, param4, param5, param6, param7
    movq \param1, %rcx
    movq \param2, %rdx
    movq \param3, %r8
    movq \param4, %r9

    # push backwards
    pushq \param7
    pushq \param6
    pushq \param5
.endm

.macro PARAMS8 param1, param2, param3, param4, param5, param6, param7, param8
    movq \param1, %rcx
    movq \param2, %rdx
    movq \param3, %r8
    movq \param4, %r9

    # push backwards
    pushq \param8
    pushq \param7
    pushq \param6
    pushq \param5
.endm

.macro PARAMS9 param1, param2, param3, param4, param5, param6, param7, param8, param9
    movq \param1, %rcx
    movq \param2, %rdx
    movq \param3, %r8
    movq \param4, %r9

    # push backwards
    pushq \param9
    pushq \param8
    pushq \param7
    pushq \param6
    pushq \param5
.endm

.macro PARAMS10 param1, param2, param3, param4, param5, param6, param7, param8, param9, param10
    movq \param1, %rcx
    movq \param2, %rdx
    movq \param3, %r8
    movq \param4, %r9

    # push backwards
    pushq \param10
    pushq \param9
    pushq \param8
    pushq \param7
    pushq \param6
    pushq \param5
.endm

.macro PARAMS11 param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11
    movq \param1, %rcx
    movq \param2, %rdx
    movq \param3, %r8
    movq \param4, %r9

    # push backwards
    pushq \param11
    pushq \param10
    pushq \param9
    pushq \param8
    pushq \param7
    pushq \param6
    pushq \param5
.endm

.macro PARAMS12 param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11, param12
    movq \param1, %rcx
    movq \param2, %rdx
    movq \param3, %r8
    movq \param4, %r9

    # push backwards
    pushq \param12
    pushq \param11
    pushq \param10
    pushq \param9
    pushq \param8
    pushq \param7
    pushq \param6
    pushq \param5
.endm

.macro SHADOW_SPACE
    sub $32, %rsp                           # allocate shadow space (i dont like shadow space)
.endm

.macro CHECK_RETURN_FAILURE error_code
    cmp $0, %rax
    jnz 1f

    PARAMS1 \error_code
    call exit

    1:
.endm
