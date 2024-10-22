
.equ PF_INITIAL_CAPACITY, 1000 # initial capacity of the path finding data structures
.equ PF_MAX_LOOP_COUNT, 1000 # how many times the main loop is allowed to run

.data

pf_frontier: .quad 0 # pointer to the binary heap representing the frontier

# the following lists are "linked" and elements at the same index correspond to the same node

pf_visited_pos: .quad 0 # pointer to the list containing all packed integer position of visited nodes
pf_came_from: .quad 0 # pointer to the list containing the index of the node back to the start
pf_cost_so_far: .quad 0 # pointer to the list containing the cost from the start to the node represented by this index

pf_west: .long -1, 0
pf_east: .long 1, 0
pf_south: .long 0, -1
pf_north: .long 0, 1

.text
path_failed: .asciz "path too difficult to find!"

# initializes the data structures needed to do pathfinding
SetupPathFinding:
    PROLOGUE

    movq $PF_INITIAL_CAPACITY, %rcx                # initial capacity
    call MakeBinaryHeap
    movq %rax, pf_frontier(%rip)

    movq $PF_INITIAL_CAPACITY, %rcx                # initial capacity
    call MakeList
    movq %rax, pf_visited_pos(%rip)

    movq $PF_INITIAL_CAPACITY, %rcx                # initial capacity
    call MakeList
    movq %rax, pf_came_from(%rip)

    movq $PF_INITIAL_CAPACITY, %rcx                # initial capacity
    call MakeList
    movq %rax, pf_cost_so_far(%rip)

    EPILOGUE

