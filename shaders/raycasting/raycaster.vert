
# version 330 core // glsl version

layout(location = 0) in vec2 inPosition;
layout(location = 1) in vec2 texPosition;

out vec3 rayTarget;

void main() {
    gl_Position = vec4(inPosition, 0, 1);
    rayTarget = vec3(texPosition, 1);
}