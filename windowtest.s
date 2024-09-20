
.include "macro.s"

.data

hello_world: .asciz "Hello World!\n"

window_class_name: .asciz "myclass"
window_class: 
    .skip 96 # space for 8 quads and 4 longs

window_title: .asciz "heya! how ya doin'"

msg_class:
    .skip 64 # space for 6 quads and 1 long

.bss

window_handle: .quad 0

is_running: .byte 0

.text

.globl main

main:
    PROLOGUE

    push %r12                               # save register so it can be used
    sub $8, %rsp                            # allign stack

    mov $0, %rax
    lea hello_world(%rip), %rcx
    call printf

    movb $1, is_running(%rip)               # set to true

#----------------------------------------------------------------------------------------------------------
# make window
#----------------------------------------------------------------------------------------------------------

make_window:
    PARAMS1 $0
    call GetModuleHandleA                   # get handle for this program
    CHECK_WINDOWS_FAILURE $2

    movq %rax, %r12                         # save handle in r12

    # initialize window class

    lea window_class(%rip), %rcx            # get pointer to class structure
    lea window_class_name(%rip), %r10       # get pointer to class name
    lea event_handling(%rip), %r11          # get pointer to event handler

    movl $80, (%rcx)                        # size in bytes
    movl $0, 4(%rcx)                        # style
    movq %r11, 8(%rcx)                      # wndproc (event handling)
    movl $0, 16(%rcx)                       # cbClsExtra
    movl $0, 20(%rcx)                       # cbWndExtra
    movq %r12, 24(%rcx)                     # hInstance
    movq $0, 32(%rcx)                       # hIcon
    movq $0, 40(%rcx)                       # hCursor
    movq $0, 48(%rcx)                       # hbrBackground
    movq $0, 56(%rcx)                       # lpszMenuName
    movq %r10, 64(%rcx)                     # lpszClassName
    movq $0, 72(%rcx)                       # hIconSm

    call RegisterClassExA                   # register window class
    CHECK_WINDOWS_FAILURE $3

    # create window

    leaq window_title(%rip), %r8            # load pointer
    # pass parameters
    PARAMS12 $0, %rax, %r8, $0x00CF0000, $100, $100, $1920, $1080, $0, $0, $0, $0
    sub $32, %rsp                           # allocate shadow space (i dont like shadow space)

    call CreateWindowExA                    # create window
    CHECK_WINDOWS_FAILURE $4

    movq %rax, window_handle(%rip)          # store window handle      

    # show window

    PARAMS2 window_handle(%rip), $1
    call ShowWindow

    #----------------------------------------------------------------------------------------------------------
    # Loop
    #----------------------------------------------------------------------------------------------------------

    sys_loop:
        cmpb $0, is_running(%rip)            # if true do loop
        jz end

        call poll_events

        jmp sys_loop

    end:

    add $8, %rsp                            # account for alignment
    pop %r12                                # restore register

    # skip epilogue since it crashes program
    PARAMS1 $0
    call exit

event_handling:
    PROLOGUE

    cmp $2, %rdx                            # wd_destroy
    jne default
    destroy:
    movq $0, is_running(%rip)

    default:
        sub $32, %rsp                       # allocate shadow space (i dont like shadow space)
        call DefWindowProcA

    EPILOGUE

poll_events:
    PROLOGUE

    sub $8, %rsp                        # align stack

    poll_events_loop:

        # get event

        leaq msg_class(%rip), %rcx          # get pointer to msg class
        # pass params
        PARAMS5 %rcx, window_handle(%rip), $0, $0, $1
        sub $32, %rsp                       # allocate shadow space (i dont like shadow space)

        call PeekMessageA                   # get msg without blocking

        cmp $0, %rax                        # if 0 (no msg's in queue)
        jz poll_events_end                  # end loop

        # dispatch msg event
        leaq msg_class(%rip), %rcx          # get pointer to msg class
        call TranslateMessage               # translate key msg's
        leaq msg_class(%rip), %rcx          # get pointer to msg class
        call DispatchMessageA

        jmp poll_events_loop

    poll_events_end:
    EPILOGUE

