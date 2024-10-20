
# sockets
.equ PATH, 0
.equ WALL, 1

.equ PIECE_SIZE, 16 
.equ PIECE_VOLUME, PIECE_SIZE * PIECE_SIZE

# block types
.equ ERROR, 0
.equ DOPEN, 1
.equ DWALL, 2

.data

socket_connections: # represents to which socket the socket of that index can connect to, keep it symmetric or the wfc will break!!!
            .byte PATH
            .byte WALL

piece_sockets: .byte 11 # used to calculate the wfc ruleset
            .byte WALL, WALL, WALL, WALL

            .byte PATH, PATH, WALL, WALL
            .long 0

            .byte WALL, PATH, WALL, PATH
            .long 0
            .long 0
            .long 0

            .byte PATH, PATH, WALL, PATH
            .long 0
            .long 0
            .long 0

piece_weights: 
            .long 10
            .long 5, 5
            .long 3, 3, 3, 3
            .long 1, 1, 1, 1

wfc_ruleset: .quad 0 # a pointer to the ruleset, first a byte for the amount of pieces, then for each piece 4 quads

piece_chars: .byte 178 # used when printing the map using printwfc
        .byte 32
        .byte 196, 179
        .byte 192, 218, 191, 217
        .byte 193, 195, 194, 180

piece_data: # stores the block data of each piece, used for rendering and collision
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR
    .byte ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR, ERROR

    # wall
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL

    # straight
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DOPEN, DOPEN, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DOPEN, DOPEN, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DOPEN, DOPEN, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DOPEN, DOPEN, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL

    .skip PIECE_VOLUME 

    # corner
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL

    .skip PIECE_VOLUME 

    .skip PIECE_VOLUME 

    .skip PIECE_VOLUME 

    # split
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DWALL, DWALL, DOPEN, DOPEN, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN, DOPEN
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL
    .byte DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL, DWALL

    .skip PIECE_VOLUME 

    .skip PIECE_VOLUME 

    .skip PIECE_VOLUME 


blocks: .byte 3 # stores each block data
    # 1 bit isWall, 5 bits wall texture, 5 bits floor texture, 5 bits ceiling texture
    #           |    |    |
    .word 0b0000000000000000
    #           |    |    |
    .word 0b0000100001000010
    .word 0b0000100001000011

.text 

#----------------------------------------------------------------------------------------------------------
# RuleSet
#----------------------------------------------------------------------------------------------------------

.macro GETSOCKET dest, piece, side, pointer
    movq \pointer, \dest
    add \side, \dest                        # add offset to pointer
    movzb 1(\dest, \piece, 4), \dest        # get socket of piece at side
.endm

# makes and calculates the wfc_ruleset based on the sockets stored in piece_sockets
CalculateRuleset:
    PROLOGUE

    # allocate ruleset

    movzb piece_sockets(%rip), %rcx           # get amount of pieces
    shl $5, %rcx                            # multiply by 32 for 4 quads per piece
    add $1, %rcx                            # 1 byte for the amount of pieces
    SHADOW_SPACE
    call malloc                             # allocate space for ruleset
    movq %rax, wfc_ruleset(%rip)

    # initialize all values to 0

    movq $0, %rax                           # value to set each quad too
    movzb piece_sockets(%rip), %rcx           # get amount of pieces
    shl $2, %rcx                            # multiply by 4 (4 quads per piece)
    movq wfc_ruleset(%rip), %rdi            # pointer to ruleset
    add $1, %rdi                            # move pointer to after piece count byte
    rep stosq                               # fill all the quads in ruleset with 0

    movzb piece_sockets(%rip), %rsi           # get amount of pieces
    movq wfc_ruleset(%rip), %rdx            # get pointer to wfc_ruleset
    movb %sil, (%rdx)                       # put piece count in ruleset

    # calculate ruleset

    leaq piece_sockets(%rip), %r10            # get pointer to sockets

    1: # loop over every piece
        cmp $0, %rsi                        # if counter is 0
        je 2f                               # exit loop
        dec %rsi                            # decrease counter

        movq $4, %rdx                       # use as side counter
        3: # loop over every side
            cmp $0, %rdx                        # if counter is 0
            je 4f                               # exit loop
            dec %rdx                            # decrease counter

            GETSOCKET %r9, %rsi, %rdx, %r10     # get socket of current piece at the current side and put in r9
            leaq socket_connections(%rip), %rcx
            movzb (%rcx, %r9), %r9              # get socket the current socket can connect to
            
            movzb piece_sockets(%rip), %r8        # use as piece counter
            5: # loop over every piece (again)
                cmp $0, %r8                         # if counter is 0
                je 6f                               # exit loop
                dec %r8                             # decrease counter
                
                movq %rdx, %rdi
                xorq $1, %rdi                       # get opposide side (side ^ 1)
                GETSOCKET %r11, %r8, %rdi, %r10     # get socket of the other piece at the opposide side and put in r11

                cmp %r9, %r11                       # if sockets are not the same
                jne 5b                              # continue loop

                # add piece to possible pieces on this side

                movb %r8b, %cl                      # move piece index to cl for shr
                movq $1, %rax                      
                shl %cl, %rax                       # get a quad with the only 1 bit being the module that can connect

                movq %rsi, %rcx
                shl $2, %rcx                        # multiply by 4
                add %rdx, %rcx                      # add size to get index of the rule to union
                shl $3, %rcx                        # multiply by 8 for index in bytes
                add $1, %rcx                        # add 1 for the size byte
                add wfc_ruleset(%rip), %rcx         # get pointer to quad to union

                orq %rax, (%rcx)                    # add piece to possible pieces on this side

                jmp 5b
            6: # exit loop

            jmp 3b
        4: # exit loop

        jmp 1b
    2: # exit loop

    EPILOGUE

