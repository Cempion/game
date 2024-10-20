
.text

#----------------------------------------------------------------------------------------------------------
# List
#----------------------------------------------------------------------------------------------------------

# list holds elements the size of quads. is resized if there is not enough space to 
# add all the elements.

# 4 bytes capacity
# 4 bytes element count
# data...

# makes a new resizable list with the given initial capacity.
# PARAMS:
# %rcx =    initial capacity of the list
# RETURNS:
# %rax =    pointer to the resulting list
MakeList:
    PROLOGUE
    push %r12
    sub $40, %rsp       # allocate shadow space

    movl %ecx, %r12d    # save initial capacity

    incl %ecx           # add space for size and element count
    shl $3, %ecx        # multiply initial capacity by 8 for size in bytes

    call malloc

    movl %r12d, (%rax)  # initialize capacity
    movl $0, 4(%rax)    # make element count 0

    movq -8(%rbp), %r12
    EPILOGUE

# grows the given list by allocating new memory of the given size and copying over the contents.
# frees the old memory as well.
# PARAMS:
# %rcx =    pointer to the list to grow
# %rdx =    new capacity of the list (should be higher than the current capacity!)
# RETURNS:
# %rax =    pointer to the new list
GrowList:
    PROLOGUE
    push %r12
    push %r13
    sub $32, %rsp       # allocate shadow space

    movq %rcx, %r12     # save old pointer
    movl %edx, %r13d    # save new capacity

    # allocate new memory

    movl %edx, %ecx
    incl %ecx           # add space for size and element count
    shl $3, %ecx        # multiply capacity by 8 for size in bytes

    call malloc

    # fill new memory

    movl %r13d, (%rax)  # initialize capacity
    movl 4(%r12), %ecx  # get element count
    movl %ecx, 4(%rax)  # set element count

    # copy over contents

    #movq (%r12), %rcx  # element count is already in rcx
    movq %r12, %rsi     # source is old array
    add $8, %rsi        # skip capacity and size bytes
    movq %rax, %rdi     # destination is new array
    add $8, %rdi        # skip capacity and size bytes
    rep movsq

    movq %rax, %r13     # save new pointer to callee saved register

    # free memory of old list

    movq %r12, %rcx
    call free

    movq %r13, %rax     # return new pointer

    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    EPILOGUE

# shrinks the given list by allocating new memory of the given size and copying over the contents.
# frees the old memory as well.
# PARAMS:
# %rcx =    pointer to the list to shrink
# %rdx =    new capacity of the list (should be lower than the current capacity!)
# RETURNS:
# %rax =    pointer to the new list
ShrinkList:
    PROLOGUE
    push %r12
    push %r13
    sub $32, %rsp       # allocate shadow space

    movq %rcx, %r12     # save old pointer
    movl %edx, %r13d    # save new capacity

    # allocate new memory

    movl %edx, %ecx
    incl %ecx           # add space for size and element count
    shl $3, %ecx        # multiply capacity by 8 for size in bytes

    call malloc

    # fill new memory

    movl %r13d, (%rax)  # initialize capacity
    movl 4(%r12), %ecx  # get element count
    cmpl %ecx, %r13d    # if capacity is less than element count
    cmovl %r13d, %ecx   # use capacity as alement count
    movl %ecx, 4(%rax)  # set element count

    # copy over contents

    #movq (%r12), %rcx  # element count is already in rcx
    movq %r12, %rsi     # source is old array
    add $8, %rsi        # skip capacity and size bytes
    movq %rax, %rdi     # destination is new array
    add $8, %rdi        # skip capacity and size bytes
    rep movsq

    movq %rax, %r13     # save new pointer to callee saved register

    # free memory of old list

    movq %r12, %rcx
    call free

    movq %r13, %rax     # return new pointer

    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    EPILOGUE

