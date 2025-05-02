#version 430 compatibility
#include "Includes/Settings.glsl"
#include "Includes/Depth.glsl"

//No touchy
#define Pi 3.141592653589
#define Epsilon .0005

//Buffers
uniform sampler2D noisetex;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0; // Image
uniform sampler2D colortex1; // Voxels
uniform sampler2D colortex5; // Screen normals
uniform sampler2D colortex6; // Screen Specular
uniform sampler2D colortex7; // Test
uniform sampler2D colortex8; // Textures
uniform sampler2D colortex9; // Specular textures
uniform sampler2D SunMoon;
/*
    const int colortex1Format = RGBA16;
    const int colortex2Format = RGBA16F;
    const int colortex7Format = RGBA16F;
*/

layout(std430, binding = 0) buffer LightBuffer{
    int LightIndex;
};

//Game Data
uniform int biome_category;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform int isEyeInWater;
uniform vec3 cameraPosition;
uniform vec3 skyColor;
uniform float sunAngle;
uniform vec3 sunPosition;
uniform int moonPhase;
uniform bool hasCeiling;

/* DRAWBUFFERS:7 */
layout(location = 0) out vec4 fragColor;

//Shader Data
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform int heldItemId;
uniform int heldItemId2;
in vec2 texcoord;
vec3 Normal;
uniform ivec2 atlasSize;

const float SurfaceRadius = 120.0;
const float AtmosphereRadius = SurfaceRadius + 960.0;

//Basic Definitions
struct Ray{
    vec3 orgn;
    vec3 dir;
};

struct Material{
    float Roughness;
    float Reflectance;
    float Emission;
    float RefractionProbability;
};

Ray ViewRay;
vec3 EyeCameraPosition = cameraPosition + gbufferModelViewInverse[3].xyz;
int Seed;
int PrevID;
float depth;
vec2 SampleCoord;

vec3 LightColor[LightsBinSize+3]; // +3 for sun, moon, and hand
vec3 LightPos[LightsBinSize+3];
vec2 LightProp[LightsBinSize+3];

#ifdef TraceLights
    int LightCount = LightIndex;
#else
    int LightCount = 3;
#endif

ivec2 imgSize = ivec2(VoxelBufferSize, VoxelBufferSize);

//Code
vec3 ProjectNDivide(mat4 Matrix, vec3 Pos){
    vec4 HgnsPos = Matrix*vec4(Pos,1);
    return HgnsPos.xyz/HgnsPos.w;
}

void LoadLights(){
    //x: Lumenosity, y: Size
    float TimeAngle = (Pi/2.)-(sunAngle*2.*Pi);
    vec3 HandLightPos = normalize(vec3(.4,-.3,0.0113));
    if (heldItemId2!=-1) HandLightPos.x = -HandLightPos.x;
    vec3 HandOff = normalize(mat3(gbufferModelViewInverse)*ProjectNDivide(gbufferProjectionInverse,HandLightPos))*0.5;
    LightColor[0] = vec3(1,.7, .55);
    LightPos[0] = vec3(sin(TimeAngle),cos(TimeAngle),.04)*4500.;
    LightProp[0] = vec2(30000000.*SunLightBrightness, 100);

    LightColor[1] = vec3(.6,.8,1); //Multiply by moon phase brightness in next update
    LightPos[1] = -LightPos[0]; //opposite sun
    LightProp[1] = vec2(500000.*MoonLightBrightness*(cos(float(moonPhase)*2.0*Pi/7.0) + 1.5)/2.0, 150);

    //Prevent Sun & Moon rendering if below horizon and fade
    LightProp[0].x *= min(pow(max(LightPos[0].y/1000., 0.), .5), 1.0) * float(!hasCeiling) * float(biome_category != CAT_THE_END && biome_category != CAT_NETHER);
    LightProp[1].x *= min(pow(max(LightPos[1].y/1000., 0.), .5), 1.0) * float(!hasCeiling) * float(biome_category != CAT_THE_END && biome_category != CAT_NETHER);

    LightColor[2] = vec3(1,1,1);
    LightProp[2] = vec2(0, .1398); // value calculated from pixel sizes (sqrt(2^2 + 1^1))
    LightPos[2] = vec3(VoxelDist/2)+mod(EyeCameraPosition,1.)+HandOff;

    if (max(heldItemId, heldItemId2)>3999) LightProp[2].x = BlockLightBrightness*8.0;
    if (max(heldItemId, heldItemId2)==4000) LightColor[2] = vec3(1,.7,.4);
    if (max(heldItemId, heldItemId2)==4001) LightColor[2] = vec3(.4,.7,1);
    if (max(heldItemId, heldItemId2)==4002) LightColor[2] = vec3(1,.2,.2);
    if (max(heldItemId, heldItemId2)==4004) LightColor[2] = vec3(1,.4,1);
    if (max(heldItemId, heldItemId2)==4005) LightColor[2] = vec3(.4,1,.5);
}

