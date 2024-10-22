
.data

monster_size: .float 1
monster_height: .float 3
# half width, half height (in pixels), texture index
monster_texture: .byte 0x53, 1

monster_acceleration: .float 0.0125

.text

#----------------------------------------------------------------------------------------------------------
# Make monster
#----------------------------------------------------------------------------------------------------------

# makes a new monster entity with the given parameters
# PARAMS:
# %xmm0 =   x, z position as 2 floats
# RETURNS:
# %rax =    the index of the created entity
MakeMonster:
    PROLOGUE

    # make entity

    movss monster_height(%rip), %xmm1   # height
    movss monster_size(%rip), %xmm2     # size
    shufps $0, %xmm1, %xmm1             # fill entire register with second float
    movss %xmm2, %xmm1                  # size height, 2 floats
    movw monster_texture(%rip), %r8w    # texture
    leaq MonsterAi(%rip), %r9           # ai subroutine
    call MakeEntity

    # make path list

    sub $8, %rsp
    push %rax                           # save entity index

    PARAMS1 $100
    call MakeList                       # make list for path

    leaq entity_ai_paths(%rip), %rcx
    movq (%rsp), %rdx                   # get entity index
    movq %rax, (%rcx, %rdx, 8)          # put in created list

    pop %rax                            # return entity index
    EPILOGUE

#----------------------------------------------------------------------------------------------------------
# Ai
#----------------------------------------------------------------------------------------------------------

# handles the monster ai
# PARAMS:
# %rcx =    index of the entity to run this for
# RETURNS:
# void
MonsterAi:
    PROLOGUE
    push %r12
    push %r13 
    push %r14
    push %r15
    movq %rcx, %r12                     # save entity index to callee saved register

    leaq entity_positions(%rip), %r10
    movups (%r10, %r12, 8), %xmm0       # start pos
    movd %xmm0, %r13                    # save start postion for after the call
    movups (%r10), %xmm1                # destination
    movd %xmm1, %r14                    # save destination postion for after the call

    leaq entity_sizes(%rip), %r10
    movups (%r10, %r12, 4), %xmm2       # radius
    movss f_2(%rip), %xmm3     
    mulss %xmm3, %xmm2                  # multiply radius by 2 for diameter

    leaq entity_ai_paths(%rip), %r15
    movq (%r15, %r12, 8), %r9           # pointer to the list to use for the path
    call CalculatePath
    movq %rax, (%r15, %r12, 8)          # update path list in case it grew

    # move on the path

    # get last node in path

    GET_SIZE_LIST %rax, %ecx
    cmpl $0, %ecx                       # if path is empty
    je 1f

        decq %rcx                           # get last index
        GET_LIST %rax, %rcx, %rcx

        # get distance to position

        movd %r13, %xmm0                    # current position
        movd %rcx, %xmm1                    # target position

        subps %xmm0, %xmm1                  # vector to target
        LENGTH_VEC2 %xmm2, %xmm1            # get distance to target

        movss f_1(%rip), %xmm3
        comiss %xmm3, %xmm2                 # if distance is less than 0.5
        jl 3f

        jmp 4f

        3: # remove last node from path

        REMOVE_LAST_LIST %rax

        4: # dont remove last node
        jmp 2f

    1: # path failed so default to just running towards the destination
        movq %r14, %rcx

        # get distance to position

        movd %r13, %xmm0                    # current position
        movd %rcx, %xmm1                    # target position

        subps %xmm0, %xmm1                  # vector to target
        LENGTH_VEC2 %xmm2, %xmm1            # get distance to target

    2: # calculate acceleration

    movss f_0(%rip), %xmm3
    comiss %xmm3, %xmm2                 # if length is 0
    je 3f                               # target already reached so dont do anything

    # normalize vector to target
    shufps $0, %xmm2, %xmm2             # fill entire register with same value
    divps %xmm2, %xmm1                  # vec / -length = vec from position to target

    # get acceleration
    movss monster_acceleration(%rip), %xmm2
    shufps $0, %xmm2, %xmm2
    mulps %xmm2, %xmm1                  # multiply direction by acceleration

    # apply acceleration
    movd %xmm1, %rcx
    leaq entity_accelerations(%rip), %r10
    movq %rcx, (%r10, %r12, 8)

    3: # return
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    EPILOGUE
    