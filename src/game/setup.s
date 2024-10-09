
.data 

map_wfc: .quad 0 # the pointer to the wfc running the map

map_data: .skip WFC_TILE_COUNT

player_cam:
    .float 0, 0 # position
    .float 0 # angle x
    .float 0 # angle y
    .float 0 # fov
    .float 0 # aspect ratio (view width / view height)

mouse_sensitivity: .float 500 # low numbers mean high sensitivity

.text

# setup game related things
SetupGame:
    PROLOGUE

    #----------------------------------------------------------------------------------------------------------
    # Setup wfc
    #----------------------------------------------------------------------------------------------------------

    call CalculateRuleset

    PARAMS3 $WFC_WIDTH, $WFC_HEIGHT, wfc_ruleset(%rip)
    lea wfcOnChange(%rip), %r9
    call CreateWfc

    movq %rax, map_wfc(%rip)

    PARAMS1 %rax
    call CollapseAllTiles

    call printWfc

    #----------------------------------------------------------------------------------------------------------
    # Setup PlayerCam
    #----------------------------------------------------------------------------------------------------------

    leaq player_cam(%rip), %rcx

    # set camera fov to half PI (90 degrees)
    movss f_pi(%rip), %xmm0
    movss f_2(%rip), %xmm1
    divss %xmm1, %xmm0
    movss %xmm0, 16(%rcx)

    # calculate aspect ratio of the camera

    # get camera size in ints
    movq $VIEW_WIDTH, %r8
    movq $VIEW_HEIGHT, %r9

    # convert to floats
    cvtsi2ss %r8, %xmm0
    cvtsi2ss %r9, %xmm1

    # aspect ratio = width / height
    divss %xmm1, %xmm0
    movss %xmm0, 20(%rcx)

    EPILOGUE