bool GetVoxel(in int ID){ // change!!
    ivec2 LoadPos = ivec2(ID%imgSize.x, ID/imgSize.x);
    return (texelFetch(colortex1, LoadPos, 0).x < 0.99);
}

float GetRand(in float mi, in float ma){
    Seed = Seed * 747796405 + 2891336453;
    int result = ((Seed >> ((Seed >> 28) + 4)) ^ Seed) * 277803737;
    result = (result >> 22) ^ result;
    return (mod(float(result)/149729.4323, (ma-mi)) + mi); 
}

float GetRandNormDist(){
    float theta = 2.0*Pi*GetRand(0.0,1.0);
    return sqrt(-2.0 * log(GetRand(-1.0,1.0))) * cos(theta);
}

vec3 GetRandVec(){
    return normalize(vec3(GetRand(-1.0,1.0), GetRand(-1.0,1.0), GetRand(-1.0,1.0)));
}

void GetTexture(in int ID, vec3 inNormal, out vec3 Color, out vec4 Material){
    if (ID == -2){
        Color = vec3(0.8, 0.8, 0.8);
        Material = vec4(1.0, 0.0, 0.0, 0.0);
    }
    vec4 TextureCoords = texelFetch(colortex1, ivec2(ID%imgSize.x, ID/imgSize.x), 0);
    vec2 interpolate;
    if (abs(inNormal.y) != 0.0) {interpolate = mod(ViewRay.orgn.xz, 1.0); interpolate = vec2(interpolate.x, interpolate.y);}
    if (abs(inNormal.x) != 0.0) {interpolate = mod(ViewRay.orgn.zy, 1.0); interpolate = vec2(1.0-interpolate.x, 1.0-interpolate.y);}
    if (abs(inNormal.z) != 0.0) {interpolate = mod(ViewRay.orgn.xy, 1.0); interpolate = vec2(1.0-interpolate.x, 1.0-interpolate.y);}
    vec2 SubTexCoord = vec2(mix(TextureCoords.x, TextureCoords.z, interpolate.x), mix(TextureCoords.y, TextureCoords.w, interpolate.y));
    Color = pow(texture(colortex8, SubTexCoord).rgb, vec3(Gamma));
    vec4 Specular = texture(colortex9, SubTexCoord);
    Material = vec4(Specular.rg, Specular.a*float(Specular.a!=1.0), 0);
}

vec3 VoxelNormal(in int ID){
    //         HitPoint - (Bottom Corner of Voxel + Half) -- Center of Voxel
    vec3 Dir = ViewRay.orgn-(floor(ViewRay.orgn+(ViewRay.dir*.005)) + .5);

    // Compare each coordinate and take max, as that will be the face of the normal, then normalize via "/abs(Dir.coord)"
    if (abs(Dir.x)>max(abs(Dir.y),abs(Dir.z))) {return vec3(Dir.x/abs(Dir.x),0,0);}
    if (abs(Dir.y)>abs(Dir.z)) {return vec3(0,Dir.y/abs(Dir.y),0);}
    return vec3(0,0,Dir.z/abs(Dir.z));
}

//keep this for screen space shadows
bool ScreenSpaceIntersection(vec3 Coord){
    vec3 RayPlayerPos = Coord-(float(VoxelDist/2)+mod(EyeCameraPosition, 1));
    vec3 RayViewPos = mat3(gbufferModelView)*RayPlayerPos;
    float RayDepth = length(RayViewPos);
    vec3 RayNDC = ProjectNDivide(gbufferProjection, RayViewPos);
    vec3 RayScreenPos = RayNDC*0.5+0.5;
    vec3 RayScreenView = mat3(gbufferModelViewInverse)*ProjectNDivide(gbufferProjectionInverse,vec3(RayScreenPos.xy,texture(depthtex0,RayScreenPos.xy))*2.-1.);
    return RayDepth-0.25 > length(RayScreenView) && abs(length(RayScreenView) - RayDepth) < 10.0;
}

