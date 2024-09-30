.include "macro.s"
.include "data/properties.s"
.include "data/ruleset.s"

.include "data/tile_possibilities.s"

.include "data/entropy_indexes.s"
.include "data/entropy_list.s"

.include "data/collapse_queue_info.s"
.include "data/collapse_queue.s"

.include "data/uncollapse_queue_info.s"
.include "data/uncollapse_queue.s"

.global CreateWfc

.global CollapseTile
.global CollapseTiles
.global CollapseAllTiles

.global UncollapseTile
.global UncollapseTiles
.global Regen

#----------------------------------------------------------------------------------------------------------
# MEMORY LAYOUT
#----------------------------------------------------------------------------------------------------------

# all data structures within the wfc have a size, which is located with at the pointer.
# the size is the amount of elements that can be stored in the array.

# same for queues exept the read and write index are on an offset of 4 and 8 respectively.

.equ PROPERTIES_SIZE, 88

# 0  | 4 bytes = wfc memory size in bytes
# 4  | 4 bytes = tilecount

# 8  | 4 bytes = width
# 12 | 4 bytes = height
#
# 16 | 8 bytes = pointer to ruleset. first byte is the ammount of modules, then 4 quads per module for each side.
# 24 | 8 bytes = pointer to onChange subroutine %rcx = tile index, %rdx = tile possibilities. 
#                is called when a tile is collapsed to an entropy of 1 or 0, or is uncollapsed from said entropies.
#
# 32 | 8 bytes = pointer to tile possibilities
# 40 | 8 bytes = pointer to entropy list
# 48 | 8 bytes = pointer to entropy indexes
# 56 | 8 bytes = pointer to collapse check queue
# 64 | 8 bytes = pointer to collapse check info (side to skip and wether tile is in queue)
# 72 | 8 bytes = pointer to uncollapse check queue
# 80 | 8 bytes = pointer to uncollapse check info (side to skip and wether tile is in queue)
#
# 4 bytes + 8 bytes * width * height = tile possibilities (so a max of 64 possibilities)
#
# 4 bytes + 4 bytes * max_entropy * (1 + width * height) = the entropy list is a 2d array
#                                                          X axis = entropy starting at an entropy of 1, which each store:
#                                                          Y axis = first 4 bytes is the amount of tiles currently stored in the array
#                                                                  everything after are the 4 byte sized tile indexes. 
#                                                                  tiles stored with entropy 2 or higher are marked to be collapsed, 
#                                                                  tiles with an entropy of 1 are not.
#
# 4 bytes + 4 bytes * width * height = entropy indexes. stores for each tile where they can be found at the corresponding entropy, 
#                                      or 0 if not in the entropy list.
#
# 16 bytes + 4 bytes * width * height = collapse check queue (looping queue with a read and write index)
# 4 bytes + 1 byte   * width * height = collapse check info (side to skip and wether tile is in queue)
#
# 16 bytes + 4 bytes * width * height = uncollapse check queue (looping queue with a read and write index)
# 4 bytes + 1 byte   * width * height = uncollapse check info (wether tile is in queue)

#----------------------------------------------------------------------------------------------------------
# SUBROUTINES
#----------------------------------------------------------------------------------------------------------

