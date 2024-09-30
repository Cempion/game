
# get size of wfc in bytes
.macro G_SIZE dest, wfcPointer
    movl (\wfcPointer), \dest
.endm

# get tile count
.macro G_TILE_CNT dest, wfcPointer
    movl 4(\wfcPointer), \dest
.endm

# get width
.macro G_WIDTH dest, wfcPointer
    movl 8(\wfcPointer), \dest
.endm

# get height
.macro G_HEIGHT dest, wfcPointer
    movl 12(\wfcPointer), \dest
.endm

# get pointer to onchange subroutine
.macro GP_ONCHANGE dest, wfcPointer
    movq 24(\wfcPointer), \dest
.endm

# DATA STRUCTURE HELPERS
#----------------------------------------------------------------------------------------------------------

# gets the size in elements of the given data structure
.macro G_DATA_SIZE dest, pointer
    movl (\pointer), \dest
.endm

# gets the first tile in the queue, or trash if empty :)
.macro DEQ_QUEUE dest, dataPointer
    movl 4(\dataPointer), %eax                              # get read index
    movl 12(\dataPointer, %rax, 4), \dest                   # get first tile
    incl %eax                                               # increment read index
    
    # loop read index
    movq $0, %rdx                                           # clear so div can be used
    divl (\dataPointer)                                     # module read index with size
    movl %edx, 4(\dataPointer)                              # move result into read index
.endm

# adds a tile to the back of the queue
.macro ENQ_QUEUE tile, dataPointer
    movl 8(\dataPointer), %eax                              # get write index
    movl \tile, 12(\dataPointer, %rax, 4)                   # add tile
    incl %eax                                               # increment write index
    
    # loop write index
    movq $0, %rdx                                           # clear so div can be used
    divl (\dataPointer)                                     # module write index with size
    movl %edx, 8(\dataPointer)                              # move result into write index
.endm
