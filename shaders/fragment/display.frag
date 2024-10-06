
# version 330 core // glsl version

in vec2 texPos;

out vec4 color;

sampler2D scene;

void main() {
    color = vec4(texPos, 0.5, 1);
}