# calculates a path from the given start to the given destination, and puts it in the given list.
# the path is created using the A* algorithm. Returns an empty list if no path is possible.
# PARAMS:
# %xmm0 =   x, z position of the start as 2 floats
# %xmm1 =   x, z position of the destination as 2 floats
# %xmm2 =   width of the path to create
# %r9   =   pointer to the list to use for the path.
# RETURNS:
# %rax =    the pointer to the list containing the path, is empty if no path is possible.
CalculatePath:
    PROLOGUE
    push %r12
    push %r13
    push %r14
    push %r15
    push %rbx
    sub $8, %rsp

    # get width of path
    roundss $2, %xmm2, %xmm2                # ceil the width
    cvttss2si %xmm2, %r13d                  # convert to integer

    # calculate path size offset
    movq %r13, %rcx                         # get path width
    decq %rcx                               # path width - 1
    cvtsi2ss %rcx, %xmm2                    # turn into float
    movss f_0.5(%rip), %xmm3                # get 0.5
    mulps %xmm3, %xmm2                      # (path_width - 1) * 0.5
    shufps $0, %xmm2, %xmm2                 # fill entire register

    # save destination position as integers
    movaps %xmm1, %xmm3                    
    roundps $1, %xmm3, %xmm3                # floor the floats for correct tile position
    cvttps2dq %xmm3, %xmm3                  # convert to int
    movd %xmm3, %r12                        # move to int register

    # convert starting position to node position
    addps %xmm2, %xmm0                      # add path size offset
    roundps $1, %xmm0, %xmm0                # floor the floats for correct tile position
    cvttps2dq %xmm0, %xmm0                  # convert to int
    movd %xmm0, %r14                        # move to int register

    # add starting tile to visited tiles

    # add destination to the start of the path
    CLEAR_LIST %r9
    movd %xmm1, %r10
    PARAMS2 %r9, %r10
    call AddToList
    movq %rax, (%rsp)                       # save on the stack

    # position
    PARAMS2 pf_visited_pos(%rip), %r14
    call AddToList
    movq %rax, pf_visited_pos(%rip)         # in case array grew

    # came from
    PARAMS2 pf_came_from(%rip), $-1
    call AddToList
    movq %rax, pf_came_from(%rip)           # in case array grew

    # cost so far
    PARAMS2 pf_cost_so_far(%rip), $0
    call AddToList
    movq %rax, pf_cost_so_far(%rip)         # in case array grew

    # add starting tile to frontier

    PARAMS3 pf_frontier(%rip), $0, $0       # starting tile is always index 0
    call InsertInBinaryHeap
    movq %rax, pf_frontier(%rip)            # in case array grew

    # frontier loop

    movq $0, %r15                           # use as loop counter
    1: # loop over frontier
        cmp $PF_MAX_LOOP_COUNT, %r15        # if at max loop count
        je 3f                               # failed to find path

        # get highest priority in frontier
        PARAMS1 pf_frontier(%rip)
        call ExtractFromBinaryHeap
        movq %rax, %rbx                         # save current node in callee saved register

        # check if at destination

        movq pf_visited_pos(%rip), %rcx
        GET_LIST %rcx, %rbx, %r14               # get position of the extracted node
        PARAMS3 %r14, %r13, %r12
        call IsNodeDestination
        cmp $1, %rax                            # if current position is the same as destination
        je 2f                                   # found path

        # check neighbours

        # west
        PARAMS4 %rbx, pf_west(%rip), %r13, %r12
        call CheckNeighbour

        # east
        PARAMS4 %rbx, pf_east(%rip), %r13, %r12
        call CheckNeighbour

        # south
        PARAMS4 %rbx, pf_south(%rip), %r13, %r12
        call CheckNeighbour

        # north
        PARAMS4 %rbx, pf_north(%rip), %r13, %r12
        call CheckNeighbour

        incq %r15                               # increment counter

        # end while loop if frontier is empty

        movq pf_frontier(%rip), %rcx
        GET_SIZE_BH %rcx, %ecx                  # get element count of frontier
        cmp $0, %rcx                            # if there are more than 0 nodes in frontier
        jg 1b                                   # continue loop

        jmp 3f
    
    2: # reconstruct path
    # rbx = index of destination node
    # r12 = position of destination
    # r13 = width of the path in blocks

    pop %r14

    movq pf_visited_pos(%rip), %r15         # get pointer to node positions

    cmp $0, %rbx                            # if at starting node
    je 6f                                   # skip loop

    5: # path reconstruct loop

        # get next node
        movq pf_came_from(%rip), %rcx
        GET_LIST %rcx, %rbx, %rbx           # next node in the path

        # check if gotten node is the start
        cmp $0, %rbx                        # if at starting node
        je 6f                               # end loop

        # get float position of node

        # convert integer position to floats
        GET_LIST %r15, %rbx, %rcx               # get node position
        movd %rcx, %xmm0
        cvtdq2ps %xmm0, %xmm0                   # convert to floats

        # go to center of block
        movss f_0.5(%rip), %xmm1                # get 0.5
        shufps $0, %xmm1, %xmm1                 # fill register with 0.5
        addps %xmm1, %xmm0                      # add 0.5 to pos

        # correct for path width
        movq %r13, %rcx                         # get path width
        decq %rcx                               # path width - 1
        cvtsi2ss %rcx, %xmm2                    # turn into float
        shufps $0, %xmm2, %xmm2                 # fill entire register
        mulps %xmm2, %xmm1                      # (path_width - 1) * 0.5
        subps %xmm1, %xmm0                      # pos - (path_width - 1) * 0.5
        movd %xmm0, %r10

        PARAMS2 %r14, %r10
        call AddToList
        movq %rax, %r14

        jmp 5b

    6: # end path loop

    movq %r14, %rax                         # return path list
    jmp 4f

    3: # failed to find path

    pop %rcx
    CLEAR_LIST %rcx                          # clear list since no path was found
    movq %rcx, %rax                          # return path list

    4: # cleanup and return

    # clear data structures of all elements
    movq pf_frontier(%rip), %rcx
    CLEAR_BH %rcx

    movq pf_visited_pos(%rip), %rcx
    CLEAR_LIST %rcx
    movq pf_came_from(%rip), %rcx
    CLEAR_LIST %rcx
    movq pf_cost_so_far(%rip), %rcx
    CLEAR_LIST %rcx

    pop %rbx
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    EPILOGUE

