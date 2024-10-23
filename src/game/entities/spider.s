
.data

spider_size: .float 0.5
spider_height: .float 1
# half width, half height (in pixels), texture index
spider_texture: .byte 0x11, 2

spider_acceleration: .float 0.01

.text

#----------------------------------------------------------------------------------------------------------
# Make spider
#----------------------------------------------------------------------------------------------------------

# makes a new spider entity with the given parameters
# PARAMS:
# %xmm0 =   x, z position as 2 floats
# RETURNS:
# %rax =    the index of the created entity
MakeSpider:
    PROLOGUE

    # make entity

    movss spider_height(%rip), %xmm1    # height
    movss spider_size(%rip), %xmm2      # size
    shufps $0, %xmm1, %xmm1             # fill entire register with second float
    movss %xmm2, %xmm1                  # size height, 2 floats
    movw spider_texture(%rip), %r8w     # texture
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
    