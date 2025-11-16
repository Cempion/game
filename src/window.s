.include "listeners/keyListener.s"
.include "listeners/mouseListener.s"

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

wglCreateContextAttribsARB: .asciz "        wglCreateContextAttribsARB"

context_attribList:
    .long 0x2091        # WGL_CONTEXT_MAJOR_VERSION_ARB
    .long 4             # Major version 3
    .long 0x2092        # WGL_CONTEXT_MINOR_VERSION_ARB
    .long 6             # Minor version 0
    .long 0             # Termination (int 0)

.bss

window_handle: .quad 0
device_context: .quad 0
opengl_context: .quad 0

screen_width: .quad 0
screen_height: .quad 0

.text

.globl main

CreateWindow:
    PROLOGUE
    SHADOW_SPACE                                        # allocate for all subroutines in this method

    #----------------------------------------------------------------------------------------------------------
    # get screen width and height
    #----------------------------------------------------------------------------------------------------------

    # SM_CXSCREEN
    PARAMS1 $0
    call GetSystemMetrics
    movq %rax, screen_width(%rip)                       # save screen width

    # SM_CYSCREEN
    PARAMS1 $1
    call GetSystemMetrics
    movq %rax, screen_height(%rip)                      # save screen height

    #----------------------------------------------------------------------------------------------------------
    # get device handle
    #----------------------------------------------------------------------------------------------------------

    PARAMS1 $0
    call GetModuleHandleA                               # get handle for this program
    CHECK_RETURN_FAILURE $100

    #----------------------------------------------------------------------------------------------------------
    # register class
    #----------------------------------------------------------------------------------------------------------

    lea window_class(%rip), %rcx                        # get pointer to class structure
    lea window_class_name(%rip), %rdx                   # get pointer to class name
    lea HandleEvent(%rip), %r8                          # get pointer to event handler

    movq %r8, 8(%rcx)                                   # wndproc (event handling)
    movq %rax, 24(%rcx)                                 # hInstance
    movq %rdx, 64(%rcx)                                 # lpszClassName

    call RegisterClassExA                               # register window class
    CHECK_RETURN_FAILURE $101

    #----------------------------------------------------------------------------------------------------------
    # create window
    #----------------------------------------------------------------------------------------------------------

    leaq window_title(%rip), %r8                        # load pointer

    # pass parameters
    # dwExStyle, class name, window title, dwStyle (topmost | layered | popup), x, y, width, height, parent, menu, instance, param
    PARAMS12 $0, %rax, %r8, $0x80080008, $0, $0, screen_width(%rip), screen_height(%rip), $0, $0, $0, $0
    SHADOW_SPACE
    call CreateWindowExA                                # create window
    CLEAN_SHADOW
    CHECK_RETURN_FAILURE $102

    movq %rax, window_handle(%rip)                      # store window handle   

    #----------------------------------------------------------------------------------------------------------
    # get device context
    #----------------------------------------------------------------------------------------------------------   

    PARAMS1 window_handle(%rip)
    call GetDC
    CHECK_RETURN_FAILURE $103

    movq %rax, device_context(%rip)                     # store device context

    #----------------------------------------------------------------------------------------------------------
    # set pixel format
    #----------------------------------------------------------------------------------------------------------

    leaq pixel_format(%rip), %rdx                       # load pixel format pointer

    PARAMS2 %rax, %rdx
    call ChoosePixelFormat                              # choose valid pixel format
    CHECK_RETURN_FAILURE $104

    leaq pixel_format(%rip), %r8                        # load pixel format pointer

    PARAMS3 device_context(%rip), %rax, %r8
    call SetPixelFormat                                 # set pixel format
    CHECK_RETURN_FAILURE $105

    #----------------------------------------------------------------------------------------------------------
    # create opengl context
    #----------------------------------------------------------------------------------------------------------

    # make temporary context because the wglCreateContextAttribsARB subroutine needed to make a context in
    # a specific version can only be gotten with another opengl context.

    PARAMS1 device_context(%rip)
    call wglCreateContext                               # create temp context just to get wglCreateContextAttribsARB
    CHECK_RETURN_FAILURE $106

    movq %rax, opengl_context(%rip)                     # store temporary opengl context

    PARAMS2 device_context(%rip), %rax
    call wglMakeCurrent                                 # make temp context current
    CHECK_RETURN_FAILURE $107

    # get wglCreateContextAttribsARB

    leaq wglCreateContextAttribsARB(%rip), %rcx
    add $8, %rcx                                        # offset to the name
    call wglGetProcAddress                              # get pointer to wglCreateContextAttribsARB
    CHECK_RETURN_FAILURE $108
    movq %rax, wglCreateContextAttribsARB(%rip)         # store pointer to wglCreateContextAttribsARB

    # delete temporary context
    PARAMS1 opengl_context(%rip)
    call wglDeleteContext
    CHECK_RETURN_FAILURE $109

    # make permanent context

    PARAMS2 device_context(%rip), $0
    leaq context_attribList(%rip), %r8
    call *wglCreateContextAttribsARB(%rip)              # call wglCreateContextAttribsARB to make permanent context with the correct version
    CHECK_RETURN_FAILURE $110

    movq %rax, opengl_context(%rip)                     # store permanent opengl context

    PARAMS2 device_context(%rip), %rax
    call wglMakeCurrent                                 # make permanent context current
    CHECK_RETURN_FAILURE $111

    call HideCursor

    EPILOGUE


