
.include "macro.s"
.include "opengl.s"
.include "window.s"

.data

hello_world: .asciz "Hello World!\n"

clear_color:
    .float 0.0 # red
    .float 1.0 # green
    .float 0.0 # blue
    .float 0.0 # alpha

.bss

.text

.globl main

main:
    PROLOGUE

    push %r12                               # save register so it can be used
    sub $8, %rsp                            # allign stack

    mov $0, %rax
    lea hello_world(%rip), %rcx
    SHADOW_SPACE
    call printf

    call load_opengl_methods

    call create_window

    #----------------------------------------------------------------------------------------------------------
    # Loop
    #----------------------------------------------------------------------------------------------------------

    sys_loop:
        cmpb $0, has_window(%rip)            # if true do loop
        jz end

        leaq clear_color(%rip), %rcx
        movss (%rcx), %xmm0
        movss 4(%rcx), %xmm1
        movss 8(%rcx), %xmm2
        movss 12(%rcx), %xmm3
        SHADOW_SPACE
        call glClearColor
        
        PARAMS1 $0x00004000
        SHADOW_SPACE
        call glClear

        PARAMS1 device_context(%rip)
        SHADOW_SPACE
        call SwapBuffers

        call poll_events

    jmp sys_loop

    #----------------------------------------------------------------------------------------------------------
    # end
    #----------------------------------------------------------------------------------------------------------

    end:

    # skip epilogue since it crashes program
    
    # cleanup
    PARAMS1 opengl_context(%rip)
    SHADOW_SPACE
    call wglDeleteContext
    CHECK_RETURN_FAILURE $10

    PARAMS1 $0
    call exit
