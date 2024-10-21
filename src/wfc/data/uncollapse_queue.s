
# get uncollapse queue pointer
.macro GP_UNCOLL_QUEUE dest, wfcPointer
    movq 80(\wfcPointer), \dest    # pointer to datastructure
.endm

# gets the first tile in the uncollapse queue and updates uncollapse queue info, or -1 if empty
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# %rax =    the dequed tile, or -1 if empty
DeqUncollQueue:
    PROLOGUE

    GP_UNCOLL_QUEUE %r9, %rcx                               # get pointer to uncollapse queue

    movl 4(%r9), %r8d                                       # get read index
    cmpl %r8d, 8(%r9)                                       # if the read and write indexes are the same the queue is empty
    je 2f

    DEQ_QUEUE %ecx, %r9
    movq %rcx, %rax                                         # put result in rax

    jmp 1f
    
    2:  # queue empty
    movq $-1, %rax                                          # return -1 since empty

    1:  # end
    EPILOGUE

# adds a tile to the back of the uncollapse queue and updates uncollapse queue info
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    the tileindex to add
# RETURNS:
# void
EnqUncollQueue:
    PROLOGUE

    movq %rdx, %rsi                                         # move tileIndex to a register that ENQ_QUEUE wont touch

    GP_UNCOLL_QUEUE_INF %rdi, %rcx                          # get pointer to collapse queue info
    IS_NOT_IN_UNCOLL_QUEUE %rsi, %rdi                       # if in uncollapse queue info skip adding it again
    jne 1f

    GP_UNCOLL_QUEUE %r9, %rcx                               # get pointer to uncollapse queue
    ENQ_QUEUE %esi, %r9
    S_IN_UNCOLL_QUEUE $1, %rsi, %rdi                        # set uncollapse queue info to true (1)
    
    1:
    EPILOGUE

# regen uncollapse queue | only the first 2 doubles should be 0
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# void
RegenUncollQueue:
    PROLOGUE

    GP_UNCOLL_QUEUE %rdi, %rcx                              # pointer to datastructure
    movq $0, 4(%rdi)                                        # clear read and write index

    EPILOGUE
