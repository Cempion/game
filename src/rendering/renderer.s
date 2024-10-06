.include "opengl.s"
.include "setup.s"

# renders the current frame and swaps the buffer so the frame is displayed
RenderFrame:
    PROLOGUE
    SHADOW_SPACE

    PARAMS3 $GL_TRIANGLE_STRIP, $0, $4
    call glDrawArrays
    CHECK_OPENGL_ERROR

    PARAMS1 device_context(%rip)
    call SwapBuffers

    EPILOGUE
