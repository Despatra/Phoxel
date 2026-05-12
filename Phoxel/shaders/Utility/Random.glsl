#define UTILITY_RANDOM

// Textures //
#ifdef Use2DBlueNoise
    uniform sampler2D BlueNoiseTex;
#else
    uniform sampler3D BlueNoiseTex;
#endif

// Uniforms //
uniform int frameCounter;

// Globals //
#ifdef PASS_STYLE_COMPOSITE
    ivec2 Texel = ivec2(FragCoord * ScreenSize);
#else
    ivec2 Texel = ivec2(gl_FragCoord.xy);
#endif

int Blue_SampleCount = 0;
int IGN_SampleCount = 0;

int BlueNoiseSample = 0;
vec3 BlueNoiseSaved = vec3(0.0);

bool NormDistSampled = false;
float NormDistSaved = 0.0;

// Code //
#ifdef Use2DBlueNoise
const float g = 1.32471795724474602596;
const float a1 = 1.0 / g;
const float a2 = 1.0 / (g * g);
int BlueNoiseTexSize = textureSize(BlueNoiseTex, 0).x;

vec3 RN_Simulate3DSample(sampler2D Sampler, vec3 TexCoord){
    float Texelz = TexCoord.z * BlueNoiseTexSize;
    int z0 = int(floor(Texelz));
    int z1 = int(ceil(Texelz));

    vec2 z0Coord = TexCoord.xy + vec2(
        fract(0.5 + a1*z0),
        fract(0.5 + a2*z0)
    ) * BlueNoiseTexSize;
    vec2 z1Coord = TexCoord.xy + vec2(
        fract(0.5 + a1*z1),
        fract(0.5 + a2*z1)
    ) * BlueNoiseTexSize;

    vec3 z0Sample = texture(Sampler, fract(z0Coord)).rgb;
    vec3 z1Sample = texture(Sampler, fract(z1Coord)).rgb;

    return mix(z0Sample, z1Sample, fract(Texelz));
}

float RN_Blue_GetFloat(){
    

    switch (BlueNoiseSample){
        case 0:
            int SampleOffsetMul = Blue_SampleCount + frameCounter % 64;
            vec2 Offset = 128 * vec2(
                fract(0.5 + a1*SampleOffsetMul),
                fract(0.5 + a2*SampleOffsetMul)
            );

            Blue_SampleCount += 1;
            BlueNoiseSample += 1;
            BlueNoiseSaved = texelFetch(BlueNoiseTex, ivec2(Texel + Offset) % BlueNoiseTexSize, 0).rgb;
            return BlueNoiseSaved.r;
        case 1:
            BlueNoiseSample += 1;
            return BlueNoiseSaved.g;
        case 2:
            BlueNoiseSample = 0;
            return BlueNoiseSaved.b;
    }
}

#else
const int BlueNoiseTexSize = 128;

// STBN sampling code and bin file from Jbritain on shaderlabs discord / bin file generated from NVidia's STBN
// Use Blue for world-space noise
float RN_Blue_GetFloat(){
    const float g = 1.32471795724474602596;
    const float a1 = 1.0 / g;
    const float a2 = 1.0 / (g * g);

    switch (BlueNoiseSample){
        case 0:
            vec2 Offset = BlueNoiseTexSize * vec2(
                fract(0.5 + a1*Blue_SampleCount),
                fract(0.5 + a2*Blue_SampleCount)
            );

            Blue_SampleCount += 1;
            BlueNoiseSample += 1;
            BlueNoiseSaved = texelFetch(BlueNoiseTex, ivec3(ivec2(Texel + Offset) % BlueNoiseTexSize, frameCounter % 64), 0).rgb;
            return BlueNoiseSaved.r;
        case 1:
            BlueNoiseSample += 1;
            return BlueNoiseSaved.g;
        case 2:
            BlueNoiseSample = 0;
            return BlueNoiseSaved.b;
    }
}
#endif

// Code referenced from the paper "Interleaved Gradient Noise: A Different Kind of Low Discrepancy Sequence" by Alan Wolfe
// Use IGN for screen-space noise
float RN_IGN_GetFloat(){
    vec2 OffsetCoord = vec2(Texel) + vec2(5.588238) * ((frameCounter + IGN_SampleCount) % 64);

    IGN_SampleCount += 1;
    return fract(52.9829189 * fract( dot(OffsetCoord, vec2(0.06711056, 0.00583715)) ));
}

// Normal Distribution / Box Muller Transform
float RN_GetNormDist(){
    if (NormDistSampled){
        NormDistSampled = false;
        return NormDistSaved;
    } else {
        float Variate = sqrt(-2.0 * log(clamp(RN_Blue_GetFloat(), 0.0001, 0.9999)) );
        float Theta = 2.0*Pi * RN_Blue_GetFloat();

        NormDistSaved = Variate * cos(Theta);
        NormDistSampled = true;
        return Variate * sin(Theta);
    }
}

vec3 RN_GetDirection(){
    //return normalize(vec3(RN_Blue_GetFloat(),RN_Blue_GetFloat(),RN_Blue_GetFloat())*2.0 - 1.0);
    return normalize(vec3(RN_GetNormDist(), RN_GetNormDist(), RN_GetNormDist()));
}