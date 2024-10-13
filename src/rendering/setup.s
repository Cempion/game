# how many pixels to render (rays to cast)
.equ RENDER_WIDTH, 256 #256
.equ RENDER_HEIGHT, 288 #144

# used to calculate the ratio between width and height for the view, decides which direction 
# the rays are cast and the final size of the view on the screen
.equ VIEW_WIDTH, 16
.equ VIEW_HEIGHT, 9

.data

render_shader_program: .quad 0 # the shader program responsible for rendering the game to the scene texture (casts rays & stuff)
display_shader_program: .quad 0 # the shader program responsible for rendering the scene to the screen

full_vao: .quad 0 # the vertex array object used while doing a full screen draw call
full_vbo: .quad 0 # the vertex buffer object containing a square that represents the entire screen

display_vao: .quad 0 # the vertex array object used while rendering the scene to the screen
display_vbo: .quad 0 # the vertex buffer object containing the square to display the scene to the screen

# xPos, yPos, xTexPos, yTexPos : 64 bytes in total
vbo_data:
    .float -1.0, -1.0, 0, 0
    .float -1.0,  1.0, 0, 1
    .float  1.0, -1.0, 1, 0
    .float  1.0,  1.0, 1, 1

camera_ubo: .quad 0 # the uniform buffer object that stores the needed camera data in 6 floats

render_fbo: .quad 0 # the framebuffer object used to render the scene too.

# textures

# unit 0
scene_tex: .quad 0 # the 2d texture used to render the scene in the render fbo.
# unit 1
map_texture: .quad 0 # a 2d texture containing the map data
# unit 2
piece_texture: .quad 0 # a 3d texture containing the piece data
# unit 3
block_texture: .quad 0 # a 1d texture containing the block data

# 8 spaces to make space for a quad
raycaster_vert_shader:  .asciz "        shaders\\raycasting\\raycaster.vert"
raycaster_frag_shader:  .asciz "        shaders\\raycasting\\raycaster.frag"

pass_vert_shader:       .asciz "        shaders\\pass.vert"
display_frag_shader:    .asciz "        shaders\\display.frag"

.text

# uniform names
scene_uniform: .asciz "scene"

map_uniform: .asciz "mapData"
piece_uniform: .asciz "pieceData"
block_uniform: .asciz "blockData"

read_mode: .asciz "rb" # mode to use when reading shader code, rd = read binary

#----------------------------------------------------------------------------------------------------------
# Setup
#----------------------------------------------------------------------------------------------------------