#----------------------------------------------------------------------------------------------------------
# OnChange
#----------------------------------------------------------------------------------------------------------

# the function that gets called when a tile get collapsed or uncollapsed
# PARAMS:
# %rcx =    tile index
# %rdx =    tile possibilities
# RETURNS:
# void
WfcOnChange:
    PROLOGUE
    leaq map_data(%rip), %r8

    popcnt %rdx, %rsi
    cmp $0, %rsi                        # if entropy is 0
    je 1f                               # go to special case

    cmp $1, %rsi                        # if entropy is 0
    je 2f                               # add piece to map

    jmp 3f                              # dont do anything

    1: # entropy = 0
        movb $0, (%r8, %rcx)            # move error piece into map
        jmp 3f

    2: # entropy = 1
        bsf %rdx, %rax                  # get index of piece
        inc %rax                        # correct for 0 entropy default

        movb %al, (%r8, %rcx)           # move piece into map

    3: # end
    EPILOGUE

.equ space, 0x20
.equ new_line, 0x0a

#----------------------------------------------------------------------------------------------------------
# Print Wfc
#----------------------------------------------------------------------------------------------------------

PrintWfc:
    PROLOGUE
    lea map_data(%rip), %rcx            # get pointer to map data
    lea piece_chars(%rip), %r10         # get pointer to chars

    # calculate string size

    movq $WFC_TILE_COUNT, %rax          # put tile count into rax to calculate string size
    add $WFC_HEIGHT, %rax               # add height to account for new line
    add $1, %rax                        # add space for null terminator
    movq %rax, %r8                      # move string size to free rax

    # allocate space on stack

    sub %r8, %rsp                       # move stack pointer to make space
    movq %rsp, %rax                     # move stack pointer to rax to do a modulo
    movq $0, %rdx                       # make 0 to do div
    movq $8, %r9
    div %r9                             # stack pointer % 8
    sub %rdx, %rsp                      # allign stack

    # make string

    movq $0, %r9                        # use as string index

    movq $WFC_HEIGHT, %rsi              # use as y counter       
    1: # outer loop (y position)
        cmp $0, %rsi                    # if y is than 0
        jle 4f                          # exit loop
        dec %rsi                        # decrement counter

        movq $0, %rdi                   # use as x counter                  
        2: # inner loop (x position)
            cmp $WFC_WIDTH, %rdi            # if x is greater or equal to width
            jge 3f                          # exit loop

            # calculate tile index
            movq %rsi, %rax                 # put y in rax
            movq $WFC_WIDTH, %rdx
            mul %rdx                        # y * width
            add %rdi, %rax                  # x + y * width

            # put chars in string
            movzb (%rcx, %rax), %rax        # get piece index
            movb (%r10, %rax), %al          # get piece char
            movb %al, (%rsp, %r9)           # put in char
            inc %r9
            
            inc %rdi                        # increment counter
            jmp 2b
        3: # exit inner loop

        movb $new_line, (%rsp, %r9)         # put in new line
        inc %r9

        jmp 1b
    4: # exit outer loop

    movb $0, (%rsp, %r9)                    # put in null terminator
    
    # print string

    movq $0, %rax
    PARAMS1 %rsp
    SHADOW_SPACE
    call printf
    CLEAN_SHADOW

    EPILOGUE