# checks if the neighbour is valid and puts it into the frontier if it is. if the neighbour is already
# in the frontier the priority is updated if its lower.
# PARAMS:
# %rcx =    node index of the source
# %rdx =    offset to get the neighbour
# %r8  =    width of the path in blocks
# %r9  =    2 packed 4 byte integers representing the destination
# RETURNS:
# void
CheckNeighbour:
    PROLOGUE
    push %r12
    push %r13
    push %r14
    push %r15

    movq %rcx, %r12                         # save node index in callee saved register
    movq %r9, %r14                          # save destination in callee saved register

    # get current position
    movq pf_visited_pos(%rip), %rcx
    GET_LIST %rcx, %r12, %r13               # get position of the node

    # add offset to position for neighbour position
    movd %r13, %xmm0
    movd %rdx, %xmm1
    paddd %xmm1, %xmm0                      # add packed 4 byte integers together
    movd %xmm0, %r13            

    # check if neighbour is valid
    movq %r13, %rcx                         # position of neighbour
    movq %r8, %rdx                          # width of the path
    call IsNodeValid
    cmp $0, %rax                            # if node is not valid
    je 3f                                   # dont do anything and exit

    # calculate new cost

    # calculate distance from start
    movq pf_cost_so_far(%rip), %rcx
    GET_LIST %rcx, %r12, %rdx               # get cost of came from
    incq %rdx                               # add 1 to the cost for distance from start

    # calculate heuristic (manhattan distance from destination)
    movd %r13, %xmm0                        # neighbour position
    movd %r14, %xmm1                        # destination
    psubd %xmm1, %xmm0                      # subtract packed integers
    pabsd %xmm0, %xmm0                      # get the absolute of both packed integers
    phaddd %xmm0, %xmm0                     # add packed integers together
    movd %xmm0, %r15                        # resulting manhattan distance

    movq %rdx, %r14                         # save total cost

    # check if neighbour is already visited
    PARAMS2 pf_visited_pos(%rip), %r13
    call IndexOfList
    cmp $-1, %rax                           # if result is -1
    je 1f                                   # add neighbour to frontier and lists

    movq %rax, %r13                         # save neighbour index

    # check if new cost is less than the cost currently stored

    movq pf_cost_so_far(%rip), %rcx
    GET_LIST %rcx, %r13, %r8                # get current neighbour cost
    cmp %r8, %r14                           # if new cost is greater or equal to old cost
    jge 3f                                  # do nothing

    jmp 2f                                  # update neighbour cost

    1: # add neighbour to frontier
        # r12 = came from index
        # r13 = neighbour pos
        # r14 = new total cost
        # r15 = heuristic

        # position
        PARAMS2 pf_visited_pos(%rip), %r13
        call AddToList
        movq %rax, pf_visited_pos(%rip)         # in case array grew

        # came from
        PARAMS2 pf_came_from(%rip), %r12
        call AddToList
        movq %rax, pf_came_from(%rip)           # in case array grew

        # cost so far
        PARAMS2 pf_cost_so_far(%rip), %r14
        call AddToList
        movq %rax, pf_cost_so_far(%rip)         # in case array grew

        # add starting tile to frontier

        GET_SIZE_LIST %rax, %edx
        decq %rdx                               # get last index
        PARAMS3 pf_frontier(%rip), %rdx, %r14 
        addq %r15, %r8                          # add heuristic  
        call InsertInBinaryHeap                 # put tile in frontier
        movq %rax, pf_frontier(%rip)            # in case array grew

        jmp 3f
    2: # update neighbour already visited
        # r12 = came from index
        # r13 = neighbour index
        # r14 = new total cost
        # r15 = heuristic

        # came from
        movq pf_came_from(%rip), %rcx
        SET_LIST %rcx, %r13, %r12

        # cost so far
        movq pf_cost_so_far(%rip), %rcx
        SET_LIST %rcx, %r13, %r14

        # check if in frontier

        PARAMS2 pf_frontier(%rip), %r13
        call IndexOfBinaryHeap
        cmp $-1, %rax                           # if not in frontier
        je 3f                                   # do nothing

        # update priority
        movq pf_frontier(%rip), %rcx
        movq %r14, %rdx
        addq %r15, %rdx                         # add heuristic
        SET_PRIORITY_BH %rcx, %rax, %rdx

        PARAMS2 %rcx, %rax
        call BubbleUp

    3: # exit
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    EPILOGUE

