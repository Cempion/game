
# get uncollapse queue info pointer
.macro GP_UNCOLL_QUEUE_INF dest, wfcPointer
    movq 88(\wfcPointer), \dest                             # pointer to datastructure
.endm

# calls cmp for $0 ,"value in uncollapse queue info". if equal tile is not in uncollapse queue
.macro IS_NOT_IN_UNCOLL_QUEUE tileIndex, dataPointer
    cmpb $0, 4(\dataPointer, \tileIndex)                    # check if not in queue
.endm

# set if in uncollapse queue or not.
.macro S_IN_UNCOLL_QUEUE inUncollapseQueue, tileIndex, dataPointer
    movb \inUncollapseQueue, 4(\dataPointer, \tileIndex, 1) # set side to skip for the given tile
.endm

# regen uncollapse queue info | should all be 0 (false)
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# void
RegenUncollQueueInf:
    PROLOGUE

    GP_UNCOLL_QUEUE_INF %rdi, %rcx                          # pointer to datastructure
    G_DATA_SIZE %ecx, %rdi                                  # size of data structure in bytes
    movq $0, %rax                                           # value to set
    add $4, %rdi                                            # move pointer to after size value
    rep stosb                                               # fill data structure with 0

    EPILOGUE