float VoxelIntersection(in Ray Cast, inout int HitID, in float MaxDist, in ivec3 Exclude){
    int BlockID;
    vec3 Coord = Cast.orgn;
    float t = 0.;

    // Calculate first Intersection for each coordinate
    vec3 tCoord = (( floor(Coord)+vec3(Cast.dir.x>0., Cast.dir.y>0., Cast.dir.z>0.) ) - Coord) / Cast.dir;
    // This tells the program how far along the ray it will have to travel to move 1 along each axis
    vec3 StepLen = abs(1.0/Cast.dir);

    for (int i=0; i<TraceDist; i++){
        // DDA //
        // Get minimum between all three intersections -might change to manual calculation for a little speed up, not requiring if's
        float mi = min(tCoord.x, min(tCoord.y, tCoord.z));
        // Set "t" to the minimum
        t = mi;
        if (t>MaxDist) return -1.;
        // Offset intersection point to the next whole number coordinate
        if (tCoord.x == mi) {tCoord.x+=StepLen.x;}
        if (tCoord.y == mi) {tCoord.y+=StepLen.y;}
        if (tCoord.z == mi) {tCoord.z+=StepLen.z;}

        // Get world location of t and check if it's a voxel
        Coord = Cast.orgn+(Cast.dir*(t+Epsilon));
        if ((Coord.x<0.0 || Coord.y<0.0 || Coord.z<0.0) || (Coord.x>VoxelDist || Coord.y>VoxelDist || Coord.z>VoxelDist)){
            #if defined Panorama || defined RenderMode
            #else
                if (ScreenSpaceIntersection(Coord)){
                    HitID = -2;
                    return t-Epsilon;
                }
            #endif
        } else{
            ivec3 iCoord = ivec3(Coord);
            BlockID = iCoord.x + (iCoord.y*VoxelDist) + (iCoord.z*VoxelDist*VoxelDist);
            if ((iCoord != Exclude) && GetVoxel(BlockID)){
                // If so set the intersection and return "t"
                HitID = BlockID;
                return t-Epsilon;
            }
        }
    }
    return -1.; // If past the maximum intersection, return -1 to prevent it thinking it hit something
}

float SphereIntersection(in Ray Cast, in vec3 Center, in float radius){
    vec3 l = Center-Cast.orgn;
    float tc = dot(l,Cast.dir);
    //if (tc < 0.0) return -1.0;
    float d2 = dot(l,l) - tc*tc;
    if (d2 > radius*radius) return -1.0;
    float toc = sqrt(radius*radius - d2);
    float[] t = float[](tc-toc, tc+toc);
    if (t[0] > t[1]) t = float[](t[1], t[0]);
    if (t[0]< 0.0){
        t[0] = t[1];
    }
    return t[0];
}

// Setup for the atmospheric update
vec2 PlaneUV(vec3 PlaneCenter, vec3 PlaneNormal, vec3 HitPoint){
    vec3 e1 = normalize(cross(PlaneNormal, vec3(1,0,0)));
    if (e1 == vec3(0,0,0)){
        e1 = normalize(cross(PlaneNormal, vec3(0,0,1)));
    }
    vec3 e2 = normalize(cross(PlaneNormal, e1));
    return vec2(dot(e1, HitPoint), dot(e2, HitPoint));
}

float PlaneIntersection(vec3 PlaneCenter, vec3 PlaneNormal, Ray Cast){
    float Step = -dot(PlaneNormal, Cast.dir);
    float Dist = dot((Cast.orgn-PlaneCenter), PlaneNormal);
    return Dist/Step;
}

/*  Currently this function doesn't do much, but for more complex affects in the future
        it will be helpful to have this.
*/
float GetIntersection(in Ray Cast, inout int HitID, in float Max, in ivec3 Exclude){
    float Closest = Max-Epsilon;
    HitID = -1;
    Closest = VoxelIntersection(Cast, HitID, Closest, Exclude);
    return Closest;
}