#----------------------------------------------------------------------------------------------------------
# Piece Data
#----------------------------------------------------------------------------------------------------------

# calculate missing pieces based on templates (im not gonna make every rotation by hand)
CalculatePieces:
    PROLOGUE

    # straight

    # to correct for the way its written in this file
    PARAMS1 $2
    call FlipYPieceData

    PARAMS2 $2, $3
    call CopyPiece
    PARAMS2 $3, $1
    call RotatePiece

    # corner

    # to correct for the way its written in this file
    PARAMS1 $4
    call FlipYPieceData

    PARAMS2 $4, $5
    call CopyPiece
    PARAMS2 $5, $1
    call RotatePiece

    PARAMS2 $4, $6
    call CopyPiece
    PARAMS2 $6, $2
    call RotatePiece

    PARAMS2 $4, $7
    call CopyPiece
    PARAMS2 $7, $3
    call RotatePiece

    # split

    # to correct for the way its written in this file
    PARAMS1 $8
    call FlipYPieceData

    PARAMS2 $8, $9
    call CopyPiece
    PARAMS2 $9, $1
    call RotatePiece

    PARAMS2 $8, $10
    call CopyPiece
    PARAMS2 $10, $2
    call RotatePiece

    PARAMS2 $8, $11
    call CopyPiece
    PARAMS2 $11, $3
    call RotatePiece

    EPILOGUE

# copies the piece data and sockets of the first piece into the second piece.
# don't copy piece 0, since its reserved as the error piece
# PARAMS:
# %rcx =    piece index of the piece to copy
# %rdx =    piece index of the destination
# RETURNS:
# void
CopyPiece:
    PROLOGUE

    # copy sockets
    leaq piece_sockets(%rip), %r8
    movl -3(%r8, %rcx, 4), %r9d
    movl %r9d, -3(%r8, %rdx, 4)

    call CopyPieceData

    EPILOGUE

# copies the piece data of the first piece into the second piece
# PARAMS:
# %rcx =    piece index of the data to copy
# %rdx =    piece index of the destination
# RETURNS:
# void
CopyPieceData:
    PROLOGUE

    leaq piece_data(%rip), %r8                          # get pointer to piece data

    # get destination pointer
    movq $PIECE_VOLUME, %rax
    mulq %rdx                                           # piece volume * piece index
    movq %r8, %rdi
    addq %rax, %rdi                                     # add offset to base pointer
    
    # get source pointer
    movq $PIECE_VOLUME, %rax
    mulq %rcx                                           # piece volume * piece index
    movq %r8, %rsi
    addq %rax, %rsi                                     # add offset to base pointer

    movq $PIECE_VOLUME, %rcx                            # amount of bytes to copy
    rep movsb

    EPILOGUE

# flips the piece data and sockets of the given piece index on the X axis
# don't flip piece 0, since its reserved as the error piece
# PARAMS:
# %rcx =    piece index of the piece to flip on the X axis
# RETURNS:
# void
FlipXPiece:
    PROLOGUE

    leaq piece_sockets(%rip), %r8

    # get sockets to flip
    movb -3(%r8, %rcx, 4), %r9b
    movb -2(%r8, %rcx, 4), %r10b

    # flip sockets
    movb %r9b, -2(%r8, %rcx, 4)
    movb %r10b, -3(%r8, %rcx, 4)

    call FlipXPieceData

    EPILOGUE

