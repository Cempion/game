
.data 

pressed_keys: .skip 256 #256 keys

.text

# handles the windows msg where the given key is pressed
# PARAMS:
# %rcx =    keycode of pressed key
# RETURNS:
# void
HandleKeyDownMsg:
    PROLOGUE
    leaq pressed_keys(%rip), %rdx                   # get pointer to pressed keys

    cmpb $0, (%rdx, %rcx)                           # if key is not pressed
    je 1f
    # key already pressed
    call KeyHold

    jmp 2f

    1: # key not already pressed
    movb $1, (%rdx, %rcx)                           # set pressed key to true in pressed keys
    call KeyPressed

    2: # end
    EPILOGUE

# handles the windows msg where the given key is released
# PARAMS:
# %rcx =    keycode of released key
# RETURNS:
# void
HandleKeyUpMsg:
    PROLOGUE
    leaq pressed_keys(%rip), %rdx                   # get pointer to pressed keys

    movb $0, (%rdx, %rcx)                           # set pressed key to false in pressed keys
    call KeyReleased

    EPILOGUE

# gets called when the given key is pressed
# PARAMS:
# %rcx =    keycode of pressed key
# RETURNS:
# void
KeyPressed:
    PROLOGUE

    # esc key
    cmp $0x1B, %ecx                                 # if esc key was not pressed
    jne 1f                                          # go to next

    PARAMS1 window_handle(%rip)
    call DestroyWindow                              # destroy window
    jmp 0f

    1:
    # alt key
    cmp $0x12, %ecx                                 # if alt key was not pressed
    jne 2f                                          # go to next

    call DisplayCursor                              # show cursor
    jmp 0f

    2:

    0:
    EPILOGUE

# gets called when the given key is held
# PARAMS:
# %rcx =    keycode of held key
# RETURNS:
# void
KeyHold:
    PROLOGUE

    EPILOGUE

# gets called when the given key is released
# PARAMS:
# %rcx =    keycode of released key
# RETURNS:
# void
KeyReleased:
    PROLOGUE

    # alt key
    cmp $0x12, %ecx                                 # if alt key was not released
    jne 1f                                          # go to next

    call HideCursor                                 # hide cursor
    jmp 0f

    1:

    0:
    EPILOGUE
