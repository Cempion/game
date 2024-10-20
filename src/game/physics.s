
.data

drag: .float 0.1

.text

# updates positions and velocities of all entities based on a fixed delta time of 1
SimulateFrame:
    PROLOGUE
    push %r12
    push %r13

    movq entity_count(%rip), %r13       # get entity count and use as counter
    1: # entity loop
        cmpq $0, %r13                       # if counter is 0
        je 2f                               # exit loop
        decq %r13                           # decrement counter

        PARAMS1 %r13
        call SimulateEntity

        jmp 1b
    2: # exit loop

    pop %r13
    pop %r12
    EPILOGUE

# updates position and velocity of the given entity based on a fixed delta time of 1
# PARAMS:
# %rcx  =   entity index of the entity to simulate
# RETURNS:
# void
SimulateEntity:
    PROLOGUE

    # get pointers
    leaq entity_positions(%rip), %r9
    leaq entity_velocities(%rip), %r10
    leaq entity_accelerations(%rip), %r11

    # get position
    movsd (%r9, %rcx, 8), %xmm0
    # get velocity
    movsd (%r10, %rcx, 8), %xmm1
    # get acceleration
    movsd (%r11, %rcx, 8), %xmm2

    # formula to calculate acceleration 
    # a - c * v, c, 0

    # c * v
    movss drag(%rip), %xmm3
    shufps $0, %xmm3, %xmm3
    mulps %xmm1, %xmm3

    # max(c * v, c)
    movss drag(%rip), %xmm4

    # a - (c * v)
    subps %xmm3, %xmm2

    # max(a - max(c * v, c), 0)
    movss f_0(%rip), %xmm3

    # formula to calculate new position
    # 0.5 * a + v + p

    # a / 2
    movsd %xmm2, %xmm3
    movss f_2(%rip), %xmm4
    shufps $0, %xmm4, %xmm4
    divps %xmm4, %xmm3

    # (a / 2) + v
    addps %xmm1, %xmm3

    # (a / 2 + v) + p
    addps %xmm3, %xmm0

    # set new position
    movsd %xmm0, (%r9, %rcx, 8)

    # formula to calculate new velocity
    # a + v

    # a + v
    addps %xmm2, %xmm1

    # set new velocity
    movsd %xmm1, (%r10, %rcx, 8)

    # make acceleration 0
    xorps %xmm2, %xmm2
    movsd %xmm2, (%r11, %rcx, 8)

    call DoWallCollision

    EPILOGUE

