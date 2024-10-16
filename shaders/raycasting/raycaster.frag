
# version 430 core // glsl version

precision highp float;

in vec3 rayTarget;

out vec4 color;

uniform vec4 fogColor = vec4(0.1, 0.05, 0, 1);
uniform int blockHeight = 4;
uniform float maxRayDist = 24;
uniform float epsilon = 0.001;

layout(std140) uniform CameraData {
    vec3 pos;
    float angleX;
    float angleY;
    float fov;
    float aspectRatio;
} camera;

uniform usampler2D mapData;
uniform usampler2DArray pieceData;
uniform usampler1D blockData;

struct rayHit {
    float dist;
    vec4 color;
};

ivec2 loop(ivec2 value, ivec2 border) {
    return value - border * ivec2(floor(value / vec2(border)));
}

uint getPiece(vec2 pos) {
    // loop pos
    ivec2 pieceSize = textureSize(pieceData, 0).xy;
    ivec2 mapSize = textureSize(mapData, 0) * pieceSize;
    ivec2 iPos = ivec2(floor(pos));
    iPos = loop(iPos, mapSize);

    return texelFetch(mapData, iPos / pieceSize, 0).r;
}

uint getBlock(vec2 pos) {
    // loop pos
    ivec2 pieceSize = textureSize(pieceData, 0).xy;
    ivec2 mapSize = textureSize(mapData, 0) * pieceSize;
    ivec2 iPos = ivec2(floor(pos));
    iPos = loop(iPos, mapSize);

    // get block
    uint piece = texelFetch(mapData, iPos / pieceSize, 0).r;
    uint block = texelFetch(pieceData, ivec3(iPos % pieceSize, piece), 0).r;
    return texelFetch(blockData, int(block), 0).r;
}

rayHit getHitX() {
    int dir = int(step(0, rayTarget.x)); // 0 if negative, 1 if positive

    // calculate first intersection on the x axis
    float multiplier = (1 - dir) * (fract(camera.pos.x) / -rayTarget.x) + dir * ((1 - fract(camera.pos.x)) / rayTarget.x);
    vec3 rayPos = camera.pos + rayTarget * multiplier;

    vec3 rayStep = rayTarget / abs(rayTarget.x);
    float stepLength = length(rayStep);

    float totalLength = distance(camera.pos, rayPos);
    // loop while block at position is open (first bit in block data)
    while ((((getBlock(rayPos.xz + vec2(0.5 * (dir - 0.5) * 2, epsilon)) & 1) == 0 ||
            (getBlock(rayPos.xz + vec2(-0.5 * (dir - 0.5) * 2, epsilon)) & 1) == 1) &&
            ((getBlock(rayPos.xz + vec2(0.5 * (dir - 0.5) * 2, -epsilon)) & 1) == 0 ||
            (getBlock(rayPos.xz + vec2(-0.5 * (dir - 0.5) * 2, -epsilon)) & 1) == 1))
            && totalLength < maxRayDist) {

        rayPos += rayStep;
        totalLength += stepLength;
    }

    uint piece = getPiece(rayPos.xz);
    return rayHit(distance(camera.pos, rayPos), vec4(piece, 11 - piece, piece, 1) / 11);
}

rayHit getHitZ() {
    int dir = int(step(0, rayTarget.z)); // 0 if negative, 1 if positive

    // calculate first intersection on the Z axis
    float multiplier = (1 - dir) * (fract(camera.pos.z) / -rayTarget.z) + dir * ((1 - fract(camera.pos.z)) / rayTarget.z);
    vec3 rayPos = camera.pos + rayTarget * multiplier;

    vec3 rayStep = rayTarget / abs(rayTarget.z);
    float stepLength = length(rayStep);

    float totalLength = distance(camera.pos, rayPos); 
    // loop while block at position is open (first bit in block data)
    while ((((getBlock(rayPos.xz + vec2(epsilon, 0.5 * (dir - 0.5) * 2)) & 1) == 0 ||
            (getBlock(rayPos.xz + vec2(epsilon, -0.5 * (dir - 0.5) * 2)) & 1) == 1) &&
            ((getBlock(rayPos.xz + vec2(-epsilon, 0.5 * (dir - 0.5) * 2)) & 1) == 0 ||
            (getBlock(rayPos.xz + vec2(-epsilon, -0.5 * (dir - 0.5) * 2)) & 1) == 1)) 
            && totalLength < maxRayDist) {

        rayPos += rayStep;
        totalLength += stepLength;
    }

    uint piece = getPiece(rayPos.xz);
    return rayHit(distance(camera.pos, rayPos), vec4(piece, 11 - piece, piece, 1) / 11);
}

rayHit getHitY() {
    float dir = step(0, rayTarget.y); // 0 if negative, 1 if positive
    float multiplier = (1 - dir) * (-camera.pos.y / rayTarget.y) + dir * ((blockHeight - camera.pos.y) / rayTarget.y);

    return rayHit(length(rayTarget * multiplier), vec4(0, 0, 0, 1));
}

void main() {

    // get hit on X axis
    rayHit hitX = getHitX();

    // get hit on Y axis
    rayHit hitY = getHitY();

    // get hit on Z axis
    rayHit hitZ = getHitZ();

    // get closest color
    float comp1 = step(hitX.dist, hitY.dist);
    float comp2 = step(hitY.dist, hitZ.dist);
    float comp3 = step(hitX.dist, hitZ.dist);

    rayHit hit = rayHit(hitX.dist * comp1 * comp3 + hitY.dist * (1 - comp1) * comp2 + hitZ.dist * (1 - comp2) * (1 - comp3), 
                    hitX.color * comp1 * comp3 + hitY.color * (1 - comp1) * comp2 + hitZ.color * (1 - comp2) * (1 - comp3));

    float ratio = min(max(hit.dist / maxRayDist, 0), 1);
    color = clamp(mix(hit.color, fogColor, ratio), vec4(0), vec4(1));
}