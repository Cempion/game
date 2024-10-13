.include "opengl.s"
.include "setup.s"

.data

clear_color:
    .float 0 # red
    .float 0 # green
    .float 0 # blue
    .float 1 # alpha

.text

# renders the current frame and swaps the buffer so the frame is displayed
RenderFrame:
    PROLOGUE
    SHADOW_SPACE

    #----------------------------------------------------------------------------------------------------------
    # Pass data
    #----------------------------------------------------------------------------------------------------------

    # update camera ubo

    # make sure camera ubo is bound
    PARAMS2 $GL_UNIFORM_BUFFER, camera_ubo(%rip)
    call *glBindBuffer(%rip)

    # target, offset, size, pointer to data to write to ubo
    PARAMS3 $GL_UNIFORM_BUFFER, $0, $28 
    leaq player_cam(%rip), %r9
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

    # enable gamma correction
    PARAMS1 $GL_FRAMEBUFFER_SRGB
    call glEnable

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

    # disable gamma correction
    PARAMS1 $GL_FRAMEBUFFER_SRGB
    call glDisable

    CHECK_OPENGL_ERROR
    EPILOGUE
