// displays the final render on the window

# version 430 core // glsl version

in vec2 texPos;

out vec4 color;

uniform sampler2D scene;

void main() {
    color = texture(scene, texPos);
}