// Needs rewrite //
#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_GBUFFERS
#define PASS_FRAGMENT

// Textures //
uniform sampler2D gtexture;
uniform sampler2D normals;

uniform sampler2D noisetex;

// Uniforms //
uniform float alphaTestRef;
uniform float frameTimeCounter;

uniform vec3 cameraPosition;

// In //
in vec2 TexCoord;
in vec4 GLColor;

in vec3 Normal;
in mat3 TBN;

in vec3 WorldPosition;

flat in int BlockID;

// Out //
/* RENDERTARGETS: 0,5,6 */
layout(location = 0) out vec4 FragColor;
layout(location = 1) out vec4 FragNormal;
layout(location = 2) out vec4 FragSpecular;

// Constants //
const float[] NoiseMults = float[]( 0.15, 0.25, 0.6 );
const float[] WaveDirections = float[]( 18.0, 35.0, 65.0 );
const float[] WaveSpeeds = float[]( -0.35, 0.7, 0.4 );
const vec2[] NoiseScales = vec2[](
    24.0*vec2(0.8, 4.2),
    50.0*vec2(0.8, 3.4),
    60.0*vec2(0.8, 2.8)
);

const float NormalSampleOffset = 0.05;

// Code //
float CalculateHeight(vec2 Position){
    float Height = 0.0;
    for (int lvl = 0; lvl < 3; lvl++){
        float Mult = NoiseMults[lvl];
        vec2 Scale = NoiseScales[lvl];
        float WaveDirection = WaveDirections[lvl] * (Pi / 180.0);
        mat2 RotationMat = mat2(
            cos(WaveDirection), -sin(WaveDirection),
            sin(WaveDirection), cos(WaveDirection)
        );
        vec2 WaveMovementOffset = vec2(0.0, frameTimeCounter*WaveSpeeds[lvl]) * RotationMat;

        vec2 NoiseUV = Position + WaveMovementOffset;
        vec4 Noise = textureLod(noisetex, fract((NoiseUV * RotationMat) / Scale), 1);
        switch (lvl){
            case 0: Height += Noise.r*Mult; break;
            case 1: Height += Noise.g*Mult; break;
            case 2: Height += Noise.b*Mult; break;
        }
    }
    return Height;
}

void main(){
    FragColor = texture(gtexture, TexCoord) * GLColor;
    // Remove once we do refraction //
    FragColor.rgb = mix(vec3(1.0), FragColor.rgb, FragColor.a);
    FragColor.a = 1.0;
    
    if (BlockID == 1002){
        float PointHeight = CalculateHeight(WorldPosition.xz);

        vec2 CalculatedNormal = (vec2(
            CalculateHeight(WorldPosition.xz + vec2(NormalSampleOffset, 0.0)),
            CalculateHeight(WorldPosition.xz + vec2(0.0, NormalSampleOffset))
        ) - PointHeight) / NormalSampleOffset;
        vec3 NormalizedCalculated = normalize(vec3(CalculatedNormal, 64.0));

        FragNormal = vec4(normalize(TBN * NormalizedCalculated)*0.5 + 0.5, 1);
    } else {
        FragNormal = vec4(normalize(TBN * texture(normals, TexCoord).rgb*2.0 - 1.0)*0.5 + 0.5, 1);
    }

    FragSpecular = vec4(0.0, 1.0, 0.0, 1.0); // Hardcoded

	if (FragColor.a < alphaTestRef) discard;
}