# flips the piece data of the given piece index on the X axis
# PARAMS:
# %rcx =    piece index of the data to flip on the X axis
# RETURNS:
# void
FlipXPieceData:
    PROLOGUE

    # get pointer to data to flip
    movq $PIECE_VOLUME, %rax
    mulq %rcx                                           # piece volume * piece index

    leaq piece_data(%rip), %rdx                         # get pointer to piece data
    addq %rax, %rdx                                     # add offset to base pointer
    
    movq $PIECE_SIZE, %rcx                              # piece height, use as counter for Y loop
    1: # loop over Y
        cmp $0, %rcx                                    # if counter is 0
        je 2f                                           # end loop
        decq %rcx                                       # decrement counter

        movq $0, %r8                                    # use as index for first half
        movq $PIECE_SIZE, %r9                           # use as index for second half
        decq %r9                                        # decrement for last index

        movq $PIECE_SIZE, %r10                          # piece width
        shr $1, %r10                                    # piece width / 2, use as counter for X loop
        3: # loop over X
            cmp $0, %r10                                # if counter is 0
            je 4f                                       # end loop
            decq %r10                                   # decrement counter

            # get 2 values to flip
            movb (%rdx, %r8), %dil                     
            movb (%rdx, %r9), %sil

            # fip values
            movb %dil, (%rdx, %r9)
            movb %sil, (%rdx, %r8)

            incq %r8                                    # increment first half index
            decq %r9                                    # decrement second half index

            jmp 3b
        4: # end X loop

        add $PIECE_SIZE, %rdx                           # increment pointer to next row

        jmp 1b
    2: # end Y loop

    EPILOGUE

# flips the piece data and sockets of the given piece index on the Y axis
# don't flip piece 0, since its reserved as the error piece
# PARAMS:
# %rcx =    piece index of the piece to flip on the Y axis
# RETURNS:
# void
FlipYPiece:
    PROLOGUE

    leaq piece_sockets(%rip), %r8

    # get sockets to flip
    movb -1(%r8, %rcx, 4), %r9b
    movb (%r8, %rcx, 4), %r10b

    # flip sockets
    movb %r9b, (%r8, %rcx, 4)
    movb %r10b, -1(%r8, %rcx, 4)

    call FlipYPieceData

    EPILOGUE

# flips the piece data of the given piece index on the Y axis
# PARAMS:
# %rcx =    piece index of the data to flip on the Y axis
# RETURNS:
# void
FlipYPieceData:
    PROLOGUE

    # get pointer to data to flip
    movq $PIECE_VOLUME, %rax
    mulq %rcx                                           # piece volume * piece index

    leaq piece_data(%rip), %rcx                         # get pointer to piece data
    addq %rax, %rcx                                     # add offset to base pointer
    
    # setup loop
    movq %rcx, %r8                                      # use as pointer for first half
    movq %rcx, %r9                                      # use as pointer for second half
    addq $PIECE_VOLUME, %r9                             # go to next piece
    subq $PIECE_SIZE, %r9    	                        # go to last row of this piece

    movq $PIECE_SIZE, %rdx                              # piece height
    shr $1, %rdx                                        # piece height / 2, use as counter for Y loop
    1: # loop over Y
        cmp $0, %rdx                                    # if counter is 0
        je 2f                                           # end loop
        decq %rdx                                       # decrement counter
        
        movq $PIECE_SIZE, %rcx                          # piece width, use as counter for X loop
        3: # loop over X
            cmp $0, %rcx                                # if counter is 0
            je 4f                                       # end loop
            decq %rcx                                   # decrement counter

            # get 2 values to flip
            movb (%r8, %rcx), %dil                     
            movb (%r9, %rcx), %sil

            # fip values
            movb %dil, (%r9, %rcx)
            movb %sil, (%r8, %rcx)

            jmp 3b
        4: # end X loop 

        addq $PIECE_SIZE, %r8                           # increment to next row
        subq $PIECE_SIZE, %r9                           # decrement to last row

        jmp 1b
    2: # end Y loop

    EPILOGUE

