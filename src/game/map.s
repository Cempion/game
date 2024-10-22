.equ WFC_WIDTH, 20
.equ WFC_HEIGHT, 20
.equ WFC_TILE_COUNT, WFC_WIDTH * WFC_HEIGHT

.equ LOAD_DISTANCE, 32

.data 

map_wfc: .quad 0 # the pointer to the wfc running the map

map_data: .skip WFC_TILE_COUNT

loaded_tiles: .quad 0 # list used to pass to the wfc

.text

# gets the block data at the given coordinates
# PARAMS:
# %rcx =    x_position as a 4 byte integer
# %rdx =    z_position as a 4 byte integer
# RETURNS:
# %rax =    block data at the given position
GetBlockData:
    PROLOGUE

    # loop the gives pos to map space

    # save input
    movq %rcx, %r8
    movq %rdx, %r9

    # calculate map width in blocks
    movq $PIECE_SIZE, %rax
    movq $WFC_WIDTH, %rdx
    mulq %rdx
    movq %rax, %rcx

    LOOP_LONG %r8d, %rcx            # loop x in map space

    # calculate map height in blocks
    movq $PIECE_SIZE, %rax
    movq $WFC_HEIGHT, %rdx
    mulq %rdx
    movq %rax, %rcx

    LOOP_LONG %r9d, %rcx            # loop y in map space

    # get piece at looped position

    movq $PIECE_SIZE, %rcx

    # get x_pos in piece & block coordinates
    movq $0, %rdx                   # prepare for div
    movq %r8, %rax                  # looped x_position
    div %rcx                        # x_pos / piece size
    movq %rax, %r10                 # store result
    movq %rdx, %rdi                 # store remainder

    # get z_pos in piece & block coordinates
    movq $0, %rdx                   # prepare for div
    movq %r9, %rax                  # looped z_position
    div %rcx                        # z_pos / piece size
    movq %rax, %r11                 # store result
    movq %rdx, %rsi                 # store remainder

    # get index of piece in map
    movq $WFC_WIDTH, %rdx           # map width
    #movq %r11, %rax                # z_pos already in rax              
    mul %rdx                        # z_pos * width
    add %rax, %r10                  # z_pos * width + x_pos

    # get piece
    leaq map_data(%rip), %r11       # get pointer
    movzb (%r11, %r10), %r10        # get piece index

    # get block at looped position

    # get pointer to needed piece data
    movq $PIECE_VOLUME, %rax        # get piece volume (size^2)
    mulq %r10                       # piece_volume * piece_index
    leaq piece_data(%rip), %r10     # get pointer
    addq %rax, %r10                 # add offset to pointer for correct piece

    # get index of block in piece
    movq %rsi, %rax                 # block_z_pos           
    mul %rcx                        # block_z_pos * piece width
    add %rax, %rdi                  # block_z_pos * width + block_x_pos

    # get block in piece
    movzb (%r10, %rdi), %r10        # get block index

    # get block data
    leaq blocks(%rip), %r11         # get pointer
    movw 1(%r11, %r10, 2), %ax      # get block data
    andq $0xFFFF, %rax              # zero out the higher 6 bytes

    EPILOGUE

.macro BLOCK_TO_PIECE_POS pos
    cmp $0, \pos                    # if pos is not negative
    jge skip_\@                     # skip correction

    movq $PIECE_SIZE, %rcx
    dec %rcx
    sub %rcx, \pos

    skip_\@:
    movq $PIECE_SIZE, %rcx
    movq \pos, %rax
    cqto
    idiv %rcx
    mov %rax, \pos
.endm

# gets all the tiles that should be loaded in a list
# PARAMS:
# %rcx  =   pointer to the list to add the loaded tiles to
# RETURNS:
# %rax =    pointer to list where the loaded tiles got added to
GetLoadedTiles:
    PROLOGUE
    push %r12
    push %r13
    movq %rcx, %r12

    movq entity_count(%rip), %r13               # get entity count and use as counter
    movq $1, %r13
    1: # entity loop
        cmp $0, %r13                                # if counter is 0
        je 2f                                       # exit loop
        decq %r13                                   # decrement counter

        # get position of this entity in ints
        leaq entity_positions(%rip), %rcx
        movups (%rcx, %r13, 8), %xmm0

        roundps $1, %xmm0, %xmm0
        cvttps2dq %xmm0, %xmm0

        movd %xmm0, %rdx                            
        movsxd %edx, %rcx                           # x pos
        sar $32, %rdx                               # z pos

        PARAMS3 %rcx, %rdx, %r12
        call AddLoadedTiles
        movq %rax, %r12                             # in case list grew

        jmp 1b
    2: # exit loop

    movq %r12, %rax                             # return list

    pop %r13
    pop %r12
    EPILOGUE

# adds the tiles loaded at the given position to the given list, does not add duplicates.
# PARAMS:
# %rcx =    x_position as a 4 byte integer
# %rdx =    z_position as a 4 byte integer
# %r8  =    pointer to the list to add the loaded tiles to
# RETURNS:
# %rax =    pointer to list where the loaded tiles got added to
AddLoadedTiles:
    PROLOGUE
    push %r8
    push %r12
    push %r13
    push %r14
    push %r15
    push %rbx

    movq %rcx, %r12             # x pos      
    movq %rdx, %r13             # z pos

    # get maximum position of grid
    addq $LOAD_DISTANCE, %r12 
    addq $LOAD_DISTANCE, %r13

    # get minimum position of grid
    movq $LOAD_DISTANCE, %rcx
    shl $1, %rcx
    movq %r12, %r14
    movq %r13, %r15
    subq %rcx, %r14
    subq %rcx, %r15

    # convert min max to piece positions
    BLOCK_TO_PIECE_POS %r12
    BLOCK_TO_PIECE_POS %r13

    BLOCK_TO_PIECE_POS %r14
    BLOCK_TO_PIECE_POS %r15

    dec %r14                    # correct for loop
    dec %r15                    # correct for loop

    # loop over the grid defined by min and max pos

    1: # x loop
        cmpq %r14, %r12         # if counter equals minimum x (exclusive)
        je 2f                   # exit loop

        movq %r13, %rbx         # use as y loop counter
        3: # y loop
            cmpq %r15, %rbx         # if counter equals minimum y (exclusive)
            je 4f                   # exit loop

            # get tile index

            PARAMS3 map_wfc(%rip), %r12, %rbx
            call GetTileIndex

            movq -8(%rbp), %rcx     # get pointer to list
            push %rax               # save tileIndex on stack

            # check if tile index is already in list

            PARAMS2 %rcx, %rax       
            call IndexOfList        

            pop %rdx                # restore tileIndex
            decq %rbx               # decrement counter

            cmp $-1, %rax           # if tileIndex is already in list
            jne 3b                  # continue loop without adding it to list

            PARAMS2 -8(%rbp), %rdx
            call AddToList
            movq %rax, -8(%rbp)     # in case list grew

            jmp 3b
        4: # end y loop

        dec %r12                # decrement counter
        jmp 1b
    2: # end x loop

    movq -8(%rbp), %rax         # return pointer to list

    pop %rbx
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    EPILOGUE