# initializes everything the renderer needs
SetupRenderer:
    PROLOGUE
    SHADOW_SPACE

    call LoadOpenGlMethods                  # load opengl methods that are not included in windows

    # enable VSync
    PARAMS1 $1
    call *wglSwapIntervalEXT(%rip)

    #----------------------------------------------------------------------------------------------------------
    # Shaders
    #----------------------------------------------------------------------------------------------------------

    # make render shaders & program

    # make raycaster vertex shader
    leaq raycaster_vert_shader(%rip), %rcx
    add $8, %rcx                            # since first 8 bytes are the shader name
    movq $GL_VERTEX_SHADER, %rdx
    call MakeShader
    movq %rax, raycaster_vert_shader(%rip)  # store shader name

    # make raycaster fragment shader
    leaq raycaster_frag_shader(%rip), %rcx
    add $8, %rcx                            # since first 8 bytes are the shader name
    movq $GL_FRAGMENT_SHADER, %rdx
    call MakeShader
    movq %rax, raycaster_frag_shader(%rip)  # store shader name

    # make shader program
    PARAMS2 raycaster_vert_shader(%rip), raycaster_frag_shader(%rip)
    call MakeShaderProgram
    movq %rax, render_shader_program(%rip)  # store program name

    # clean up shader objects
    PARAMS1 raycaster_vert_shader(%rip)
    call *glDeleteShader(%rip)
    PARAMS1 raycaster_frag_shader(%rip)
    call *glDeleteShader(%rip)

    # bind mapData uniform to texture unit 1
    PARAMS1 render_shader_program(%rip)
    leaq map_uniform(%rip), %rdx
    call *glGetUniformLocation(%rip)

    PARAMS3 render_shader_program(%rip), %rax, $1
    call *glProgramUniform1i(%rip)

    # bind pieceData uniform to texture unit 2
    PARAMS1 render_shader_program(%rip)
    leaq piece_uniform(%rip), %rdx
    call *glGetUniformLocation(%rip)

    PARAMS3 render_shader_program(%rip), %rax, $2
    call *glProgramUniform1i(%rip)

    # bind blockData uniform to texture unit 3
    PARAMS1 render_shader_program(%rip)
    leaq block_uniform(%rip), %rdx
    call *glGetUniformLocation(%rip)

    PARAMS3 render_shader_program(%rip), %rax, $3
    call *glProgramUniform1i(%rip)

    # make display shaders & program

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
    movq %rax, display_shader_program(%rip) # store program name

    # clean up shader objects
    PARAMS1 pass_vert_shader(%rip)
    call *glDeleteShader(%rip)
    PARAMS1 display_frag_shader(%rip)
    call *glDeleteShader(%rip)

    # bind scene uniform to texture unit 0
    PARAMS1 display_shader_program(%rip)
    leaq scene_uniform(%rip), %rdx
    call *glGetUniformLocation(%rip)

    PARAMS3 display_shader_program(%rip), %rax, $0
    call *glProgramUniform1i(%rip)

    #----------------------------------------------------------------------------------------------------------
    # Vertex Array Object
    #----------------------------------------------------------------------------------------------------------

    # make full screen vao & vbo

    # generate render vao name
    PARAMS1 $1
    leaq full_vao(%rip), %rdx
    call *glGenVertexArrays(%rip)

    # bind render vao
    PARAMS1 full_vao(%rip)
    call *glBindVertexArray(%rip)

    # make & bind full vbo
    leaq vbo_data(%rip), %rcx
    call MakeVertexArrayBuffer
    movq %rax, full_vbo(%rip)

    # make display vao & vbo

    # modify vbo_data to contain the correct square to render the scene
    call MakeDisplayVboData

    # generate render vao name
    PARAMS1 $1
    leaq display_vao(%rip), %rdx
    call *glGenVertexArrays(%rip)

    # bind render vao
    PARAMS1 display_vao(%rip)
    call *glBindVertexArray(%rip)

    # make & bind display vbo
    leaq vbo_data(%rip), %rcx
    call MakeVertexArrayBuffer
    movq %rax, display_vbo(%rip)

    #----------------------------------------------------------------------------------------------------------
    # Map Textures
    #----------------------------------------------------------------------------------------------------------

    # use correct settings for passing the data
    PARAMS2 $GL_UNPACK_ALIGNMENT, $1
    call glPixelStorei

    # map data

    # make texture for map data
    PARAMS1 $1
    leaq map_texture(%rip), %rdx
    call glGenTextures

    # bind texture
    PARAMS1 $GL_TEXTURE1
    call *glActiveTexture(%rip)
    PARAMS2 $GL_TEXTURE_2D, map_texture(%rip)
    call glBindTexture

    # set texture parameters
    PARAMS3 $GL_TEXTURE_2D, $GL_TEXTURE_MIN_FILTER, $GL_NEAREST
    call glTexParameteri
    PARAMS3 $GL_TEXTURE_2D, $GL_TEXTURE_MAG_FILTER, $GL_NEAREST
    call glTexParameteri

    PARAMS3 $GL_TEXTURE_2D, $GL_TEXTURE_WRAP_S, $GL_REPEAT
    call glTexParameteri
    PARAMS3 $GL_TEXTURE_2D, $GL_TEXTURE_WRAP_T, $GL_REPEAT
    call glTexParameteri

    sub $8, %rsp                            # allign stack
    # target, level, internal_format, width, height, border, external_format, type, data
    PARAMS9 $GL_TEXTURE_2D, $0, $GL_R8UI, $WFC_WIDTH, $WFC_HEIGHT, $0, $GL_RED_INTEGER, $GL_UNSIGNED_BYTE, $0
    SHADOW_SPACE
    call glTexImage2D
    add $80, %rsp                           # restore stack pointer

    # piece data

    # make texture for piece data
    PARAMS1 $1
    leaq piece_texture(%rip), %rdx
    call glGenTextures

    # bind texture
    PARAMS1 $GL_TEXTURE2
    call *glActiveTexture(%rip)
    PARAMS2 $GL_TEXTURE_2D_ARRAY, piece_texture(%rip)
    call glBindTexture

    # set texture parameters
    PARAMS3 $GL_TEXTURE_2D_ARRAY, $GL_TEXTURE_MIN_FILTER, $GL_NEAREST
    call glTexParameteri
    PARAMS3 $GL_TEXTURE_2D_ARRAY, $GL_TEXTURE_MAG_FILTER, $GL_NEAREST
    call glTexParameteri

    PARAMS3 $GL_TEXTURE_2D_ARRAY, $GL_TEXTURE_WRAP_S, $GL_REPEAT
    call glTexParameteri
    PARAMS3 $GL_TEXTURE_2D_ARRAY, $GL_TEXTURE_WRAP_T, $GL_REPEAT
    call glTexParameteri

    # get parameters to allocate piece texture
    movzb piece_sockets(%rip), %rdi         # get piece count
    incq %rdi                               # add space for piece 0 (error piece)
    leaq piece_data(%rip), %rsi             # get data to put in texture

    # target, level, internal_format, width, height, depth, border, external_format, type, data
    PARAMS10 $GL_TEXTURE_2D_ARRAY, $0, $GL_R8UI, $PIECE_SIZE, $PIECE_SIZE, %rdi, $0, $GL_RED_INTEGER, $GL_UNSIGNED_BYTE, %rsi
    SHADOW_SPACE
    call *glTexImage3D(%rip)
    add $80, %rsp                           # restore stack pointer

    # block data

    # make texture for block data
    PARAMS1 $1
    leaq block_texture(%rip), %rdx
    call glGenTextures

    # bind texture
    PARAMS1 $GL_TEXTURE3
    call *glActiveTexture(%rip)
    PARAMS2 $GL_TEXTURE_1D, block_texture(%rip)
    call glBindTexture

    # set texture parameters
    PARAMS3 $GL_TEXTURE_1D, $GL_TEXTURE_MIN_FILTER, $GL_NEAREST
    call glTexParameteri
    PARAMS3 $GL_TEXTURE_1D, $GL_TEXTURE_MAG_FILTER, $GL_NEAREST
    call glTexParameteri

    PARAMS3 $GL_TEXTURE_1D, $GL_TEXTURE_WRAP_S, $GL_CLAMP_TO_BORDER
    call glTexParameteri

    # get parameters to allocate piece texture
    movzb blocks(%rip), %rdi                # get block count
    leaq blocks(%rip), %rsi                 # get data to put in texture
    incq %rsi                               # correct for size byte

    # target, level, internal_format, width, border, external_format, type, data
    PARAMS8 $GL_TEXTURE_1D, $0, $GL_R16UI, %rdi, $0, $GL_RED_INTEGER, $GL_UNSIGNED_SHORT, %rsi
    SHADOW_SPACE
    call glTexImage1D
    add $64, %rsp                           # restore stack pointer

    #----------------------------------------------------------------------------------------------------------
    # Camera UBO
    #----------------------------------------------------------------------------------------------------------

    # generate camera ubo name
    PARAMS1 $1
    leaq camera_ubo(%rip), %rdx
    call *glGenBuffers(%rip)

    # bind buffer to ubo target (make it a ubo)
    PARAMS2 $GL_UNIFORM_BUFFER, camera_ubo(%rip)
    call *glBindBuffer(%rip)
    
    # target, size in bytes (7 * 4), data (null for now), usage
    PARAMS4 $GL_UNIFORM_BUFFER, $28, $0, $GL_DYNAMIC_DRAW
    call *glBufferData(%rip)

    # bind camera ubo to base 0
    PARAMS3 $GL_UNIFORM_BUFFER, $0, camera_ubo(%rip)
    call *glBindBufferBase(%rip)

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
    leaq scene_tex(%rip), %rdx
    call glGenTextures

    PARAMS1 $GL_TEXTURE0
    call *glActiveTexture(%rip)

    PARAMS2 $GL_TEXTURE_2D, scene_tex(%rip)
    call glBindTexture

    # set texture parameters
    PARAMS3 $GL_TEXTURE_2D, $GL_TEXTURE_MIN_FILTER, $GL_LINEAR
    call glTexParameteri
    PARAMS3 $GL_TEXTURE_2D, $GL_TEXTURE_MAG_FILTER, $GL_NEAREST
    call glTexParameteri

    PARAMS3 $GL_TEXTURE_2D, $GL_TEXTURE_WRAP_S, $GL_CLAMP_TO_EDGE
    call glTexParameteri
    PARAMS3 $GL_TEXTURE_2D, $GL_TEXTURE_WRAP_T, $GL_CLAMP_TO_EDGE
    call glTexParameteri

    sub $8, %rsp                            # allign stack
    # target, level, internal_format, width, height, border, external_format, type, data
    PARAMS9 $GL_TEXTURE_2D, $0, $GL_RGB, $RENDER_WIDTH, $RENDER_HEIGHT, $0, $GL_RGB, $GL_UNSIGNED_BYTE, $0
    SHADOW_SPACE
    call glTexImage2D
    add $80, %rsp                           # restore stack pointer

    # link texture to framebuffer
    sub $8, %rsp                            # allign stack
    # target, attachment, texture target, texture, level
    PARAMS5 $GL_FRAMEBUFFER, $GL_COLOR_ATTACHMENT0, $GL_TEXTURE_2D, scene_tex(%rip), $0
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

    CHECK_OPENGL_ERROR
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