# creates a new wfc and returns its pointer.
# PARAMS:
# %rcx =    width
# %rdx =    height
# %r8  =    pointer to ruleset
# %r9  =    pointer to onChange subroutine
# RETURNS:
# %rax =    pointer to wfc, or 0 if it failed
CreateWfc:
    PROLOGUE

    sub $PROPERTIES_SIZE, %rsp      # allocate space to push size, tilecount, width, height, and structure size on stack
    movl %ecx, 8(%rsp)              # width
    movl %edx, 12(%rsp)             # height
    movq %r8, 16(%rsp)              # ruleset
    movq %r9, 24(%rsp)              # onChange subroutine

    #----------------------------------------------------------------------------------------------------------
    # CALCULATE SIZE IN BYTES
    #----------------------------------------------------------------------------------------------------------

    movq $PROPERTIES_SIZE, %rcx     # initialize total size in bytes to size of the properties.

    # calculate tilecount
    movl 8(%rsp), %eax              # width
    mull %edx                       # * height = tilecount
    movl %eax, 4(%rsp)              # save tilecount to stack

    # tile possibilities size in bytes | 8 bytes * tilecount

    shl $3, %rax                    # same as 8 bytes * tilecount
    add $4, %rax                    # add 4 bytes for structure size

    movq %rax, 32(%rsp)             # save size of structure on stack
    add %rax, %rcx                  # add to total

    # entropy list size in bytes | 4 bytes * max_entropy * (tilecount + 1)

    movl 4(%rsp), %eax              # get tilecount
    inc %rax                        # tilecount + 1
    shl $2, %rax                    # same as (tilecount + 1) * 4 bytes
    mulb (%r8)                      # multiply by max_entropy (first byte in ruleset is max_entropy)
    add $4, %rax                    # add 4 bytes for structure size

    movq %rax, 40(%rsp)             # save size of structure on stack
    add %rax, %rcx                  # add to total

    # entropy indexes size in bytes | 4 bytes * tilecount

    movl 4(%rsp), %eax              # get tilecount
    shl $2, %rax                    # same as 4 bytes * tilecount
    add $4, %rax                    # add 4 bytes for structure size

    movq %rax, 48(%rsp)             # save size of structure on stack
    add %rax, %rcx                  # add to total

    # collapse check queue size in bytes | 4 bytes * tilecount + 8 bytes

    movl 4(%rsp), %eax              # get tilecount
    shl $2, %rax                    # same as 4 bytes * tilecount
    add $16, %rax                   # add 16 bytes for size, read and write index and padding

    movq %rax, 56(%rsp)             # save size of structure on stack
    add %rax, %rcx                  # add to total

    # collapse check queue info size in bytes | 1 byte * tilecount

    movl 4(%rsp), %eax              # get tilecount
    add $4, %rax                    # add 4 bytes for structure size

    movq %rax, 64(%rsp)             # save size of structure on stack
    add %rax, %rcx                  # add to total

    # uncollapse check queue size in bytes | 4 bytes * tilecount + 8 bytes

    movl 4(%rsp), %eax              # get tilecount
    shl $2, %rax                    # same as 4 bytes * tilecount
    add $16, %rax                   # add 16 bytes for size, read and write index and padding

    movq %rax, 72(%rsp)             # save size of structure on stack
    add %rax, %rcx                  # add to total

    # uncollapse check queue info size in bytes | 1 byte * tilecount

    movl 4(%rsp), %eax              # get tilecount
    add $4, %rax                    # add 4 bytes for structure size

    movq %rax, 80(%rsp)             # save size of structure on stack
    add %rax, %rcx                  # add to total

    movl %ecx, (%rsp)               # save total size

    #----------------------------------------------------------------------------------------------------------
    # ALLOCATE MEMORY
    #----------------------------------------------------------------------------------------------------------

    SHADOW_SPACE
    call malloc
    CLEAN_SHADOW

    cmp $0, %rax                    # if malloc failed                
    je 1f                           # exit subroutine

    #----------------------------------------------------------------------------------------------------------
    # INITIALIZE PROPERTIES
    #----------------------------------------------------------------------------------------------------------

    movl (%rsp), %edx
    movl %edx, (%rax)               # size in bytes of the wfc (includes itself)

    movl 4(%rsp), %edx
    movl %edx, 4(%rax)              # tilecount

    movl 8(%rsp), %edx
    movl %edx, 8(%rax)              # width

    movl 12(%rsp), %edx
    movl %edx, 12(%rax)             # height

    movq 16(%rsp), %rdx
    movq %rdx, 16(%rax)             # ruleset pointer

    movq 24(%rsp), %rdx
    movq %rdx, 24(%rax)             # onChange subroutine pointer

    #----------------------------------------------------------------------------------------------------------
    # INITIALIZE POINTERS
    #----------------------------------------------------------------------------------------------------------

    movq %rax, %r8                  # use as "total" to set pointers

    add $PROPERTIES_SIZE, %r8       # calculate pointer to tile possibilities
    movq %r8, 32(%rax)              # save pointer

    add 32(%rsp), %r8               # calculate pointer to entropy list
    movq %r8, 40(%rax)              # save pointer

    add 40(%rsp), %r8               # calculate pointer to entropy indexes
    movq %r8, 48(%rax)              # save pointer

    add 48(%rsp), %r8               # calculate pointer to collapse check queue
    movq %r8, 56(%rax)              # save pointer

    add 56(%rsp), %r8               # calculate pointer to collapse check queue info
    movq %r8, 64(%rax)              # save pointer

    add 64(%rsp), %r8               # calculate pointer to uncollapse check queue
    movq %r8, 72(%rax)              # save pointer

    add 72(%rsp), %r8               # calculate pointer to uncollapse check queue info
    movq %r8, 80(%rax)              # save pointer

    #----------------------------------------------------------------------------------------------------------
    # INITIALIZE DATA STRUCTURE SIZE VALUE
    #----------------------------------------------------------------------------------------------------------
    
    # tile possibilities
    movq 32(%rsp), %r8              # get size
    movq 32(%rax), %r9              # get pointer
    sub $4, %r8                     # remove the 4 bytes used to store size
    shr $3, %r8                     # element size in bytes / 8 = size in quads
    movl %r8d, (%r9)                # save size

    # entropy list
    movq 40(%rsp), %r8              # get size
    movq 40(%rax), %r9              # get pointer
    sub $4, %r8                     # remove the 4 bytes used to store size (size does not include itself)
    shr $2, %r8                     # element size in bytes / 4 = size in doubles
    movl %r8d, (%r9)                # save size

    # entropy indexes
    movq 48(%rsp), %r8              # get size
    movq 48(%rax), %r9              # get pointer
    sub $4, %r8                     # remove the 4 bytes used to store size (size does not include itself)
    shr $2, %r8                     # element size in bytes / 4 = size in doubles
    movl %r8d, (%r9)                # save size

    # collapse check queue
    movq 56(%rsp), %r8              # get size
    movq 56(%rax), %r9              # get pointer
    sub $12, %r8                    # remove the 12 bytes used to store size and read/write index
    shr $2, %r8                     # element size in bytes / 4 = size in doubles
    movl %r8d, (%r9)                # save size

    # collapse check queue info
    movq 64(%rsp), %r8              # get size
    movq 64(%rax), %r9              # get pointer
    sub $4, %r8                     # remove the 4 bytes used to store size (size does not include itself)
    movl %r8d, (%r9)                # save size

    # uncollapse check queue
    movq 72(%rsp), %r8              # get size
    movq 72(%rax), %r9              # get pointer
    sub $12, %r8                    # remove the 12 bytes used to store size and read/write index
    shr $2, %r8                     # element size in bytes / 4 = size in doubles
    movl %r8d, (%r9)                # save size

    # uncollapse check queue info
    movq 80(%rsp), %r8              # get size
    movq 80(%rax), %r9              # get pointer
    sub $4, %r8                     # remove the 4 bytes used to store size (size does not include itself)
    movl %r8d, (%r9)                # save size

    #----------------------------------------------------------------------------------------------------------
    # REGEN WFC (initialize values)
    #----------------------------------------------------------------------------------------------------------

    push %rax                       # save wfc pointer for return

    PARAMS1 %rax
    call Regen                      # initialize values in data structures so they aren't garbage

    pop %rax                        # set return to wfc pointer

    1: # exit creating wfc
    EPILOGUE

