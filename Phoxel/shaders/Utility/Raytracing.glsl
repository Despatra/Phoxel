#define UTILITY_RAYTRACING

// Textures //
uniform sampler2D colortex0;
uniform sampler2D AlbedoAtlas;
uniform sampler2D SpecularAtlas;

uniform sampler2D CelestialAtlas;
uniform sampler2D CloudTexture;

// Data Structures //
struct RayStruct {
    vec3 Position;
    vec3 Direction;

    bool Specular;
};

struct MaterialStruct {
    vec3 Color;
    float Emission;
    float Roughness;
    float Reflectance;
};

struct HitDataStruct {
    bool Bounce;
    float t;
    vec2 uv;
    vec3 Normal;
    MaterialStruct Material;
};

struct VolumeStruct {
    float Density; vec3 ScatterColor;
    bool Randomness; bool Glows;
};

struct QuadStruct {
    vec3 Center; vec2 Size;
    vec3 Normal; vec3 Tangent; vec3 Bitangent;
};

// Dependencies //
#ifndef UTILITY_RANDOM
    #include Random.glsl
#endif
#ifndef UTILITY_ATMOSPHERE
    #include Atmosphere.glsl
#endif
#ifndef UTILITY_BRDF
    #include BRDF.glsl
#endif

// Constants //
// Celestial Quads //
QuadStruct SunQuad = QuadStruct(
    -SunNormal*2048.0, vec2(1250.0),
    SunNormal, SunTangent, normalize(cross(SunNormal, SunTangent))
);

QuadStruct MoonQuad = QuadStruct(
    -SunQuad.Center, SunQuad.Size*0.75,
    -SunNormal, SunTangent, normalize(cross(SunNormal, SunTangent))
);

QuadStruct EndFlashQuad = QuadStruct(
    -EndFlashNormal*2048.0, vec2(1250.0),
    EndFlashNormal, EndFlashTangent, normalize(cross(EndFlashNormal, EndFlashTangent))
);

// Default Volumes //
const VolumeStruct AtmosphereVolume = VolumeStruct(
    FogDensity, FogColor,
    true, false
);

const VolumeStruct WaterVolume = VolumeStruct(
    0.075, vec3(0.0, 0.05, 0.7),
    true, false
);

const VolumeStruct LavaVolume = VolumeStruct(
    2.5, 2.0*vec3(0.79, 0.25, 0.05),
    true, true
);

const VolumeStruct PowderedSnowVolume = VolumeStruct(
    3.0, vec3(0.67, 0.75, 0.93),
    false, false
);

const VolumeStruct CloudVolume = VolumeStruct(
    0.075, vec3(0.62),
    true, false
);

// Code //
void RT_Bounce(inout RayStruct Ray, HitDataStruct HitData){
    vec3 RandDir = normalize(HitData.Normal + RN_GetDirection());
    
    if (RN_Blue_GetFloat() < HitData.Material.Reflectance){
        Ray.Direction = normalize(mix(reflect(Ray.Direction, HitData.Normal), RandDir, HitData.Material.Roughness));
        Ray.Specular = true;
    } else{
        Ray.Direction = RandDir;
        Ray.Specular = false;
    }
}

// Add texture direction info later for correct, for now this will work enough
vec2 RT_GetVoxelUV(vec3 RayPos, vec3 Normal){
    RayPos = fract(RayPos);

    /* Correct version:
    vec3 Tangent = cross(Normal, vec3(1.0, 0.0, 0.0));
    if (Tangent == vec3(0.0)) Tangent = cross(Normal, vec3(0.0, 0.0, 1.0));
    Tangent = normalize(Tangent);

    vec3 Bitangent = normalize(cross(Normal, Tangent));
    return vec2(dot(Tangent, RayPos), dot(Bitangent, RayPos));
    */

    vec2 interpolate;
    if (abs(Normal.y) != 0.0) {interpolate = RayPos.xz; interpolate = vec2(interpolate.x, interpolate.y);}
    if (abs(Normal.x) != 0.0) {interpolate = RayPos.zy; interpolate = vec2(1.0-interpolate.x, 1.0-interpolate.y);}
    if (abs(Normal.z) != 0.0) {interpolate = RayPos.xy; interpolate = vec2(1.0-interpolate.x, 1.0-interpolate.y);}
    return interpolate;
}