# make a vbo with the provided 4 vertices in the format of x, y, texX, texY.
# and bind to the currently bound vao
# PARAMS:
# %rcx =    pointer to 4 vertices
# RETURNS:
# %rax =    name of the resulting vbo
MakeVertexArrayBuffer:
    PROLOGUE

    push %r12
    sub $8, %rsp
    movq %rcx, %r12                         # save pointer to data in callee saved register

    SHADOW_SPACE

    # generate vbo name
    PARAMS1 $1
    leaq -16(%rbp), %rdx
    call *glGenBuffers(%rip)

    # bind to array buffer target
    PARAMS2 $GL_ARRAY_BUFFER, -16(%rbp)
    call *glBindBuffer(%rip)

    # fill with data
    PARAMS4 $GL_ARRAY_BUFFER, $64, %r12, $0
    call *glBufferStorage(%rip)

    # tell currently bound vao how to read the buffer

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

    movq -16(%rbp), %rax                    # return result

    movq -8(%rbp), %r12

    EPILOGUE

# calculate display vbo data and puts them in the vbo_data label
# ratio = min(screen_width / view_width, screen_height / view_height)
# normalized_x = (ratio * view_width) / screen_width
# normalized_y = (ratio * view_height) / screen_height
MakeDisplayVboData:
    PROLOGUE

    # get screen and view dimensions
    movq screen_width(%rip), %r8
    movq screen_height(%rip), %r9
    movq $VIEW_WIDTH, %r10
    movq $VIEW_HEIGHT, %r11

    # convert to floats
    cvtsi2ss %r8, %xmm0
    cvtsi2ss %r9, %xmm1
    cvtsi2ss %r10, %xmm2
    cvtsi2ss %r11, %xmm3

    # calculate ratio and store in xmm4, xmm5
    movss %xmm0, %xmm4
    movss %xmm1, %xmm5

    divss %xmm2, %xmm4
    divss %xmm3, %xmm5
    
    minss %xmm5, %xmm4                      # store minimum (ratio) in xmm4

    # calculate normalized screen coordinates
    mulss %xmm4, %xmm2
    mulss %xmm4, %xmm3

    divss %xmm0, %xmm2
    divss %xmm1, %xmm3

    # put values in vbo data
    leaq vbo_data(%rip), %rcx

    # positive x
    movss %xmm2, 32(%rcx)
    movss %xmm2, 48(%rcx)
    # positive y
    movss %xmm3, 20(%rcx)
    movss %xmm3, 52(%rcx)

    # invert
    movss f_min_1(%rip), %xmm0
    mulss %xmm0, %xmm2
    mulss %xmm0, %xmm3

    # negative x
    movss %xmm2, (%rcx)
    movss %xmm2, 16(%rcx)
    # negative y
    movss %xmm3, 4(%rcx)
    movss %xmm3, 36(%rcx)

    EPILOGUE