# adds the given element to the given list. always returns a pointer to the list in case 
# its grown, in which case a pointer to the new list is returned and the old pointer is freed.
# PARAMS:
# %rcx =    pointer to the list to add the given element to
# %rdx =    the element to add
# RETURNS:
# %rax =    pointer to the list. points to the new list if the list is grown.
AddToList:
    PROLOGUE

    # check if full

    movl 4(%rcx), %r8d              # get element count
    cmpl (%rcx), %r8d               # if element count is not equal to capacity
    jne 1f                          # skip growing the array

        sub $8, %rsp
        pushq %rdx                  # save element to add

        #movq %rcx, %rcx            # pointer is already in rcx
        movq %r8, %rdx              # get current capacity
        shl $1, %rdx                # double capacity
        call GrowList
        movq %rax, %rcx

        popq %rdx                   # restore element to add

    1: # dont grow array
    
    movl 4(%rcx), %r8d              # get element count
    movq %rdx, 8(%rcx, %r8, 8)      # put the element at the end
    incl 4(%rcx)                    # increment the element count

    movq %rcx, %rax                 # return pointer
    EPILOGUE

# removes the first occurence of the given element from the given list, or nothing if element isn't present.
# removes elements by moving the last element to the index to remove and removing the last element.
# PARAMS:
# %rcx =    pointer to the list to remove the given element from
# %rdx =    the element to remove
# RETURNS:
# void
RemoveFromList:
    PROLOGUE
    sub $8, %rsp
    push %rcx                       # save pointer

    call IndexOfList

    cmp $-1, %rax                   # if no element found
    je 1f                           # exit subroutine

    pop %rcx                        # restore pointer
    movq %rax, %rdx                 # index to remove
    call RemoveIndexFromList

    1: # exit
    EPILOGUE

# removes the element at the given index from the given list. removes elements by moving 
# the last element to the index to remove and removing the last element.
# PARAMS:
# %rcx =    pointer to the list to remove the given index from
# %rdx =    the index of the element to remove (should be within 0 - element_count!)
# RETURNS:
# void
RemoveIndexFromList:
    PROLOGUE

    # get last index
    movl 4(%rcx), %r8d              # get element count
    decq %r8                        # index to last element

    # move last element to index to remove
    movq 8(%rcx, %r8, 8), %r8
    movq %r8, 8(%rcx, %rdx, 8)

    # remove last index
    decl 4(%rcx)                    # decrement the element count

    1: # exit
    EPILOGUE

# gets the element count of the given list
.macro GET_SIZE_LIST pointer, dest
    movl 4(\pointer), \dest
.endm

# gets the element at the given index
.macro GET_LIST pointer, index, dest
    movq 8(\pointer, \index, 8), \dest
.endm

# sets the element at the given index
.macro SET_LIST pointer, index, value
    movq \value, 8(\pointer, \index, 8)
.endm

# removes the last element of the given list
.macro REMOVE_LAST_LIST pointer
    decl 4(\pointer)
.endm

# clears the given list of all elements, resulting in an element count of 0
.macro CLEAR_LIST pointer
    movl $0, 4(\pointer)            # make element count 0 ;)
.endm

# gets the index of the first occurence of the given element in the given list
# PARAMS:
# %rcx =    pointer to the list to search in
# %rdx =    the element to get the index of
# RETURNS:
# %rax =    the found index, or -1 if not found
IndexOfList:
    PROLOGUE

    movl 4(%rcx), %r8d              # get element count          

    movq %rdx, %rax                 # element to get the index of
    movq %rcx, %rdi                 # array to loop over
    add $8, %rdi                    # skip capacity and element count values
    movq %r8, %rcx                  # get element count
    repne scasq

    jnz 1f                          # if not found return invalid answer

    sub %rcx, %r8                   # get index with element_count - rcx
    decq %r8
    movq %r8, %rax                  # return index

    jmp 2f

    1: # invalid answer
    movq $-1, %rax                  # return error value

    2: # exit
    EPILOGUE
