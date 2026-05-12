#define UTILITY_COMMON
#include Settings.glsl

// Shader Controls //
const float ambientOcclusionLevel = 0.0;
const float sunPathRotation = Atmosphere_SunPathRotation;

// Buffers //
layout(std430, binding = 2) buffer TextureDataBuffer {
    vec4 SunCoords;
    vec4 MoonCoords;
    vec4 EndFlashCoords;
} TextureData;

// Uniforms //
uniform vec2 ScreenSize;
uniform float Pi;

// Constants //
const float BlocklightLumenosity = 8.0;
const float RadianSunPathRotation = Atmosphere_SunPathRotation * Pi/180.0;

const int VoxelArea = 1 << Meshing_Voxels_AreaExp;
const float Epsilon = 0.0005;

// Code //
float pow2(float v) {return v*v;}

// Raytracing //
bool PickHit(float new, float old) {return (new > Epsilon) && (new < old || old < Epsilon);}

// Color Conversion //
// https://www.titanwolf.org/Network/q/bb468365-7407-4d26-8441-730aaf8582b5/x
vec3 LinearToSRGB(vec3 linear) {
    vec3 higher = (pow(abs(linear), vec3(1.0 / Camera_Gamma)) * 1.055) - 0.055;
    vec3 lower  = linear * 12.92;
    return mix(higher, lower, step(linear, vec3(0.0031308)));
}

vec3 SRGBToLinear(vec3 sRGB) {
    vec3 higher = pow((sRGB + 0.055) / 1.055, vec3(Camera_Gamma));
    vec3 lower  = sRGB / 12.92;
    return mix(higher, lower, step(sRGB, vec3(0.04045)));
}

vec3 RGBFromKelvin(float Kelvin){
    Kelvin /= 100.0;
    vec3 Color = vec3(
        (Kelvin <= 66.0) ? 
            (255) :
            (329.698727446 * pow((Kelvin - 60.0), -0.1332047592)),
        (Kelvin <= 66.0) ?
            (99.4708025861 * log(Kelvin) - 161.1195681661) :
            (288.1221695283 * pow((Kelvin - 60.0), -0.0755148492)),
        (Kelvin >= 66.0) ?
            (255) :
            (Kelvin <= 19.0) ?
                (0) :
                (138.5177312231 * log(Kelvin - 10.0) - 305.0447927307)
    );

    return clamp(Color / 255.0, 0.0, 1.0);
}