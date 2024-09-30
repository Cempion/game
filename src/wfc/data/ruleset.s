
# get pointer to ruleset
.macro GP_RULESET dest, wfcPointer
    movq 16(\wfcPointer), \dest                             # pointer to datastructure
.endm

# the maximum possibilities allowed by the tileset (the amount of given tiles)
.macro G_MAX_MODULES dest, dataPointer
    movb (\dataPointer), \dest
.endm

# get a quad that represents the possible modules on the given side of the given module
# PARAMS:
# %rcx =    pointer to wfc
# %rdx =    module
# %r8  =    side (0 = west, 1 = east, 2 = south, 3 = north : side xor 1 == opposite)
# RETURNS:
# %rax =    possible modules on the given side of the given module
GetPossibleModules:
    PROLOGUE
    GP_RULESET %rcx, %rcx                                   # get pointer to ruleset

    movq $4, %rax                                           # 4 since there are 4 sides (west, east, south, north)
    mul %rdx                                                # 4 * module
    add %r8, %rax                                           # the index where the possibilities can be found

    movq 1(%rcx, %rax, 8), %rax                             # copy result into rax (offset of 1 due to size byte)

    EPILOGUE
