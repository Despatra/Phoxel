#define UTILITY_ATMOSPHERE

// Dependencies //
#ifndef UTILITY_SPACE_CONVERSION
    #include SpaceConversion.glsl
#endif

// uniforms //
uniform int Dimension;
uniform float DimensionFogDensity;

uniform vec3 sunPosition;
uniform float cloudHeight;
uniform float cloudTime;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;

uniform vec3 endFlashPosition;
uniform float endFlashIntensity;

// Constants //
vec3 SunNormal = -normalize(mat3(gbufferModelViewInverse) * sunPosition);
vec3 SunTangent = normalize(cross(SunNormal, vec3(0.0, -sin(RadianSunPathRotation), -cos(RadianSunPathRotation))));

vec3 EndFlashNormal = -normalize(mat3(gbufferModelViewInverse) * endFlashPosition);
vec3 EndFlashTangent = normalize(cross(EndFlashNormal, vec3(0.0, 0.0, -1.0)));

// Colors are samples from actual game
const vec3 DaytimeSkyColor = vec3(0.36, 0.57, 1.0);
const vec3 NighttimeSkyColor = vec3(0.07, 0.07, 0.14);
const vec3 DaytimeFogColor = vec3(0.45, 0.62, 1.0);
const vec3 NighttimeFogColor = vec3(0.12, 0.12, 0.23);
const vec3 EndFogColor = vec3(0.82, 0.71, 0.83);
const vec3 EndFlashBaseColor = vec3(0.8, 0.58, 0.85);

float DaySkyFactor = clamp(-SunNormal.y * 4.0, -1.0, 1.0);

// Current Colors //
vec3 SunColor = SRGBToLinear(RGBFromKelvin(Atmosphere_Sun_Tempurature)) * Atmosphere_Sun_Brightness * smoothstep(0.0, 1.7, DaySkyFactor + 0.7);
vec3 MoonColor = SRGBToLinear(RGBFromKelvin(Atmosphere_Moon_Tempurature)) * Atmosphere_Moon_Brightness * smoothstep(0.0, 1.7, (-DaySkyFactor) + 0.7);
vec3 EndFlashColor = SRGBToLinear(EndFlashBaseColor) * endFlashIntensity * Atmosphere_EndFlash_Brightness;
// Purposefully done so that sunsets and sunrises won't affect the fogcolor
const vec3 SkyColor = mix(NighttimeSkyColor, DaytimeSkyColor, clamp(DaySkyFactor, 0.0, 1.0));

// Fog Info //
float FogDensity = Atmosphere_Volumes_FogDensity * DimensionFogDensity;
vec3 FogColor = (Dimension == 2) ? pow(EndFogColor, vec3(Camera_Gamma)) :
    (Dimension == 1) ? fogColor : mix(NighttimeFogColor, DaytimeFogColor, clamp(DaySkyFactor, 0.0, 1.0));

// Code //
vec3 AS_GetAmbientLight(vec3 Direction){
    vec3 AmbientColor;
    if (Dimension == 0){
        Direction.y = max(Direction.y, 0.0);

        const float Coefficient = 0.25;
        float Factor = Coefficient / (Direction.y * Direction.y + Coefficient);
        vec3 SkyColor = mix(SkyColor, FogColor, Factor);

        float SunShiftedDot = dot(Direction, mix(vec3(0.0, -1.0, 0.0), -SunNormal, 0.15)) - (SunNormal.y - 0.2);
        float SunsetFactor = clamp(1.0 - (DaySkyFactor + 0.2), 0.0, 1.0) * clamp(SunShiftedDot * 1.0, 0.0, 1.0);

        float MoonShiftedDot = dot(Direction, mix(vec3(0.0, -1.0, 0.0), -SunNormal*vec3(-1.0, 1.0, -1.0), 0.15)) + (SunNormal.y + 0.2);
        float MoonsetFactor = clamp(1.0 + DaySkyFactor, 0.0, 1.0) * clamp(MoonShiftedDot * 1., 0.0, 1.0);

        AmbientColor = SkyColor + (SunColor * min(8.0*SunsetFactor, 4.0)) + (MoonColor*64.0*MoonsetFactor);
    } else if (Dimension == 1){
        AmbientColor = vec3(0.2);
    } else {
        AmbientColor = vec3(0.2, 0.13, 0.21);
    }

    return SRGBToLinear(AmbientColor);
}