#----------------------------------------------------------------------------------------------------------
# COMMANDS
#----------------------------------------------------------------------------------------------------------

# collapses the given tile in the given wfc
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    tileindex to collapse
# RETURNS:
# void
CollapseTile:
    PROLOGUE

    push %r12
    push %r13
    movq %rcx, %r12                     # save pointer to wfc in callee saved register
    movq %rdx, %r13                     # save tile index in callee saved register

    PARAMS2 %r12, %r13
    call CollapsePossibilities

    PARAMS3 %r12, %r13, $1 
    call AddToEntList                   # since the tile must be collapsed add to entropy list at entropy 1

    pop %r13
    pop %r12

    EPILOGUE

# collapses the given tiles in the given wfc
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    pointer to tile array (first 4 bytes specifying the amount of tile indexes, then 4 byte tile indexes)
# RETURNS:
# void
CollapseTiles:
    PROLOGUE

    push %r12
    push %r13
    push %r14
    movq %rcx, %r12                     # save pointer to wfc in callee saved register
    movq %rdx, %r13                     # save tile index array pointer in callee saved register
    movl (%rdx), %r14d                  # save size and use as counter 

    1: #loop
        cmp $0, %r14                    # if counter is 0                
        je 2f                           # jump to end

        dec %r14                        # decrement counter

        movl 4(%r13, %r14, 4), %edx     # get tile to add

        GP_TILE_POSS %r8, %r12          # get pointer to tile possibilities
        G_ENT %r9, %rdx, %r8            # get tile entropy

        PARAMS3 %r12, %rdx, %r9
        call AddToEntList               # register tile to entropy list 

        jmp 1b    

    2: # end loop
    PARAMS1 %r12
    call CollapseLoop                   # collapse registered tiles

    pop %r14
    pop %r13
    pop %r12

    EPILOGUE

