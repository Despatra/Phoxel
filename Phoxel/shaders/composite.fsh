// Rendering //
#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_COMPOSITE
#define PASS_FRAGMENT

// Textures //
uniform sampler2D depthtex0;
uniform sampler2D colortex5; // Screen normals
uniform sampler2D colortex6; // Screen Specular

/*
    const int colortex7Format = RGBA16F;
    const int colortex8Format = RGBA16F;
    const int colortex9Format = RGBA16F;
*/

// Uniforms //
uniform int heldItemId;
uniform int heldItemId2;
uniform int isEyeInWater;

// In //
in vec2 FragCoord;

// Out //
/* RENDERTARGETS: 7,8,9 */
layout(location = 0) out vec4 VolumeLight;   // Volume Lighting
layout(location = 1) out vec4 DirectLight;   // Direct Lighting
layout(location = 2) out vec4 GlobalLight;       // Global Illumination

// Includes //
#include Utility/Meshing.glsl
#include Utility/Atmosphere.glsl
#include Utility/Raytracing.glsl

// Globals // -- Clean up
float depth;
vec2 SampleCoord;

// Code //
void PathTrace(RayStruct Ray){
    // Sample screen
    HitDataStruct HitData;
    RT_WriteHitDataFromTextures(vec4(AS_GetAmbientLight(Ray.Direction), 1.0), vec4(0.0), texture(colortex6, SampleCoord), HitData);
    vec3 PixColor = vec3(HitData.Material.Emission);
    vec3 RayColor = vec3(1);

    HitData.Normal = -SunNormal;
    vec3 ViewPos = ( mat3(gbufferModelViewInverse)*ProjectAndDivide(gbufferProjectionInverse, vec3(SampleCoord, texture(depthtex0,vec2(SampleCoord)))*2.0-1.0) ) - (Ray.Direction*0.005);
    
    // Fog //
    VolumeStruct CameraSubmerged;
    switch (isEyeInWater) {
        case 0: CameraSubmerged = AtmosphereVolume; break;
        case 1: CameraSubmerged = WaterVolume; break;
        case 2: CameraSubmerged = LavaVolume; break;
        case 3: CameraSubmerged = PowderedSnowVolume; break;
    }
    float TraversalLength = length(ViewPos);
    VolumeLight = RT_SampleVolume(Ray, HitData, CameraSubmerged, TraversalLength);

    if (texture(depthtex0, SampleCoord).r == 1.0){
        HitData.Material.Color = vec3(0.0);
        RT_CelestialIntersection(Ray, HitData);
        RT_CloudIntersection(Ray, HitData);

        DirectLight = vec4(HitData.Material.Color, 1.0);
        return;
    }
    //Translate from Screen-space to View-space

    Ray.Position += ( mat3(gbufferModelViewInverse)*ProjectAndDivide(gbufferProjectionInverse, vec3(SampleCoord,texture(depthtex0,vec2(SampleCoord)))*2.0-1.0) ) - (Ray.Direction*0.01);;
    HitData.Normal = texture(colortex5, SampleCoord).xyz * 2.0 - 1.0;

    // Perform explicit light sample and add blocklight value for glowing
    DirectLight = vec4(PixColor + RT_GetOutgoingLight(Ray, HitData) + (HitData.Material.Emission*BlocklightLumenosity*Materials_Emission), 1.0);
    RT_Bounce(Ray, HitData);
    
    PixColor = vec3(0.0);
    for (int Bounce = 0; Bounce < Pathtracing_Bounces; Bounce++){
        HitData = RT_GetIntersection(Ray, (Ray.Specular) ? Pathtracing_TestDists_Specular : Pathtracing_TestDists_Rough);
        if (!HitData.Bounce){
            PixColor += HitData.Material.Color * RayColor;
            break;
        }
        Ray.Position += Ray.Direction*HitData.t;

        RayColor *= HitData.Material.Color;
        PixColor += RayColor * (RT_GetOutgoingLight(Ray, HitData) + (HitData.Material.Emission*BlocklightLumenosity*Materials_Emission));

        RT_Bounce(Ray, HitData);
    }
    GlobalLight = vec4(PixColor, 1.0);
}

void main(){
    // Linearize depths
    depth = LinearizeDepthFast(texture(depthtex0, FragCoord).r);
    vec3 ScreenPos = vec3(FragCoord, texture(depthtex0, FragCoord).r);
    SampleCoord = FragCoord;

    // Get ray direction
    RayStruct CameraRay;
    CameraRay.Position = vec3(VoxelArea / 2) + fract(EyeCameraPosition);
    CameraRay.Direction = normalize(SC_ScreenToRelative(ScreenPos));
    CameraRay.Specular = true;
    
    PathTrace(CameraRay);
}