
# get uncollapse queue pointer
.macro GP_UNCOLL_QUEUE dest, wfcPointer
    movq 72(\wfcPointer), \dest    # pointer to datastructure
.endm

# gets the first tile in the uncollapse queue and updates uncollapse queue info, or -1 if empty
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# %rax =    the dequed tile, or -1 if empty
DeqUncollQueue:
    PROLOGUE

    GP_UNCOLL_QUEUE %rdx, %rcx                                  # get pointer to collapse queue

    movl 4(%rdx), %eax                                          # get read index
    cmpl %eax, 8(%rdx)                                          # if the read and write indexes are the same the queue is empty
    je 2f

    DEQ_QUEUE %eax , %rdx
    
    GP_UNCOLL_QUEUE_INF %rdx, %rcx                              # get pointer to collapse queue info
    S_IN_UNCOLL_QUEUE $0, %rax, %rdx                            # clear collapse queue info

    jmp 1f
    
    2:
    movq $-1, %rax                                              # return -1 since empty

    1:
    EPILOGUE

# adds a tile to the back of the uncollapse queue and updates uncollapse queue info
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    the tileindex to add
# RETURNS:
# void
EnqUncollQueue:
    PROLOGUE

    GP_UNCOLL_QUEUE_INF %r9, %rcx                           # get pointer to collapse queue info
    IS_NOT_IN_UNCOLL_QUEUE %rdx, %r9                        # if in collapse queue skip adding it again
    jne 1f

    GP_UNCOLL_QUEUE %r9, %rcx                               # get pointer to collapse queue info
    ENQ_QUEUE %edx, %r9

    S_SIDE_TO_SKIP $1, %rdx, %r9                            # set to is in uncollapse queue
    
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