# collapses all the tiles in the given wfc
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# void
CollapseAllTiles:
    PROLOGUE

    push %r12
    push %r13
    movq %rcx, %r12                     # save pointer to wfc in callee saved register
    G_TILE_CNT %r13d, %r12              # save tilecount to a callee saved register and use as tile index

    1: #loop
        dec %r13                        # decrement counter

        GP_TILE_POSS %r8, %r12          # get pointer to tile possibilities
        G_ENT %r9, %r13, %r8            # get tile entropy

        PARAMS3 %r12, %r13, %r9
        call AddToEntList               # register tile to entropy list   

        cmp $0, %r13                    # if counter is 0                
        jne 1b                          # jump if counter is not -1

    PARAMS1 %r12
    call CollapseLoop                   # collapse registered tiles

    pop %r13
    pop %r12

    EPILOGUE

UncollapseTile:
    PROLOGUE

    EPILOGUE

UncollapseTiles:
    PROLOGUE

    EPILOGUE

# regens the given wfc to its uncollapsed state.
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# void
Regen:
    PROLOGUE

    push %r12
    movq %rcx, %r12                      # copy wfc pointer to callee saved register

    PARAMS1 %r12
    call RegenTilePoss                     

    PARAMS1 %r12
    call RegenEntList
    PARAMS1 %r12
    call RegenEntIndexes

    PARAMS1 %r12
    call RegenCollQueue
    PARAMS1 %r12
    call RegenCollQueueInf

    PARAMS1 %r12
    call RegenUncollQueue
    PARAMS1 %r12
    call RegenUncollQueueInf

    pop %r12

    EPILOGUE

#----------------------------------------------------------------------------------------------------------
# INDEX TO POSITION
#----------------------------------------------------------------------------------------------------------

# gets the index of the given position
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    x position
# %r8  =    y position
# RETURNS:
# %rax =    tile index corresponding with the specified position, or -1 if out of bounds.
GetTileIndex:
    PROLOGUE

    G_WIDTH %edi, %rcx                                      # get width of wfc
    G_HEIGHT %esi, %rcx                                     # get height of wfc

    movq %rdx, %rcx                                         # since LOOP_VALUE changed rdx

    LOOP_VALUE %rcx, %rdi                                   # loop width
    LOOP_VALUE %r8, %rsi                                    # loop height

    movq %r8, %rax                                          # put y position in rax
    movq $0, %rdx                                           # make 0 to prepare for mult
    mul %rdi                                                # y * width
    add %rcx, %rax                                          # x + y * width

    EPILOGUE

