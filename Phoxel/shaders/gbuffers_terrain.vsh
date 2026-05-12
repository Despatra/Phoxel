#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_GBUFFERS
#define PASS_VERTEX

// Out //
out vec2 TexCoord;
out vec4 GLColor;

out vec3 VertexNormal;
out mat3 TBN;

flat out vec2 BottomCoord;
out vec2 TextureSize;

out vec3 RelativePos;

// In //
in vec3 at_midBlock;
in vec3 mc_Entity;
in vec4 at_tangent;
in vec2 mc_midTexCoord;

// Includes //
#include Utility/SpaceConversion.glsl
#include Utility/Meshing.glsl

// Code //
mat3 CalculateTBN() {
    vec3 bitangent = cross(at_tangent.xyz, gl_Normal);
    return mat3(at_tangent.xyz, bitangent, gl_Normal);
}

void main(){
    gl_Position = ftransform();
	TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	GLColor = gl_Color;

    VertexNormal = gl_Normal;
    TBN = CalculateTBN();
    
    BottomCoord = mc_midTexCoord - abs(TexCoord - mc_midTexCoord);
    TextureSize = 2.0 * abs(TexCoord - mc_midTexCoord);

    RelativePos = mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix*gl_Vertex).xyz;

    int BlockID = int(mc_Entity.x + 0.5);
    if (((BlockID % 100) & 1u) == 0 && BlockID > 1000) return;

    ivec3 VoxelPos = SC_RelativeToVoxel(RelativePos);
    if (!MS_VoxelInRange(VoxelPos)) return;

    //convert to 2D coordinates and store to colortex1
    if (any(greaterThan(TexCoord, mc_midTexCoord.xy))) return;

    MS_StoreVoxel(
        RelativePos + (at_midBlock / 64.0),
        VoxelStruct(
            vec4(TexCoord, TexCoord+TextureSize),
            packUnorm4x8(gl_Color)
        )
    );
}