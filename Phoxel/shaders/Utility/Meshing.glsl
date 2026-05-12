#define UTLITY_MESHING

// Dependencies //
#ifndef UTILITY_COMMON
    #include Common.glsl
#endif
#ifndef UTILITY_SPACE_CONVERSION
    #include SpaceConversion.glsl
#endif

// Data Structures //
//- 20 bytes
struct VoxelStruct {
    vec4 TextureCoords;
    uint Color;
};

// Buffers //
layout(std430, binding = 0) buffer VoxelMapBuffer {
    uint[] Array;
} VoxelMap;

layout(std430, binding = 1) buffer VoxelDataMapBuffer {
    VoxelStruct[] Array;
} VoxelDataMap;

// Code //
bool MS_VoxelInRange(ivec3 VoxelPos){
    return !( any(lessThan(VoxelPos, ivec3(0))) || any(greaterThanEqual(VoxelPos, ivec3(VoxelArea))) );
}

void MS_GetVoxelIDs(ivec3 VoxelPos, out int VoxelID, out int ArrayID, out int BitID){
    VoxelID = VoxelPos.x + (VoxelPos.y << Meshing_Voxels_AreaExp) + (VoxelPos.z << (Meshing_Voxels_AreaExp << 1));
    ArrayID = VoxelID / 32;
    BitID = VoxelID % 32;
}

void MS_StoreVoxel(vec3 RelativePos, VoxelStruct VoxelData){
    ivec3 VoxelPos = SC_RelativeToVoxel(RelativePos);
    if (!MS_VoxelInRange(VoxelPos)) return;
    int VoxelID; int ArrayID; int BitID;
    MS_GetVoxelIDs(VoxelPos, VoxelID, ArrayID, BitID);

    VoxelDataMap.Array[VoxelID] = VoxelData;
    atomicOr(VoxelMap.Array[ArrayID], 1u << BitID);
}

VoxelStruct MS_GetVoxel(ivec3 VoxelPos){
    int VoxelID; int ArrayID; int BitID;
    MS_GetVoxelIDs(VoxelPos, VoxelID, ArrayID, BitID);
    return VoxelDataMap.Array[VoxelID];
}

bool MS_IsVoxel(ivec3 VoxelPos){
    int VoxelID; int ArrayID; int BitID;
    MS_GetVoxelIDs(VoxelPos, VoxelID, ArrayID, BitID);
    return (VoxelMap.Array[ArrayID] & (1u << BitID)) != 0;
}