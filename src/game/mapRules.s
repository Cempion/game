.equ WFC_WIDTH, 50
.equ WFC_HEIGHT, 50
.equ WFC_TILE_COUNT, WFC_WIDTH * WFC_HEIGHT

.equ PATH, 0
.equ WALL, 1

.data

piece_sockets: .byte 11 # used to calculate the wfc ruleset
            .byte WALL, WALL, WALL, WALL

            .byte PATH, PATH, WALL, WALL
            .byte WALL, WALL, PATH, PATH

            .byte WALL, PATH, WALL, PATH
            .byte WALL, PATH, PATH, WALL
            .byte PATH, WALL, PATH, WALL
            .byte PATH, WALL, WALL, PATH

            .byte PATH, PATH, WALL, PATH
            .byte WALL, PATH, PATH, PATH
            .byte PATH, PATH, PATH, WALL
            .byte PATH, WALL, PATH, PATH

wfc_ruleset: .quad 0 # a pointer to the ruleset, first a byte for the amount of pieces, then for each piece 4 quads

piece_chars: .byte 178 # used when printing the map using printwfc
        .byte 32
        .byte 196, 179
        .byte 192, 218, 191, 217
        .byte 193, 195, 194, 180

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
wfcOnChange:
    PROLOGUE
    leaq piece_chars(%rip), %r8
    leaq map_data(%rip), %r9

    popcnt %rdx, %rsi
    cmp $0, %rsi                        # if entropy is 0
    je 1f                               # go to special case

    cmp $1, %rsi                        # if entropy is 0
    je 2f                               # add piece to map

    jmp 3f                              # dont do anything

    1: # entropy = 0
        movb (%r8), %al                 # move entropy 0 default into map
        movb %al, (%r9, %rcx)
        jmp 3f

    2: # entropy = 1
        bsf %rdx, %rax                  # get index of piece
        inc %rax                        # correct for 0 entropy default

        movb (%r8, %rax), %al           # move piece into map
        movb %al, (%r9, %rcx)

    3: # end
    EPILOGUE

.equ space, 0x20
.equ new_line, 0x0a

#----------------------------------------------------------------------------------------------------------
# Print Wfc
#----------------------------------------------------------------------------------------------------------

printWfc:
    PROLOGUE
    lea map_data(%rip), %rcx

    # calculate string size

    movq $WFC_TILE_COUNT, %rax          # put tile count into rax to calculate string size
    movq $3, %r9
    mul %r9                             # each tile is 3 chars long, SPACE CHAR SPACE
    add $WFC_HEIGHT, %rax                   # add height to account for new line
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

    movq $WFC_HEIGHT, %rsi                  # use as y counter
    dec %rsi         
    1: # outer loop (y position)
        cmp $0, %rsi                    # if y is than 0
        jl 4f                           # exit loop

        movq $0, %rdi                   # use as x counter                  
        2: # inner loop (x position)
            cmp $WFC_WIDTH, %rdi                # if x is greater or equal to width
            jge 3f                          # exit loop

            # calculate tile index
            movq %rsi, %rax                 # put y in rax
            movq $WFC_WIDTH, %rdx
            mul %rdx                        # y * width
            add %rdi, %rax                  # x + y * width

            # put chars in string
            movq (%rcx, %rax), %rax         # get piece char
            movq %rax, (%rsp, %r9)          # put in char
            inc %r9
            
            inc %rdi                        # increment counter
            jmp 2b
        3: # exit inner loop

        movq $new_line, (%rsp, %r9)         # put in new line
        inc %r9

        dec %rsi                            # decrement counter
        jmp 1b
    4: # exit outer loop

    movq $0, (%rsp, %r9)                    # put in null terminator
    
    # print string

    movq $0, %rax
    PARAMS1 %rsp
    SHADOW_SPACE
    call printf
    CLEAN_SHADOW

    EPILOGUE
