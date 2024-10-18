
.text

# get the element count of the given binary heap
.macro GET_BH_SIZE pointer, dest
    movl 4(\pointer), \dest
.endm

# get the priority at the given index
.macro GET_BH_PRIORITY pointer, index, dest
    movq 16(\pointer, \index, 8), \dest
.endm

# get the data at the given index
.macro GET_BH_DATA pointer, index, dest
    movq 8(\pointer), \dest
    movq (\dest, \index, 8), \dest
.endm

# set the priority at the given index
.macro SET_BH_PRIORITY pointer, index, value
    movq \value, 16(\pointer, \index, 8)
.endm

# set the data at the given index
.macro SET_BH_DATA pointer, index, value, temp
    movq 8(\pointer), \temp
    movq \value, (\temp, \index, 8)
.endm

# get the index of the left child node at the given index (2 * i + 1)
.macro GET_BH_LEFT_INDEX index, dest
    mov \index, \dest
    shl $1, \dest               # multiply by 2
    inc \dest
.endm

# get the index of the right child node at the given index (2 * i + 2)
.macro GET_BH_RIGHT_INDEX index, dest
    mov \index, \dest
    shl $1, \dest               # multiply by 2
    add $2, \dest
.endm

# get the index of the parent node at the given index ((i - 1) / 2)
.macro GET_BH_PARENT_INDEX index, dest
    mov \index, \dest
    dec \dest
    shr $1, \dest               # divide by 2
.endm

#----------------------------------------------------------------------------------------------------------
# Binary Heap
#----------------------------------------------------------------------------------------------------------

# a binary heap is a binary tree disigned to efficiently get the element with the lowest priority,
# in other words a priority queue. for every node in the tree their value is less or equal that of
# their children.

# 4 bytes capacity
# 4 bytes element count
# 8 bytes pointer to the start of the data tree
# data... priority tree
# data... data tree

# makes a new binary heap with the given initial capacity.
# PARAMS:
# %rcx =    initial capacity of the binary heap
# RETURNS:
# %rax =    pointer to the resulting binary heap
MakeBinaryHeap:
    PROLOGUE
    push %r12
    sub $40, %rsp       # allocate shadow space

    movl %ecx, %r12d    # save initial capacity

    shl $4, %rcx        # multiply initial capacity by 16 for size in bytes
    addq $16, %rcx      # add space for size, element count and pointer to data tree

    call malloc

    movl %r12d, (%rax)  # initialize capacity
    movl $0, 4(%rax)    # make element count 0

    # calculate pointer to data

    movq %rax, %rcx
    addq $16, %rcx      # add header offset to pointer
    shl $3, %r12        # multiply capacity by 8
    addq %r12, %rcx     # add to pointer
    movq %rcx, 8(%rax)  # put in pointer to data tree

    movq -8(%rbp), %r12
    EPILOGUE

# grows the given binary heap by allocating new memory of the given size and copying over the contents.
# frees the old memory as well.
# PARAMS:
# %rcx =    pointer to the binary heap to grow
# %rdx =    new capacity of the binary heap (should be higher than the current capacity!)
# RETURNS:
# %rax =    pointer to the new binary heap
GrowBinaryHeap:
    PROLOGUE
    push %r12
    push %r13
    sub $32, %rsp       # allocate shadow space

    movq %rcx, %r12     # save old pointer
    movl %edx, %r13d    # save new capacity

    # allocate new memory

    movl %edx, %ecx
    shl $4, %rcx        # multiply initial capacity by 16 for size in bytes
    addq $16, %rcx      # add space for size, element count and pointer to data tree

    call malloc

    # fill new memory

    movl %r13d, (%rax)  # initialize capacity
    movl 4(%r12), %ecx  # get element count
    movl %ecx, 4(%rax)  # set element count

    # calculate pointer to data
    movq %rax, %rdx
    addq $16, %rdx      # add header offset to pointer
    shl $3, %r13        # multiply capacity by 8
    addq %r13, %rdx     # add to pointer
    movq %rdx, 8(%rax)  # put in pointer to data tree

    # copy over contents

    # copy priority tree
    #movq (%r12), %rcx  # element count is already in rcx
    movq %r12, %rsi     # source is old array
    add $16, %rsi       # skip header
    movq %rax, %rdi     # destination is new array
    add $16, %rdi       # skip header
    rep movsq

    # copy data tree
    movl 4(%rax), %ecx  # get element count
    movq 8(%r12), %rsi  # source is old data array
    movq 8(%rax), %rdi  # destination is new data array
    rep movsq

    movq %rax, %r13     # save new pointer to callee saved register

    # free memory of old binary heap

    movq %r12, %rcx
    call free

    movq %r13, %rax     # return new pointer

    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    EPILOGUE