# gets the position of the given tile index
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    the tile index
# RETURNS:
# %rax =    x position, or -1 if the tile index is invalid
# %rdi =    y position, or -1 if the tile index is invalid
GetTilePosition:
    PROLOGUE

    G_TILE_CNT %r8d, %rcx                                   # get tile count of wfc     
    G_WIDTH %r9d, %rcx                                      # get width of wfc                                            

    cmp $0, %rdx                                            # if tile index is less than 0 return -1
    jl 1f
    cmp %r8, %rdx                                           # if tile index is greater or equal to tile count return -1
    jge 1f

    movq %rdx, %rax                                         # move tile index into rax
    movq $0, %rdx                                           # make rdx 0 for division
    div %r9                                                 # remainder = x : quotient = y

    movq %rax, %rdi                                         # y position
    movq %rdx, %rax                                         # x position

    jmp 2f

    1: # return -1 (out of bounds)
    movq $-1, %rax
    movq $-1, %rdi
    2: #end normally
    EPILOGUE

# gets the tile index of the neighbouring tile of the given tile index on the given side
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    the tile index to get the neighbour from
# %r8  =    side (0 = west, 1 = east, 2 = south, 3 = north : side xor 1 == opposite)
# RETURNS:
# %rax =    the tile index of the neighbour on the given side, or -1 if side is invalid or out of bounds
GetTileNeighbour:
    PROLOGUE

    mov $-1, %rax                                           # initialize rax

    # check if side is valid
    cmp $0, %r8
    jl 5f
    cmp $4, %r8
    jge 5f

    push %r12
    push %r13
    movq %rcx, %r12                                         # save wfc pointer to callee saved register
    movq %r8, %r13                                          # save side to callee saved register

    # get tile position
    PARAMS2 %r12, %rdx
    call GetTilePosition                                    # x position saved in rax : y position saved in rdi

    lea GetTileNeighbourTable(%rip), %rdx                   # get address of table
    jmp *(%rdx, %r13, 8)                                    # jump to correct case using a table

    0: # west
        dec %rax                                            # west = x position - 1
        jmp 4f
    1: # east
        inc %rax                                            # east = x position + 1
        jmp 4f
    2: # south
        dec %rdi                                            # south = y position - 1
        jmp 4f
    3: # north
        inc %rdi                                            # north = y position + 1

    4: # continue

    PARAMS3 %r12, %rax, %rdi
    call GetTileIndex                                   # neighbour tile index = rax

    pop %r13
    pop %r12

    5: # end
    EPILOGUE

GetTileNeighbourTable:
        .quad 0b                                            # west
        .quad 1b                                            # east
        .quad 2b                                            # south
        .quad 3b                                            # north

#----------------------------------------------------------------------------------------------------------
# COLLAPSING
#----------------------------------------------------------------------------------------------------------

# collapse all tiles egistered in the entropy list with the lowest entropy first
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# void
CollapseLoop:
    PROLOGUE

    push %r12
    movq %rcx, %r12                                         # save pointer to wfc

    1:

        PARAMS1 %r12
        call GetNextCollapse                                # get a random tile with the lowest entropy to collapse

        cmp $-1, %rax
        je 2f                                               # if no next collapse was found exit loop

        PARAMS2 %r12, %rax
        call CollapsePossibilities                          # collapse possibilities of the given tile

        jmp 1b

    2:

    pop %r12

    EPILOGUE

# collapses the possibilities of the given tile in the wfc without doing any bookkeeping
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    tileindex to collapse
# RETURNS:
# void
CollapsePossibilities:
    PROLOGUE

    # free registers
    push %r12
    push %r13

    movq %rcx, %r12                                         # save pointer to wfc in callee saved register
    movq %rdx, %r13                                         # save tile index in callee saved register

    GP_TILE_POSS %r8, %rcx
    G_POSS %rcx, %rdx, %r8                                  # get possibilities of tile

    PARAMS1 %rcx
    call PickPossibility

    movq %rax, %rcx                                         # since only rcx works with bitshifts

    movq $1, %rax
    shl %cl, %rax                                           # the possibilites to intersect with current possibilities

    PARAMS3 %r12, %r13, %rax
    call IntersectTilePossibilities

    cmp $0, %rax                                            # if tile is unchanged skip propagation
    je 1f

    PARAMS2 %r12, %r13
    call PropagateRemoval

    1: # skip propagation
    # restore registers
    pop %r13
    pop %r12

    EPILOGUE