vec3 SingleLight(in Ray Cast, in int ID, in vec3 inNormal){
    if (PixelLock != 0) Cast.orgn = (floor(Cast.orgn*float(PixelLock))+.5)/float(PixelLock);
    vec3 Rand = GetRandVec();
    // Make light softness cubed by normalizing based off of the maximum length coordinate
    Rand /= sqrt(pow(max( max(abs(Rand.x), abs(Rand.y)), abs(Rand.z) ), 2.0));
    #ifdef TraceLights
        ivec2 LightTextureLoc = ivec2(ID%int(viewWidth),ID/int(viewWidth));
        Cast.dir = ((texelFetch(colortex7, LightTextureLoc, 0).xyz+0.5)+(Rand*0.5*LightSize)) - Cast.orgn;
    #else
        Cast.dir = (LightPos[ID]+(Rand*LightProp[ID].y*LightSize)) - Cast.orgn;
    #endif

    float Dist = length(Cast.dir);
    Cast.dir /= Dist;

    float a = dot(Cast.dir, inNormal);
    if (a<0.) {return vec3(0);}

    int HitID;
    
    #ifdef TraceLights
        GetIntersection(Cast, HitID, Dist, ivec3(texelFetch(colortex7, LightTextureLoc, 0).xyz+0.5));
    #else
        GetIntersection(Cast, HitID, Dist, ivec3(LightPos[ID]));
    #endif
    if (HitID != -1) return vec3(0);

    #ifdef TraceLights
        return (vec3(2.0)*BlockLightBrightness*a*float(LightCount)) / (max(Dist*Dist, 16.0)*float(LightSamples));
    #else
        return (LightColor[ID]*LightProp[ID].x*a*float(LightCount)) / (max(Dist*Dist, 16.0)*float(LightSamples));
    #endif
}

vec3 GetLight(in vec3 inNormal){
    vec3 LightCol;
    #ifndef TraceLights
        for (int i=0; i<LightSamples / (LightCount); i++){
            for (int ID=0; ID<LightCount; ID++){
                LightCol += SingleLight(ViewRay, ID, inNormal);
            }
        }
    #endif
    int ID;
    for (int i=0; i<LightSamples % (LightCount); i++){
        #ifdef TraceLights
            ID = int( GetRand(.5, float(LightsBinSize+3)+.5) );
        #else
            ID = int(GetRand(0.5, 3.5));
        #endif
        LightCol += SingleLight(ViewRay, ID, inNormal);
    }
    return LightCol;
}

float CalcFresnel(in float x, in float R0){
    return clamp(R0 + (1.0-R0)*pow(1.0-x, 4.0), 0.0, 1.0);
}

void Bounce(in vec3 inNormal, in vec4 Mat){
    // Change to normal distribution (makes accurate)
    vec3 Rand = normalize(inNormal + GetRandVec());
    
    // Flip ray if negative
    if (dot(Rand,inNormal) < 0.0){
        Rand *= -1.0;
    }
    if (GetRand(0.0,1.0) < Mat.g){
        ViewRay.dir = normalize(mix(reflect(ViewRay.dir, inNormal), Rand, Mat.r));
    } else{
        ViewRay.dir = Rand;
    }
    #ifdef ReflectLock
        if (PixelLock != 0) ViewRay.orgn = (floor((ViewRay.orgn)*float(PixelLock))+.5)/float(PixelLock);
    #endif
}

float getDensity(in vec3 point, in vec3 Center){
    float Height = (length(point-Center) - SurfaceRadius) / (AtmosphereRadius-SurfaceRadius);
    return exp(-Height*DensityFallOff);
}

float getOpticalDepth(in Ray Cast, in float t, in vec3 Center){
    float Density = 0.0;
    float StepSize = t / float(OpticalDepthSamples-1);
    for (int i=0; i<OpticalDepthSamples; i++){
        Density += getDensity(Cast.orgn, Center) * StepSize;
        Cast.orgn += Cast.dir*StepSize;
    }
    return Density;
}

float max3(vec3 vec){
    return max(max(vec.x, vec.y), vec.z);
}

