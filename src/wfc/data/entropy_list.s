
# get entropy list pointer
.macro GP_ENT_LIST dest, wfcPointer
    movq 48(\wfcPointer), \dest                             # pointer to datastructure
.endm

# used by entropy list to get the pointer to the entropy sublist to modify, stores result in %rax
.macro G_ENT_OFFSET entropy, wfcPointer
    G_TILE_CNT %eax, \wfcPointer                            # get tile count
    incq %rax                                               # account for 4 bytes for size
    mov \entropy, %rdx

    cmp $0, %rdx                                            # if entropy is 0
    je skip_\@                                              # skip decrementing

    decq %rdx                                               # entropy 1 should be index 0

    skip_\@:                                    
    mulq %rdx                                               # get index to correct entropy

    shl $2, %rax                                            # multiply by 4

    add $4, %rax                                            # account for the first size value
.endm

# add the given tile to the entropy list at the given entropy, or does nothing if its already 
# in the entropy list (ignores entropy!)
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    tileindex to add
# %r8  =    entropy to add tile to
# RETURNS:
# void
AddToEntList:
    PROLOGUE

    GP_ENT_INDEXES %rdi, %rcx                               # get pointer to indexes
    IS_NOT_IN_ENT_LIST %rdx, %rdi
    jne 1f                                                  # if in entropy list return

    movq %rdx, %r9                                          # since the macros overwrite rdx                                 

    G_ENT_OFFSET %r8, %rcx                                  # get offset to correct entropy sublist
    GP_ENT_LIST %rdx, %rcx                                  # get pointer to data
    add %rax, %rdx                                          # pointer to correct entropy list

    movl (%rdx), %eax                                       # get the index to last tile
    movl %r9d, 4(%rdx, %rax, 4)                             # put tile in list, offset of 4 to account for size bytes

    incl (%rdx)                                             # increase size

    movl (%rdx), %edx                                       # the index the tile got added too
    S_ENT_INDEX %edx, %r9, %rdi                             # save index in entropy indexes
                            
    1:
    EPILOGUE

# remove the given tile from the entropy list, only use when sure the tile is in the given entropy list!
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    tileindex to remove
# %r8  =    entropy to remove tile from
# RETURNS:
# void
SubFromEntList:
    PROLOGUE
    movq %rdx, %r9                                          # since the macros overwrite rdx  

    G_ENT_OFFSET %r8, %rcx                                  # get offset to correct entropy sublist
    GP_ENT_LIST %rdx, %rcx                                  # get pointer to data
    add %rax, %rdx                                          # pointer to correct entropy list

    GP_ENT_INDEXES %r8, %rcx                                # get pointer to entropy indexes
    G_ENT_INDEX %r10d, %r9, %r8                             # get index of the tile to remove

    movl (%rdx), %eax                                       # get the index to last tile
    movl (%rdx, %rax, 4), %eax                              # get the last tile in the list
    movl %eax, (%rdx, %r10, 4)                              # overwrite the tile to remove with the last tile in the list

    decl (%rdx)                                             # decrease size          
    S_ENT_INDEX %r10d, %rax, %r8                            # set new entropy index of the moved tile            
    S_ENT_INDEX $0, %r9, %r8                                # clear index in entropy indexes for removed tile
                                              
    EPILOGUE

# get the next tile to collapse, which is randomly picked from the saved tiles with the lowest entropy 
# that have yet to get collapsed, or -1 if no tiles where found.
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# %rax =    tile index of a random tile with the lowest entropy that has yet to get collapsed
GetNextCollapse:
    PROLOGUE

    PARAMS1 %rcx
    call GetLowestEntListP
    cmp $-1, %rax                                            
    je 1f                                                   # if no pointer was found return -1

    movq %rax, %r8                                          # copy pointer to lowest sublist
    movl (%r8), %ecx                                        # get amount of tiles in sublist
    RANDOM %rax                                             # get random number

    movq $0, %rdx                                           # make 0 to prep for modulo
    div %rcx                                                # random % size of sublist

    movl 4(%r8, %rdx, 4), %eax                              # get and return the tile at the random index

    1: # end

    EPILOGUE

# get the pointer to the lowest entropy sublist with tiles (starting at entropy 2), or -1 if all 
# sublists are empty.
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# %rax =    the pointer to the lowest entropy sublist that contains tiles
GetLowestEntListP:
    PROLOGUE

    # get size in bytes of each sublist
    G_TILE_CNT %eax, %rcx                                   # get tile count
    incq %rax                                               # get entropy sublist length in 4bytes (increment to account for size bytes)

    movq $4, %r8                                            
    mul %r8                                                 # get size in bytes
    movq %rax, %r8                                          # copy to r8 to free rax

    # get max entropy
    GP_RULESET %r9, %rcx
    G_MAX_PIECES %r9b, %r9                                 # get max pieces (max entropy)

    movq $0, %rax                                           # use rax as entropy index counter
    GP_ENT_LIST %rdx, %rcx                                  # get pointer to entropy list

    1: #loop
    inc %rax                                                # increment entropy
    addq %r8, %rdx                                          # go to next sublist (starts at 1, entropy 2)

    cmpb %r9b, %al                                          
    je 2f                                                   # if entropy index == max entropy then we're at the end of the list

    cmpl $0, 4(%rdx)                                        # if no tiles in the list
    je 1b                                                   # continue to next loop

    movq %rdx, %rax                                         # value to return
    add $4, %rax                                            # add offset of 4 to pointer to account for size value
    jmp 3f                                                  # skip 2

    2:
    movq $-1, %rax

    3:
    EPILOGUE

# regen entropy list | should all be 0 (false)
# PARAMS:
# %rcx =    pointer to wfc
# RETURNS:
# void
RegenEntList:
    PROLOGUE

    GP_ENT_LIST %rdi, %rcx                                  # pointer to datastructure
    G_DATA_SIZE %ecx, %rdi                                  # size of data structure in bytes
    add $4, %rdi                                            # move pointer to after size value
    movq $0, %rax                                           # value to set
    rep stosl                                               # fill data structure with 0

    EPILOGUE
