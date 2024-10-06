# how many pixels to render (rays to cast)
.equ RENDER_WIDTH, 16
.equ RENDER_HEIGHT, 9

# used to calculate the ratio between width and height for the view, decides which direction 
# the rays are cast and the final size of the view on the screen
.equ VIEW_WIDTH, 16
.equ VIEW_HEIGHT, 9

.data

render_shader_program: .quad 0 # the shader program responsible for rendering the game to the render texture (casts rays & stuff)

render_vao: .quad 0 # the vertex array object used while doing a rendering draw call

full_vbo: .quad 0 # the vertex buffer object containing a square that represents the entire screen

# xPos, yPos, xTexPos, yTexPos : 64 bytes in total
vbo_data:
    .float -1.0, -1.0, 0, 0
    .float -1.0,  1.0, 0, 1
    .float  1.0, -1.0, 1, 0
    .float  1.0,  1.0, 1, 1

render_fbo: .quad 0 # the framebuffer object used to render the scene too.
render_tex_2d: .quad 0 # the 2d texture used to render the scene in the render fbo.

# 8 spaces to make space for a quad
pass_vert_shader:       .asciz "        shaders\\vertex\\pass.vert"
display_frag_shader:    .asciz "        shaders\\fragment\\display.frag"

.text

read_mode: .asciz "rb"

#----------------------------------------------------------------------------------------------------------
# Setup
#----------------------------------------------------------------------------------------------------------

# initializes everything the renderer needs
SetupRenderer:
    PROLOGUE
    SHADOW_SPACE

    call LoadOpenGlMethods                  # load opengl methods that are not included in windows

    #----------------------------------------------------------------------------------------------------------
    # Shaders
    #----------------------------------------------------------------------------------------------------------

    # make pass through vertex shader
    leaq pass_vert_shader(%rip), %rcx
    add $8, %rcx                            # since first 8 bytes are the shader name
    movq $GL_VERTEX_SHADER, %rdx
    call MakeShader
    movq %rax, pass_vert_shader(%rip)       # store shader name

    # make display fragment shader
    leaq display_frag_shader(%rip), %rcx
    add $8, %rcx                            # since first 8 bytes are the shader name
    movq $GL_FRAGMENT_SHADER, %rdx
    call MakeShader
    movq %rax, display_frag_shader(%rip)    # store shader name

    # make shader program
    PARAMS2 pass_vert_shader(%rip), display_frag_shader(%rip)
    call MakeShaderProgram
    movq %rax, render_shader_program(%rip)  # store program name

    # clean up shader objects
    PARAMS1 pass_vert_shader(%rip)
    call *glDeleteShader(%rip)
    PARAMS1 display_frag_shader(%rip)
    call *glDeleteShader(%rip)

    PARAMS1 render_shader_program(%rip)
    call *glUseProgram(%rip)

    #----------------------------------------------------------------------------------------------------------
    # Vertex Array Object
    #----------------------------------------------------------------------------------------------------------