vec3 SampleAurora(in Ray AuroraRay, in int ASamples, bool Offset, bool move){
    vec3 AuroraColor = vec3(0);
    vec3 AuroraOffset = mod(vec3(1318,0,3832)*floor((frameTimeCounter/5.0)-float(Offset)), 12453.0);
    float PlaneT = SphereIntersection(AuroraRay, vec3(0,-1100,0), 2000.0);
    AuroraRay.orgn += cameraPosition + AuroraOffset * float(move);
    if (PlaneT > 0.0){
        vec3 PlanePos = AuroraRay.orgn + (PlaneT*AuroraRay.dir*(0.025+0.05*float(move)));
        for (int s=0; s<ASamples; s++){
            if (length(texture(noisetex, floor(PlanePos.xz/10.0)/300.0, 0).rgb) > 0.875 - 0.1*float(!move)){
                AuroraColor += mix(vec3(1,0,1), vec3(0,1,0), 1.0-pow(1.0 - (float(s) / float(ASamples)), 2.0)) * (1.0-clamp(pow((2000.0-length((PlanePos-(AuroraOffset*float(move))).xz-cameraPosition.xz))/2000.0, 5.0), 0.0, 1.0)) * ((1.0 - (float(s) / float(ASamples))) / float(ASamples));
            }
            PlanePos += AuroraRay.dir*(60.0 / float(ASamples));
        }
        AuroraColor = clamp(AuroraColor, 0.0, 1.0);
    }
    return AuroraColor;
}

vec3 SampleClouds(in Ray CloudRay, in int VSamples, bool Offset, bool move){
    vec3 AuroraColor = vec3(0);
    float PlaneT = SphereIntersection(CloudRay, vec3(0,-3000,0), 4000.0);
    CloudRay.orgn += cameraPosition + vec3(2.0*frameTimeCounter,0,0);
    if (PlaneT > 0.0){
        vec3 PlanePos = CloudRay.orgn + (PlaneT*CloudRay.dir*0.5);
        for (int s=0; s<VSamples; s++){
            vec3 NextOffset = CloudRay.dir*(40.0 / float(VSamples));
            if (length(texture(noisetex, floor(PlanePos.xz/20.0)/300.0, 0).rgb) > 1.0){
                AuroraColor += vec3(0.2) * clamp(1.0, 0.0, 1.0) * ((1.0 - (float(s) / float(VSamples))) / float(VSamples));
            }
            PlanePos += NextOffset;
        }
        AuroraColor = clamp(AuroraColor, 0.0, 1.0);
    }
    return AuroraColor;
}