// Write to perform TBN
// Possibly merge RT_GetVoxelUV with this, so we have Tangent and Bitangent, plus it only being one function
void RT_WriteHitDataFromTextures(vec4 Albedo, vec4 Normal, vec4 Specular, inout HitDataStruct HitData){
    //HitData.Normal = Normal.rgb * 2.0 - 1.0;

    HitData.Material.Color = SRGBToLinear(Albedo.rgb);
    HitData.Material.Emission = fract(Specular.a);
    HitData.Material.Reflectance = Specular.g;
    HitData.Material.Roughness = pow2(1.0 - Specular.r);
}

// Used for SSPT
bool RT_ScreenSpaceIntersection(vec3 VoxelPos, out vec3 ScreenPos){
    vec3 RelativePos = SC_VoxelToRelative(VoxelPos);
    ScreenPos = SC_RelativeToScreen(RelativePos);
    
    float RayDepth = LinearizeDepthFast(ScreenPos.z - 0.000005);
    float LinearDepth = LinearizeDepthFast(texture(depthtex0, ScreenPos.xy).r);

    if ((RayDepth - LinearDepth) > 5.0) return false; // This just assumes all rendered points are 2m thick
    return RayDepth > LinearDepth;
}

// We'll use this for explicit sampling lights that aren't celestial (so we don't have to set the celestials to ridiculous lumenosities)
vec3 RT_BeerLambertObsorption(VolumeStruct Volume, float TraversalLength){
    return vec3(1.0);
}

void RT_VolumeIntersection(RayStruct Ray, inout HitDataStruct HitData, VolumeStruct Volume, float TraversalLength){
    float FogMissProb = exp(-Volume.Density * TraversalLength);
    float BlueNoise = RN_Blue_GetFloat();
    if (BlueNoise > FogMissProb){
        HitData.Bounce = true;
        HitData.Material = MaterialStruct(
            Volume.ScatterColor,
            0.0,
            1.0,
            0.0
        );
        HitData.t = -log(BlueNoise / (1.0 - FogMissProb)) / Volume.Density;
        HitData.Normal = RN_GetDirection();
    }
}

// Cloud data from within the game //
int CloudTextureSize = int(textureSize(CloudTexture, 0).x + 0.5);
const int CloudThickness = 4;
const int CloudCellSize = 12;

// Make them get sampled with RT_SampleVolume later //
bool RT_CloudIntersection(RayStruct Ray, inout HitDataStruct HitData){
    if (Dimension != 0) return false;
    if (Ray.Direction.y <= 0.0) return false;

    vec3 RayWorldPos = (Ray.Position - vec3(VoxelArea / 2)) + floor(EyeCameraPosition);
    float t = (cloudHeight - RayWorldPos.y) / Ray.Direction.y;
    vec2 PlaneHitXZ = RayWorldPos.xz + Ray.Direction.xz * t;

    vec2 uv = (PlaneHitXZ + vec2(cloudTime, 4.0)) / (CloudTextureSize * CloudCellSize);
    ivec2 Texel = ivec2(fract(uv) * CloudTextureSize);
    if (texelFetch(CloudTexture, Texel, 0).a > 0.0){
        if (!PickHit(t, HitData.t)) return false;
        HitData.Bounce = false;
        HitData.Material.Color = mix(HitData.Material.Color, vec3(0.015), exp(-t * FogDensity));
        //HitData.t = t;
        return true;
    }
    return false;
}