break:
    # generate render vao name
    PARAMS1 $1
    leaq render_vao(%rip), %rdx
    call *glGenVertexArrays(%rip)

    # bind render vao
    PARAMS1 render_vao(%rip)
    call *glBindVertexArray(%rip)

    # generate full square vbo name
    PARAMS1 $1
    leaq full_vbo(%rip), %rdx
    call *glGenBuffers(%rip)

    # bind to array buffer target
    PARAMS2 $GL_ARRAY_BUFFER, full_vbo(%rip)
    call *glBindBuffer(%rip)

    # fill full square vbo
    PARAMS2 $GL_ARRAY_BUFFER, $64
    leaq vbo_data(%rip), %r8
    movq $0, %r9
    call *glBufferStorage(%rip)

    # tell render vao how to read the vbo

    # position
    # index, element count, type, normalized, stride, offset
    PARAMS6 $0, $2, $GL_FLOAT, $GL_FALSE, $16, $0
    SHADOW_SPACE
    call *glVertexAttribPointer(%rip)
    add $48, %rsp                           # cleanup stack after passing parameters

    # texture coords
    # index, element count, type, normalized, stride, offset
    PARAMS6 $1, $2, $GL_FLOAT, $GL_FALSE, $16, $8
    SHADOW_SPACE
    call *glVertexAttribPointer(%rip)
    add $48, %rsp                           # cleanup stack after passing parameters

    # enable attributes
    PARAMS1 $0
    call *glEnableVertexAttribArray(%rip)
    PARAMS1 $1
    call *glEnableVertexAttribArray(%rip)

    #----------------------------------------------------------------------------------------------------------
    # Framebuffer
    #----------------------------------------------------------------------------------------------------------

    PARAMS1 $1
    leaq render_fbo(%rip), %rdx
    call *glGenFramebuffers(%rip)

    PARAMS2 $GL_FRAMEBUFFER, render_fbo(%rip)
    call *glBindFramebuffer(%rip)

    # make texture for frame buffer to draw too
    PARAMS1 $1
    leaq render_tex_2d(%rip), %rdx
    call glGenTextures

    PARAMS2 $GL_TEXTURE_2D, render_tex_2d(%rip)
    call glBindTexture

    sub $8, %rsp                            # allign stack
    # target, level, internal_format, width, height, border, external_format, type, data
    PARAMS9 $GL_TEXTURE_2D, $0, $GL_RGB, $RENDER_WIDTH, $RENDER_HEIGHT, $0, $GL_RGB, $GL_UNSIGNED_BYTE, $0
    SHADOW_SPACE
    call glTexImage2D
    add $80, %rsp                           # restore stack pointer

    # link texture to framebuffer

    sub $8, %rsp                            # allign stack
    # target, attachment, texture target, texture, level
    PARAMS5 $GL_FRAMEBUFFER, $GL_COLOR_ATTACHMENT0, $GL_TEXTURE_2D, render_tex_2d(%rip), $0
    SHADOW_SPACE
    call *glFramebufferTexture2D(%rip)
    add $48, %rsp                           # restore stack pointer

    # check if frame buffer is complete

    PARAMS1 $GL_FRAMEBUFFER
    call *glCheckFramebufferStatus(%rip)
    movq $0, %rcx                     
    cmp $GL_FRAMEBUFFER_COMPLETE, %rax      # if frame buffer is not complete
    cmovne %rcx, %rax                       # set rax to 0 to indicate return failure
    CHECK_RETURN_FAILURE $201

    # unbind framebuffer

    PARAMS2 $GL_FRAMEBUFFER, $0
    call *glBindFramebuffer(%rip)

    EPILOGUE


#----------------------------------------------------------------------------------------------------------
# Utils
#----------------------------------------------------------------------------------------------------------

# gets the string contained in the given file. used to give shader code to opengl.
# PARAMS:
# %rcx =    pointer to filepath string
# RETURNS:
# %rax =    pointer to the resulting string
GetFileString:
    PROLOGUE

    push %r12
    push %r13
    push %r14
    sub $8, %rsp
    SHADOW_SPACE

    # filepath, mode
    PARAMS1 %rcx
    leaq read_mode(%rip), %rdx
    call fopen                              # get pointer to the opened file
    CHECK_RETURN_FAILURE $202
    movq %rax, %r12                         # move file pointer into a callee saved register

    # file pointer, offset, $2 for seek_end
    PARAMS3 %r12, $0, $2
    call fseek                              # go to the end of the file

    # file pointer
    PARAMS1 %r12
    call ftell                              # get current position within file (this is the size in bytes)
    inc %rax                                # make space for null terminator
    movq %rax, %r13                         # save size in callee saved register

    # size in bytes to allocate
    PARAMS1 %rax
    call malloc                             # allocate memory for the string
    movq %rax, %r14                         # save pointer to string in callee saved register

    # file pointer, offset, $0 for seek_set
    PARAMS1 %r12
    call rewind                             # go to the start of the file to be able to read

    sub $1, %r13                            # subtract null terminator from size to get ready for fread
    # pointer to string, element size, element count, file to read
    PARAMS4 %r14, $1, %r13, %r12
    call fread                              # read the file into the allocated memory

    movb $0, (%r14, %r13)                   # null terminate string

    PARAMS1 %r12
    call fclose                             # cleanup after ourselves (free file)

    movq %r14, %rax                         # return string

    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    movq -24(%rbp), %r14

    EPILOGUE