# hides the cursor and binds it to the window
HideCursor:
    PROLOGUE
    SHADOW_SPACE

    PARAMS1 $0
    call ShowCursor                         # hide cursor

    EPILOGUE

# shows the cursor and unbinds it from the window
DisplayCursor:
    PROLOGUE
    SHADOW_SPACE

    PARAMS1 $1
    call ShowCursor                         # show cursor

    EPILOGUE

#----------------------------------------------------------------------------------------------------------
# Events
#----------------------------------------------------------------------------------------------------------

PollEvents:
    PROLOGUE

    push %r12
    push %r13
    movq window_handle(%rip), %r12          # save window handle in callee saved register
    leaq msg_class(%rip), %r13              # save msg class pointer in callee saved register

    // cmpb $0, is_player_alive(%rip)          # if dead do crash ;)   
    // je poll_events_end

    sub $48, %rsp                           # allocate shadowspace and fifth parameter and allign stack

    poll_events_loop:

        # pass params
        PARAMS4 %r13, %r12, $0, $0
        movq $1, -32(%rbp)                  # fifth parameter
        call PeekMessageA                   # get msg without blocking

        cmp $0, %rax                        # if 0 (no msg's in queue)
        jz poll_events_end                  # end loop

        # dispatch msg event
        PARAMS1 %r13                        # get pointer to msg class
        call TranslateMessage               # translate key msg's

        PARAMS1 %r13                        # get pointer to msg class
        call DispatchMessageA               # dispatch msg

        jmp poll_events_loop

    poll_events_end:

    # restore callee saved registers
    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    EPILOGUE

# event handler for the window
HandleEvent:
    PROLOGUE
    SHADOW_SPACE

    cmp $2, %rdx                            # wm_destroy
    je wm_destroy

    # keyboard

    cmp $0x0100, %rdx                       # wm_keydown
    je wm_keydown

    cmp $0x0101, %rdx                       # wm_keyup
    je wm_keyup

    cmp $0x0104, %rdx                       # wm_syskeydown
    je wm_syskeydown

    cmp $0x0105, %rdx                       # wm_syskeyup
    je wm_syskeyup

    # mouse

    cmp $0x0201, %rdx                       # wm_lbuttondown
    je wm_lbuttondown

    cmp $0x0202, %rdx                       # wm_lbuttonup
    je wm_lbuttonup

    cmp $0x0204, %rdx                       # wm_rbuttondown
    je wm_rbuttondown

    cmp $0x0205, %rdx                       # wm_rbuttonup
    je wm_rbuttonup

    cmp $0x0207, %rdx                       # wm_mbuttondown
    je wm_mbuttondown

    cmp $0x0208, %rdx                       # wm_mbuttonup
    je wm_mbuttonup

    cmp $0x0200, %rdx                       # wm_mousemove
    je wm_mousemove

    default:
        call DefWindowProcA


    event_end:
    EPILOGUE

wm_destroy:
    movq $0, is_running(%rip)               # set to false
    jmp default

wm_keydown:
    PARAMS1 %r8
    call HandleKeyDownMsg
    movq $0, %rax                           # return 0 to show that the msg got handled
    jmp event_end

wm_keyup:
    PARAMS1 %r8
    call HandleKeyUpMsg
    movq $0, %rax                           # return 0 to show that the msg got handled
    jmp event_end

wm_syskeydown:
    PARAMS1 %r8
    call HandleKeyDownMsg
    movq $0, %rax                           # return 0 to show that the msg got handled
    jmp event_end

wm_syskeyup:
    PARAMS1 %r8
    call HandleKeyUpMsg
    movq $0, %rax                           # return 0 to show that the msg got handled
    jmp event_end

wm_lbuttondown:
    PARAMS1 $LEFT_BUTTON
    call HandleButtonDownMsg
    movq $0, %rax                           # return 0 to show that the msg got handled
    jmp event_end

wm_lbuttonup:
    PARAMS1 $LEFT_BUTTON
    call HandleButtonUpMsg
    movq $0, %rax                           # return 0 to show that the msg got handled
    jmp event_end

wm_rbuttondown:
    PARAMS1 $RIGHT_BUTTON
    call HandleButtonDownMsg
    movq $0, %rax                           # return 0 to show that the msg got handled
    jmp event_end

wm_rbuttonup:
    PARAMS1 $RIGHT_BUTTON
    call HandleButtonUpMsg
    movq $0, %rax                           # return 0 to show that the msg got handled
    jmp event_end

wm_mbuttondown:
    PARAMS1 $MIDDLE_BUTTON
    call HandleButtonDownMsg
    movq $0, %rax                           # return 0 to show that the msg got handled
    jmp event_end

wm_mbuttonup:
    PARAMS1 $MIDDLE_BUTTON
    call HandleButtonUpMsg
    movq $0, %rax                           # return 0 to show that the msg got handled
    jmp event_end

wm_mousemove:
    # get x and y coordinates of the mouse (first 2 bytes = x, second 2 bytes = y)
    movq %r9, %rcx
    andq $0xFFFF, %rcx                      # get x pos
    shr $16, %r9
    movq %r9, %rdx
    andq $0xFFFF, %rdx                      # get y pos

    call HandleMouseMoveMsg
    movq $0, %rax                           # return 0 to show that the msg got handled
    jmp event_end

