// Post Processing //
#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_COMPOSITE
#define PASS_FRAGMENT

// Textures //
uniform sampler2D depthtex1;
uniform sampler2D colortex0;

uniform sampler2D colortex5;
uniform sampler2D colortex6;

// Uniforms //
uniform float centerDepthSmooth;

// In //
in vec2 FragCoord;

// Out //
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 FragColor;

// Includes //
#include Utility/SpaceConversion.glsl
#include Utility/Blur.glsl

// Code //
void main(){
    FragColor = texture(colortex0, FragCoord);

    #ifdef Post_DOF
        float focus = abs(pow(LinearizeDepthFast(centerDepthSmooth), 0.5) - pow(LinearizeDepthFast(texture(depthtex1, FragCoord).r) , 0.5));
        focus = clamp(focus, 0.0, 1.0);
        FragColor.rgb = Blur_GetSample(colortex0, FragCoord, focus*Post_DOF_Strength*10.0, Post_DOF_Samples);
    #endif

    //FragColor.rgb = texture(colortex6, FragCoord).rga;
}