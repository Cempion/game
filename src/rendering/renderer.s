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
    PARAMS3 $GL_UNIFORM_BUFFER, $0, $24 
    leaq player_cam(%rip), %r9
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
