
.include "game/pieces.s"
.include "game/entities.s"
.include "game/physics.s"

.equ WFC_WIDTH, 50
.equ WFC_HEIGHT, 50
.equ WFC_TILE_COUNT, WFC_WIDTH * WFC_HEIGHT

.data 

map_wfc: .quad 0 # the pointer to the wfc running the map

map_data: .skip WFC_TILE_COUNT

player_start: .float 8, 8

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
    # Setup entities
    #----------------------------------------------------------------------------------------------------------

    movsd player_start(%rip), %xmm0
    call MakePlayer

    EPILOGUE
