.equ WFC_WIDTH, 50
.equ WFC_HEIGHT, 50
.equ WFC_TILE_COUNT, WFC_WIDTH * WFC_HEIGHT

.data 

map_wfc: .quad 0 # the pointer to the wfc running the map

map_data: .skip WFC_TILE_COUNT

.text

# gets the block data at the given coordinates
# PARAMS:
# %rcx =    x_position as a 4 byte integer
# %rdx =    y_positon as a 4 byte integer
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

    # get y_pos in piece & block coordinates
    movq $0, %rdx                   # prepare for div
    movq %r9, %rax                  # looped y_position
    div %rcx                        # y_pos / piece size
    movq %rax, %r11                 # store result
    movq %rdx, %rsi                 # store remainder

    # get index of piece in map
    movq $WFC_WIDTH, %rdx           # map width
    #movq %r11, %rax                # y_pos already in rax              
    mul %rdx                        # y_pos * width
    add %rax, %r10                  # y_pos * width + x_pos

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
    movq %rsi, %rax                 # block_y_pos           
    mul %rcx                        # block_y_pos * piece width
    add %rax, %rdi                  # block_y_pos * width + block_x_pos

    # get block in piece
    movzb (%r10, %rdi), %r10        # get block index

    # get block data
    leaq blocks(%rip), %r11         # get pointer
    movw 1(%r11, %r10, 2), %ax      # get block data
    andq $0xFFFF, %rax              # zero out the higher 6 bytes

    EPILOGUE
