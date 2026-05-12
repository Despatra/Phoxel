// Temporal Accumulation //
#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_COMPOSITE
#define PASS_FRAGMENT

// Textures //
uniform sampler2D depthtex0; // Solid + Transparent

uniform sampler2D colortex0; // Raster Albedo

uniform sampler2D colortex3; // Accumulation
uniform sampler2D colortex4; // Previous Depth

uniform sampler2D colortex5; // Screen normals

uniform sampler2D colortex7; // Volume Lighting
uniform sampler2D colortex8; // Direct Lighting
uniform sampler2D colortex9; // Global Illumination

// In //
in vec2 FragCoord;

// Out //
/* RENDERTARGETS: 0,3,4 */
layout(location = 0) out vec4 AccumulatedColor;
layout(location = 1) out vec4 StoreColor;
layout(location = 2) out float StoreDepth; // Depth
/*
    const int colortex3Format = RGBA16F;
    const bool colortex3Clear = false;

    const int colortex4Format = R16;
    const bool colortex4Clear = false;
*/

// Includes //
#include Utility/SpaceConversion.glsl
#include Utility/Blur.glsl

// Code //
void main(){
    // Get sample position from the previous frame
    vec3 ScreenPos = vec3(FragCoord, texture(depthtex0, FragCoord).r);
    vec3 PrevScreenPos = SC_ScreenToPrevScreen(ScreenPos);

    float LinearDepth = LinearizeDepthFast(ScreenPos.z);
    float PrevDepth = texture(colortex4, PrevScreenPos.xy).r;
    float PrevLinearDepth = LinearizeDepthFast(PrevDepth);

    vec3 ViewDir = normalize(SC_ScreenToRelative(ScreenPos));
    vec3 PrevViewDir = normalize(SC_PrevScreenToRelative(PrevScreenPos));

    vec3 Normal = normalize(texture(colortex5, ScreenPos.xy).rgb * 2.0 - 1.0);
    vec3 PrevNormal = normalize(texture(colortex5, PrevScreenPos.xy).rgb * 2.0 - 1.0);

    // Clamp to prevent floating point errors
    float HistoryWeight = 1.0 - (1.0 / min(Post_TA, int((1.0 / (1.0 - texture(colortex3, PrevScreenPos.xy).a)) + 1.5)));
    if (
        (clamp(PrevScreenPos.xy, 0.0, 1.0) != PrevScreenPos.xy) ||
        (abs(ScreenPos.z - PrevDepth) > 0.005) || // Improve this threshold value
        (ScreenPos.z == 1.0)
    ) HistoryWeight = 0.0;

    if (HistoryWeight > 0.0){
        // History weight adjustment to prevent stretching by CyanEmber on the ShaderLabs Discord
        HistoryWeight *= dot(PrevNormal, Normal) * clamp(
            (pow2(LinearDepth) * dot(-PrevViewDir, PrevNormal)) / (pow2(PrevLinearDepth) * dot(-ViewDir, Normal)),
            0.0, 1.0
        );
    }
    
    vec3 PreviousColor = texture(colortex3, PrevScreenPos.xy).rgb;
    vec3 CombinedColor = texture(colortex8, FragCoord).rgb + texture(colortex9, FragCoord).rgb;
    StoreColor = vec4(mix(CombinedColor, PreviousColor, HistoryWeight), HistoryWeight);
    StoreDepth = texture(depthtex0, FragCoord).r;

    AccumulatedColor.rgb = clamp(LinearToSRGB(StoreColor.rgb), 0.0, 1.0); // Don't know how values are negative
    if (ScreenPos.z != 1.0) AccumulatedColor.rgb *= texture(colortex0, FragCoord).rgb;

    #ifdef Post_Denoising_Volumes
        vec4 VolumeLight = vec4(Blur_GetSample(colortex7, FragCoord, Post_Denoising_Volumes_Radius, Post_Denoising_Volumes_Samples), texture(colortex7, FragCoord).a);
    #else
        vec4 VolumeLight = texture(colortex7, FragCoord);
    #endif
    VolumeLight.rgb = LinearToSRGB(VolumeLight.rgb);

    if (ScreenPos.z == 1.0){
        AccumulatedColor.rgb += VolumeLight.rgb;
    } else {
        AccumulatedColor.rgb = mix(AccumulatedColor.rgb, VolumeLight.rgb, VolumeLight.a);
    }
}