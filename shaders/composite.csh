#version 430 compatibility
#include "Includes/Settings.glsl"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;
const ivec3 workGroups = ivec3(LightVoxelDist/8, LightVoxelDist/8, LightVoxelDist/8);

layout(std430, binding = 0) buffer LightBuffer {
    int LightIndex;
};

uniform sampler2D colortex2;
layout(RGBA16F) uniform image2D colorimg7;
/*
    const int colortex2Format = RGBA8;
*/

//shared int LightIndex;

void main(){
    //atomicExchange(LightIndex, 0);
    barrier();
    memoryBarrierBuffer();
    int ID = int(gl_GlobalInvocationID.x + gl_NumWorkGroups.x * gl_WorkGroupSize.x * (gl_GlobalInvocationID.y + gl_NumWorkGroups.y * gl_WorkGroupSize.y * gl_GlobalInvocationID.z));
    ivec3 LightVoxel = ivec3(ID % LightVoxelDist, (ID / LightVoxelDist) % LightVoxelDist, ID / (LightVoxelDist * LightVoxelDist));
    ivec3 RealVoxel = ivec3((VoxelDist-LightVoxelDist)/2)+LightVoxel;
    ivec2 ReadLocation = ivec2(ID % LightBufferSize, ID / LightBufferSize);
    if (texelFetch(colortex2, ReadLocation, 0).r == 1.0){
        int storeID = 0;
        barrier();
        memoryBarrierBuffer();
        storeID = atomicAdd(LightIndex, 1);
        imageStore(colorimg7, ivec2(storeID%int(ViewSize.x), storeID/int(ViewSize.x)), vec4(RealVoxel, 1));
    }
}