
.data

window_class_name: .asciz "myclass"
window_class:     
    .long 80                       # size in bytes
    .long 0                        # style
    .quad 0                        # wndproc (event handling)
    .long 0                        # cbClsExtra
    .long 0                        # cbWndExtra
    .quad 0                        # hInstance
    .quad 0                        # hIcon
    .quad 0                        # hCursor
    .quad 0                        # hbrBackground
    .quad 0                        # lpszMenuName
    .quad 0                        # lpszClassName
    .quad 0                        # hIconSm

window_title: .asciz "heya! how ya doin'"

msg_class: .skip 64                 # space for msg class

pixel_format:
    .word 40                        # nSize: size of the structure
    .word 1                         # nVersion: version number
    .long 0x00000007                # dwFlags: PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER
    .byte 0                         # iPixelType: type of pixel
    .byte 32                        # cColorBits: number of color bits
    .byte 8, 0, 8, 0, 8, 0, 8, 0    # cRedBits, cRedShift, cGreenBits, cGreenShift, cBlueBits, cBlueShift, cAlphaBits, cAlphaShift
    .byte 0                         # cAccumBits: number of accumulation bits
    .byte 0, 0, 0, 0                # cAccumRedBits, cAccumGreenBits, cAccumBlueBits, cAccumAlphaBits
    .byte 16                        # cDepthBits: number of depth bits
    .byte 0                         # cStencilBits: number of stencil bits
    .byte 0                         # cAuxBuffers: number of auxiliary buffers
    .byte 0                         # iLayerType: layer type
    .byte 0                         # bReserved: reserved
    .long 0, 0, 0                   # dwLayerMask, dwVisibleMask, dwDamageMask

.bss

window_handle: .quad 0
device_context: .quad 0
opengl_context: .quad 0

has_window: .byte 0

.text

.globl main

create_window:
    PROLOGUE
    SHADOW_SPACE                            # allocate for all subroutines in this method

    PARAMS1 $0
    call GetModuleHandleA                   # get handle for this program
    CHECK_RETURN_FAILURE $2

    #----------------------------------------------------------------------------------------------------------
    # register class
    #----------------------------------------------------------------------------------------------------------

    lea window_class(%rip), %rcx            # get pointer to class structure
    lea window_class_name(%rip), %rdx       # get pointer to class name
    lea event_handling(%rip), %r8           # get pointer to event handler

    movq %r8, 8(%rcx)                       # wndproc (event handling)
    movq %rax, 24(%rcx)                     # hInstance
    movq %rdx, 64(%rcx)                     # lpszClassName

    call RegisterClassExA                   # register window class
    CHECK_RETURN_FAILURE $3

    #----------------------------------------------------------------------------------------------------------
    # create window
    #----------------------------------------------------------------------------------------------------------

    leaq window_title(%rip), %r8            # load pointer

    # pass parameters
    PARAMS12 $0, %rax, %r8, $0x00CF0000, $100, $100, $1920, $1080, $0, $0, $0, $0
    SHADOW_SPACE
    call CreateWindowExA                    # create window
    CLEAN_SHADOW
    CHECK_RETURN_FAILURE $4

    movq %rax, window_handle(%rip)          # store window handle   

    #----------------------------------------------------------------------------------------------------------
    # get device context
    #----------------------------------------------------------------------------------------------------------   

    PARAMS1 window_handle(%rip)
    call GetDC
    CHECK_RETURN_FAILURE $5

    movq %rax, device_context(%rip)         # store device context

    #----------------------------------------------------------------------------------------------------------
    # set pixel format
    #----------------------------------------------------------------------------------------------------------

    leaq pixel_format(%rip), %rdx           # load pixel format pointer

    PARAMS2 %rax, %rdx
    call ChoosePixelFormat                  # choose valid pixel format
    CHECK_RETURN_FAILURE $6

    leaq pixel_format(%rip), %r8            # load pixel format pointer

    PARAMS3 device_context(%rip), %rax, %r8
    call SetPixelFormat                     # set pixel format
    CHECK_RETURN_FAILURE $7

    #----------------------------------------------------------------------------------------------------------
    # create opengl context
    #----------------------------------------------------------------------------------------------------------

    PARAMS1 device_context(%rip)
    call wglCreateContext                   # create context
    CHECK_RETURN_FAILURE $8

    movq %rax, opengl_context(%rip)         # store opengl context

    PARAMS2 device_context(%rip), %rax
    call wglMakeCurrent                     # make current
    CHECK_RETURN_FAILURE $9

    #----------------------------------------------------------------------------------------------------------
    # show window
    #----------------------------------------------------------------------------------------------------------

    PARAMS2 window_handle(%rip), $1
    call ShowWindow

    movb $1, has_window(%rip)               # set to true             

    EPILOGUE

poll_events:
    PROLOGUE
    SHADOW_SPACE                        # allocate for all calls in this subroutine

    sub $8, %rsp                        # align stack

    poll_events_loop:

        # get event

        leaq msg_class(%rip), %rcx          # get pointer to msg class

        # pass params
        PARAMS5 %rcx, window_handle(%rip), $0, $0, $1
        SHADOW_SPACE
        call PeekMessageA                   # get msg without blocking
        CLEAN_SHADOW

        cmp $0, %rax                        # if 0 (no msg's in queue)
        jz poll_events_end                  # end loop

        # dispatch msg event
        leaq msg_class(%rip), %rcx          # get pointer to msg class
        call TranslateMessage               # translate key msg's

        leaq msg_class(%rip), %rcx          # get pointer to msg class
        call DispatchMessageA               # dispatch msg

        jmp poll_events_loop

    poll_events_end:
    EPILOGUE

event_handling:
    PROLOGUE
    SHADOW_SPACE

    cmp $2, %rdx                            # wm_destroy
    je wm_destroy

    cmp $0x0201, %rdx                       # wm_lbuttondown
    je wm_lbuttondown

    default:
        call DefWindowProcA


    event_end:
    EPILOGUE

wm_destroy:
    movq $0, has_window(%rip)               # set to false
    jmp default

wm_lbuttondown:
    mov $0, %rax

    lea lbuttondown(%rip), %rcx
    call printf

    jmp event_end

lbuttondown: .asciz "Left button pressed!"
