
.data

player_size: .float 1.5
player_walk_acceleration: .float 0.01666666666666666666666666 # 1 per second

# used to store intermediate results
temp: .float 0

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

    movss player_size(%rip), %xmm1
    leaq DoKeyControls(%rip), %r8
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
    leaq entity_accelerations(%rip), %r13           # get pointer to entity accelerations
    movq %rcx, %r14                                 # save entity index to callee saved register
    leaq camera(%rip), %rcx
    movl 12(%rcx), %r15d                            # get x angle and store in callee saved register

    # set to 0 and use as resulting acceleration
    xorps %xmm3, %xmm3
    xorps %xmm4, %xmm4

       # w
    cmpb $1, 0x57(%r12)      
    jne 1f           

        # get dir and store in xmm0, xmm1
        # dir y
        movd %r15, %xmm0
        call sinf
        movss %xmm0, temp(%rip)

        # dir x
        movd %r15, %xmm0
        call cosf

        movss temp(%rip), %xmm1                         # mov dir y to final location

        # invert z axis
        movss f_min_1(%rip), %xmm5
        mulss %xmm5, %xmm1 

        # calculate acceleration
        movss player_walk_acceleration(%rip), %xmm2     # get movement acceleration
        mulss %xmm2, %xmm0
        mulss %xmm2, %xmm1

        # add to resulting acceleration
        addss %xmm1, %xmm3
        addss %xmm0, %xmm4
    1: # a
    cmpb $1, 0x41(%r12)       
    jne 2f    

        # get dir and store in xmm0, xmm1
        # dir y
        movd %r15, %xmm0
        call sinf
        movss %xmm0, temp(%rip)

        # dir x
        movd %r15, %xmm0
        call cosf

        movss temp(%rip), %xmm1                         # mov dir y to final location

        # invert x and z axis
        movss f_min_1(%rip), %xmm5
        mulss %xmm5, %xmm0
        mulss %xmm5, %xmm1 

        # calculate acceleration
        movss player_walk_acceleration(%rip), %xmm2     # get movement acceleration
        mulss %xmm2, %xmm0
        mulss %xmm2, %xmm1

        # add to acceleration
        addss %xmm0, %xmm3
        addss %xmm1, %xmm4
            
    2: # s
    cmpb $1, 0x53(%r12)      
    jne 3f

        # get dir and store in xmm0, xmm1
        # dir y
        movd %r15, %xmm0
        call sinf
        movss %xmm0, temp(%rip)

        # dir x
        movd %r15, %xmm0
        call cosf

        movss temp(%rip), %xmm1                         # mov dir y to final location

        # invert x axis
        movss f_min_1(%rip), %xmm5
        mulss %xmm5, %xmm0

        # calculate acceleration
        movss player_walk_acceleration(%rip), %xmm2     # get movement acceleration
        mulss %xmm2, %xmm0
        mulss %xmm2, %xmm1

        # add to acceleration
        addss %xmm1, %xmm3
        addss %xmm0, %xmm4

    3: # d
    cmpb $1, 0x44(%r12)      
    jne 4f

        # get dir and store in xmm0, xmm1
        # dir y
        movd %r15, %xmm0
        call sinf
        movss %xmm0, temp(%rip)

        # dir x
        movd %r15, %xmm0
        call cosf

        movss temp(%rip), %xmm1                         # mov dir y to final location

        # calculate acceleration
        movss player_walk_acceleration(%rip), %xmm2     # get movement acceleration
        mulss %xmm2, %xmm0
        mulss %xmm2, %xmm1

        # add to acceleration
        addss %xmm0, %xmm3
        addss %xmm1, %xmm4

    4: # end

    # update acceleration
    movss %xmm3, (%r13, %r14, 8)
    movss %xmm4, 4(%r13, %r14, 8)

    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    movups -32(%rbp), %xmm6
    EPILOGUE
    