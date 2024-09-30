
# get entropy indexes pointer
.macro GP_ENT_INDEXES dest, wfcPointer
    movq 48(\wfcPointer), \dest                             # pointer to datastructure
.endm

# calls cmp for $0 ,"value in entropy list indexes". if equal tile is not in entropy list
.macro IS_NOT_IN_ENT_LIST tileIndex, dataPointer
    cmpl $0, 4(\dataPointer, \tileIndex, 4)                 # check if not in entropy list
.endm

# get entropy index of the given tileIndex (where it is stored in entropyList)
.macro G_ENT_INDEX dest, tileIndex, dataPointer
    movl 4(\dataPointer, \tileIndex, 4), \dest              # get entropy index
.endm

# set entropy index of the given tileIndex (where it is stored in entropyList)
.macro S_ENT_INDEX entropyIndex, tileIndex, dataPointer
    movl \entropyIndex, 4(\dataPointer, \tileIndex, 4)      # set isCollapsed for the given tile
.endm

# regen entropy indexes | should all be 0 (not in entropy list)
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# void
RegenEntIndexes:
    PROLOGUE

    GP_ENT_INDEXES %rdi, %rcx                               # pointer to datastructure
    G_DATA_SIZE %ecx, %rdi                                  # size of data structure in bytes
    add $4, %rdi                                            # move pointer to after size value
    movq $0, %rax                                           # value to set
    rep stosl                                               # fill data structure with -1

    EPILOGUE
