
.text

# check input and do player controls
DoPlayerControls:
    PROLOGUE

    leaq pressed_keys(%rip), %rcx
    cmpb $0, 0x12(%rcx)                                 # if the alt key is not pressed
    jne 1f                                              # skip doing mouse controls

    call GetForegroundWindow                            # get window on the foreground
    cmpq %rax, window_handle(%rip)                      # if the game window is not on the foreground
    jne 1f                                              # skip doing mouse controls

    call DoMouseControls

    1:
    EPILOGUE

# handles rotating the camera using the mouse
DoMouseControls:
    PROLOGUE

    push %r12
    push %r13
    leaq player_cam(%rip), %r12                         # get pointer to player camera struct

    # calculate mouse movement this frame, %r8 = x, %r9 = y
    movq mouse_x(%rip), %r8
    sub mouse_past_x(%rip), %r8

    movq mouse_y(%rip), %r9
    sub mouse_past_y(%rip), %r9

    # turn delta mouse positions into floats
    cvtsi2ss %r8, %xmm0
    cvtsi2ss %r9, %xmm1

    # divide delta positions by 1000
    divss mouse_sensitivity(%rip), %xmm0
    divss mouse_sensitivity(%rip), %xmm1

    # get player angles
    movss 8(%r12), %xmm6
    movss 12(%r12), %xmm7

    # modify camara angle based on mouse movement
    subss %xmm0, %xmm6
    subss %xmm1, %xmm7

    # loop angle x in range 0 - 2pi
    movss %xmm6, %xmm0
    movss f_tau(%rip), %xmm1
    call fmodf

    movd %xmm0, %eax                                    # get bits of the float
    andl $0x80000000, %eax                              # and so only the sign bit is left
    cmp $0, %eax                                        # if the float is not negative
    je 1f                                               # skip correcting for minus

    movss f_tau(%rip), %xmm1
    addss %xmm1, %xmm0

    1: # float is not negative
    movss %xmm0, 8(%r12)

    # clamp angle y in range -half pi - half pi
    
    movss f_half_pi(%rip), %xmm0
    minps %xmm0, %xmm7

    movss f_min_half_pi(%rip), %xmm0
    maxps %xmm0, %xmm7

    movss %xmm7, 12(%r12)

    # put mouse cursor in the center of the screen

    # get screen size
    movq screen_width(%rip), %r12
    movq screen_height(%rip), %r13
    # devide by 2
    shr $1, %r12
    shr $1, %r13

    SHADOW_SPACE
    PARAMS2 %r12, %r13
    call SetCursorPos                                   # set mouse position to the center of the screen

    PARAMS2 %r12, %r13
    call HandleMouseSetPos                              # make sure the listener works

    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    EPILOGUE

    .data
    temp: .float 0
