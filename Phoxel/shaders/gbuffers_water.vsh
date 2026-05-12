// Needs rewrite //
#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_GBUFFERS
#define PASS_VERTEX

// In //
in vec3 mc_Entity;
in vec4 at_tangent;

// Out //
out vec2 TexCoord;
out vec4 GLColor;

out vec3 Normal;
out mat3 TBN;

out vec3 WorldPosition;

flat out int BlockID;

// Includes //
#include Utility/SpaceConversion.glsl

// Code //
mat3 CalculateTBN() {
    vec3 bitangent = cross(at_tangent.xyz, gl_Normal);
    return mat3(at_tangent.xyz, bitangent, gl_Normal);
}

void main() {
	gl_Position = ftransform();
	TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	GLColor = gl_Color;

    Normal = gl_Normal;
	TBN = CalculateTBN(); // TBN Broken?

	WorldPosition = EyeCameraPosition + mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix*gl_Vertex).xyz;

	BlockID = int(mc_Entity.x + 0.5);
}