#version 430 compatibility
#extension GL_ARB_shader_image_load_store : enable

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform ivec2 atlasSize;
uniform sampler2D colortex1;
uniform sampler2D colorimg8; // specular textures
layout(RGBA8) uniform image2D colorimg9; // output specular

in vec2 texcoord;
in vec4 glcolor;
in vec3 Normal;
in vec3 ViewDir;
in vec2 TextureSize;
in mat3 TBN;
flat in int BlockID;
flat in ivec2 StorePos;
flat in float Dist;

int TextureRes = int(ceil(TextureSize*vec2(atlasSize)/16.)*16.);
vec2 pixsize = TextureSize/TextureRes;

/* DRAWBUFFERS:056 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 ScreenNormals;
layout(location = 2) out vec4 SpecularTex;

#include "Includes/Settings.glsl"
#include "Includes/Parallax.glsl"

void main() {
    vec2 parallaxCoord = texcoord;
    float ParallaxHeight = 1.0;
    // force shader to recognize setting
    #ifdef POM
    #endif
    #if defined POM && (MaterialMode != 0)
        if (GetDepth(texcoord) < 1.0 && Dist<(ParallaxRenderDist)) parallaxCoord = performParallax(normalize(ViewDir*TBN), ParallaxHeight);
    #endif
    color = texture(gtexture, parallaxCoord)*glcolor;

    vec2 NormalTex;
    if (MaterialMode == 0){
        const float SampleDist = IntegratedNormalsScale;
        NormalTex.x = 4.0*(((GetDepth(parallaxCoord+(vec2(SampleDist,0)*pixsize)))-GetDepth(parallaxCoord-(vec2(SampleDist,0)*pixsize)))/(2.0*SampleDist));
        NormalTex.y = 4.0*(((GetDepth(parallaxCoord+(vec2(0,SampleDist)*pixsize)))-GetDepth(parallaxCoord-(vec2(0,SampleDist)*pixsize)))/(2.0*SampleDist));
        NormalTex = normalize(vec3(NormalTex, 1.0)).xy*-0.5+0.5;
    } else{
        NormalTex = texture(normals, parallaxCoord).xy; // z component is AO
    }
    vec3 ScrNorm = Normal;
    if (NormalMapStrength != 0.0) ScrNorm = normalize(TBN * vec3(NormalTex*2.0-1.0, (1./NormalMapStrength)*sqrt(1.0 - dot(NormalTex, NormalTex))));
    ScreenNormals = vec4(ScrNorm*0.5 + 0.5, 1);

    //Data Structure for Specular: r: Roughness, g: Reflectance, b: lumenosity, a: unuse
        //LabPBR: red: Smoothness, green: reflectance, blue: porosity, alpha: emission
        //SuesPBR: red: Smoothness, green: reflectance, blue: Emission, alpha: 
    vec4 Data = texture(specular, parallaxCoord);
    if (MaterialMode == 0){
        SpecularTex = vec4(1.0-(float(BlockID % 2) * 0.25), (BlockID % 2) * 0.75, float(BlockID-4000 > 100)*0.9, 1.0);
    } else{
        SpecularTex = vec4(pow(1.0-(Data.r), 1.0), Data.g, Data.a*float(Data.a!=1.0), 1); //LabPBR
    }

	if (color.a<.1){
		discard;
	}
}