# do wall collision and update position and velocity
# PARAMS:
# %rcx  =   entity index of the entity to do wall collisions for
# RETURNS:
# void
DoWallCollision:
    PROLOGUE
    sub $56, %rsp
    movaps %xmm6, -16(%rbp)
    movaps %xmm7, -32(%rbp)
    movaps %xmm8, -48(%rbp)
    movq %rcx, -56(%rbp)
    push %r12
    push %r13
    push %r14
    push %r15
    push %rbx

    # get pointers
    leaq entity_positions(%rip), %r9
    leaq entity_velocities(%rip), %r10
    leaq entity_sizes(%rip), %r11

    # get position
    movsd (%r9, %rcx, 8), %xmm6

    # get size
    movss (%r11, %rcx, 4), %xmm7
    shufps $0, %xmm7, %xmm7

    movsd %xmm6, %xmm0
    movsd %xmm7, %xmm1
    call DoEdgeCollision
    movsd %xmm0, %xmm6

    # do corner detection

    # calculate bounding box

    # lower corner
    movsd %xmm6, %xmm0
    subps %xmm7, %xmm0
    # upper corner
    movsd %xmm6, %xmm1
    addps %xmm7, %xmm1

    # convert bounding box to integers

    # floor the floats for correct tile position
    roundps $1, %xmm0, %xmm0
    roundps $1, %xmm1, %xmm1

    # convert to int
    cvttps2dq %xmm0, %xmm0
    cvttps2dq %xmm1, %xmm1

    # move bounding box to int registers
    movd %xmm0, %r13
    movd %xmm1, %r15

    movq $0, %r12
    movl %r13d, %r12d
    shr $32, %r13

    movq $0, %r14
    movl %r15d, %r14d
    shr $32, %r15

    # loop over all blocks in the bounding box

    xorps %xmm8, %xmm8          # zero out the register

    1: # x loop
        cmpl %r14d, %r12d           # if x pos used as counter is greater than upper bounding x
        jg 2f                       # end loop

        movl %r13d, %ebx            # reset counter for y loop
        3: # z loop
            cmpl %r15d, %ebx            # if y pos used as counter is greater than upper bounding y
            jg 4f                       # end loop

            # detect collision

            PARAMS2 %r12, %rbx
            call GetBlockData
            andq $1, %rax               # zero out all exept first bit
            cmp $0, %rax                # if first bit is 0
            je 5f                       # skip collision since block is open

            # clamp entity position in block to get closest point in block to entity

            # get min pos
            movl %ebx, %ecx             # put in y pos
            shl $32, %rcx               # make space for x pos
            orq %r12, %rcx              # put in x pos
            movd %rcx, %xmm1            # convert to packed ints
            cvtdq2ps %xmm1, %xmm1       # convert to packed floats

            # get max pos
            movss f_1(%rip), %xmm2      # load 1 into register
            shufps $0, %xmm2, %xmm2     # put 1 in all 4 floats
            addps %xmm1, %xmm2          # add 1 to min pos for max pos

            # clamp position
            movsd %xmm6, %xmm0          # entity position
            minps %xmm2, %xmm0          # min
            maxps %xmm1, %xmm0          # max

            # get distance to position

            subps %xmm6, %xmm0          # get vector from position to block    

            # calculate the distance (length of the vector) of position to the block
            LENGTH_VEC2 %xmm3, %xmm0

            # no collision if length is 0

            xorps %xmm4, %xmm4          # make 0
            comiss %xmm4, %xmm3         # if length is 0
            je 5f                       # there is no collision

            # normalize vector to block
            shufps $0, %xmm3, %xmm3
            divps %xmm3, %xmm0

            # subtract size from distance
            subps %xmm7, %xmm3

            # check if there is a collision

            xorps %xmm4, %xmm4          # make 0
            comiss %xmm4, %xmm3         # if distance to wall is greater than 0
            jae 5f                      # there is no collision

            # calculate displacement

            mulps %xmm3, %xmm0          # results in displacement vector
            addps %xmm0, %xmm8          # add to total displacement

            5: # not a collision (block is open)

            incl %ebx                   # increment y pos used as counter
            jmp 3b
        4: # end y loop

        incl %r12d                      # increment x pos used as counter
        jmp 1b
    2: # end x loop

    # update position based on displacement
    addps %xmm8, %xmm6                  # apply displacement to position

    leaq entity_positions(%rip), %r9    # get pointer to entity positions
    movq -56(%rbp), %rcx                # get entity index
    movsd %xmm6, (%r9, %rcx, 8)         # update position

    pop %rbx
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    movaps -16(%rbp), %xmm6
    movaps -32(%rbp), %xmm7
    movaps -48(%rbp), %xmm8
    EPILOGUE

