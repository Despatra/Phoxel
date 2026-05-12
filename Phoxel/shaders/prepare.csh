#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_COMPOSITE
#define PASS_COMPUTE

// Compute Setup //
const int x8CubeCount = VoxelArea / 8;
layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;
const ivec3 workGroups = ivec3(x8CubeCount, x8CubeCount, x8CubeCount);

// Buffers //
layout(std430, binding = 0) buffer VoxelMapBuffer {
    uint[] Array;
} VoxelMap;

// Code //
uint GetComputeID(){
    return gl_GlobalInvocationID.x + 
        (gl_NumWorkGroups.x*gl_WorkGroupSize.x) * 
        (gl_GlobalInvocationID.y + (gl_NumWorkGroups.y*gl_WorkGroupSize.y) * gl_GlobalInvocationID.z);
}

void main(){
    uint ComputeID = GetComputeID();

    if ((ComputeID % 32) != 0) return;
    VoxelMap.Array[ComputeID / 32] = 0u;
}