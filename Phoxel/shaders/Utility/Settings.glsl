#define UTILITY_SETTINGS

// -- Pathtracing -- //
    #define Pathtracing_Bounces 2 // [2 3 4 5 6]
    #define Pathtracing_LightSamples 1 // [1 2 3 4]
    #define Pathtracing_VolumeSamples 2 // [1 2 4 8 16]

    // Intersection Test Distances //
    #define Pathtracing_TestDists_Shadow 24.0 // [8.0 16.0 24.0 32.0 40.0 48.0 56.0 64.0]
    #define Pathtracing_TestDists_Rough 16.0 // [8.0 16.0 24.0 32.0 40.0 48.0 56.0 64.0]
    #define Pathtracing_TestDists_Specular 24.0 // [8.0 16.0 24.0 32.0 40.0 48.0 56.0 64.0]

// -- Post Processing -- //
    #define Post_TA 4 // [1 2 4 8 16 32 64 128]

    // upscale [4x, 3x, 2x, 1.5x, 1x]
    // sqrt([25%, 33%, 50%, 66%, 100%])
    #define Post_Renderscale 1.0 // [0.5 0.577 0.707 0.816 1.0]

    // Denoising //
        // Volumes //
        #define Post_Denoising_Volumes
        #define Post_Denoising_Volumes_Radius 3.0 // [2.0 3.0 4.0]
        #define Post_Denoising_Volumes_Samples 3 // [3 4 5 6]

    // Depth of Field //
        // #define Post_DOF
        #define Post_DOF_Strength 0.5 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
        #define Post_DOF_Samples 4 // [4 8 12 16]

// -- Meshing -- //
    // Voxels //
    #define Meshing_Voxels_AreaExp 7 // [6 7]

// -- Materials -- //
    #define Materials_Emission 1.0 // [1.0 1.25 1.5 1.75 2.0]
    #define Materials_NormalStrength 1.0 // [0.0 0.25 0.5 0.75 1.0]

    // POM //
    #define Materials_POM
    #define Materials_POM_Distance 12 // [8 12 16 20 24]
    #define Materials_POM_Samples 128 // [64 96 128 160 192 224 256]
    #define Materials_POM_Depth 0.25 // [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]

// -- Lighting -- //

// -- Atmosphere -- //
    #define Atmosphere_SunPathRotation 10.0 // [-20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0]

        // Sun //
        #define Atmosphere_Sun_Tempurature 3600 // [1000 1200 1400 1600 1800 2100 2400 2800 3200 3600 4000 4300 4700 5100 5700 6300 7000 7600 8400 9000 11000 15000 20000 28000 40000]
        #define Atmosphere_Sun_Brightness 1.5 // [1.25 1.5 2.0]
        #define Atmosphere_Sun_Penumbra 0.2 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

        // Moon //
        #define Atmosphere_Moon_Tempurature 28000 // [1000 1200 1400 1600 1800 2100 2400 2800 3200 3600 4000 4300 4700 5100 5700 6300 7000 7600 8400 9000 11000 15000 20000 28000 40000]
        #define Atmosphere_Moon_Brightness 0.025 // [0.0125 0.025 0.05]
        #define Atmosphere_Moon_Penumbra 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

        // End Flashes //
        #define Atmosphere_EndFlash_Brightness 1.15 // [0.05 0.1 0.15 0.2 0.25]
        #define Atmosphere_EndFlash_Penumbra 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

        // Volumes //
        #define Atmosphere_Volumes_Threshold 0.1 // [0.05 0.075 0.1 0.125 0.15]
        #define Atmosphere_Volumes_FogDensity 1.0 // [0.5 0.75 1.0 1.5 2.0]



// -- Camera -- //
    #define Camera_Gamma 2.4 // [1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4]

// -- Test Features -- //
// #define POMAffectsDepth

// -- About -- //
#define HowTo 0 // [0]
#define AboutShader 0 // [0]

// -- Extras -- //
#define Use2DBlueNoise