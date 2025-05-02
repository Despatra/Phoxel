#define SETTINGS

#ifndef ViewSize
    uniform float viewWidth;
    uniform float viewHeight;
    vec2 ViewSize = vec2(viewWidth, viewHeight);
#endif

//Configurable
#define ProfileType 0 // [0 1]

//#define RenderMode
#define RenderFrames 120 // [30 45 60 75 90 105 120 135 150 165 180 195 210 225 240 10000]
#define RenderBounces 10 // [8 9 10 11 12 13 14 15 16 17 18 19 20]
#define RenderMaxDist 100 // [60 80 100 120 140 160 180 200]
#define RenderDelay 0.5 // [0.0 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0]
#ifdef RenderMode
    #define TemporalAccumulation RenderFrames
    #define Bounces RenderBounces
    #define TraceDist RenderMaxDist
    #define Samples 1
    #define LightSamples 1
    #define FogSamples 1
    #define MaxVoxelizationDist 512

    #define AA 2
    #define DenoiserFactor 0.0

    #define ScatterCount 12
    #define OpticalDepthSamples 10
    #define AuroraSamples 24
#endif

// Path Tracer
#define FogStrength 0.2 // [0.0 0.05 0.1 0.2 0.4 0.6 0.8]
#ifndef RenderMode
    #define TemporalAccumulation 10 // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
    #define Bounces 4 // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]
    #define TraceDist 20 // [10 15 20 25 30 35 40 45 50 55 60 65 70 75 80]
    #define Samples 1 // [1 2 3 4 5 6 7 8 9 10]
    #define LightSamples 3 // [1 2 3 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60]
    #define FogSamples 1 // [1 2 3 4 5 6 7 8]
#endif

// Voxelization
#define VoxelBufferSize 1449 // [512 1449 2661 4096 5725 7525 9483 11585]
const int VoxelDist = int(pow(VoxelBufferSize, 2.0/3.0));
#define LightBufferSize 1449 // [182 512 941 1449]
const int LightVoxelDist = int(pow(LightBufferSize, 2.0/3.0));
#define LightsBinSize 10 // [10 20 30 40 50 60 70 80 90 100]

// Lighting
#define PixelLock 0 // [0 8 16 32 64 128]
//#define ReflectLock
#define GiStrength 1.0 // [0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define LightSize 1.0 // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define BlockLightBrightness 2.0 // [0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0 3.2 3.4 3.6 3.8 4.0]

// Atmosphere
#define SunLightBrightness 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define MoonLightBrightness 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define DensityFallOff 8.0
#ifndef RenderMode
    #define ScatterCount 24 // [8 12 16 20 24 28 32]
    #define OpticalDepthSamples 4 // [4 5 6 7 8]
    #define AuroraSamples 16 // [8 16 24 32]
#endif

// Materials
#define MaterialMode 0 // [0 1 2]
#define IntegratedNormalsScale 0.5 // [0.125 0.1428 0.1666 0.2 0.25 0.3333 0.5 1.0]
#define NormalMapStrength 0.5 // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define ParallaxRenderDist 16 // [8 16 24 32 40 48 56 64]
#define POM
#define ParallaxSamples 8 // [6 7 8 9 10 11 12]
#define ParallaxDepth 0.25 // [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
//#define BinaryPOM

// Camera
#define Brightness 1.0 // [0.25 0.5 0.75 1.0 1.25 1.5]
#define Gamma 2.2 // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
//#define DOF
#define DOFStrength 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define UpscalingType 0 // [0 1 2]
#define DenoisingType 0 // [0]
#define AAStrength 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#ifndef RenderMode
    #define AA 1 // [0 1 2]
    #define DenoiserFactor 0.0 // [0.0 0.1 0.2 0.3 0.4 0.5]
    #define RenderScale 0.866 // [1.0 0.935 0.866 0.791 0.707 0.612 0.5 0.354]
#endif

// Debug
//#define Panorama
#define PanoramaScale 0.25 // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
//#define TraceLights

//Set by shader
const float ambientOcclusionLevel = 0.0;

//For Show Only
#define HowTo 0 // [0]
#define AboutShader 0 // [0]
#define GetPerformance 0 // [0]
#define ReduceNoise 0 // [0]
#define ParallaxAbout 0 // [0]
#define BinaryPOMAbout 0 // [0]
#define RenderModeAbout 0 // [0]