# picks a random possibility from the possibilities of the given tile and returns it
# PARAMS:
# %rcx =    the possibilities to pick from
# RETURNS:
# %rax =    the picked possibility
PickPossibility:
    PROLOGUE

    RANDOM %eax                                             # get random number

    popcnt %rcx, %r8                                        # get bitcount of possibilities

    movq $0, %rdx                                           # make 0 to prep for modulo
    div %r8                                                 # random % entropy

    PARAMS2 %rcx, %rdx
    call GetNthPossibility                                  # get actual possibility index

    EPILOGUE

# gets the n-th possibility of the given possibilities
# PARAMS:
# %rcx =    possibilities (quad)
# %rdx =    n
# RETURNS:
# %rax =    the index of the nth possibility
GetNthPossibility:
    PROLOGUE

    movq $0, %rax                                           # initialize rax
    movq %rcx, %r8                                          # since rcx should be used for bitshifts

    1:
    bsf %r8, %rcx                                           # get index to first 1 bit
    add %rcx, %rax                                          # add to result

    cmp $0, %rdx                                            # if n = 0 end loop
    je 2f

    add $1, %rcx                                            # always shift 1
    shr %cl, %r8                                            # shift possibilities
    add $1, %rax                                            # add 1 to result since bits got shifted

    dec %rdx                                                # decrease counter (n)
    jmp 1b

    2:
    EPILOGUE

#----------------------------------------------------------------------------------------------------------
# PROPAGATING
#----------------------------------------------------------------------------------------------------------

# intersects the possibilties of the given tile with the given possibilities, and updates the entropy list.
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    tileindex whose possibilities to intersect
# %r8  =    possibilities to intersect with
# RETURNS:
# %rax =    1 if changed, 0 if unchanged.
IntersectTilePossibilities:
    PROLOGUE

    GP_TILE_POSS %r9, %rcx                                  # get pointer to tile possibilities
    G_ENT %rdi, %rdx, %r9                                   # save old entropy
    I_POSS %r8, %rdx, %r9                                   # intersect tile possibilities
    G_ENT %rsi, %rdx, %r9                                   # get new entropy

    movq $0, %rax                                           # initialize rax to 0 in case tile is unchanged.

    cmp %rdi, %rsi                                          # if old and new entropy are the same nothing changed
    je 2f                                                   # so you can skip to end

    push %r12
    push %r13
    push %r14
    movq %rcx, %r12                                         # save wfc pointer                                  
    movq %rdx, %r13                                         # save tile index
    movq %rsi, %r14                                         # save new entropy

    GP_ENT_INDEXES %r9, %rcx                                # get pointer to entropy list indexes
    IS_NOT_IN_ENT_LIST %rdx, %r9                            # if not in entropy list skip updating
    je 1f                                                   

    # update entropy list
    GP_ENT_LIST %r9, %rcx                                   # get pointer to entropy list

    PARAMS3 %r12, %r13, %rdi
    call SubFromEntList                                     # remove tile from old entropy

    PARAMS3 %r12, %r13, %r14
    call AddToEntList                                       # add tile to new entropy

    1: # skip updating entropy list

    GP_TILE_POSS %r9, %r12
    G_POSS %rdx, %r13, %r9                                  # get tile possibilities

    PARAMS2 %r13, %rdx                                      # tile index, tile possibilities
    call *24(%r12)                                          # call onChange subroutine                                      

    pop %r14
    pop %r13
    pop %r12

    movq $1, %rax                                           # return 1 (got changed)

    2: # dont return 1 (return 0 instead)
    EPILOGUE

# propagates the changes caused by the removal of possibilities of the given tile to its neighbours
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    tileindex whose possibilities got removed
# RETURNS:
# void
PropagateRemoval:
    PROLOGUE

    push %r12
    movq %rcx, %r12                                         # save wfc pointer to callee saved register

    PARAMS3 %r12, %rdx, $5
    call EnqCollQueue                                       # add starting tile to collapse queue with sideToSkip == 5 (dont skip a side)

    1: # loop

        PARAMS1 %r12
        call DeqCollQueue                                   # get first tile in queue

        cmp $-1, %rax                                       # if queue is empty stop loop
        je 2f

        PARAMS2 %r12, %rax
        call CheckRemoval                                   # check neighbouring tile possibilities

        jmp 1b

    2: # end loop

    pop %r12

    EPILOGUE

