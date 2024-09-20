.include "macro.s"

#----------------------------------------------------------------------------------------------------------
# MEMORY LAYOUT
#----------------------------------------------------------------------------------------------------------

# 4 bytes = width
# 4 bytes = height
#
# 8 bytes = pointer to ruleset
# 8 bytes = pointer to tile possibilities
# 8 bytes = pointer to tile states
# 8 bytes = pointer to entropy list
# 8 bytes = pointer to entropy list indexes
# 8 bytes = pointer to check queue
# 8 bytes = pointer to check info (side to skip and wether tile is in queue)
#
# 8 bytes * width * height = tile possibilities (so a max of 64 possibilities)
#
# 1 byte  * width * height = tile state
#                            0 - 5 bits = collapsed possibility
#                            6     bit  = isContradiction boolean
#                            7     bit  = isCollapsen boolean
#
# 4 bytes * (max entropy - 1) * (1 + width * height) = the entropy list is a 2d array
#                                                      X axis = entropy starting at an entropy of 1, which each store:
#                                                      Y axis = first 4 bytes is the amount of tiles currently stored with the corresponding entropy
#                                                               everything after are the 4 byte sized tile indexes
#
# 4 bytes * width * height = entropy list indexes, stores for each tile where they can be found at the corresponding entropy
#
# 8 bytes + 4 bytes * width * height = check queue (looping queue with a read and write index)
# 4 bits * width * height            = check info

#----------------------------------------------------------------------------------------------------------
# SUBROUTINE
#----------------------------------------------------------------------------------------------------------

# creates a new wfc and returns its pointer.
# PARAMS:
# %rcx =    pointer to ruleset
# %rdx =    width
# %r8  =    height
# RETURNS:
# %rax =    pointer to wfc
CreateWfc:
    PROLOGUE

    # calculate bytes that need to be allocated

    movq %rcx, %r9                  # move ruleset pointer to r9
    movq $64, %rcx                  # memory size, 64 bytes is the static size.

    movq %rdx, %rax                 # width * height
    mul %r8                         # calculate tile count and put it in r10
    movq %rax, %r10

    movq $8, %rax                   # 8 bytes * tilecount
    mul %r10                        # calculate tile possibilities bytes and add to size
    add %rax, %rcx

    movq $1, %rax                   # 1 byte * tilecount
    mul %r10                        # calculate tile states bytes and add to size
    add %rax, %rcx

    movq %r10, %rax                 # tilecount
    add $1, %rax                    # + 1
    mul "max entropy - 1"           # (max entropy - 1) * (1 + tilecount)
    mul $4                          # 8 4 bytes
    add %rax, %rcx                  # calculate tile states bytes and add to size



    call malloc



    EPILOGUE

CollapseTile:
    PROLOGUE

    EPILOGUE

CollapseTiles:
    PROLOGUE

    EPILOGUE

CollapseAllTiles:
    PROLOGUE

    EPILOGUE

UncollapseTile:
    PROLOGUE

    EPILOGUE

UncollapseTiles:
    PROLOGUE

    EPILOGUE

UncollapseAllTiles:
    PROLOGUE

    EPILOGUE