// Integrated PBR //
#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_COMPOSITE
#define PASS_COMPUTE

// Compute Setup //
layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;
const ivec3 workGroups = ivec3(8, 8, 1);

// Textures //

// Code //
uint GetComputeID(){
    return gl_GlobalInvocationID.x + 
        (gl_NumWorkGroups.x*gl_WorkGroupSize.x) * 
        (gl_GlobalInvocationID.y + (gl_NumWorkGroups.y*gl_WorkGroupSize.y) * gl_GlobalInvocationID.z);
}

void main(){
    uint ComputeID = GetComputeID();

    
}