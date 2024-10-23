
.equ LEFT_BUTTON, 0
.equ RIGHT_BUTTON, 1
.equ MIDDLE_BUTTON, 2

.data 

pressed_buttons: .skip 3 # left right middle

# mouse position
mouse_x: .quad 0
mouse_y: .quad 0

mouse_past_x: .quad 0
mouse_past_y: .quad 0

.text

#----------------------------------------------------------------------------------------------------------
# buttons
#----------------------------------------------------------------------------------------------------------

# handles the windows msg where the given mouse button is pressed
# PARAMS:
# %rcx =   the button that got pressed
# RETURNS:
# void
HandleButtonDownMsg:
    PROLOGUE
    leaq pressed_buttons(%rip), %rdx                # get pointer to pressed buttons

    movb $1, (%rdx, %rcx)                           # set pressed button to true
    call ButtonPressed

    EPILOGUE

# handles the windows msg where the given mouse button is released
# PARAMS:
# %rcx =    the button that got released
# RETURNS:
# void
HandleButtonUpMsg:
    PROLOGUE
    leaq pressed_buttons(%rip), %rdx                # get pointer to pressed keys

    movb $0, (%rdx, %rcx)                           # set pressed key to false in pressed keys
    call ButtonReleased

    EPILOGUE

# gets called when the given button is pressed
# PARAMS:
# %rcx =    button that got pressed
# RETURNS:
# void
ButtonPressed:
    PROLOGUE

    EPILOGUE

# gets called when the given mouse button is released
# PARAMS:
# %rcx =    keycode of released key
# RETURNS:
# void
ButtonReleased:
    PROLOGUE

    EPILOGUE

#----------------------------------------------------------------------------------------------------------
# position
#----------------------------------------------------------------------------------------------------------

# handles the windows msg where the mouse is moved
# PARAMS:
# %rcx =    new x position
# %rdx =    new y position
# RETURNS:
# void
HandleMouseMoveMsg:
    PROLOGUE

    movq %rcx, mouse_x(%rip)
    movq %rdx, mouse_y(%rip)

    call MouseMove

    EPILOGUE

# handles setting the mouse pos using SetCursorPos, and makes sure the listener doesn't break
# PARAMS:
# %rcx =    new x position
# %rdx =    new y position
# RETURNS:
# void
HandleMouseSetPos:
    PROLOGUE
    # put new pos in both past and current pos
    movq %rcx, mouse_x(%rip)
    movq %rdx, mouse_y(%rip)
    movq %rcx, mouse_past_x(%rip)
    movq %rdx, mouse_past_y(%rip)

    EPILOGUE

# updates the mouse listener at the end of the frame
HandleMouseEndFrame:
    PROLOGUE

    # move last position to past position
    movq mouse_x(%rip), %r8
    movq %r8, mouse_past_x(%rip)
    movq mouse_y(%rip), %r8
    movq %r8, mouse_past_y(%rip)

    EPILOGUE

# gets called when the mouse is moved
# PARAMS:
# void
# RETURNS:
# void
MouseMove:
    PROLOGUE

    EPILOGUE
