
# version 430 core // glsl version

precision highp float;

in vec3 rayTarget;

out vec4 color;

uniform vec4 fogColor = vec4(0.1, 0.05, 0, 1);
uniform int blockHeight = 4;
uniform float maxRayDist = 16;
uniform float epsilon = 0.001; // corner error correction

layout(std140, binding = 0) uniform CameraData {
    vec3 pos;
    float angleX;
    float angleY;
    float fov;
    float aspectRatio;
} camera;

uniform int entityCount = 0;

layout(std430, binding = 0) buffer EntityP {      
    vec2 positions[];          
};

layout(std430, binding = 1) buffer EntityS {      
    float sizes[];          
};

layout(std430, binding = 2) buffer EntityH {      
    float heights[];          
};

layout(std430, binding = 3) buffer EntityT {      
    uint textureData[]; // each int holds 2 shorts that represent texture data (so actual index = entity / 2)
};

uniform usampler2D mapData;
uniform usampler2DArray pieceData;
uniform usampler1D blockData;

uniform sampler2DArray textures;
uniform sampler2DArray entityTextures;

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

vec2 rotateVector(vec2 vec, uint rotation) {
    if (rotation == 0) {
        return vec;
    } else if (rotation == 1) {
        return vec2(vec.y, -vec.x);
    } else if (rotation == 2) {
        return vec2(-vec.x, -vec.y);
    } else if (rotation == 3) {
        return vec2(-vec.y, vec.x);
    }
}

rayHit getHitX() {
    int dirX = int(step(0, rayTarget.x)); // 0 if negative, 1 if positive

    // calculate first intersection on the x axis
    float multiplier = (1 - dirX) * (fract(camera.pos.x) / -rayTarget.x) + dirX * ((1 - fract(camera.pos.x)) / rayTarget.x);
    vec3 rayPos = camera.pos + rayTarget * multiplier;

    vec3 rayStep = rayTarget / abs(rayTarget.x);
    float stepLength = length(rayStep);

    // convert dirX to -1 - 1
    dirX = int((dirX - 0.5) * 2);

    float totalLength = distance(camera.pos, rayPos);
    // loop while block at position is open (first bit in block data)
    while ((((getBlock(rayPos.xz + vec2(0.5 * dirX, epsilon)) & 1) == 0 ||
            (getBlock(rayPos.xz + vec2(-0.5 * dirX, epsilon)) & 1) == 1) &&
            ((getBlock(rayPos.xz + vec2(0.5 * dirX, -epsilon)) & 1) == 0 ||
            (getBlock(rayPos.xz + vec2(-0.5 * dirX, -epsilon)) & 1) == 1))
            && totalLength < maxRayDist) {

        rayPos += rayStep;
        totalLength += stepLength;
    }

    // get intersected block
    int dirZ = int((step(0, rayTarget.z) - 0.5) * 2); // -1 - 1
    int blockComp = int((step(1, getBlock(rayPos.xz + vec2(0.5 * dirX, -epsilon * dirZ)) & 1) - 0.5) * 2); // offset to the camera, is it air or not?
    vec2 blockPos = rayPos.xz + vec2(0.5 * dirX, -epsilon * dirZ * blockComp); // if wall use that position, if air offset away from camera
    uint blockData = getBlock(blockPos); 

    uint wallTex = blockData >> 1;

    // convert dirX to 0 - 1
    dirX = int((dirX + 1) / 2);

    vec2 texCoord = vec2(blockPos.y, rayPos.y);
    texCoord = fract(texCoord / 4);
    texCoord.x = texCoord.x * (1 - dirX) + (1 - texCoord.x) * dirX;

    return rayHit(distance(camera.pos, rayPos), texture(textures, vec3(texCoord.xy, wallTex)));
}

rayHit getHitZ() {
    int dirZ = int(step(0, rayTarget.z)); // 0 if negative, 1 if positive

    // calculate first intersection on the Z axis
    float multiplier = (1 - dirZ) * (fract(camera.pos.z) / -rayTarget.z) + dirZ * ((1 - fract(camera.pos.z)) / rayTarget.z);
    vec3 rayPos = camera.pos + rayTarget * multiplier;

    vec3 rayStep = rayTarget / abs(rayTarget.z);
    float stepLength = length(rayStep);

    // convert dirZ to -1 - 1
    dirZ = int((dirZ - 0.5) * 2);

    float totalLength = distance(camera.pos, rayPos); 
    // loop while block at position is open (first bit in block data)
    while ((((getBlock(rayPos.xz + vec2(epsilon, 0.5 * dirZ)) & 1) == 0 ||
            (getBlock(rayPos.xz + vec2(epsilon, -0.5 * dirZ)) & 1) == 1) &&
            ((getBlock(rayPos.xz + vec2(-epsilon, 0.5 * dirZ)) & 1) == 0 ||
            (getBlock(rayPos.xz + vec2(-epsilon, -0.5 * dirZ)) & 1) == 1)) 
            && totalLength < maxRayDist) {

        rayPos += rayStep;
        totalLength += stepLength;
    }

    // get intersected block
    int dirX = int((step(0, rayTarget.x) - 0.5) * 2); // -1 - 1
    int blockComp = int((step(1, getBlock(rayPos.xz + vec2(-epsilon * dirX, 0.5 * dirZ)) & 1) - 0.5) * 2); // offset to the camera, is it air or not?
    vec2 blockPos = rayPos.xz + vec2(-epsilon * dirX * blockComp, 0.5 * dirZ); // if wall use that position, if air offset away from camera
    uint blockData = getBlock(blockPos); 

    uint wallTex = blockData >> 1;

    // convert dirZ to 0 - 1
    dirZ = int((dirZ + 1) / 2);
    vec2 texCoord = vec2(blockPos.x, rayPos.y);
    texCoord = fract(texCoord / 4);
    texCoord.x = texCoord.x * dirZ + (1 - texCoord.x) * (1 - dirZ);

    return rayHit(distance(camera.pos, rayPos), texture(textures, vec3(texCoord.xy, wallTex)));
}