# rotates the piece data and sockets of the given piece index, based on the given rotation
# don't rotate piece 0, since its reserved as the error piece
# PARAMS:
# %rcx =    piece index of the data to flip
# %rdx =    rotation (how many times to rotate 90 degrees clockwise)
# RETURNS:
# void
RotatePiece:
    PROLOGUE

    push %r12
    push %r13
    movq %rcx, %r12                                     # save piece index in callee saved register
    movq %rdx, %r13                                     # save rotation in callee saved register and use as loop counter

    1: # rotation loop
        cmp $0, %r13                                    # if counter is 0
        je 2f                                           # end loop
        decq %r13                                       # decrement loop counter

        # rotate sockets

        leaq piece_sockets(%rip), %rdi

        # get sockets
        movb -3(%rdi, %r12, 4), %cl
        movb -2(%rdi, %r12, 4), %dl
        movb -1(%rdi, %r12, 4), %r8b
        movb (%rdi, %r12, 4), %r9b

        # rotate sockets
        movb %cl, (%rdi, %r12, 4)
        movb %dl, -1(%rdi, %r12, 4)
        movb %r8b, -3(%rdi, %r12, 4)
        movb %r9b, -2(%rdi, %r12, 4)

        # rotate data

        PARAMS1 %r12
        call RotateClockwisePieceData

        jmp 1b
    2: # end rotation loop

    pop %r13
    pop %r12

    EPILOGUE

# used in rotation of piece data, modifies rax and rdx
.macro G_PIECE_DATA dest, x, y, pointer
    movq $PIECE_SIZE, %rax                      # piece width
    mul \y                                      # piece width * Y
    add \pointer, %rax                          # add pointer to offset
    movb (%rax, \x), \dest                      # get value at x, y
.endm

# used in rotation of piece data, modifies rax and rdx
.macro S_PIECE_DATA value, x, y, pointer
    movq $PIECE_SIZE, %rax                      # piece width
    mul \y                                      # piece width * Y
    add \pointer, %rax                          # add pointer to offset
    movb \value, (%rax, \x)                     # set value at x, y
.endm

# rotates the piece data of the given piece index 90 degrees clockwise
# PARAMS:
# %rcx =    piece index of the data to flip
# RETURNS:
# void
RotateClockwisePieceData:
    PROLOGUE

    # get pointer to data to flip
    movq $PIECE_VOLUME, %rax
    mulq %rcx                                           # piece volume * piece index

    leaq piece_data(%rip), %rcx                         # get pointer to piece data
    addq %rax, %rcx                                     # add offset to base pointer
    
    # setup loop (only loop over 1/4)

    movq $PIECE_SIZE, %rax                              # piece height
    movq $2, %r8
    movq $0, %rdx                                       # make 0 to prepare for div
    div %r8                                             # piece height / 2
    add %rdx, %rax                                      # add remainder to int division result (corrects for when size is uneven)

    movq %rax, %r9                                      # use as Y loop counter
    1: # loop over Y
        cmp $0, %r9                                     # if counter is 0
        je 2f                                           # end loop
        decq %r9                                        # decrement counter
        
        movq $PIECE_SIZE, %r8                           # piece width
        shr $1, %r8                                     # piece width / 2, use as counter for X loop
        3: # loop over X
            cmp $0, %r8                                 # if counter is 0
            je 4f                                       # end loop
            decq %r8                                    # decrement counter

            # rotate 4 blocks, r10 = next x, r11 = next y

            # get 1st value
            G_PIECE_DATA %dil, %r8, %r9, %rcx

            # get second position (x, y = y, -x)
            movq %r9, %r10                              # x
            movq $PIECE_SIZE, %r11                      # y
            subq %r8, %r11
            decq %r11                                   # correct for last index is size - 1

            # get & set second value
            G_PIECE_DATA %sil, %r10, %r11, %rcx
            S_PIECE_DATA %dil, %r10, %r11, %rcx

            # get third position (x, y = -x, -y)
            movq $PIECE_SIZE, %r10                      # x
            subq %r8, %r10
            decq %r10                                   # correct for last index is size - 1
            movq $PIECE_SIZE, %r11                      # y
            subq %r9, %r11
            decq %r11                                   # correct for last index is size - 1

            # get & set third value
            G_PIECE_DATA %dil, %r10, %r11, %rcx
            S_PIECE_DATA %sil, %r10, %r11, %rcx

            # get fourth position (x, y = -y, x)
            movq $PIECE_SIZE, %r10                      # x
            subq %r9, %r10
            decq %r10                                   # correct for last index is size - 1
            movq %r8, %r11                              # y

            # get & set fourth value
            G_PIECE_DATA %sil, %r10, %r11, %rcx
            S_PIECE_DATA %dil, %r10, %r11, %rcx

            # set first value
            S_PIECE_DATA %sil, %r8, %r9, %rcx

            jmp 3b
        4: # end X loop 

        jmp 1b
    2: # end Y loop

    EPILOGUE
