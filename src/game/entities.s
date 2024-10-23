
.include "game/pathfinding.s"
.include "game/entities/player.s"
.include "game/entities/monster.s"
.include "game/entities/spider.s"
.include "game/entities/ravager.s"

.equ MAX_ENTITIES, 5

.data

# keeps track of the ammount of entities
entity_count: .quad 0

# float float (x, z)
entity_positions: .skip MAX_ENTITIES * 8
# float float (x, z)
entity_velocities: .skip MAX_ENTITIES * 8
# float float (x, z)
entity_accelerations: .skip MAX_ENTITIES * 8

# float
entity_sizes: .skip MAX_ENTITIES * 4

# float
entity_heights: .skip MAX_ENTITIES * 4

# short (first 4 bits = half width in pixels, second 4 bits = half height in pixels, rest 8 bits = texture index)
# it is nessecary to specify the half size in pixels since all entity textures are stored as 32*32 pixel textures, 
# the half size tells the renderer where the actual entity texture is and render it correctly.
entity_textures: .skip MAX_ENTITIES * 2

# quad
entity_ai_pointers: .skip MAX_ENTITIES * 8
# ai subroutine is defined as this:
# PARAMS:
# %rcx =    index of the entity this is run for
# RETURNS:
# void

# quad, list of pointers to lists that contain a path the ai may use.
entity_ai_paths: .skip MAX_ENTITIES * 8

.text

#----------------------------------------------------------------------------------------------------------
# Make entity
#----------------------------------------------------------------------------------------------------------

# makes a new entity with the given parameters
# PARAMS:
# %xmm0 =   x, z position as 2 floats
# %xmm1 =   s, h size of the entity (radius of its collision circle), height of the entity. packed as 2 floats
# %r8   =   entity texture information as a short (first 4 bits = half width in pixels, second 4 bits = half height in pixels, rest 8 bits = texture index)
# %r9   =   pointer to the subroutine handling the entities movement (ai)
# RETURNS:
# %rax =    the index of the created entity
MakeEntity:
    PROLOGUE

    movq entity_count(%rip), %rsi           # get the index where this entity should be added

    # set position
    leaq entity_positions(%rip), %rdi       # get pointer to entity positions
    movsd %xmm0, (%rdi, %rsi, 8)            # x, z

    # set size
    leaq entity_sizes(%rip), %rdi           # get pointer to entity sizes
    movss %xmm1, (%rdi, %rsi, 4)            # diameter

    # set height
    leaq entity_heights(%rip), %rdi         # get pointer to entity heights
    shufps $1, %xmm1, %xmm1                 # fill with second float
    movss %xmm1, (%rdi, %rsi, 4)            # height

    # set texture data
    leaq entity_textures(%rip), %rdi        # get pointer to entity ai subroutine pointers
    movw %r8w, (%rdi, %rsi, 2)              # texture information as a short

    # set pointer to ai subroutine
    leaq entity_ai_pointers(%rip), %rdi     # get pointer to entity ai subroutine pointers
    movq %r9, (%rdi, %rsi, 8)               # pointer to subroutine to call for ai

    incq entity_count(%rip)                 # increment entity count
    movq %rsi, %rax                         # return index of entity
    EPILOGUE

#----------------------------------------------------------------------------------------------------------
# do Entity ai
#----------------------------------------------------------------------------------------------------------

# loops over all existing entities and calls their ai subroutine
DoEntityAi:
    PROLOGUE
    push %r12
    push %r13

    leaq entity_ai_pointers(%rip), %r12         # get pointer to ai subroutines
    movq entity_count(%rip), %r13               # get entity count and use as counter
    1: # entity loop
        cmp $0, %r13                                # if counter is 0
        je 2f                                       # exit loop
        decq %r13                                   # decrement counter

        PARAMS1 %r13
        call *(%r12, %r13, 8)                       # call ai subroutine of the entity

        jmp 1b
    2: # exit loop

    pop %r13
    pop %r12
    EPILOGUE

# handles the monster ai
# PARAMS:
# %rcx =    index of the entity to run this for
# RETURNS:
# void
DefaultAi:
    PROLOGUE
    push %r12
    push %r13 
    push %r14
    push %r15
    movq %rcx, %r12                     # save entity index to callee saved register

    call AttackPlayer

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

# the given entity attempts to attack the player, if collision boxes overlap the player is attacked and dies.
# PARAMS:
# %rcx =    index of the entity to run this for
# RETURNS:
# void
AttackPlayer:
    PROLOGUE

    cmpb $0, is_player_alive(%rip)      # if player is dead            
    je 1f                               # it cannot be attacked

    # check if entity is close enough to attack

    # get positions
    leaq entity_positions(%rip), %rsi
    movups (%rsi), %xmm0                # player position
    movups (%rsi, %rcx, 8), %xmm1       # this entity position

    # get distance between this entity and the player (entity 0)
    subps %xmm1, %xmm0                  # get vector from other entity to this entity
    LENGTH_VEC2 %xmm1, %xmm0            # get distance

    # get collision distance
    leaq entity_sizes(%rip), %rsi
    movss (%rsi), %xmm2                 # get player size
    movss (%rsi, %rcx, 4), %xmm3        # get this entity size

    subss %xmm2, %xmm1                  # subtract this entity size
    subss %xmm3, %xmm1                  # subtract other entity size

    xorps %xmm2, %xmm2                  # make 0
    minss %xmm2, %xmm1                  # min distance with 0

    ucomiss %xmm2, %xmm1                # if distance is 0
    je 1f                               # cant attack and is out of range

    # attack player

    # half player height
    leaq entity_heights(%rip), %rsi
    movss (%rsi), %xmm0
    movss f_0.5(%rip), %xmm1
    mulss %xmm1, %xmm0
    movss %xmm0, (%rsi)

    # kill player
    movb $0, is_player_alive(%rip)

    1: # return, cannot attack player
    EPILOGUE
