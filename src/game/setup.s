
.include "game/map.s"
.include "game/pieces.s"
.include "game/entities.s"
.include "game/physics.s"

.data

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