# shrinks the given binary heap by allocating new memory of the given size and copying over the contents.
# frees the old memory as well.
# PARAMS:
# %rcx =    pointer to the binary heap to shrink
# %rdx =    new capacity of the binary heap (should be lower than the current capacity!)
# RETURNS:
# %rax =    pointer to the new binary heap
ShrinkBinaryHeap:
    PROLOGUE
    push %r12
    push %r13
    sub $32, %rsp       # allocate shadow space

    movq %rcx, %r12     # save old pointer
    movl %edx, %r13d    # save new capacity

    # allocate new memory

    movl %edx, %ecx
    shl $4, %rcx        # multiply initial capacity by 16 for size in bytes
    addq $16, %rcx      # add space for size, element count and pointer to data tree

    call malloc

    # fill new memory

    movl %r13d, (%rax)  # initialize capacity
    movl 4(%r12), %ecx  # get element count
    cmpl %ecx, %r13d    # if capacity is less than element count
    cmovl %r13d, %ecx   # use capacity as alement count
    movl %ecx, 4(%rax)  # set element count

    # calculate pointer to data
    movq %rax, %rdx
    addq $16, %rdx      # add header offset to pointer
    shl $3, %r13        # multiply capacity by 8
    addq %r13, %rdx     # add to pointer
    movq %rdx, 8(%rax)  # put in pointer to data tree

    # copy over contents

    # copy priority tree
    #movq (%r12), %rcx  # element count is already in rcx
    movq %r12, %rsi     # source is old array
    add $16, %rsi       # skip header
    movq %rax, %rdi     # destination is new array
    add $16, %rdi       # skip header
    rep movsq

    # copy data tree
    movl 4(%rax), %ecx  # get element count
    movq 8(%r12), %rsi  # source is old data array
    movq 8(%rax), %rdi  # destination is new data array
    rep movsq

    movq %rax, %r13     # save new pointer to callee saved register

    # free memory of old binary heap

    movq %r12, %rcx
    call free

    movq %r13, %rax     # return new pointer

    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    EPILOGUE

# inserts the given element in the given binary heap with the given priority. always returns a pointer 
# to the binary heap in case its grown, in which case a pointer to the new binary heap is returned 
# and the old pointer is freed.
# PARAMS:
# %rcx =    pointer to the binary heap to insert the given element in
# %rdx =    the element to add
# %r8  =    the priority to assign the element
# RETURNS:
# %rax =    pointer to the binary heap. points to the new binary heap if the binary heap is grown.
InsertInBinaryHeap:
    PROLOGUE

    # check if full

    movl 4(%rcx), %r9d              # get element count
    cmpl (%rcx), %r9d               # if element count is not equal to capacity
    jne 1f                          # skip growing the array

        pushq %rdx                  # save element to add
        pushq %r8                   # save priority to assign

        #movq %rcx, %rcx            # pointer is already in rcx
        movq %r9, %rdx              # get current capacity
        shl $1, %rdx                # double capacity
        call GrowBinaryHeap
        movq %rax, %rcx

        popq %r8                    # restore priotity to assign
        popq %rdx                   # restore element to add

    1: # dont grow array
    
    movl 4(%rcx), %r9d              # get element count

    # put in data
    movq 8(%rcx), %r10              # get pointer to data
    movq %rdx, (%r10, %r9, 8)       # put the element data at the end

    # put in priority
    movq %r8, 16(%rcx, %r9, 8)      # put the element priority at the end

    incl 4(%rcx)                    # increment the element count

    #movq %rcx, %rcx                # pointer already in rcx
    movq %r9, %rdx                  # element index
    call BubbleUp

    EPILOGUE