bool RT_QuadIntersection(QuadStruct Quad, RayStruct Ray, inout HitDataStruct HitData){
    float Step = -dot(Quad.Normal, Ray.Direction);
    float Dist = dot((Ray.Position - Quad.Center), Quad.Normal);
    float t = Dist / Step;
    if (!PickHit(t, HitData.t)) return false;

    vec3 HitPoint = (Ray.Position + Ray.Direction*t) - Quad.Center;
    vec2 uv = vec2(dot(Quad.Tangent, HitPoint), dot(Quad.Bitangent, HitPoint));
    uv /= Quad.Size;
    uv += 0.5;

    if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) return false;

    HitData.t = t;
    HitData.uv = uv.yx;
    HitData.Normal = Quad.Normal;
    return true;
}

void RT_CelestialIntersection(RayStruct Ray, inout HitDataStruct HitData){
    Ray.Position -= vec3(VoxelArea / 2);

    if (Dimension == 0){
        // Sun //
        if (RT_QuadIntersection(SunQuad, Ray, HitData)){
            HitData.Bounce = false;
            HitData.Material.Color += (smoothstep(0.0, 0.2, (DaySkyFactor + 0.7) / 1.7)) * 
                SRGBToLinear(texture(CelestialAtlas, mix(TextureData.SunCoords.xy, TextureData.SunCoords.zw, HitData.uv)).rgb);
        }

        // Moon //
        if (RT_QuadIntersection(MoonQuad, Ray, HitData)){
            HitData.Bounce = false;
            HitData.Material.Color += (smoothstep(0.0, 0.2, (-DaySkyFactor + 0.7) / 1.7)) *
                SRGBToLinear(texture(CelestialAtlas, mix(TextureData.MoonCoords.xy, TextureData.MoonCoords.zw, HitData.uv)).rgb);
        }
    }
    
    if (Dimension == 2){
        if (RT_QuadIntersection(EndFlashQuad, Ray, HitData)){
            HitData.Bounce = false;
            HitData.Material.Color += endFlashIntensity * 
                SRGBToLinear(texture(CelestialAtlas, mix(TextureData.EndFlashCoords.xy, TextureData.EndFlashCoords.zw, HitData.uv)).rgb);
        }
    }
}

void RT_VoxelTraversal(RayStruct Ray, inout HitDataStruct HitData, float MaxDistance){
    float t = 0.0;

    ivec3 Voxel = ivec3(floor(Ray.Position));
    vec3 FullStep = 1.0 / abs(Ray.Direction);
    vec3 SignDir = sign(Ray.Direction);
    vec3 Next = FullStep * abs(ceil(Ray.Direction) - fract(Ray.Position));

    for (int i = 0; i < 128; i++){
        if (t >= MaxDistance) return;
        vec3 StepDir; float Step;
        if (Next.x <= min(Next.y, Next.z))  { StepDir = vec3(SignDir.x, 0.0, 0.0); Step = Next.x; }
        else if (Next.y <= Next.z)          { StepDir = vec3(0.0, SignDir.y, 0.0); Step = Next.y; }
        else                                { StepDir = vec3(0.0, 0.0, SignDir.z); Step = Next.z; }

        t += Step;
        Voxel += ivec3(StepDir);
        Next -= Step;
        Next += FullStep * abs(StepDir);
        Ray.Position += Ray.Direction * Step;

        if (!MS_VoxelInRange(Voxel)){
            vec3 RayScreenPos;
            if (RT_ScreenSpaceIntersection(Ray.Position, RayScreenPos)){
                HitData.Bounce = true;
                HitData.t = t - Epsilon;
                HitData.Normal = texture(colortex5, RayScreenPos.xy).rgb * 2.0 - 1.0;

                RT_WriteHitDataFromTextures(texture(colortex0, RayScreenPos.xy), vec4(0.0), texture(colortex6, RayScreenPos.xy), HitData);
                return;
            }
        } else {
            if (MS_IsVoxel(Voxel)){
                Ray.Position += Ray.Direction* -Epsilon;
                VoxelStruct VoxelData = MS_GetVoxel(Voxel);

                HitData.Bounce = true;
                HitData.t = t - Epsilon; 
                HitData.uv = RT_GetVoxelUV(Ray.Position, -StepDir);
                HitData.Normal = -StepDir;

                vec2 AtlasUV = mix(VoxelData.TextureCoords.xy, VoxelData.TextureCoords.zw, HitData.uv);
                RT_WriteHitDataFromTextures(
                    texture(AlbedoAtlas, AtlasUV) * vec4(unpackUnorm4x8(VoxelData.Color).rgb, 1.0),
                    vec4(0.0),
                    texture(SpecularAtlas, AtlasUV),
                    HitData
                );
                return;
            }
        }
    }
}

