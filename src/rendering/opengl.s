
.equ GL_FALSE, 0
.equ GL_TRUE, 1

.equ GL_COLOR_BUFFER_BIT, 0x00004000

.equ GL_TRIANGLE_STRIP, 0x0005

.equ GL_FRAGMENT_SHADER, 0x8B30
.equ GL_VERTEX_SHADER, 0x8B31
.equ GL_COMPILE_STATUS, 0x8B81

.equ GL_LINK_STATUS, 0x8B82

.equ GL_INFO_LOG_LENGTH, 0x8B84

.equ GL_ARRAY_BUFFER, 0x8892
.equ GL_FLOAT, 0x1406

.equ GL_TEXTURE_2D, 0x0DE1
.equ GL_RGB, 0x1907
.equ GL_UNSIGNED_BYTE, 0x1401
.equ GL_TEXTURE0, 0x84c0

.equ GL_TEXTURE_MIN_FILTER, 0x2801
.equ GL_TEXTURE_MAG_FILTER, 0x2800
.equ GL_TEXTURE_WRAP_S, 0x2802
.equ GL_TEXTURE_WRAP_T, 0x2803
.equ GL_LINEAR, 0x2601
.equ GL_NEAREST, 0x2600
.equ GL_REPEAT, 0x2901
.equ GL_CLAMP_TO_BORDER, 0x812D
.equ GL_CLAMP_TO_EDGE, 0x812F

.equ GL_FRAMEBUFFER, 0x8D40
.equ GL_COLOR_ATTACHMENT0, 0x8CE0
.equ GL_FRAMEBUFFER_COMPLETE, 0x8CD5

.data

# 8 spaces to make space for the pointer which is a quad (8 bytes)
glCreateShader:             .asciz "        glCreateShader"
glShaderSource:             .asciz "        glShaderSource"
glCompileShader:            .asciz "        glCompileShader"
glGetShaderiv:              .asciz "        glGetShaderiv"
glGetShaderInfoLog:         .asciz "        glGetShaderInfoLog"
glDeleteShader:             .asciz "        glDeleteShader"

glCreateProgram:            .asciz "        glCreateProgram"
glAttachShader:             .asciz "        glAttachShader"
glLinkProgram:              .asciz "        glLinkProgram"
glGetProgramiv:             .asciz "        glGetProgramiv"
glGetProgramInfoLog:        .asciz "        glGetProgramInfoLog"
glUseProgram:               .asciz "        glUseProgram"
glGetUniformLocation:       .asciz "        glGetUniformLocation"
glProgramUniform1i:         .asciz "        glProgramUniform1i"

glGenBuffers:               .asciz "        glGenBuffers"
glBindBuffer:               .asciz "        glBindBuffer"
glBufferStorage:            .asciz "        glBufferStorage"

glGenVertexArrays:          .asciz "        glGenVertexArrays"
glBindVertexArray:          .asciz "        glBindVertexArray"
glVertexAttribPointer:      .asciz "        glVertexAttribPointer"
glEnableVertexAttribArray:  .asciz "        glEnableVertexAttribArray"

glActiveTexture:            .asciz "        glActiveTexture"

glGenFramebuffers:          .asciz "        glGenFramebuffers"
glBindFramebuffer:          .asciz "        glBindFramebuffer"
glFramebufferTexture2D:     .asciz "        glFramebufferTexture2D"
glCheckFramebufferStatus:   .asciz "        glCheckFramebufferStatus"

.text

.macro CHECK_OPENGL_ERROR
    call glGetError
    cmp $0, %rax
    je end_\@

    PARAMS1 %rax
    call exit

    end_\@:
.endm

.macro LOAD_METHOD name
    leaq \name(%rip), %rcx
    add $8, %rcx
    call wglGetProcAddress
    CHECK_RETURN_FAILURE $200
    movq %rax, \name(%rip)
.endm

# loads the needed opengl methods that are not included in windows
LoadOpenGlMethods:
    PROLOGUE
    SHADOW_SPACE

    LOAD_METHOD glCreateShader
    LOAD_METHOD glShaderSource
    LOAD_METHOD glCompileShader
    LOAD_METHOD glGetShaderiv
    LOAD_METHOD glGetShaderInfoLog
    LOAD_METHOD glDeleteShader

    LOAD_METHOD glCreateProgram
    LOAD_METHOD glAttachShader
    LOAD_METHOD glLinkProgram
    LOAD_METHOD glGetProgramiv
    LOAD_METHOD glGetProgramInfoLog
    LOAD_METHOD glUseProgram
    LOAD_METHOD glGetUniformLocation
    LOAD_METHOD glProgramUniform1i

    LOAD_METHOD glGenBuffers
    LOAD_METHOD glBindBuffer
    LOAD_METHOD glBufferStorage

    LOAD_METHOD glGenVertexArrays
    LOAD_METHOD glBindVertexArray
    LOAD_METHOD glVertexAttribPointer
    LOAD_METHOD glEnableVertexAttribArray

    LOAD_METHOD glActiveTexture

    LOAD_METHOD glGenFramebuffers
    LOAD_METHOD glBindFramebuffer
    LOAD_METHOD glFramebufferTexture2D
    LOAD_METHOD glCheckFramebufferStatus

    EPILOGUE
    