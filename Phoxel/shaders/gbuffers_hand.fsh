#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_GBUFFERS
#define PASS_FRAGMENT

// Textures //
uniform sampler2D gtexture;
uniform sampler2D specular;

// Uniforms //
uniform float alphaTestRef;

// In //
in vec2 TexCoord;
in vec4 GLColor;

in vec3 VertexNormal;

// Out //
/* RENDERTARGETS: 0,5,6 */
layout(location = 0) out vec4 FragColor;
layout(location = 1) out vec4 FragNormal;
layout(location = 2) out vec4 FragSpecular;

// Code //
void main() {
	FragColor = texture(gtexture, TexCoord) * GLColor;
    FragNormal = vec4(VertexNormal * 0.5 + 0.5, 1.0);
    FragSpecular = vec4(0.0, 0.0, 0.0, 1.0);

	if (FragColor.a < alphaTestRef) discard;
}