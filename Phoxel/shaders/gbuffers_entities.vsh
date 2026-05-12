#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_GBUFFERS
#define PASS_VERTEX

// In //
in vec3 at_tangent;

// Out //
out vec2 TexCoord;
out vec4 GLColor;

out vec3 VertexNormal;
out mat3 TBN;

// Code //
mat3 CalculateTBN() {
    vec3 bitangent = cross(at_tangent.xyz, gl_Normal);
    return mat3(at_tangent.xyz, bitangent, gl_Normal);
}

void main() {
	gl_Position = ftransform();
	TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	GLColor = gl_Color;
    
    VertexNormal = gl_Normal;
    TBN = CalculateTBN();
}