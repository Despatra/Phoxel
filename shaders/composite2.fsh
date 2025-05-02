#version 420 compatibility
#include "Includes/Settings.glsl"
#include "Includes/Depth.glsl"
// Temporal Accumulation //

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
mat4 gbufferPreviousModelViewInverse = inverse(gbufferPreviousModelView);
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform int frameCounter;
uniform float frameTimeCounter;
vec3 cameraOffset = previousCameraPosition-cameraPosition;

uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex7;
uniform sampler2D colortex3; // previous Frames
uniform sampler2D colortex4; // previous Depth and Exposure

in vec2 texcoord;

/* DRAWBUFFERS:034 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 StoreColor;
layout(location = 2) out vec2 OutData; // Depth and Exposure
/*
    const bool colortex3Clear = false;
    const bool colortex4Clear = false;
    const int colortex3Format = RGBA32F;
    const int colortex4Format = RG32F;
    const bool colortex3MipmapEnabled = true;
    const bool colortex0MipmapEnabled = true;
*/

vec3 LinearToSrgb(vec3 linear) {
    vec3 SRGBLo = linear * 12.92;
    vec3 SRGBHi = (pow(abs(linear), vec3(1.0/2.4)) * 1.055) - 0.055;
    vec3 SRGB = mix(SRGBHi, SRGBLo, step(linear, vec3(0.0031308)));
    return SRGB;
}

vec3 ProjectNDivide(mat4 Matrix, vec3 Pos){
    vec4 HgnsPos = Matrix*vec4(Pos,1);
    return HgnsPos.xyz/HgnsPos.w;
}

void main(){
    // Get sample position from the previous frame
    vec3 ScreenPos = vec3(texcoord, texture(depthtex1, texcoord));
    vec3 ViewPos = ProjectNDivide(gbufferProjectionInverse, ScreenPos*2.0-1.0);
    vec4 PrevPlayerPos = gbufferModelViewInverse * vec4(ViewPos, 1.0) - vec4(cameraOffset, 0.0);
    vec3 PrevViewPos = (gbufferPreviousModelView * PrevPlayerPos).xyz;
    vec3 PrevScreenPos = ProjectNDivide(gbufferPreviousProjection, PrevViewPos) * 0.5 + 0.5;
    vec2 ReadCoord = texcoord;
    ReadCoord = PrevScreenPos.xy;

    // Previous Data
    float PrevDepth = (near*far) / (texture(colortex4, ReadCoord).r * (near-far) + far);
    vec3 prevFrameData = texture(colortex3, ReadCoord).rgb;

    // Clamp to prevent floating point errors
    int passNum = min(TemporalAccumulation, int(texture(colortex3, ReadCoord).a*float(TemporalAccumulation) + 0.1) + 1);
    
    // New Data
    float Depth = (near*far) / (ScreenPos.z * (near-far) + far);
    #ifndef RenderMode
        vec2 PixelCenter = (floor(texcoord * ViewSize * RenderScale) + 0.5) / (RenderScale * ViewSize);
        #if (UpscalingType == 0)
            vec3 FrameData = texture(colortex7, PixelCenter).rgb;
        #elif (UpscalingType == 1)
            vec3 FrameData = texture(colortex7, texcoord).rgb;
        #else
            vec3 FrameData = texture(colortex7, texcoord+vec2(pow(PixelCenter.x-texcoord.x, 3.0), pow(PixelCenter.y-texcoord.y, 3.0))).rgb;
        #endif
    #else
        vec3 FrameData = texture(colortex7, texcoord).rgb;
        if (frameTimeCounter <= RenderDelay){
            passNum = 1;
        }
    #endif

    // Reproject to see if previous data should be overwritten
    vec3 PrevWorldPos = (mat3(gbufferPreviousModelViewInverse) * ProjectNDivide(inverse(gbufferPreviousProjection), vec3(ReadCoord, texture(colortex4,ReadCoord).r)*2.0-1.0)) + previousCameraPosition + gbufferPreviousModelViewInverse[3].xyz;
    vec3 WorldPos = mat3(gbufferModelViewInverse) * ViewPos + cameraPosition + gbufferModelViewInverse[3].xyz;
    #ifndef RenderMode
        if (clamp(ReadCoord,0.0,1.0)!=ReadCoord || (length(PrevWorldPos-WorldPos) / (1.0+(length(WorldPos)/100.0)) ) > 0.06 || Depth<.113) passNum = 1;
    #endif

    StoreColor = vec4(mix(prevFrameData, FrameData, 1.0/float(passNum)), float(passNum)/float(TemporalAccumulation));
    float Exposure = length(textureLod(colortex3, vec2(.5,.5), 8.0).rgb)*.01 + texture(colortex4, texcoord).g*.99;
    OutData = vec2(texture(depthtex1, texcoord).x, Exposure);

    #if defined Panorama || defined RenderMode
        color = vec4(pow(StoreColor.rgb*Brightness/pow(Exposure, 0.35), vec3(1.0/Gamma)), 1.0);
    #else
        if (texture(depthtex1, texcoord).r == 1.0){
            color = vec4(pow(StoreColor.rgb*Brightness/pow(Exposure, 0.35), vec3(1.0/Gamma)), 1.0);
        } else{
            color = vec4(pow(StoreColor.rgb*pow(texture(colortex0, texcoord).rgb, vec3(Gamma))*Brightness/pow(Exposure, 0.35), vec3(1.0/Gamma)), 1);
        }
    #endif
}