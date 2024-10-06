
.include "macro.s"
.include "window.s"
.include "rendering/renderer.s"

.extern CreateWfc

.data

hello_world: .asciz "Hello World!\n"

.equ WFC_WIDTH, 20
.equ WFC_HEIGHT, 20
.equ WFC_TILE_COUNT, 400

wfc_ruleset: .byte 3
             .quad 0b011, 0b011, 0b011, 0b011 # everything possible on all sides
             .quad 0b111, 0b111, 0b111, 0b111 # everything possible on all sides
             .quad 0b110, 0b110, 0b110, 0b110 # everything possible on all sides


wfc_chars: .ascii "*KLM"

wfc_map: .skip WFC_TILE_COUNT

.bss

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

    call SetupRenderer

    PARAMS2 $WFC_WIDTH, $WFC_HEIGHT
    lea wfc_ruleset(%rip), %r8
    lea wfcOnChange(%rip), %r9
    call CreateWfc

    movq %rax, %r12

    PARAMS1 %r12
    call CollapseAllTiles

    # call printWfc

    # show window

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
    CLEAN_SHADOW
    CHECK_RETURN_FAILURE $112

    PARAMS1 $0
    call exit


wfcOnChange:
    PROLOGUE
    lea wfc_chars(%rip), %r8
    lea wfc_map(%rip), %r9

    popcnt %rdx, %rsi
    cmp $0, %rsi                        # if entropy is 0
    je 1f                               # go to special case

    cmp $1, %rsi                        # if entropy is 0
    je 2f                               # add module to map

    jmp 3f                              # dont do anything

    1: # entropy = 0
        movb (%r8), %al                 # move entropy 0 default into map
        movb %al, (%r9, %rcx)
        jmp 3f

    2: # entropy = 1
        bsf %rdx, %rax                  # get index of module
        inc %rax                        # correct for 0 entropy default

        movb (%r8, %rax), %al           # move module into map
        movb %al, (%r9, %rcx)

    3: # end
    EPILOGUE

.equ space, 0x20
.equ new_line, 0x0a

printWfc:
    PROLOGUE
    lea wfc_map(%rip), %rcx

    # calculate string size

    movq $WFC_TILE_COUNT, %rax              # put tile count into rax to calculate string size
    movq $3, %r9
    mul %r9                             # each tile is 3 chars long, SPACE CHAR SPACE
    add $WFC_HEIGHT, %rax                   # add height to account for new line
    add $1, %rax                        # add space for null terminator
    movq %rax, %r8                      # move string size to free rax

    # allocate space on stack

    sub %r8, %rsp                       # move stack pointer to make space
    movq %rsp, %rax                     # move stack pointer to rax to do a modulo
    movq $0, %rdx                       # make 0 to do div
    movq $8, %r9
    div %r9                             # stack pointer % 8
    sub %rdx, %rsp                      # allign stack

    # make string

    movq $0, %r9                        # use as string index

    movq $WFC_HEIGHT, %rsi                  # use as y counter
    dec %rsi         
    1: # outer loop (y position)
        cmp $0, %rsi                    # if y is than 0
        jl 4f                           # exit loop

        movq $0, %rdi                   # use as x counter                  
        2: # inner loop (x position)
            cmp $WFC_WIDTH, %rdi                # if x is greater or equal to width
            jge 3f                          # exit loop

            # calculate tile index
            movq %rsi, %rax                 # put y in rax
            movq $WFC_WIDTH, %rdx
            mul %rdx                        # y * width
            add %rdi, %rax                  # x + y * width

            # put chars in string
            movq $space, (%rsp, %r9)        # put in space
            inc %r9
            movq (%rcx, %rax), %rax         # get module char
            movq %rax, (%rsp, %r9)          # put in char
            inc %r9
            movq $space, (%rsp, %r9)        # put in space
            inc %r9
            
            inc %rdi                        # increment counter
            jmp 2b
        3: # exit inner loop

        movq $new_line, (%rsp, %r9)         # put in new line
        inc %r9

        dec %rsi                            # decrement counter
        jmp 1b
    4: # exit outer loop

    movq $0, (%rsp, %r9)                    # put in null terminator
    
    # print string

    movq $0, %rax
    PARAMS1 %rsp
    SHADOW_SPACE
    call printf
    CLEAN_SHADOW

    EPILOGUE
