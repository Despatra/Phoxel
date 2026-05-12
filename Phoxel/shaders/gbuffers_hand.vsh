#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_GBUFFERS
#define PASS_VERTEX

// Uniforms //
uniform mat4 gbufferModelViewInverse;

// Out //
out vec2 TexCoord;
out vec4 GLColor;

out vec3 VertexNormal;

// Code //
void main() {
	gl_Position = ftransform();
	TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	GLColor = gl_Color;

    VertexNormal = mat3(gbufferModelViewInverse)*(gl_ModelViewMatrix*vec4(gl_Normal,1.0)).xyz;
}