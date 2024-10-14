
.data

drag: .float 0.2

.text

# updates positions and velocities of all entities based on a fixed delta time of 1
SimulateFrame:
    PROLOGUE
    push %r12
    push %r13

    movq entity_count(%rip), %r13       # get entity count and use as counter
    1: # entity loop
        cmpq $0, %r13                       # if counter is 0
        je 2f                               # exit loop
        decq %r13                           # decrement counter

        PARAMS1 %r13
        call SimulateEntity

        jmp 1b
    2: # exit loop

    pop %r13
    pop %r12
    EPILOGUE

# updates position and velocity of the given entity based on a fixed delta time of 1
# PARAMS:
# %rcx  =   entity index of the entity to simulate
# RETURNS:
# void
SimulateEntity:
    PROLOGUE

    # get pointers
    leaq entity_positions(%rip), %r9
    leaq entity_velocities(%rip), %r10
    leaq entity_accelerations(%rip), %r11

    # get position
    movsd (%r9, %rcx, 8), %xmm0
    # get velocity
    movsd (%r10, %rcx, 8), %xmm1
    # get acceleration
    movsd (%r11, %rcx, 8), %xmm2

    # formula to calculate acceleration 
    # a - c * v, c, 0

    # c * v
    movss drag(%rip), %xmm3
    shufps $0, %xmm3, %xmm3
    mulps %xmm1, %xmm3

    # max(c * v, c)
    movss drag(%rip), %xmm4

    # a - (c * v)
    subps %xmm3, %xmm2

    # max(a - max(c * v, c), 0)
    movss f_0(%rip), %xmm3

    # formula to calculate new position
    # 0.5 * a + v + p

    # a / 2
    movsd %xmm2, %xmm3
    movss f_2(%rip), %xmm4
    shufps $0, %xmm4, %xmm4
    divps %xmm4, %xmm3

    # (a / 2) + v
    addps %xmm1, %xmm3

    # (a / 2 + v) + p
    addps %xmm3, %xmm0

    # set new position
    movsd %xmm0, (%r9, %rcx, 8)

    # formula to calculate new velocity
    # a + v

    # a + v
    addps %xmm2, %xmm1

    # set new velocity
    movsd %xmm1, (%r10, %rcx, 8)

    # make acceleration 0
    xorps %xmm2, %xmm2
    movsd %xmm2, (%r11, %rcx, 8)

    EPILOGUE
