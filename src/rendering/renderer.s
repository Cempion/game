.include "opengl.s"
.include "setup.s"

.data

clear_color:
    .float 0 # red
    .float 0 # green
    .float 0 # blue
    .float 1 # alpha

camera:
    .float 0, 0, 0 # position
    .float 0 # angle x
    .float 0 # angle y
    .float 0 # fov
    .float 0 # aspect ratio (view width / view height)

mouse_sensitivity: .float 500 # low numbers mean high sensitivity

.text

# renders the current frame and swaps the buffer so the frame is displayed
RenderFrame:
    PROLOGUE
    SHADOW_SPACE

    #----------------------------------------------------------------------------------------------------------
    # Pass data
    #----------------------------------------------------------------------------------------------------------

    # update camera ubo

    # update camera angles based on user input
    call DoCameraControls
    
    # update camera position & height based on entity with index 0
    leaq entity_positions(%rip), %rcx                   # get pointer to entity positions
    movl (%rcx), %eax                                   # get x position of entity 0
    movl 4(%rcx), %edx                                  # get z position of entity 0

    leaq entity_heights(%rip), %rcx                     # get pointer to entity heights
    movl (%rcx), %r8d                                   # get height of entity 0

    leaq camera(%rip), %r9
    movl %eax, (%r9)                                    # move x position to x position of camera
    movl %r8d, 4(%r9)                                   # move height to y position of camera
    movl %edx, 8(%r9)                                   # move z position to z position of camera

    # make sure camera ubo is bound
    PARAMS2 $GL_UNIFORM_BUFFER, camera_ubo(%rip)
    call *glBindBuffer(%rip)

    # target, offset, size, pointer to data to write to ubo
    PARAMS3 $GL_UNIFORM_BUFFER, $0, $28 
    leaq camera(%rip), %r9
    call *glBufferSubData(%rip)

    # update map texture

    # bind texture
    PARAMS1 $GL_TEXTURE1
    call *glActiveTexture(%rip)
    PARAMS2 $GL_TEXTURE_2D, map_texture(%rip)
    call glBindTexture

    # get pointer to data
    leaq map_data(%rip), %rsi

    # use correct settings for passing the data
    PARAMS2 $GL_UNPACK_ALIGNMENT, $1
    call glPixelStorei

    sub $8, %rsp                                # allign stack
    # target, level, xOffset, yOffset, width, height, external_format, type, data
    PARAMS9 $GL_TEXTURE_2D, $0, $0, $0, $WFC_WIDTH, $WFC_HEIGHT, $GL_RED_INTEGER, $GL_UNSIGNED_BYTE, %rsi
    SHADOW_SPACE
    call glTexSubImage2D
    add $80, %rsp                               # restore stack pointer

    # update entity data

    # update entity count uniform
    PARAMS1 render_shader_program(%rip)
    leaq entity_count_uniform(%rip), %rdx
    call *glGetUniformLocation(%rip)

    PARAMS3 render_shader_program(%rip), %rax, entity_count(%rip)
    call *glProgramUniform1i(%rip)

    # update position data
    PARAMS2 $GL_SHADER_STORAGE_BUFFER, entity_p_ssbo(%rip)
    call *glBindBuffer(%rip)

    movq entity_count(%rip), %rax       # get entity count
    shl $3, %rax                        # multiply by 8 for size in bytes
    leaq entity_positions(%rip), %rsi   # pointer to data
    PARAMS4 $GL_SHADER_STORAGE_BUFFER, $0, %rax, %rsi
    call *glBufferSubData(%rip)

    # update size data
    PARAMS2 $GL_SHADER_STORAGE_BUFFER, entity_s_ssbo(%rip)
    call *glBindBuffer(%rip)

    movq entity_count(%rip), %rax       # get entity count
    shl $2, %rax                        # multiply by 4 for size in bytes
    leaq entity_sizes(%rip), %rsi       # pointer to data
    PARAMS4 $GL_SHADER_STORAGE_BUFFER, $0, %rax, %rsi
    call *glBufferSubData(%rip)

    # update height data
    PARAMS2 $GL_SHADER_STORAGE_BUFFER, entity_h_ssbo(%rip)
    call *glBindBuffer(%rip)

    movq entity_count(%rip), %rax       # get entity count
    shl $2, %rax                        # multiply by 4 for size in bytes
    leaq entity_heights(%rip), %rsi     # pointer to data
    PARAMS4 $GL_SHADER_STORAGE_BUFFER, $0, %rax, %rsi
    call *glBufferSubData(%rip)

    # update texture data
    PARAMS2 $GL_SHADER_STORAGE_BUFFER, entity_t_ssbo(%rip)
    call *glBindBuffer(%rip)

    movq entity_count(%rip), %rax       # get entity count
    shl $1, %rax                        # multiply by 2 for size in bytes
    leaq entity_textures(%rip), %rsi    # pointer to data
    PARAMS4 $GL_SHADER_STORAGE_BUFFER, $0, %rax, %rsi
    call *glBufferSubData(%rip)

    #----------------------------------------------------------------------------------------------------------
    # Render Scene
    #----------------------------------------------------------------------------------------------------------

    # clear window buffer
    leaq clear_color(%rip), %r10
    movss (%r10), %xmm0
    movss 4(%r10), %xmm1
    movss 8(%r10), %xmm2
    movss 12(%r10), %xmm3
    call glClearColor

    PARAMS1 $GL_COLOR_BUFFER_BIT
    call glClear

    # render scene

    # bind framebuffer
    PARAMS2 $GL_FRAMEBUFFER, render_fbo(%rip)
    call *glBindFramebuffer(%rip)

    # set viewport to the size of the frame buffer
    PARAMS4 $0, $0, $RENDER_WIDTH, $RENDER_HEIGHT
    call glViewport

    # use render program
    PARAMS1 render_shader_program(%rip)
    call *glUseProgram(%rip)

    # bind full screen vao
    PARAMS1 full_vao(%rip)
    call *glBindVertexArray(%rip)

    # draw scene
    PARAMS3 $GL_TRIANGLE_STRIP, $0, $4
    call glDrawArrays

    # display scene to window

    # unbind framebuffer to use default
    PARAMS2 $GL_FRAMEBUFFER, $0
    call *glBindFramebuffer(%rip)

    # set viewport to size of the screen
    PARAMS4 $0, $0, screen_width(%rip), screen_height(%rip)
    call glViewport

    # use display program
    PARAMS1 display_shader_program(%rip)
    call *glUseProgram(%rip)

    # use display vao
    PARAMS1 display_vao(%rip)
    call *glBindVertexArray(%rip)

    # draw scene to window
    PARAMS3 $GL_TRIANGLE_STRIP, $0, $4
    call glDrawArrays

    # swap buffers
    PARAMS1 device_context(%rip)
    call SwapBuffers

    CHECK_OPENGL_ERROR
    EPILOGUE

