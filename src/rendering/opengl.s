# General Booleans
.equ GL_FALSE, 0
.equ GL_TRUE, 1

# Rendering Bits
.equ GL_COLOR_BUFFER_BIT, 0x00004000
.equ GL_DEPTH_BUFFER_BIT, 0x00000100
.equ GL_STENCIL_BUFFER_BIT, 0x00000400

# Primitives
.equ GL_TRIANGLES, 0x0004
.equ GL_TRIANGLE_STRIP, 0x0005
.equ GL_TRIANGLE_FAN, 0x0006
.equ GL_LINES, 0x0001
.equ GL_LINE_LOOP, 0x0002

# Shader Types and Status
.equ GL_FRAGMENT_SHADER, 0x8B30
.equ GL_VERTEX_SHADER, 0x8B31
.equ GL_COMPUTE_SHADER, 0x91B9
.equ GL_GEOMETRY_SHADER, 0x8DD9
.equ GL_TESS_CONTROL_SHADER, 0x8E88
.equ GL_TESS_EVALUATION_SHADER, 0x8E87
.equ GL_COMPILE_STATUS, 0x8B81
.equ GL_LINK_STATUS, 0x8B82
.equ GL_INFO_LOG_LENGTH, 0x8B84
.equ GL_SHADER_SOURCE_LENGTH, 0x8B88

# Buffers
.equ GL_ARRAY_BUFFER, 0x8892
.equ GL_ELEMENT_ARRAY_BUFFER, 0x8893
.equ GL_UNIFORM_BUFFER, 0x8A11
.equ GL_TEXTURE_BUFFER, 0x8C2A

# Buffer Usage
.equ GL_DYNAMIC_DRAW, 0x88E8
.equ GL_STATIC_DRAW, 0x88E4
.equ GL_STREAM_DRAW, 0x88E0

# Data Types
.equ GL_FLOAT, 0x1406
.equ GL_UNSIGNED_BYTE, 0x1401
.equ GL_INT, 0x1404
.equ GL_UNSIGNED_INT, 0x1405
.equ GL_SHORT, 0x1402
.equ GL_UNSIGNED_SHORT, 0x1403

# Texture Types
.equ GL_TEXTURE_1D, 0x0DE0
.equ GL_TEXTURE_2D, 0x0DE1
.equ GL_TEXTURE_3D, 0x806F
.equ GL_TEXTURE_1D_ARRAY, 0x8C18
.equ GL_TEXTURE_2D_ARRAY, 0x8C1A
.equ GL_TEXTURE_CUBE_MAP, 0x8513

# Texture Formats
.equ GL_R8, 0x8229
.equ GL_R8UI, 0x8232     
.equ GL_R16, 0x822A
.equ GL_R16UI, 0x8234
.equ GL_RED, 0x1903
.equ GL_RED_INTEGER, 0x8D94
.equ GL_RGB, 0x1907
.equ GL_RGBA, 0x1908
.equ GL_DEPTH_COMPONENT, 0x1902
.equ GL_STENCIL_INDEX, 0x1901

# Texture Alignment and Formats
.equ GL_UNPACK_ALIGNMENT, 0x0CF5

# Texture Units
.equ GL_TEXTURE0, 0x84C0
.equ GL_TEXTURE1, 0x84C1
.equ GL_TEXTURE2, 0x84C2
.equ GL_TEXTURE3, 0x84C3

# Texture Parameters
.equ GL_TEXTURE_MIN_FILTER, 0x2801
.equ GL_TEXTURE_MAG_FILTER, 0x2800
.equ GL_TEXTURE_WRAP_S, 0x2802
.equ GL_TEXTURE_WRAP_T, 0x2803
.equ GL_TEXTURE_WRAP_R, 0x8072
.equ GL_LINEAR, 0x2601
.equ GL_NEAREST, 0x2600
.equ GL_REPEAT, 0x2901
.equ GL_CLAMP_TO_BORDER, 0x812D
.equ GL_CLAMP_TO_EDGE, 0x812F

# Framebuffers
.equ GL_FRAMEBUFFER, 0x8D40
.equ GL_COLOR_ATTACHMENT0, 0x8CE0
.equ GL_DEPTH_ATTACHMENT, 0x8D00
.equ GL_STENCIL_ATTACHMENT, 0x8D20
.equ GL_FRAMEBUFFER_COMPLETE, 0x8CD5
.equ GL_FRAMEBUFFER_SRGB, 0x8DB9

# Miscellaneous
.equ GL_TEXTURE_SIZE, 0x8B5C
.equ GL_MAX_TEXTURE_SIZE, 0x0D33
.equ GL_MAX_CUBE_MAP_TEXTURE_SIZE, 0x851C
.equ GL_MAX_ARRAY_TEXTURE_LAYERS, 0x88FF

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
glBufferData:               .asciz "        glBufferData"
glBufferStorage:            .asciz "        glBufferStorage"
glBufferSubData:            .asciz "        glBufferSubData"
glBindBufferBase:           .asciz "        glBindBufferBase"

glGenVertexArrays:          .asciz "        glGenVertexArrays"
glBindVertexArray:          .asciz "        glBindVertexArray"
glVertexAttribPointer:      .asciz "        glVertexAttribPointer"
glEnableVertexAttribArray:  .asciz "        glEnableVertexAttribArray"

glActiveTexture:            .asciz "        glActiveTexture"
glTexImage3D:               .asciz "        glTexImage3D"

glGenFramebuffers:          .asciz "        glGenFramebuffers"
glBindFramebuffer:          .asciz "        glBindFramebuffer"
glFramebufferTexture2D:     .asciz "        glFramebufferTexture2D"
glCheckFramebufferStatus:   .asciz "        glCheckFramebufferStatus"

wglSwapIntervalEXT:         .asciz "        wglSwapIntervalEXT"

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
    LOAD_METHOD glBufferData
    LOAD_METHOD glBufferStorage
    LOAD_METHOD glBufferSubData
    LOAD_METHOD glBindBufferBase

    LOAD_METHOD glGenVertexArrays
    LOAD_METHOD glBindVertexArray
    LOAD_METHOD glVertexAttribPointer
    LOAD_METHOD glEnableVertexAttribArray

    LOAD_METHOD glActiveTexture
    LOAD_METHOD glTexImage3D

    LOAD_METHOD glGenFramebuffers
    LOAD_METHOD glBindFramebuffer
    LOAD_METHOD glFramebufferTexture2D
    LOAD_METHOD glCheckFramebufferStatus

    LOAD_METHOD wglSwapIntervalEXT

    EPILOGUE
    