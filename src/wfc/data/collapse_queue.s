
# get collapse queue pointer
.macro GP_COLL_QUEUE dest, wfcPointer
    movq 56(\wfcPointer), \dest                             # pointer to datastructure
.endm

# gets the first tile in the collapse queue, or -1 if empty. caller is responsible for clearing collapse queue info!
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# %rax =    the dequed tile, or -1 if empty
DeqCollQueue:
    PROLOGUE

    GP_COLL_QUEUE %r9, %rcx                                 # get pointer to collapse queue

    movl 4(%r9), %r8d                                       # get read index
    cmpl %r8d, 8(%r9)                                       # if the read and write indexes are the same the queue is empty
    je 2f

    DEQ_QUEUE %ecx , %r9
    movq %rcx, %rax                                         # put result in rax

    jmp 1f
    
    2:  # queue empty
    movq $-1, %rax                                          # return -1 since empty

    1:  # end
    EPILOGUE

# adds a tile to the back of the collapse queue and updates collapse queue info
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    the tileindex to add
# %r8  =    sideToSkip
# RETURNS:
# void
EnqCollQueue:
    PROLOGUE

    movq %rdx, %rsi                                         # move tileIndex to a register that ENQ_QUEUE wont touch

    GP_COLL_QUEUE_INF %rdi, %rcx                            # get pointer to collapse queue info
    IS_NOT_IN_COLL_QUEUE %rsi, %rdi                         # if in collapse queue skip adding it again
    jne 1f

    GP_COLL_QUEUE %r9, %rcx                                 # get pointer to collapse queue info
    ENQ_QUEUE %esi, %r9
    
    1:
    S_SIDE_TO_SKIP %r8b, %rsi, %rdi                         # set sideToSkip (should override when already in queue)
    EPILOGUE

# regen collapse queue | only the first 2 longs should be 0
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# void
RegenCollQueue:
    PROLOGUE

    GP_COLL_QUEUE %rdi, %rcx                                # pointer to datastructure
    movq $0, 4(%rdi)                                        # clear read and write index

    EPILOGUE
