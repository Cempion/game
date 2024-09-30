
# get collapse queue info pointer
.macro GP_COLL_QUEUE_INF dest, wfcPointer
    movq 64(\wfcPointer), \dest    # pointer to datastructure
.endm

# calls cmp for $-1 ,"value in collapse queue info". if equal tile is not in collapse queue
.macro IS_NOT_IN_COLL_QUEUE tileIndex, dataPointer
    cmpb $-1, 4(\dataPointer, \tileIndex)                   # check if not in queue
.endm

# get the side to skip when collapse checking, if this is -1 then tile is not in the queue.
.macro G_SIDE_TO_SKIP dest, tileIndex, dataPointer
    movb 4(\dataPointer, \tileIndex), \dest                 # get side to skip
.endm

# set the side to skip when collapse checking.
.macro S_SIDE_TO_SKIP sideToSkip, tileIndex, dataPointer
    movb \sideToSkip, 4(\dataPointer, \tileIndex)           # set side to skip for the given tile
.endm

# regen collapse queue info | should all be -1 (not in queue)
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# void
RegenCollQueueInf:
    PROLOGUE

    GP_COLL_QUEUE_INF %rdi, %rcx                            # pointer to datastructure
    G_DATA_SIZE %ecx, %rdi                                  # size of data structure in bytes
    add $4, %rdi                                            # move pointer to after size value
    movq $-1, %rax                                          # value to set
    rep stosb                                               # fill data structure with 0

    EPILOGUE