#----------------------------------------------------------------------------------------------------------
# Camera Controls
#----------------------------------------------------------------------------------------------------------

# handles rotating the camera using the mouse
DoCameraControls:
    PROLOGUE

    # skip checking mouse input if alt is pressed or window is not focussed

    leaq pressed_keys(%rip), %rcx
    cmpb $0, 0x12(%rcx)                                 # if the alt key is not pressed
    jne 1f                                              # skip doing mouse controls

    call GetForegroundWindow                            # get window on the foreground
    cmpq %rax, window_handle(%rip)                      # if the game window is not on the foreground
    jne 1f                                              # skip doing mouse controls

    # do actual camera controls

    push %r12
    push %r13
    subq $16, %rsp                      # allocate space for floats
    movups %xmm6, (%rsp)
    subq $16, %rsp                      # allocate space for floats
    movups %xmm7, (%rsp)
    leaq camera(%rip), %r12                         # get pointer to player camera struct

    # calculate mouse movement this frame, %r8 = x, %r9 = y
    movq mouse_x(%rip), %r8
    sub mouse_past_x(%rip), %r8

    movq mouse_y(%rip), %r9
    sub mouse_past_y(%rip), %r9

    # turn delta mouse positions into floats
    cvtsi2ss %r8, %xmm0
    cvtsi2ss %r9, %xmm1

    # divide delta positions by 1000
    divss mouse_sensitivity(%rip), %xmm0
    divss mouse_sensitivity(%rip), %xmm1

    # get player angles
    movss 12(%r12), %xmm6
    movss 16(%r12), %xmm7

    # modify camara angle based on mouse movement
    subss %xmm0, %xmm6
    subss %xmm1, %xmm7

    # loop angle x in range 0 - 2pi
    movss %xmm6, %xmm0
    movss f_tau(%rip), %xmm1
    call fmodf

    movd %xmm0, %eax                                    # get bits of the float
    andl $0x80000000, %eax                              # and so only the sign bit is left
    cmp $0, %eax                                        # if the float is not negative
    je 2f                                               # skip correcting for minus

    movss f_tau(%rip), %xmm1
    addss %xmm1, %xmm0

    2: # float is not negative
    movss %xmm0, 12(%r12)

    # clamp angle y in range -half pi - half pi
    
    movss f_half_pi(%rip), %xmm0
    minps %xmm0, %xmm7

    movss f_min_half_pi(%rip), %xmm0
    maxps %xmm0, %xmm7

    movss %xmm7, 16(%r12)

    # put mouse cursor in the center of the screen

    # get screen size
    movq screen_width(%rip), %r12
    movq screen_height(%rip), %r13
    # devide by 2
    shr $1, %r12
    shr $1, %r13

    SHADOW_SPACE
    PARAMS2 %r12, %r13
    call SetCursorPos                                   # set mouse position to the center of the screen

    PARAMS2 %r12, %r13
    call HandleMouseSetPos                              # make sure the listener works

    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    movups -32(%rbp), %xmm6
    movups -48(%rbp), %xmm7
    1: # return
    EPILOGUE