# extracts the element with the lowest priority from the binary heap. behaviour is undefined if the heap is empty. 
# PARAMS:
# %rcx =    pointer to the list to extract the lowest priority element from
# RETURNS:
# %rax =    data of the element with the lowest priority
ExtractFromBinaryHeap:
    PROLOGUE
    sub $8, %rsp
    push %r12

    movq $0, %rdx
    GET_BH_DATA %rcx, %rdx, %r12            # get the data to return

    # set root to last element
    movl 4(%rcx), %r8d                      # element count
    decq %r8                                # index of last element

    GET_BH_PRIORITY %rcx, %r8, %r9          # get last priority
    SET_BH_PRIORITY %rcx, %rdx, %r9         # set root node to last priority

    GET_BH_DATA %rcx, %r8, %r9              # get last data
    SET_BH_DATA %rcx, %rdx, %r9, %r10       # set root node to last data

    # remove last index
    decl 4(%rcx)                            # decrement the element count

    #movq %rcx, %rcx                        # pointer already in rcx              
    #movq %rdx, %rdx                        # index 0 already in rdx
    call BubbleDown
    
    movq %r12, %rax                         # return result
    pop %r12
    EPILOGUE

# make sure the binary tree keeps its property after insertion
# PARAMS:
# %rcx =    pointer to the binary heap in which to bubble up the given index
# %rdx =    the index to bubble up
# RETURNS:
# %rax =    pointer to the binary heap
BubbleUp:
    PROLOGUE
    movq %rcx, %rax

    cmpq $0, %rdx                           # if at root
    je 1f                                   # do nothing

    GET_BH_PARENT_INDEX %rdx, %r8
    GET_BH_PRIORITY %rcx, %rdx, %r9         # child priority
    GET_BH_PRIORITY %rcx, %r8, %r10         # parent priority

    cmpq %r10, %r9                          # if child priority is greater or equal to that of parent
    jge 1f                                  # do nothing

    # swap nodes around

    # swap priority
    SET_BH_PRIORITY %rcx, %rdx, %r10        # set child node to parent priority
    SET_BH_PRIORITY %rcx, %r8, %r9          # set parent node to child priority

    # swap data
    GET_BH_DATA %rcx, %rdx, %r9             # child data
    GET_BH_DATA %rcx, %r8, %r10             # parent data

    SET_BH_DATA %rcx, %rdx, %r10, %r11      # set child node to parent priority
    SET_BH_DATA %rcx, %r8, %r9, %r11        # set parent node to child priority

    PARAMS2 %rcx, %r8
    call BubbleUp

    1: # do nothing
    EPILOGUE

# make sure the binary tree keeps its property after extraction
# PARAMS:
# %rcx =    pointer to the binary heap in which to bubble down the given index
# %rdx =    the index to bubble down
# RETURNS:
# %rax =    pointer to the binary heap
BubbleDown:
    PROLOGUE
    movq %rcx, %rax

    movl 4(%rcx), %r8d                      # get element count
    shr $1, %r8                             # divide by 2
    cmpq %r8, %rdx                          # if leaf node (index greater or equal to element_count / 2)
    jge 1f                                  # do nothing

    # get smallest child index
    GET_BH_LEFT_INDEX %rdx, %r8             # left child index
    GET_BH_PRIORITY %rcx, %r8, %r9          # left child priority
    GET_BH_RIGHT_INDEX %rdx, %r10           # right child index
    GET_BH_PRIORITY %rcx, %r10, %r11        # right child priority

    cmpq %r9, %r11                          # if right priority is smaller than left priority
    cmovl %r10, %r8                         # move right index to r8

    GET_BH_PRIORITY %rcx, %rdx, %r9         # parent priority
    GET_BH_PRIORITY %rcx, %r8, %r10         # smallest child priority

    cmpq %r9, %r10                          # if child priority is greater or equal to that of parent
    jge 1f                                  # do nothing

    # swap nodes around

    # swap priority
    SET_BH_PRIORITY %rcx, %rdx, %r10        # set parent node to child priority
    SET_BH_PRIORITY %rcx, %r8, %r9          # set child node to parent priority

    # swap data
    GET_BH_DATA %rcx, %rdx, %r9             # parent data
    GET_BH_DATA %rcx, %r8, %r10             # child data

    SET_BH_DATA %rcx, %rdx, %r10, %r11      # set parent node to child data
    SET_BH_DATA %rcx, %r8, %r9, %r11        # set child node to parent data

    PARAMS2 %rcx, %r8
    call BubbleDown

    1: # do nothing
    EPILOGUE