# do wall collision and update position and velocity
# PARAMS:
# %xmm0 =   entity position
# %xmm1 =   entity size
# RETURNS:
# %xmm0 =   new position
DoEdgeCollision:
    PROLOGUE
    sub $48, %rsp
    movaps %xmm6, -16(%rbp)
    movaps %xmm7, -32(%rbp)
    movaps %xmm8, -48(%rbp)
    push %r12
    push %r13
    push %r14
    push %r15

    shufps $0, %xmm1, %xmm1             # make all 4 floats the same value

    movsd %xmm0, %xmm6                  # save position
    movsd %xmm1, %xmm7                  # save size
    xorps %xmm8, %xmm8                  # make 0 so it can be used for resulting displacement

    # calculate block position of entity
    movsd %xmm0, %xmm2
    roundps $1, %xmm2, %xmm2            # floor
    cvttps2dq %xmm2, %xmm2              # convert to packed ints
    movd %xmm2, %r12                    # move to normal register

    # calculate bounding box

    # lower corner
    movsd %xmm0, %xmm3
    subps %xmm1, %xmm3
    # upper corner
    movsd %xmm0, %xmm4
    addps %xmm1, %xmm4

    # convert bounding box to integers

    # floor the floats for correct tile position
    roundps $1, %xmm3, %xmm3
    roundps $1, %xmm4, %xmm4

    # convert to int
    cvttps2dq %xmm3, %xmm3
    cvttps2dq %xmm4, %xmm4

    # move bounding box to int registers
    movd %xmm3, %r13
    movd %xmm4, %r14

    # find edges

    # -x
    movq $0, %r15
    movl %r12d, %r15d                   # set current pos to entity pos
    1: # loop negative x
        cmpl %r13d, %r15d                   # if current x is the same as the minimum x
        je 2f                               # exit loop
        decl %r15d                          # decrement current x

        # detect collision

        movl %r15d, %ecx                    # x
        mov %r12, %rdx
        shr $32, %rdx                       # z
        call GetBlockData
        andq $1, %rax                       # zero out all exept first bit
        cmp $0, %rax                        # if first bit is 0 (not a wall)
        je 1b                               # continue loop

        # handle edge collision

        # get point closest to entity in block

        # x position is block x + 1
        movl %r15d, %eax
        incl %eax
        cltq                                # sign extend rax
        cvtsi2ss %rax, %xmm0                # convert to float

        # use the same z from the entity position
        movd %xmm6, %rcx

        # put in the new x
        movd %xmm0, %rdx
        movq $0xFFFFFFFF, %r8
        andq %r8, %rdx                      # make last 4 bytes 0
        movq $0xFFFFFFFF00000000, %r8
        andq %r8, %rcx                      # make old x zero
        orq %rdx, %rcx                      # combine x and z
        movd %rcx, %xmm0                    # move closest position into vector register

        # get distance to position

        subps %xmm6, %xmm0          # get vector from position to block    

        # calculate the distance (length of the vector) of position to the block
        LENGTH_VEC2 %xmm1, %xmm0

        # no collision if distance is 0

        xorps %xmm2, %xmm2          # make 0
        comiss %xmm2, %xmm1         # if length is 0
        je 1b                       # continue loop

        # normalize vector to block
        shufps $0, %xmm1, %xmm1
        divps %xmm1, %xmm0

        # subtract size from distance
        subps %xmm7, %xmm1
        
        # calculate displacement

        mulps %xmm1, %xmm0          # results in displacement vector
        addps %xmm0, %xmm8          # add to total displacement


    2: # end negative x loop

    # x
    movq $0, %r15
    movl %r12d, %r15d                   # set current pos to entity pos
    1: # loop x
        cmpl %r14d, %r15d                   # if current x is the same as the maximum x
        je 2f                               # exit loop
        incl %r15d                          # increment current x

        # detect collision

        movl %r15d, %ecx                    # x
        mov %r12, %rdx
        shr $32, %rdx                       # z
        call GetBlockData
        andq $1, %rax                       # zero out all exept first bit
        cmp $0, %rax                        # if first bit is 0 (not a wall)
        je 1b                               # continue loop

        # handle edge collision

        # get point closest to entity in block

        # x position is block x
        movl %r15d, %eax
        cltq                                # sign extend rax
        cvtsi2ss %rax, %xmm0                # convert to float

        # use the same z from the entity position
        movd %xmm6, %rcx

        # put in the new x
        movd %xmm0, %rdx
        movq $0xFFFFFFFF, %r8
        andq %r8, %rdx                      # make last 4 bytes 0
        movq $0xFFFFFFFF00000000, %r8
        andq %r8, %rcx                      # make old x zero
        orq %rdx, %rcx                      # combine x and z
        movd %rcx, %xmm0                    # move closest position into vector register

        # get distance to position

        subps %xmm6, %xmm0          # get vector from position to block    

        # calculate the distance (length of the vector) of position to the block
        LENGTH_VEC2 %xmm1, %xmm0

        # no collision if distance is 0

        xorps %xmm2, %xmm2          # make 0
        comiss %xmm2, %xmm1         # if length is 0
        je 1b                       # continue loop

        # normalize vector to block
        shufps $0, %xmm1, %xmm1
        divps %xmm1, %xmm0

        # subtract size from distance
        subps %xmm7, %xmm1
        
        # calculate displacement

        mulps %xmm1, %xmm0          # results in displacement vector
        addps %xmm0, %xmm8          # add to total displacement


    2: # end x loop

    # shift max and min
    shr $32, %r13
    shr $32, %r14

    # -z
    movq %r12, %r15                     # set current pos to entity pos
    shr $32, %r15
    1: # loop negative z
        cmpl %r13d, %r15d                   # if current x is the same as the minimum z
        je 2f                               # exit loop
        decl %r15d                          # decrement current z

        # detect collision

        movl %r12d, %ecx                    # x
        movl %r15d, %edx                    # z
        call GetBlockData
        andq $1, %rax                       # zero out all exept first bit
        cmp $0, %rax                        # if first bit is 0 (not a wall)
        je 1b                               # continue loop

        # handle edge collision

        # get point closest to entity in block

        # z position is block z + 1
        movl %r15d, %eax
        incl %eax
        cltq                                # sign extend rax
        cvtsi2ss %rax, %xmm0                # convert to float
        movd %xmm0, %rdx

        # use the same x from the entity position
        movd %xmm6, %rcx

        # put in the new z
        shl $32, %rdx                       # make space for x
        movq $0xFFFFFFFF, %r8
        andq %r8, %rcx                      # make old z zero
        orq %rdx, %rcx                      # combine x and z
        movd %rcx, %xmm0                    # move closest position into vector register

        # get distance to position

        subps %xmm6, %xmm0          # get vector from position to block    

        # calculate the distance (length of the vector) of position to the block
        LENGTH_VEC2 %xmm1, %xmm0

        # no collision if distance is 0

        xorps %xmm2, %xmm2          # make 0
        comiss %xmm2, %xmm1         # if length is 0
        je 1b                       # continue loop

        # normalize vector to block
        shufps $0, %xmm1, %xmm1
        divps %xmm1, %xmm0

        # subtract size from distance
        subps %xmm7, %xmm1
        
        # calculate displacement

        mulps %xmm1, %xmm0          # results in displacement vector
        addps %xmm0, %xmm8          # add to total displacement


    2: # end negative z loop

    # z
    movq %r12, %r15                     # set current pos to entity pos
    shr $32, %r15
    1: # loop z
        cmpl %r14d, %r15d                   # if current x is the same as the minimum z
        je 2f                               # exit loop
        incl %r15d                          # increment current z

        # detect collision

        movl %r12d, %ecx                    # x
        movl %r15d, %edx                    # z
        call GetBlockData
        andq $1, %rax                       # zero out all exept first bit
        cmp $0, %rax                        # if first bit is 0 (not a wall)
        je 1b                               # continue loop

        # handle edge collision

        # get point closest to entity in block

        # z position is block z + 1
        movl %r15d, %eax
        cltq                                # sign extend rax
        cvtsi2ss %rax, %xmm0                # convert to float
        movd %xmm0, %rdx

        # use the same x from the entity position
        movd %xmm6, %rcx

        # put in the new z
        shl $32, %rdx                       # make space for x
        movq $0xFFFFFFFF, %r8
        andq %r8, %rcx                      # make old z zero
        orq %rdx, %rcx                      # combine x and z
        movd %rcx, %xmm0                    # move closest position into vector register

        # get distance to position

        subps %xmm6, %xmm0          # get vector from position to block    

        # calculate the distance (length of the vector) of position to the block
        LENGTH_VEC2 %xmm1, %xmm0

        # no collision if distance is 0

        xorps %xmm2, %xmm2          # make 0
        comiss %xmm2, %xmm1         # if length is 0
        je 1b                       # continue loop

        # normalize vector to block
        shufps $0, %xmm1, %xmm1
        divps %xmm1, %xmm0

        # subtract size from distance
        subps %xmm7, %xmm1
        
        # calculate displacement

        mulps %xmm1, %xmm0          # results in displacement vector
        addps %xmm0, %xmm8          # add to total displacement


    2: # end z loop


    # output result
    movsd %xmm6, %xmm0
    addps %xmm8, %xmm0

    pop %r15
    pop %r14
    pop %r13
    pop %r12
    movaps -16(%rbp), %xmm6
    movaps -32(%rbp), %xmm7
    movaps -48(%rbp), %xmm8
    EPILOGUE

test: .asciz "Displacement: %d , %d | Count: %ld \n"
