
# version 330 core // glsl version

in vec2 pos;
in vec3 rayTarget;

out vec4 color;

layout(std140) uniform CameraData {
    vec2 pos;
    float angleX;
    float angleY;
    float fov;
    float aspectRatio;
} camera;

void main() {
    color = vec4(rayTarget, 1);
}