HitDataStruct RT_GetIntersection(RayStruct Ray, float MaxDistance){
    HitDataStruct HitData;

    // Imagine we hit the sky first //
    HitData.Material.Color = AS_GetAmbientLight(Ray.Direction) * AtmosphereVolume.ScatterColor;
    HitData.t = -1.0;
    HitData.Bounce = false;

    RT_VoxelTraversal(Ray, HitData, MaxDistance);
    RT_CloudIntersection(Ray, HitData);
    RT_VolumeIntersection(Ray, HitData, AtmosphereVolume, HitData.t);
    if (Ray.Specular) RT_CelestialIntersection(Ray, HitData);
    return HitData;
}

vec3 RT_SampleCelestialLight(RayStruct Ray, HitDataStruct HitData){
    float Distance;
    vec3 LightColor;
    RayStruct ShadowRay = Ray;

    if (Dimension == 0){
        bool SampleSun = (-SunNormal.y > 0.0);
        LightColor = (SampleSun) ? SunColor : MoonColor;
        LightColor *= abs(DaySkyFactor);
        float Penumbra = (SampleSun) ? Atmosphere_Sun_Penumbra : Atmosphere_Moon_Penumbra;

        QuadStruct TargetQuad = (SampleSun) ? SunQuad : MoonQuad;
        // Multiplied by 0.5 again cus the sun and moon's diameter is only about half that of the quad
        vec2 PlanarSquare = (vec2(RN_Blue_GetFloat(), RN_Blue_GetFloat()) - 0.5) * 0.5 * Penumbra;
        vec3 SampleOffset =
            (PlanarSquare.x * TargetQuad.Size.x * TargetQuad.Tangent) +
            (PlanarSquare.y * TargetQuad.Size.y * TargetQuad.Bitangent);

        vec3 Offset = (TargetQuad.Center + SampleOffset) - ShadowRay.Position;
        Distance = length(Offset);
        ShadowRay.Direction = normalize(Offset);
    }

    if (Dimension == 1){
        return vec3(0.0);
    }

    if (Dimension == 2){
        LightColor = EndFlashColor;

        // Pushed sample point towards center since end flashes fall off towards to edges
        float Angle = RN_Blue_GetFloat();
        vec2 PlanarCircle = vec2(sin(Angle), cos(Angle)) * (RN_Blue_GetFloat()) * 0.5 * Atmosphere_EndFlash_Penumbra;
        vec3 SampleOffset =
            (PlanarCircle.x * EndFlashQuad.Size.x * EndFlashQuad.Tangent) +
            (PlanarCircle.y * EndFlashQuad.Size.y * EndFlashQuad.Bitangent);

        vec3 Offset = (EndFlashQuad.Center + SampleOffset) - ShadowRay.Position;
        Distance = length(Offset);
        ShadowRay.Direction = normalize(Offset);
    }

    // Don't account for absorption between hitpoint and light so we don't have to store extreme lumenosity values
    float Probabilty = BRDF_GetProbability(Ray.Direction, ShadowRay.Direction, HitData);
    if (Probabilty <= 0.0) return vec3(0.0);

    HitDataStruct ShadowHitData; ShadowHitData.t = -1.0;
    RT_VoxelTraversal(ShadowRay, ShadowHitData, Pathtracing_TestDists_Shadow);
    if (ShadowHitData.t > 0.0) return vec3(0.0);
    
    return LightColor * Probabilty;
}

