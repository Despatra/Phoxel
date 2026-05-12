#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_GBUFFERS
#define PASS_FRAGMENT

// Textures //
uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

// Uniforms //
uniform ivec2 atlasSize;
uniform float alphaTestRef;

// In //
in vec2 TexCoord;
in vec4 GLColor;

in vec3 VertexNormal;
in mat3 TBN;

flat in vec2 BottomCoord;
in vec2 TextureSize;

in vec3 RelativePos;

// Out //
#ifdef Materials_POM
    out float gl_FragDepth;
#endif

/* RENDERTARGETS: 0,5,6 */
layout(location = 0) out vec4 FragColor;
layout(location = 1) out vec4 FragNormal;
layout(location = 2) out vec4 FragSpecular;

// Includes //
#include Utility/SpaceConversion.glsl
#include Utility/PBR.glsl

// Code //
void main(){
    vec2 GTexCoord = TexCoord;
    #ifdef Materials_POM
    #ifdef MC_TEXTURE_FORMAT_LAB_PBR
        gl_FragDepth = SC_RelativeToScreen(RelativePos).z;

        float ParallaxStrength = (1.0 - smoothstep(Materials_POM_Distance*0.5, Materials_POM_Distance, length(RelativePos)));
        if (ParallaxStrength > 0.0){
            float t = PBR_Parallax(
                GTexCoord,
                normalize(normalize(RelativePos) * TBN),
                Materials_POM_Depth * ParallaxStrength
            );
            #ifdef POMAffectsDepth
                gl_FragDepth = SC_RelativeToScreen(RelativePos + normalize(RelativePos)*t).z;
            #endif
        }
    #endif
    #endif
    ivec2 TexTexel = ivec2(GTexCoord * atlasSize);
    FragColor = texelFetch(gtexture, TexTexel, 0) * GLColor;

    vec3 TextureNormal = vec3(texelFetch(normals, TexTexel, 0).xy, 0.0) * 2.0 - 1.0;
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

    FragSpecular = texelFetch(specular, TexTexel, 0);
    
	if (FragColor.a < alphaTestRef) discard;
}