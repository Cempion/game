
# get tile possibilities pointer
.macro GP_TILE_POSS dest, wfcPointer
    movq 40(\wfcPointer), \dest                             # pointer to datastructure
.endm

# get possibilities of the given tile
.macro G_POSS dest, tileIndex, dataPointer
    movq 4(\dataPointer, \tileIndex, 8), \dest              # possibilities of the given tile
.endm

# get the entropy of the given tile (entropy is possibility count)
.macro G_ENT dest, tileIndex, dataPointer
    G_POSS \dest, \tileIndex, \dataPointer                  # get possibilities
    popcnt \dest, \dest                                     # calculate bitcount
.endm

# gets the first possibility of the given tile (index of first 1 bit)
.macro G_FIRST_POSS dest, tileIndex, dataPointer
    G_POSS \dest, \tileIndex, \dataPointer                  # get possibilities
    bsf \dest, \dest                                        # get first possibility
.endm

# union the possibilities of the given tile with the given possibilities (OR)
.macro U_POSS possibilities, tileIndex, dataPointer
    orq \possibilities, 4(\dataPointer, \tileIndex, 8)      # union the 2 possibilities and store it in the data structure
.endm

# intersect the possibilities of the given tile with the given possibilities (AND)
.macro I_POSS possibilities, tileIndex, dataPointer
    andq \possibilities, 4(\dataPointer, \tileIndex, 8)     # intersect the 2 possibilities and store it in the data structure
.endm

# regen tile possibilities | should all be -1 (all bits 1)
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# void
RegenTilePoss:
    PROLOGUE
    movq %rcx, %r8

    GP_RULESET %rax, %r8                                    # get pointer to ruleset
    G_MAX_PIECES %al, %rax                                  # ammount of possibilities to fill in

    movq $64, %rcx                                           
    sub %rax, %rcx                                          # 64 - maxPossibilities = amount of bits to shift

    movq $-1, %rax                                          # all bits 1
    shr %rcx, %rax                                          # make all unused bits 0

    GP_TILE_POSS %rdi, %r8                                  # pointer to datastructure
    G_DATA_SIZE %ecx, %rdi                                  # size of data structure in bytes
    add $4, %rdi                                            # move pointer to after size value

    rep stosq                                               # fill data structure with -1

    EPILOGUE
