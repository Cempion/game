
.data

player_size: .float 0.75
player_height: .float 2
# half width, half height (in pixels), texture index
player_texture: .byte 0x43, 0

player_walk_acceleration: .float 0.01
player_run_multiplier: .float 3

.text

#----------------------------------------------------------------------------------------------------------
# Make player
#----------------------------------------------------------------------------------------------------------

# makes a new player entity with the given parameters
# PARAMS:
# %xmm0 =   x, z position as 2 floats
# RETURNS:
# %rax =    the index of the created entity
MakePlayer:
    PROLOGUE

    movss player_height(%rip), %xmm1    # height
    movss player_size(%rip), %xmm2      # size
    shufps $0, %xmm1, %xmm1             # fill entire register with second float
    movss %xmm2, %xmm1                  # size height, 2 floats
    movw player_texture(%rip), %r8w     # texture
    leaq DoKeyControls(%rip), %r9       # ai subroutine
    call MakeEntity

    EPILOGUE

#----------------------------------------------------------------------------------------------------------
# Controls
#----------------------------------------------------------------------------------------------------------

# handles moving the camera using the keyboard
# PARAMS:
# %rcx =    index of the entity to run this for
# RETURNS:
# void
DoKeyControls:
    PROLOGUE
    push %r12
    push %r13 
    push %r14
    push %r15
    SHADOW_SPACE

    leaq pressed_keys(%rip), %r12                   # get pointer to pressed keys
    movq %rcx, %r13                                 # save entity index to callee saved register

    # get direction vector of the camera

    # get angle
    leaq camera(%rip), %rcx                         # get pointer to camera data
    movl 12(%rcx), %r14d                            # get x angle and store in callee saved register

    # dir z
    movd %r14, %xmm0
    call sinf
    movd %xmm0, %r15                                # save result

    # dir x
    movd %r14, %xmm0
    call cosf

    # combine for final direction vector
    movd %r15, %xmm1
    unpcklps %xmm1, %xmm0                           # combine to (x, z)

    # decide on movement direction and put result in xmm1
    xorps %xmm1, %xmm1

       # w
    cmpb $1, 0x57(%r12)      
    jne 1f           

        # rotate direction vector 90 degrees
        movsd %xmm0, %xmm2
        shufps $1, %xmm2, %xmm2
        movss f_min_1(%rip), %xmm3      # get -1
        mulss %xmm3, %xmm2              # invert x axis

        # add direction to resuting movement
        addps %xmm2, %xmm1

    1: # a
    cmpb $1, 0x41(%r12)       
    jne 2f    

        # add direction to resuting movement
        subps %xmm0, %xmm1
            
    2: # s
    cmpb $1, 0x53(%r12)      
    jne 3f

        # rotate direction vector 90 degrees
        movsd %xmm0, %xmm2
        shufps $1, %xmm2, %xmm2
        movss f_min_1(%rip), %xmm3      # get -1
        mulss %xmm3, %xmm2              # invert x axis

        # sub direction from resuting movement
        subps %xmm2, %xmm1

    3: # d
    cmpb $1, 0x44(%r12)      
    jne 4f

        # sub direction from resuting movement
        addps %xmm0, %xmm1

    4: # end

    # calculate acceleration
    movss player_walk_acceleration(%rip), %xmm2     # get movement acceleration
    cmpb $1, 0x10(%r12)                             # check if shift is pressed
    jne 5f

    movss player_run_multiplier(%rip), %xmm3
    mulss %xmm3, %xmm2                              # multiply by run multiplier

    5: # shift is not pressed
    shufps $0, %xmm2, %xmm2                         # make all floats the same
    mulps %xmm2, %xmm1

    # update acceleration
    leaq entity_accelerations(%rip), %rcx
    movsd %xmm1, (%rcx, %r13, 8)

    CLEAN_SHADOW
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    EPILOGUE
    