# used in removal propagation to check the neighbours of the given tile and remove invalid possibilities.
# uses the value in collapse queue info to skip sides that are quaranteed to be correct.
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    tileindex whose neighbours to check for invalid possibilities
# RETURNS:
# void
CheckRemoval:
    PROLOGUE

    push %r12
    push %r13
    push %r14
    push %r15
    push %rbx
    movq %rcx, %r12                                         # save wfc pointer to callee saved register
    movq %rdx, %r13                                         # save tile index to callee saved register
    GP_COLL_QUEUE_INF %r14, %r12                            # save collapse queue info pointer to callee saved register
    GP_TILE_POSS %r15, %r12                                 # save tile possibilities pointer to callee saved register
    movq $4, %rbx                                           # use as counter and side value, 4 sides to check

    G_ENT %rcx %r13, %r15                                   # get entropy of current tile
    cmp $0, %rcx                                            # if tile has no possibilities
    je side_loop_end                                        # skip checking

    side_loop:
        # loop housekeeping
        cmp $0, %rbx                                        # if counter is 0
        je side_loop_end                                    # end loop

        dec %rbx                                            # decrease counter

        G_SIDE_TO_SKIP %cl, %r13, %r14                      # get the side to skip                  
        cmp %rcx, %rbx                                      # if side to skip is the same as the current side
        je side_loop                                        # skip current iteration

        # actual code to loop

        # find possible possibilities on the given side
        GP_RULESET %rdi, %r12                               # get pointer to ruleset
        G_POSS %r8, %r13, %r15                              # get possibilities of current tile
        popcnt %r8, %r9                                     # get entropy (amount of possibilities) and use as counter
        movq $0, %r10                                       # use as resulting possible possibilities on the given side
        movq $0, %rsi                                       # use as possibility index counter
        possibility_loop:
            cmp $0, %r9                                     # if counter is 0 stop loop
            je possibility_loop_end

            bsf %r8, %rcx                                   # get index of first 1 bit
            add %rcx, %rsi                                  # add bit index to total for the correct possibility index

            # get possible possibilities on the given side of the current module

            movq $4, %rax                                           # 4 since there are 4 sides (west, east, south, north)
            mul %rsi                                                # 4 * module
            add %rbx, %rax                                          # add side to rax for index to find possibilities

            orq 1(%rdi, %rax, 8), %r10                              # union possible possibilities of this module with total

            # shift possibilities for next bsf instruction

            inc %rcx                                        # bit index + 1
            inc %rsi                                        # since rcx got incremented
            shr %cl, %r8                                    # shift to after the first 1 bit

            dec %r9                                         # decrease counter
            jmp possibility_loop

        possibility_loop_end:

        # intersect neighbour with possible possibilities

        push %r10                                           # save possible possibilities

        PARAMS3 %r12, %r13, %rbx                            # wfc pointer, tile index, side
        call GetTileNeighbour

        pop %r10                                            # restore possible possibilities
        push %rax                                           # save neighbour tile index

        PARAMS3 %r12, %rax, %r10
        call IntersectTilePossibilities

        pop %rdx                                            # restore neighbour tile index

        # if changed add neighbour to check queue

        cmp $0, %rax                                        # if intersect did not change neighbour
        je side_loop                                        # skip putting the neighbour in check list

        movq %rbx, %rax
        xorq $1, %rax                                       # get opposite side

        PARAMS3 %r12, %rdx, %rax                            # wfc pointer, neighbour index, opposite side
        call EnqCollQueue

        jmp side_loop

    side_loop_end:

    GP_COLL_QUEUE_INF %r8, %r12
    S_SIDE_TO_SKIP $-1, %r13, %r8                           # clear side to skip so tile can be put in queue again

    pop %rbx
    pop %r15
    pop %r14
    pop %r13
    pop %r12

    EPILOGUE
