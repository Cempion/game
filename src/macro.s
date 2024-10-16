
.macro PROLOGUE
    push %rbp
    movq %rsp, %rbp
.endm

.macro EPILOGUE
    movq %rbp, %rsp
    pop %rbp
    ret
.endm

.macro FREE_REGISTERS
    sub $8, %rsp
    push %rbx
    push %r12
    push %r13
    push %r14
    push %r15
.endm

.macro RESTORE_REGISTERS
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    pop %rbx
    add $8, %rsp
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

.macro CLEAN_SHADOW
    add $32, %rsp                           # clean up shadow space (i dont like shadow space)
.endm

.macro CHECK_RETURN_FAILURE error_code
    cmp $0, %rax
    jnz end_\@

    PARAMS1 \error_code
    call exit

    end_\@:
.endm

.macro LOOP_LONG value, max
    movl \value, %eax                       
    cltq                                    # convert to quad by sign extending it
    LOOP_QUAD %rax, \max
    movl %eax, \value
.endm

.macro LOOP_QUAD value, max
    movq \value, %rax                       # Move the value to rax for div
    movq $0, %rdx                           # Clear rdx
    cqto                                    # Sign extend rax to rdx:rax for division
    idiv \max                               # Divide rdx:rax by range, quotient in rax, remainder in rdx

    cmpq $0, %rdx                           # if result is greater or equal to 0
    jge end_\@                              # end macro

    addq \max, %rdx                         # correct negative number

    end_\@: # end
    movq %rdx, \value                       # return result
.endm

.macro LENGTH_VEC2 dest, vec2
    movsd \vec2, \dest
    mulps \dest, \dest          # (x^2, y^2)
    haddps \dest, \dest         # (x^2 + y^2, y^2)
    sqrtss \dest, \dest         # sqrt(x^2 + y^2)
.endm

.macro RANDOM dest
    loop_\@:
    RDRAND \dest
    jnc loop_\@
.endm