vec3 SampleSky(in Ray SampleRay, in float hitT, in vec4 Material, in bool sun){
    Ray WorldRay = Ray(
        vec3(0, 800, 0),
        SampleRay.dir
    );

    vec3 MoonColor = vec3(0);
    if (sun && biome_category != CAT_THE_END && biome_category != CAT_NETHER){
        vec3 PlanePos = WorldRay.orgn + (PlaneIntersection(LightPos[0], -normalize(LightPos[0]), WorldRay)*WorldRay.dir);
        vec2 PUV = PlaneUV(LightPos[0], -normalize(vec3(LightPos[0].xy, 0.0)), PlanePos) / 260.0;
        if (dot(LightPos[0], WorldRay.dir) < 0.0){
            PUV /= 4.0;
            if (max(abs(PUV.x), abs(PUV.y)) < 1.0){
                MoonColor = pow(texture(colortex7, (((PUV*vec2(sign(LightPos[0].y)))/2.0+0.5)/vec2(4.0,2.0)) + (vec2(moonPhase%4, int(moonPhase/4)) / vec2(4.0,2.0))).rgb * 0.75, vec3(Gamma));
            }
        } else{
            if (max(abs(PUV.x), abs(PUV.y)) < 1.0){
                return vec3(1.0, 0.8, 0.4)*1.15*pow(floor((1.0 - max(abs(PUV.x), abs(PUV.y)))*5.0 + 2.0), 0.33);
            }
        }
    }
    vec3 AuroraColor = vec3(0);
    if (moonPhase == 4 && sunPosition.y < 0.0){
        AuroraColor = abs(normalize(sunPosition).y)*(mix(SampleAurora(WorldRay, AuroraSamples, true, true), SampleAurora(WorldRay, AuroraSamples, false, true), fract(frameTimeCounter/5.0)) + (SampleAurora(WorldRay, AuroraSamples, true, false) * 0.5));
    }
    if (biome_category != CAT_THE_END && biome_category != CAT_NETHER){
        AuroraColor += SampleClouds(WorldRay, AuroraSamples, true, true);
    }

    //const vec3 PlanetPos = vec3(0,400,0);
    const vec3 PlanetPos = vec3(0,0,0);
    float sampleT = min(hitT, SphereIntersection(WorldRay, PlanetPos, AtmosphereRadius));

    if (sampleT < 0.0) return vec3(0);

    if (pow(length(WorldRay.orgn - PlanetPos), 2.0) > AtmosphereRadius*AtmosphereRadius){
        WorldRay.orgn += WorldRay.dir * (sampleT + .001);
        sampleT = SphereIntersection(WorldRay, PlanetPos, AtmosphereRadius);
        float sampleT2 = SphereIntersection(WorldRay, PlanetPos, SurfaceRadius);
        if (sampleT2 < sampleT && sampleT2 > 0.0) sampleT = sampleT2;
    } else{
        //float sampleT2 = SphereIntersection(WorldRay, PlanetPos, SurfaceRadius);
        //if (sampleT2 < sampleT && sampleT2 > 0.0) sampleT = sampleT2;
    }

    vec3 Wavelengths;
    if (biome_category == CAT_THE_END){
        Wavelengths = vec3(375, 600, 500);
    } else if (biome_category == CAT_NETHER){
        Wavelengths = vec3(450, 540, 670);
    } else{
        Wavelengths = vec3(670, 540, 450);
    }

    vec3 ScatterCoeff = pow(400.0 / Wavelengths, vec3(4.0)) * 3.0;

    if (biome_category == CAT_NETHER) return max(AuroraColor+MoonColor,0.0);
    //Sun
    Ray scatterRay = WorldRay;
    vec3 ScatterLight = vec3(0);
    float StepT = sampleT / float(ScatterCount-1);
    for (int s=0; s<ScatterCount; s++){
        scatterRay.dir = normalize(LightPos[0]-scatterRay.orgn);
        float scatterT = SphereIntersection(scatterRay, PlanetPos, AtmosphereRadius);
        float scatterOpt = getOpticalDepth(scatterRay, scatterT, PlanetPos);
        float RayOpt = getOpticalDepth(WorldRay, StepT*float(s), PlanetPos);
        vec3 transmittence = exp(-(scatterOpt+RayOpt) * ScatterCoeff);
        ScatterLight += transmittence * getDensity(scatterRay.orgn, PlanetPos) * ScatterCoeff * vec3(0.8,1,0.8) * 1.0 * SunLightBrightness * StepT;
        scatterRay.orgn += WorldRay.dir*StepT;
    }
    //Moon
    scatterRay = WorldRay;
    for (int s=0; s<ScatterCount; s++){
        scatterRay.dir = normalize(LightPos[1]-scatterRay.orgn);
        float scatterT = SphereIntersection(scatterRay, PlanetPos, AtmosphereRadius);
        float scatterOpt = getOpticalDepth(scatterRay, scatterT, PlanetPos);
        float RayOpt = getOpticalDepth(WorldRay, StepT*float(s), PlanetPos);
        vec3 transmittence = exp(-(scatterOpt+RayOpt) * ScatterCoeff);
        ScatterLight += transmittence * getDensity(scatterRay.orgn, PlanetPos) * ScatterCoeff * vec3(.10,.20,.6) * 0.25 * MoonLightBrightness * StepT;
        scatterRay.orgn += WorldRay.dir*StepT;
    }
    if (biome_category == CAT_THE_END){
        ScatterLight *= (pow(vec3(1.0, 0.10, 0.75), vec3(1.25)) * 0.45);
        ScatterLight += + vec3(.015);
    }
    return max(ScatterLight+AuroraColor+MoonColor,0.0);
}

