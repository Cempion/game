
.include "game/entities/player.s"

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
