
.include "game/map.s"
.include "game/pieces.s"
.include "game/entities.s"
.include "game/physics.s"

.data

player_start: .float 8, 8
test_start1: .float 9, 9
test_start2: .float 10, 10
test_start3: .float 7, 7
test_start4: .float 6, 6

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

    # make loaded tiles list
    PARAMS1 $10
    call MakeList
    movq %rax, loaded_tiles(%rip)

    PARAMS3 map_wfc(%rip), $0, $10
    call CollapseToTile

    #----------------------------------------------------------------------------------------------------------
    # Setup pathfinding
    #----------------------------------------------------------------------------------------------------------

    call SetupPathFinding

    #----------------------------------------------------------------------------------------------------------
    # Setup entities
    #----------------------------------------------------------------------------------------------------------

    movsd player_start(%rip), %xmm0
    call MakePlayer

    movsd test_start1(%rip), %xmm0
    #call MakeMonster

    movsd test_start2(%rip), %xmm0
    call MakeSpider

    movsd test_start3(%rip), %xmm0
    call MakeRavager

    EPILOGUE
