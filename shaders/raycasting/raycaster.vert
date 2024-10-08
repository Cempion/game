
# version 330 core // glsl version

layout(location = 0) in vec2 inPosition;
layout(location = 1) in vec2 texPosition;

out vec2 pos;
out vec3 rayTarget;

layout(std140) uniform CameraData {
    vec2 pos;
    float angleX;
    float angleY;
    float fov;
    float aspectRatio;
} camera;

void main() {
    gl_Position = vec4(inPosition, 0, 1);
    pos = inPosition;

    // calculates the direction the ray at this vertex is pointing

    // calculate half of the width
    float viewHalfWidth = tan(camera.fov / 2);                          // since the distance from the origin is 1, results in : tan(fov / 2) = width / 1
    // calculate half of the height
    float viewHalfHeight = (1 / camera.aspectRatio) * viewHalfWidth;    // (1 / aspect ratio) * width = height
    // calculate ray target
    vec3 baseTarget = vec3(inPosition.xy, 1) * vec3(viewHalfWidth, viewHalfHeight, 1);

    // rotate the ray target based on camera angles

    // rotate angleY (around the X axis)
    rayTarget = baseTarget;
    rayTarget.z = baseTarget.z * cos(camera.angleY) - baseTarget.y * sin(camera.angleY);
    rayTarget.y = baseTarget.y * cos(camera.angleY) + baseTarget.z * sin(camera.angleY);

    // rotate angleX (around the Y axis)
    baseTarget = rayTarget;
    rayTarget.x = baseTarget.x * cos(camera.angleX) - baseTarget.z * sin(camera.angleX);
    rayTarget.z = baseTarget.z * cos(camera.angleX) + baseTarget.x * sin(camera.angleX);
}