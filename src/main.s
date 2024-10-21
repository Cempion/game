.include "float.s"
.include "macro.s"
.include "util/list.s"
.include "util/binary_heap.s"

.include "window.s"

.include "game/setup.s"

.include "rendering/renderer.s"

.equ FRAME_RATE, 60 # the maximum framerate

.data

hello_world: .asciz "Hello World!\n"

is_running: .byte 0

timer_frequency: .quad 0
timer_start: .quad 0 

frame_rate_format: .asciz "FrameRate: %f \n"

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
    movq timer_frequency(%rip), %rcx 

    # calculate seconds per frame
    movq $FRAME_RATE, %rdx
    cvtsi2ss %rdx, %xmm1
    movss f_1(%rip), %xmm0
    divss %xmm1, %xmm0                      # 1 / frame_rate = seconds_per_frame

    # calculate timer units per frame and store in r13 as integer
    cvtsi2ss %rcx, %xmm1
    mulss %xmm1, %xmm0                      # (1 / frame_rate) * timer_fequency = timer_units_per_frame
    cvttss2si %xmm0, %r13

    # put in a starting value
    leaq timer_start(%rip), %rcx
    call QueryPerformanceCounter    

    sys_loop:
        cmpb $0, is_running(%rip)            # if true do loop
        jz end

        #----------------------------------------------------------------------------------------------------------
        # Cap Frame Rate
        #----------------------------------------------------------------------------------------------------------

        # store last start time in r12
        movq timer_start(%rip), %r12

        # get current time
        leaq timer_start(%rip), %rcx
        call QueryPerformanceCounter

        # get time difference
        movq timer_start(%rip), %rcx
        subq %r12, %rcx

        # busy sleep

        2: # do something to pass the time
            
            call PollEvents

            # get current time
            leaq timer_start(%rip), %rcx
            call QueryPerformanceCounter
            movq timer_start(%rip), %rcx

            sub %r12, %rcx                          # get time difference
            cmp %r13, %rcx                          # if time difference is less than time per frame
            jl 2b                                   # continue busy sleep

        //call PrintFrameRate

        #----------------------------------------------------------------------------------------------------------
        # Game Loop
        #----------------------------------------------------------------------------------------------------------

        call PollEvents

        # load and unload map

        movq loaded_tiles(%rip), %rcx
        CLEAR_LIST %rcx
        call GetLoadedTiles
        movq %rax, loaded_tiles(%rip)               # in case list grew

        PARAMS2 map_wfc(%rip), %rax
        call SetCollapsedTiles

        call RenderFrame

        call DoEntityAi

        call SimulateFrame

        call HandleMouseEndFrame

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
    PARAMS1 loaded_tiles(%rip)
    call free

    PARAMS1 pf_frontier(%rip)
    call free
    PARAMS1 pf_visited_pos(%rip)
    call free
    PARAMS1 pf_came_from(%rip)
    call free
    PARAMS1 pf_cost_so_far(%rip)
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

# prints the frame rate to the console based on the given difference between time ticks
# PARAMS:
# %rcx  =   difference between start and end time
# RETURNS:
# void
PrintFrameRate:
    PROLOGUE

    # calculate framerate
    cvtsi2sd %rcx, %xmm0                    # timer difference
    movq timer_frequency(%rip), %rcx        # timer ticks per second
    cvtsi2sd %rcx, %xmm1         
    divsd %xmm1, %xmm0                      # delta time
    movq $1, %rcx
    cvtsi2sd %rcx, %xmm1                    
    divsd %xmm0, %xmm1                      # frame rate

    movq $0, %rax
    leaq frame_rate_format(%rip), %rcx
    movd %xmm1, %rdx
    SHADOW_SPACE
    call printf

    EPILOGUE