rayHit getHitY() {
    float dir = step(0, rayTarget.y); // 0 if negative, 1 if positive
    float multiplier = (1 - dir) * (-camera.pos.y / rayTarget.y) + dir * ((blockHeight - camera.pos.y) / rayTarget.y);
    vec3 hitPos = camera.pos + rayTarget * multiplier;

    // get block data
    uint blockData = getBlock(hitPos.xz);
    uint floorRot = (blockData >> 1) & 0x7;
    uint ceilingRot = (blockData >> 3) & 0x7;
    uint floorTex = (blockData >> 6) & 0x1F;
    uint ceilingTex = (blockData >> 11) & 0x1F;

    vec2 texCoord = fract(hitPos.xz / 4); // divide by 4 since each tile is 4 pixels and the texture is 16 pixels

    vec4 floorColor = texture(textures, vec3(rotateVector(texCoord, floorRot).xy, floorTex));
    vec4 ceilingColor = texture(textures, vec3(rotateVector(texCoord, ceilingRot).xy, ceilingTex));

    return rayHit(length(rayTarget * multiplier), ceilingColor * step(2, hitPos.y) + floorColor * step(hitPos.y, 2));
}

rayHit getHitEntity(int index) {
    vec2 entityPos = positions[index];
    vec2 camToEntity = vec2(entityPos - camera.pos.xz);

    if (camToEntity.x == 0 && camToEntity.y == 0) {
        return rayHit(maxRayDist, fogColor);
    }

    vec2 entityLine = normalize(vec2(camToEntity.y, -camToEntity.x)) * sizes[index];

    // P1 + l * D1 = P2 + t * D2

    // used as texture coord
    // t = (C.x * D1.y - C.y * D1.x) / (D2.y * D1.x - D2.x * D1.y)
    float t = (camToEntity.x * rayTarget.z - camToEntity.y * rayTarget.x) /
                (entityLine.y * rayTarget.x - entityLine.x * rayTarget.z);

    // used to calculate 3d hit point
    // l = (C.x + t * D2.x) / D1.x
    float l = (camToEntity.x + t * entityLine.x) / rayTarget.x;

    vec3 hitPoint = camera.pos + l * rayTarget; 

    // check if hit

    vec2 textureCoord = vec2((t + 1) / 2, hitPoint.y / heights[index]);

    // check if l > 0, t > 0 and texture coords are within 0 - 1, if not there is no hit
    int isHit = int(step(0, l)) *
                int(step(0, textureCoord.x)) * int(step(textureCoord.x, 1)) * 
                int(step(0, textureCoord.y)) * int(step(textureCoord.y, 1));

    // get texture color

    // get texture data
    uint textureData = textureData[index / 2];
    textureData = (textureData >> (index % 2) * 16) & 0xFFFF;
    float halfWidth = (float((textureData & 0XF) + 1) * 2) / textureSize(entityTextures, 0).x;
    float halfHeight = (float(((textureData >> 4) & 0XF) + 1) * 2) / textureSize(entityTextures, 0).y;
    uint textureIndex = (textureData >> 8) & 0XFF;

    // map coordinates
    textureCoord -= vec2(0.5, 0.5);
    textureCoord *= vec2(halfWidth, halfHeight);
    textureCoord += vec2(0.5, 0.5);

    vec4 textureColor = texture(entityTextures, vec3(textureCoord.xy, textureIndex));

    // if texture color is transparent there is no hit
    isHit *= int(step(1, textureColor.a));

    return rayHit(distance(hitPoint, camera.pos) * isHit + maxRayDist * (1 - isHit), textureColor);
}

rayHit getHitEntities() {
    rayHit closestHit = rayHit(maxRayDist, fogColor);
    for (int i = 0; i < entityCount; i++) { // skip entity 0 since thats the player
        rayHit hit = getHitEntity(i);
        int hitComp = int(step(closestHit.dist, hit.dist));
        closestHit.dist = closestHit.dist * hitComp + hit.dist * (1 - hitComp);
        closestHit.color = closestHit.color * hitComp + hit.color * (1 - hitComp);
    }
    return closestHit;
}

void main() {

    // get hit on X axis
    rayHit hitX = getHitX();

    // get hit on Y axis
    rayHit hitY = getHitY();

    // get hit on Z axis
    rayHit hitZ = getHitZ();

    // get hit on entity
    rayHit entityHit = getHitEntities();

    // get closest wall hit
    float comp1 = step(hitX.dist, hitY.dist);
    float comp2 = step(hitY.dist, hitZ.dist);
    float comp3 = step(hitX.dist, hitZ.dist);

    rayHit hit = rayHit(hitX.dist * comp1 * comp3 + hitY.dist * (1 - comp1) * comp2 + hitZ.dist * (1 - comp2) * (1 - comp3), 
                    hitX.color * comp1 * comp3 + hitY.color * (1 - comp1) * comp2 + hitZ.color * (1 - comp2) * (1 - comp3));

    float entityComp = step(hit.dist, entityHit.dist); // 1 if entity is closer, 0 if wall is closer

    hit.dist = hit.dist * entityComp + entityHit.dist * (1 - entityComp);
    hit.color = hit.color * entityComp + entityHit.color * (1 - entityComp);

    float ratio = min(max(hit.dist / maxRayDist, 0), 1);
    color = mix(hit.color, fogColor, ratio);
}