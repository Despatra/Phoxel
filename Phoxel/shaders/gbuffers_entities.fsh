#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_GBUFFERS
#define PASS_VERTEX

// Textures //
uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

// Uniforms //
uniform float alphaTestRef;
uniform vec4 entityColor;

// In //
in vec2 TexCoord;
in vec4 GLColor;

in vec3 VertexNormal;
in mat3 TBN;

// Out //
/* RENDERTARGETS: 0,5,6 */
layout(location = 0) out vec4 FragColor;
layout(location = 1) out vec4 FragNormal;
layout(location = 2) out vec4 FragSpecular;

// Code //
void main() {
	FragColor = texture(gtexture, TexCoord) * GLColor;
	FragColor.rgb = mix(FragColor.rgb, entityColor.rgb, entityColor.a);

    vec3 TextureNormal = vec3(texture(normals, TexCoord).xy, 0.0) * 2.0 - 1.0;
    #ifdef MC_TEXTURE_FORMAT_LAB_PBR
    if (Materials_NormalStrength == 0.0){
        TextureNormal = VertexNormal;
    } else {
        TextureNormal.z = (1.0 / Materials_NormalStrength) * sqrt(1.0 - dot(TextureNormal.xy, TextureNormal.xy));
        TextureNormal = TBN * normalize(TextureNormal);
    }
    #else
    TextureNormal = VertexNormal;
    #endif

    FragNormal = vec4(TextureNormal * 0.5 + 0.5, 1.0);

    FragSpecular = texture(specular, TexCoord);
    
	if (FragColor.a < alphaTestRef) discard;
}