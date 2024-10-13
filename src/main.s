.include "float.s"
.include "macro.s"
.include "window.s"

.include "game/pieces.s"
.include "game/setup.s"
.include "game/controls.s"

.include "rendering/renderer.s"

.data

hello_world: .asciz "Hello World!\n"

is_running: .byte 0

timer_frequency: .quad 0
timer_start: .quad 0

.text

.globl main

main:
    PROLOGUE

    push %r12                               # save register so it can be used
    push %r13                               # save register so it can be used
    SHADOW_SPACE

    # hello world print

    mov $0, %rax
    lea hello_world(%rip), %rcx
    call printf

    # setup

    call CreateWindow

    call SetupGame

    call SetupRenderer

    # show window

    call RenderFrame                        # make sure first frame isn't black
    PARAMS2 window_handle(%rip), $1
    call ShowWindow

    movb $1, is_running(%rip)               # set to true

    #----------------------------------------------------------------------------------------------------------
    # Loop
    #----------------------------------------------------------------------------------------------------------

    # get frequency of timer
    leaq timer_frequency(%rip), %rcx
    call QueryPerformanceFrequency  

    # put in a starting value
    leaq timer_start(%rip), %rcx
    call QueryPerformanceCounter    

    sys_loop:
        cmpb $0, is_running(%rip)            # if true do loop
        jz end

        # calculate delta time

        # store last start time in r12
        movq timer_start(%rip), %r12

        # get current time
        leaq timer_start(%rip), %rcx
        call QueryPerformanceCounter

        # get time difference
        movq timer_start(%rip), %rax
        subq %r12, %rax

        # get delta time
        mov timer_frequency(%rip), %rbx
        cvtsi2ss %rax, %xmm0                
        cvtsi2ss %rbx, %xmm1                
        divss %xmm1, %xmm0                          # (this - last) / frequency = dt   

        # save dt in callee saved register
        movd %xmm0, %r12   

        # do the rest

        call RenderFrame

        call PollEvents

        movd %r12, %xmm0                            # give dt as parameter 1                          
        call DoPlayerControls

        jmp sys_loop

    #----------------------------------------------------------------------------------------------------------
    # end
    #----------------------------------------------------------------------------------------------------------

    end:
    
    # cleanup

    PARAMS1 wfc_ruleset(%rip)
    call free
    PARAMS1 map_wfc(%rip)
    call free

    PARAMS1 opengl_context(%rip)
    call wglDeleteContext
    CHECK_RETURN_FAILURE $112

    # restore registers
    movq -8(%rbp), %r12
    movq -16(%rbp), %r13

    # skip epilogue since it crashes program

    PARAMS1 $0
    call exit
