.include "float.s"
.include "macro.s"
.include "window.s"

.include "game/pieces.s"
.include "game/setup.s"
.include "game/controls.s"

.include "rendering/renderer.s"

.data

hello_world: .asciz "Hello World!\n"

.text

.globl main

main:
    PROLOGUE

    sub $8, %rsp                            # allign stack
    push %r12                               # save register so it can be used

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

    movb $1, has_window(%rip)               # set to true

    #----------------------------------------------------------------------------------------------------------
    # Loop
    #----------------------------------------------------------------------------------------------------------

    sys_loop:
        cmpb $0, has_window(%rip)            # if true do loop
        jz end

        call RenderFrame

        call PollEvents

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

    # skip epilogue since it crashes program

    PARAMS1 $0
    call exit