# checks if the given node is valid based on the path size
# PARAMS:
# %rcx =    position of the node as 2 4 byte packed integers
# %rdx =    the width of the path in blocks
# RETURNS:
# %rax  =   1 if valid, 0 if invalid
IsNodeValid:
    PROLOGUE
    sub $8, %rsp
    push %r12
    push %r13
    push %r14
    push %r15
    push %rbx

    # move node position to 2 registers
    movl %ecx, %r12d            # x pos
    shr $32, %rcx               
    movq %rcx, %r13             # z pos

    # get minimum position (exclusive) of the grid to check
    movq %r12, %r14
    sub %rdx, %r14

    movq %r13, %r15
    sub %rdx, %r15

    # loop over a grid with the given node as the top right corner

    1: # x loop
        cmp %r14, %r12          # if counter equals minimum x
        je 2f                   # exit loop

        movq %r13, %rbx         # use as y loop counter
        3: # y loop
            cmp %r15, %rbx          # if counter equals minimum y
            je 4f                   # exit loop

            PARAMS2 %r12, %rbx
            call GetBlockData
            andq $1, %rax           # zero out all exept first bit
            cmpq $1, %rax           # if first bit is 1 (wall)
            je 5f                   # return 0 (false)

            decq %rbx               # decrement counter
            jmp 3b
        4: # end y loop

        decq %r12               # decrement counter
        jmp 1b
    2: # end x loop

    movq $1, %rax           # return true
    jmp 6f

    5: # return 0
    movq $0, %rax           # return false

    6: # exit
    pop %rbx
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    EPILOGUE

# checks if the given node is at the destination based on the path size.
# PARAMS:
# %rcx =    position of the node as 2 4 byte packed integers
# %rdx =    the width of the path in blocks
# %r8  =    destination as 2 4 byte packed integers
# RETURNS:
# %rax  =   1 if at destination, 0 if not
IsNodeDestination:
    PROLOGUE
    push %r8
    push %r12
    push %r13
    push %r14
    push %r15
    push %rbx

    # move node position to 2 registers
    movl %ecx, %r12d            # x pos
    shr $32, %rcx               
    movl %ecx, %r13d            # z pos

    # get minimum position (exclusive) of the grid to check
    movl %r12d, %r14d
    subl %edx, %r14d

    movl %r13d, %r15d
    subl %edx, %r15d

    # loop over a grid with the given node as the top right corner

    1: # x loop
        cmpl %r14d, %r12d       # if counter equals minimum x
        je 2f                   # exit loop

        movl %r13d, %ebx        # use as y loop counter
        3: # y loop
            cmpl %r15d, %ebx        # if counter equals minimum y
            je 4f                   # exit loop

            movq -8(%rbp), %rcx
            movl %ebx, %edx         # put in y pos
            shlq $32, %rdx          # put at the end
            orq %r12, %rdx          # put in the x pos
            cmpq %rcx, %rdx         # position is the same as destination
            je 5f                   # return 1 (true)

            decl %ebx               # decrement counter
            jmp 3b
        4: # end y loop

        decl %r12d              # decrement counter
        jmp 1b
    2: # end x loop

    movq $0, %rax           # return false
    jmp 6f

    5: # return 1
    movq $1, %rax           # return true

    6: # exit
    pop %rbx
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    EPILOGUE
