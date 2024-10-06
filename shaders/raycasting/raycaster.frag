
# version 330 core // glsl version

in vec3 rayTarget;

out vec4 color;

void main() {
    color = vec4(rayTarget, 1);
}