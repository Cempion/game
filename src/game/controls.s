
.data

temp: .float 0, 0

.text

# check input and do player controls
DoPlayerControls:
    PROLOGUE

    call DoKeyControls

    leaq pressed_keys(%rip), %rcx
    cmpb $0, 0x12(%rcx)                                 # if the alt key is not pressed
    jne 1f                                              # skip doing mouse controls

    call GetForegroundWindow                            # get window on the foreground
    cmpq %rax, window_handle(%rip)                      # if the game window is not on the foreground
    jne 1f                                              # skip doing mouse controls

    call DoMouseControls

    1:
    EPILOGUE

# handles moving the camera using the keyboard
DoKeyControls:
    PROLOGUE
    push %r12
    push %r13 
    subq $16, %rsp                      # allocate space for floats
    movups %xmm6, (%rsp)
    SHADOW_SPACE

    leaq pressed_keys(%rip), %r12       # get pointer to pressed keys
    leaq player_cam(%rip), %r13         # get pointer to camera position

       # w
    cmpb $1, 0x57(%r12)      
    jne 1f           

        # get dir and store in xmm0, xmm1
        # dir y
        movss 12(%r13), %xmm0
        call sinf
        movss %xmm0, %xmm6

        # dir x
        movss 12(%r13), %xmm0
        call cosf

        movss %xmm6, %xmm1                  # mov dir y to final location

        # invert z axis
        movss f_min_1(%rip), %xmm5
        mulss %xmm5, %xmm1 

        # calculate movement
        movss walk_speed(%rip), %xmm2       # get movement speed
        mulss %xmm2, %xmm0
        mulss %xmm2, %xmm1

        # get position
        movss (%r13), %xmm3
        movss 8(%r13), %xmm4

        # add to position
        addss %xmm1, %xmm3
        addss %xmm0, %xmm4

        # update position
        movss %xmm3, (%r13)
        movss %xmm4, 8(%r13)

    1: # a
    cmpb $1, 0x41(%r12)       
    jne 2f    

        # get dir and store in xmm0, xmm1
        # dir y
        movss 12(%r13), %xmm0
        call sinf
        movss %xmm0, %xmm6

        # dir x
        movss 12(%r13), %xmm0
        call cosf

        movss %xmm6, %xmm1                  # mov dir y to final location

        # invert x and z axis
        movss f_min_1(%rip), %xmm5
        mulss %xmm5, %xmm0
        mulss %xmm5, %xmm1 

        # calculate movement
        movss walk_speed(%rip), %xmm2       # get movement speed
        mulss %xmm2, %xmm0
        mulss %xmm2, %xmm1

        # get position
        movss (%r13), %xmm3
        movss 8(%r13), %xmm4

        # add to position
        addss %xmm0, %xmm3
        addss %xmm1, %xmm4

        # update position
        movss %xmm3, (%r13)
        movss %xmm4, 8(%r13)
            

    2: # s
    cmpb $1, 0x53(%r12)      
    jne 3f

        # get dir and store in xmm0, xmm1
        # dir y
        movss 12(%r13), %xmm0
        call sinf
        movss %xmm0, %xmm6

        # dir x
        movss 12(%r13), %xmm0
        call cosf

        movss %xmm6, %xmm1                  # mov dir y to final location

        # invert x axis
        movss f_min_1(%rip), %xmm5
        mulss %xmm5, %xmm0

        # calculate movement
        movss walk_speed(%rip), %xmm2       # get movement speed
        mulss %xmm2, %xmm0
        mulss %xmm2, %xmm1

        # get position
        movss (%r13), %xmm3
        movss 8(%r13), %xmm4

        # add to position
        addss %xmm1, %xmm3
        addss %xmm0, %xmm4

        # update position
        movss %xmm3, (%r13)
        movss %xmm4, 8(%r13)

    3: # d
    cmpb $1, 0x44(%r12)      
    jne 4f

        # get dir and store in xmm0, xmm1
        # dir y
        movss 12(%r13), %xmm0
        call sinf
        movss %xmm0, %xmm6

        # dir x
        movss 12(%r13), %xmm0
        call cosf

        movss %xmm6, %xmm1                  # mov dir y to final location

        # calculate movement
        movss walk_speed(%rip), %xmm2       # get movement speed
        mulss %xmm2, %xmm0
        mulss %xmm2, %xmm1

        # get position
        movss (%r13), %xmm3
        movss 8(%r13), %xmm4

        # add to position
        addss %xmm0, %xmm3
        addss %xmm1, %xmm4

        # update position
        movss %xmm3, (%r13)
        movss %xmm4, 8(%r13)

    4: # end
    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    movups -32(%rbp), %xmm6
    EPILOGUE

# handles rotating the camera using the mouse
DoMouseControls:
    PROLOGUE

    push %r12
    push %r13
    subq $16, %rsp                      # allocate space for floats
    movups %xmm6, (%rsp)
    subq $16, %rsp                      # allocate space for floats
    movups %xmm7, (%rsp)
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
    movss 12(%r12), %xmm6
    movss 16(%r12), %xmm7

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
    movss %xmm0, 12(%r12)

    # clamp angle y in range -half pi - half pi
    
    movss f_half_pi(%rip), %xmm0
    minps %xmm0, %xmm7

    movss f_min_half_pi(%rip), %xmm0
    maxps %xmm0, %xmm7

    movss %xmm7, 16(%r12)

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
    movups -32(%rbp), %xmm6
    movups -48(%rbp), %xmm7
    EPILOGUE