# make a shader and compile it with the provided filepath to the source code
# PARAMS:
# %rcx =    pointer to filepath string
# %rdx =    shader type
# RETURNS:
# %rax =    name of the resulting shader
MakeShader:
    PROLOGUE
    push %r12
    push %r13
    subq $16, %rsp
    SHADOW_SPACE

    movq %rcx, %r12                         # save filepath to callee saved register

    # create shader name
    PARAMS1 %rdx
    call *glCreateShader(%rip)
    movq %rax, %r13                         # save shader name to callee saved register

    # get source code string
    PARAMS1 %r12
    call GetFileString                      # get the string of the shader source code
    movq %rax, %r12                         # save string pointer to callee saved register
    movq %r12, -24(%rbp)                    # since opengl is goofy turn the string into a string array with length 1

    # attach source code string
    PARAMS2 %r13, $1
    leaq -24(%rbp), %r8                     # source code array
    movq $0, %r9                            # stop at null terminator
    call *glShaderSource(%rip)              # attach the source code to the shader

    # cleanup source code string
    PARAMS1 %r12
    call free                               # free the returned source code string (cleanup)

    # compile shader
    PARAMS1 %r13
    call *glCompileShader(%rip)

    # check for compile errors
    PARAMS2 %r13, $GL_COMPILE_STATUS
    leaq -24(%rbp), %r8
    call *glGetShaderiv(%rip)

    cmpq $1, -24(%rbp)                      # if shader is compiled
    je 1f                                   # exit subroutine

    # print compile error and exit

    # get length of info string
    PARAMS2 %r13, $GL_INFO_LOG_LENGTH
    leaq -24(%rbp), %r8
    call *glGetShaderiv(%rip)

    # allocate space for info string
    PARAMS1 -24(%rbp)
    call malloc
    movq %rax, %r12                         # save info string into a callee saved register

    # put info string in allocated space
    PARAMS4 %r13, -24(%rbp), $0, %r12
    call *glGetShaderInfoLog(%rip)          # put shader info in string

    # print info string
    movq $0, %rax
    PARAMS1 %r12
    call printf                             # print compile error

    # cleanup
    PARAMS1 %r12
    call free                               # free info log string memory (cleanup)

    # exit
    PARAMS1 $203
    call exit

    1: # compiled succesfully

    movq %r13, %rax                         # return shader name

    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    EPILOGUE

# make a shader program with the provided vertex and fragment shaders and link them
# PARAMS:
# %rcx =    vertex shader name
# %rdx =    fragment shader name
# RETURNS:
# %rax =    name of the resulting shader program
MakeShaderProgram:
    PROLOGUE
    push %r12
    push %r13
    push %r14
    sub $8, %rsp
    SHADOW_SPACE

    movq %rcx, %r12                         # vertex shader name to callee saved register
    movq %rdx, %r13                         # fragment shader name to callee saved register

    # create shader program name
    call *glCreateProgram(%rip)
    movq %rax, %r14                         # save shader program name to callee saved register

    # attach shaders to shader program
    PARAMS2 %r14, %r12
    call *glAttachShader(%rip)
    PARAMS2 %r14, %r13
    call *glAttachShader(%rip)

    # link shader program
    PARAMS1 %r14
    call *glLinkProgram(%rip)

    # check for link errors
    PARAMS2 %r14, $GL_LINK_STATUS
    leaq -32(%rbp), %r8
    call *glGetProgramiv(%rip)

    cmpq $1, -32(%rbp)                      # if shader is compiled
    je 1f                                   # exit subroutine

    # print link error and exit

    # get length of info string
    PARAMS2 %r14, $GL_INFO_LOG_LENGTH
    leaq -32(%rbp), %r8
    call *glGetProgramiv(%rip)

    # allocate space for info string
    PARAMS1 -32(%rbp)
    call malloc
    movq %rax, %r12                         # save info string into a callee saved register

    # put info string in allocated space
    PARAMS4 %r14, -32(%rbp), $0, %r12
    call *glGetProgramInfoLog(%rip)         # put shader program info in string

    # print info string
    movq $0, %rax
    PARAMS1 %r12
    call printf                             # print link error

    # cleanup
    PARAMS1 %r12
    call free                               # free info log string memory (cleanup)

    # exit
    PARAMS1 $204
    call exit

    1: # linked succesfully

    movq %r14, %rax                         # return shader program name

    movq -8(%rbp), %r12
    movq -16(%rbp), %r13
    movq -24(%rbp), %r14
    EPILOGUE
