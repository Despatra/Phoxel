#version 430 compatibility
#include "Includes/Settings.glsl"
#extension GL_ARB_shader_image_load_store : enable

out vec2 texcoord;
out vec4 glcolor;
out vec3 Normal;
out vec3 ViewDir;
out mat3 TBN;
out vec2 TextureSize;
flat out int BlockID;
flat out float Dist;
flat out ivec2 VoxelStorePos;

in vec3 at_midBlock;
in vec3 mc_Entity;
in vec4 at_tangent;
in vec4 mc_midTexCoord;

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform ivec2 atlasSize;
uniform sampler2D specular;

layout(RGBA16) uniform image2D colorimg1; //voxels
layout(RGBA8) uniform image2D colorimg2; // Lights
/*
    const int colortex1Format = RGBA16;
*/

ivec2 VoxImgSize = ivec2(VoxelBufferSize, VoxelBufferSize);

mat3 CalculateTBN() {
    vec3 bitangent = cross(at_tangent.xyz, gl_Normal);
    return mat3(at_tangent.xyz, bitangent, gl_Normal);
}

void main(){
    gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0.xy;
	// lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
    Normal = gl_Normal;
    ViewDir = (mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix*gl_Vertex).xyz);
    TBN = CalculateTBN();

    // Getting texture size
    vec2 MidCoord = mc_midTexCoord.xy;
    TextureSize = ceil((abs(texcoord - MidCoord)*2.0*vec2(atlasSize))/16.0) * 16.0 / vec2(atlasSize);
    int TextureRes = int(TextureSize.x*atlasSize.x);
    vec2 pixsize = TextureSize/TextureRes;

    vec3 EyeCameraPosition = cameraPosition + gbufferModelViewInverse[3].xyz;
    vec3 worldPos = vec3((mat3(gbufferModelViewInverse)*(gl_ModelViewMatrix*gl_Vertex).xyz)+EyeCameraPosition);
    Dist = length(worldPos-EyeCameraPosition);

    BlockID = int(mc_Entity.x+.001);
        
    //offset it and set coordinate to bottom corner of block
    ivec3 BlockPos = ivec3(floor(worldPos + (at_midBlock/64.0)));
    ivec3 OffsetBlockPos = BlockPos-ivec3(floor(EyeCameraPosition)) + ivec3(VoxelDist/2);
    ivec3 OffestLightPos = BlockPos-ivec3(floor(EyeCameraPosition)) + ivec3(LightVoxelDist/2);

    if (OffsetBlockPos.x<0 || OffsetBlockPos.y<0 || OffsetBlockPos.z<0) return;
    if (OffsetBlockPos.x>=VoxelDist || OffsetBlockPos.y>=VoxelDist || OffsetBlockPos.z>=VoxelDist) return;

    //Convert to an index
    int VoxelID = (OffsetBlockPos.x)+((OffsetBlockPos.y)*VoxelDist)+((OffsetBlockPos.z)*(VoxelDist*VoxelDist));
    int LightID = (OffestLightPos.x)+((OffestLightPos.y)*LightVoxelDist)+((OffestLightPos.z)*(LightVoxelDist*LightVoxelDist));
    
    VoxelStorePos = ivec2(VoxelID % VoxelBufferSize, VoxelID / VoxelBufferSize);
    ivec2 LightStorePos = ivec2(LightID % LightBufferSize, LightID / LightBufferSize);
    imageStore(colorimg2, LightStorePos, vec4(BlockID == 4011 || BlockID == 4010));

    if(int(BlockID/10) % 2 == 0 && BlockID > 1000) return;

    //convert to 2D coordinates and store to colortex1
    if (texcoord.x < MidCoord.x && texcoord.y < MidCoord.y) imageStore(colorimg1, VoxelStorePos, vec4(texcoord+pixsize, texcoord+TextureSize-pixsize));
}