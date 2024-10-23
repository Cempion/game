
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
    leaq DefaultAi(%rip), %r9           # ai subroutine
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
    