vec3 PathTrace(){
    PrevID = -1;

    // Sample screen
    vec4 TexMat = texture(colortex6, SampleCoord);
    vec3 TexColor = SampleSky(ViewRay, depth, TexMat, true);
    #if defined Panorama || defined RenderMode
        int FHitID = -1;
        float ft = GetIntersection(ViewRay, FHitID, float(VoxelDist), ivec3(-1000));
        vec3 PixColor = vec3(0);
        vec3 RayColor = vec3(1);
        vec3 ResetOrgn = ViewRay.orgn;

        vec3 fogColor;
        if (biome_category == CAT_NETHER){
            fogColor = vec3(1.0, 0.7, 0.2);
        } else{
            fogColor = vec3(0.2, 0.3, 1.0);
            if (isEyeInWater == 0){
                fogColor = SampleSky(ViewRay, 9999999.0, TexMat, false);
            } else if (isEyeInWater == 2){
                fogColor = vec3(1.0, 0.4, 0.2);
            } else if (isEyeInWater == 3){
                fogColor = vec3(1);
            }
        }
        for (int s = 0; s < FogSamples; s++){
            ViewRay.orgn += ViewRay.dir * GetRand(0.0, ft-0.1);
            PixColor += clamp(float(isEyeInWater + 1)*FogStrength*fogColor*GetLight(vec3(0,1,0)), 0.0, 1.0);
            if (isEyeInWater == 2) PixColor += 2.0*fogColor;
            ViewRay.orgn = ResetOrgn;
        }
        PixColor /= float(FogSamples);
        if (biome_category == CAT_NETHER) PixColor += fogColor * texture(depthtex0,vec2(SampleCoord)).x * 0.1;

        if (FHitID == -1) {
            TexColor = SampleSky(ViewRay, 9999999.0, TexMat, true);
            return PixColor + (TexColor*RayColor);
        }
        ViewRay.orgn += ViewRay.dir*ft;
        vec3 VoxNormal = VoxelNormal(FHitID);
        TexColor = skyColor;
        TexMat = vec4(1,1,0,1);
        GetTexture(FHitID, VoxNormal, TexColor, TexMat);
        TexMat.r *= pow(1.0-CalcFresnel(dot(ViewRay.dir, -VoxNormal), TexMat.g), 2.0);
        RayColor *= TexColor;
        PixColor += RayColor*(GetLight(VoxNormal)+(TexMat.b*2.0*BlockLightBrightness));
    #else
        vec3 PixColor = vec3(0);
        vec3 RayColor = vec3(1);
        vec3 ViewPos = ( mat3(gbufferModelViewInverse)*ProjectNDivide(gbufferProjectionInverse, vec3(SampleCoord,texture(depthtex0,vec2(SampleCoord)))*2.0-1.0) ) - (ViewRay.dir*0.01);
        vec3 ResetOrgn = ViewRay.orgn;

        // Fog
        vec3 fogColor;
        if (biome_category == CAT_NETHER){
            fogColor = vec3(1.0, 0.7, 0.2);
        } else{
            fogColor = vec3(0.2, 0.3, 1.0);
            if (isEyeInWater == 0){
                fogColor = SampleSky(ViewRay, 9999999.0, TexMat, false);
            } else if (isEyeInWater == 2){
                fogColor = vec3(1.0, 0.4, 0.2);
            } else if (isEyeInWater == 3){
                fogColor = vec3(1);
            }
        }
        for (int s = 0; s < FogSamples; s++){
            ViewRay.orgn += ViewRay.dir * GetRand(0.0, length(ViewPos)-0.1);
            PixColor += clamp(0.5*float((isEyeInWater*4) + 1)*FogStrength*fogColor*GetLight(vec3(0,1,0)), 0.0, 1.0);
            if (isEyeInWater == 2) {PixColor += 2.0*fogColor;}
            ViewRay.orgn = ResetOrgn;
        }
        PixColor /= float(FogSamples);
        if (biome_category == CAT_NETHER) PixColor += fogColor * texture(depthtex0,vec2(SampleCoord)).x * 0.1;

        if (texture(depthtex1, SampleCoord).x > 0.99999) return PixColor+SampleSky(ViewRay, 9999999.0, TexMat, true);
        //Translate from Screen-space to View-space

        ViewRay.orgn += ( mat3(gbufferModelViewInverse)*ProjectNDivide(gbufferProjectionInverse, vec3(SampleCoord,texture(depthtex0,vec2(SampleCoord)))*2.0-1.0) ) - (ViewRay.dir*0.01);;
        if (depth > .113){
            int FirstHit = -1;
            ViewRay.orgn += ViewRay.dir*GetIntersection(ViewRay, FirstHit, 0.015, ivec3(-1000));
        }
        vec3 VoxNormal = texture(colortex5, SampleCoord).xyz*2.-1.;

        // Convert multiplier to roughness
        TexMat.r *= pow(1.0-CalcFresnel(dot(ViewRay.dir, -VoxNormal), TexMat.g), 2.0);
        if (TexMat == vec4(0,0,0,0)) return vec3(1);

        // Perform explicit light sample and add blocklight value for glowing
        PixColor += GetLight(VoxNormal)+(TexMat.b*BlockLightBrightness);
    #endif

    Bounce(VoxNormal, TexMat);
    
    for (int b=0; b<Bounces; b++){
        int HitID = -1;
        float t = GetIntersection(ViewRay, HitID, float(VoxelDist), ivec3(-1000));
        if (HitID == -1){
            TexColor = SampleSky(ViewRay, 99999999.0, TexMat, true);
            return PixColor+(TexColor*RayColor);
        }
        ViewRay.orgn += ViewRay.dir*t;
        vec3 TexColor;
        vec4 TexMat;
        VoxNormal = VoxelNormal(HitID);
        TexColor = skyColor;
        TexMat = vec4(1,1,0,1);

        //x: Roughness, y: Reflectance (R0), z: Lumenosity, w: unused
        GetTexture(HitID, VoxNormal, TexColor, TexMat);
        //ScreenSpaceReflection(TexColor, TexMat, VoxNormal);
        
        TexColor *= GiStrength;

        // Convert multiplier to roughness
        TexMat.r *= pow(1.0-CalcFresnel(dot(ViewRay.dir, -VoxNormal), TexMat.g), 2.0);

        RayColor *= TexColor;
        #ifdef TraceLights
            PixColor += RayColor*GetLight(VoxNormal);
        #else
            PixColor += RayColor*(GetLight(VoxNormal)+(TexMat.b*2.0*BlockLightBrightness));
        #endif
        #ifndef RenderMode
            if (max(max(RayColor.r, RayColor.g), RayColor.b) < length(PixColor)){
                return PixColor;
            }
        #endif

        Bounce(VoxNormal, TexMat);
        PrevID = HitID;
    }
    return PixColor/float(1 + int(isEyeInWater > 0));
}

