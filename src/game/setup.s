
.equ WFC_WIDTH, 50
.equ WFC_HEIGHT, 50
.equ WFC_TILE_COUNT, WFC_WIDTH * WFC_HEIGHT

.data 

map_wfc: .quad 0 # the pointer to the wfc running the map

map_data: .skip WFC_TILE_COUNT

player_cam:
    .float 7.5, 2.5, 7.5 # position
    .float 0 # angle x
    .float 0 # angle y
    .float 0 # fov
    .float 0 # aspect ratio (view width / view height)

mouse_sensitivity: .float 500 # low numbers mean high sensitivity
walk_speed: .float 0.1 # low numbers mean high sensitivity

.text

# setup game related things
SetupGame:
    PROLOGUE

    #----------------------------------------------------------------------------------------------------------
    # Setup wfc
    #----------------------------------------------------------------------------------------------------------

    call CalculatePieces

    call CalculateRuleset

    # pack width and height
    movq $WFC_WIDTH, %rcx
    shl $32, %rcx
    orq $WFC_HEIGHT, %rcx

    PARAMS2 %rcx, wfc_ruleset(%rip)
    leaq WfcOnChange(%rip), %r8
    leaq piece_weights(%rip), %r9
    call CreateWfc

    movq %rax, map_wfc(%rip)

    PARAMS1 %rax
    call CollapseAllTiles

    call PrintWfc

    #----------------------------------------------------------------------------------------------------------
    # Setup PlayerCam
    #----------------------------------------------------------------------------------------------------------

    leaq player_cam(%rip), %rcx

    # set camera fov to half PI (90 degrees)
    movss f_pi(%rip), %xmm0
    movss f_2(%rip), %xmm1
    divss %xmm1, %xmm0
    movss %xmm0, 20(%rcx)

    # calculate aspect ratio of the camera

    # get camera size in ints
    movq $VIEW_WIDTH, %r8
    movq $VIEW_HEIGHT, %r9

    # convert to floats
    cvtsi2ss %r8, %xmm0
    cvtsi2ss %r9, %xmm1

    # aspect ratio = width / height
    divss %xmm1, %xmm0
    movss %xmm0, 24(%rcx)

    EPILOGUE