vec3 RT_GetOutgoingLight(RayStruct Ray, HitDataStruct HitData){
    vec3 TotalLight = vec3(0.0);

    TotalLight += RT_SampleCelestialLight(Ray, HitData);

    return TotalLight;
}

float GetVolumeNoise(vec3 WorldPosition){
    const vec3[] SampleLayerOffsets = vec3[](
        vec3( 0.0,  0.0,  0.0),
        vec3( 0.1,  0.3, -0.25),
        vec3( 3.2, -1.72,  2.0)
    );

    const float VolumeNoiseScale = 8.0; // 1 Pixel == [Scale] Meters
    vec3 WorldAsTexCoord = WorldPosition / VolumeNoiseScale;

    #ifdef Use2DBlueNoise
    float Noise = 
        RN_Simulate3DSample(BlueNoiseTex, fract(WorldAsTexCoord / BlueNoiseTexSize)).r +
        RN_Simulate3DSample(BlueNoiseTex, fract((WorldAsTexCoord*3.0 + SampleLayerOffsets[1]) / BlueNoiseTexSize)).g +
        RN_Simulate3DSample(BlueNoiseTex, fract((WorldAsTexCoord*8.0 + SampleLayerOffsets[2]) / BlueNoiseTexSize)).b;

    #else
    float Noise = 
        texture(BlueNoiseTex, fract(WorldAsTexCoord / BlueNoiseTexSize)).r +
        texture(BlueNoiseTex, fract((WorldAsTexCoord*3.0 + SampleLayerOffsets[1]) / BlueNoiseTexSize)).g +
        texture(BlueNoiseTex, fract((WorldAsTexCoord*8.0 + SampleLayerOffsets[2]) / BlueNoiseTexSize)).b;

    #endif
    return mix(0.25, 4.0, smoothstep(0.25, 2.75, Noise));
}

// Only works for lights we can explicitly sample //
// Returns the color + alpha //
vec4 RT_SampleVolume(RayStruct Ray, HitDataStruct HitData, VolumeStruct Volume, float TraversalLength){
    // How much light we expect to make through the volume we've already traversed
    float Extinction = 1.0;
    vec3 ScatterColor = vec3(0.0);

    // The furthest we'll worry about collecting light from //
    float FurthestTraversal = -log(Atmosphere_Volumes_Threshold) / Volume.Density;
    float SampleLineLength = min(TraversalLength, FurthestTraversal);

    // Go to starting point of the volume along the ray
    Ray.Position += Ray.Direction * HitData.t;

    int SampleCount = Pathtracing_VolumeSamples;
    float StepLength = SampleLineLength*1.0 / SampleCount; // One more since we step in before iterating
    vec3 Step = Ray.Direction * StepLength;

    // Offset into the volumes for soft samples
    float Noise = RN_IGN_GetFloat() * StepLength; // Might need to be blue noise
    Ray.Position += Ray.Direction * Noise;
    Extinction *= exp(-Volume.Density * Noise);

    for (int i = 0; i < SampleCount; i++){
        float PrevExtinction = Extinction;
        float StepDensity = Volume.Density * GetVolumeNoise(Ray.Position + vec3(VoxelArea / 2) + floor(EyeCameraPosition));
        Extinction *= exp(-StepDensity * StepLength);
        float StepObsorption = PrevExtinction - Extinction;

        vec3 DirectSample = RT_GetOutgoingLight(Ray, HitData);
        if (Volume.Glows) DirectSample += Volume.ScatterColor;
        vec3 AmbientSample = AS_GetAmbientLight(Ray.Direction);

        vec3 PointScatterColor = Volume.ScatterColor * (DirectSample + AmbientSample) * StepObsorption;
        ScatterColor += PointScatterColor;
        Ray.Position += Step;
    }

    return vec4(ScatterColor, 1.0 - Extinction);
}

vec3 RT_SampleAurora(RayStruct Ray){
    return vec3(0);
}