void main(){
    // Get seed for random numbers
    Seed = int(length(texture(noisetex, mod((texcoord)+vec2(frameTimeCounter/7.0, frameTimeCounter/3.0), 1.0)).rgb*vec3(12378, 78932, 7923)));
    
    // Linearize depths
    depth = LinearDepthFast(texelFetch(depthtex0, ivec2(texcoord*ViewSize), 1).x);

    // Get ray direction
    #ifdef Panorama
        vec3 ndc = vec3(vec2(0.5+((texcoord.x-0.5)*(1.0-PanoramaScale)), texcoord.y),texture(depthtex0,vec2(0.5+((texcoord.x-0.5)*(1.0-PanoramaScale)), texcoord.y)))*2.0 - 1.0;
        vec3 VDir = normalize(mat3(gbufferModelViewInverse)*ProjectNDivide(gbufferProjectionInverse,ndc));
        float Va = (texcoord.x-.5)*-2.0*Pi;
        float OA = atan(VDir.x/VDir.z) + (Pi * float(VDir.z < 0.0));
        vec2 XZ = vec2(sin(OA+(Va*PanoramaScale)), cos(OA+(Va*PanoramaScale)));
        Ray ProjectedRay = Ray(
            vec3(VoxelDist/2)+mod(EyeCameraPosition, 1),
            normalize(vec3(XZ.x*length(VDir.xz), VDir.y, XZ.y*length(VDir.xz)))
        );
    #else
        // TAA & DOF //
        SampleCoord = texcoord;
        #ifdef AA
            #ifdef RenderMode
                SampleCoord += (sqrt(GetRandVec().xy))/ViewSize;
            #else

            #endif
        #endif
        vec3 ndc = vec3(SampleCoord,texture(depthtex0,vec2(SampleCoord)))*2.0 - 1.0;
        Ray ProjectedRay = Ray(
            vec3(VoxelDist/2)+mod(EyeCameraPosition, 1),
            normalize(mat3(gbufferModelViewInverse)*ProjectNDivide(gbufferProjectionInverse,ndc))
        );
    #endif

    LoadLights();
    // Used for Debug
    //fragColor = texelFetch(colortex7, ivec2(texcoord.x*ViewSize.x, texcoord.y*ViewSize.y)/1, 0);
    //return;
    
    vec3 Color = vec3(0);
    for (int s=0; s<Samples; s++){
        ViewRay = ProjectedRay;
        Color += PathTrace();
    }

    fragColor = vec4(Color/float(Samples), 1);
}