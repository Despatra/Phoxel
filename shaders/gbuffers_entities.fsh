#version 420 compatibility

uniform sampler2D gtexture;
uniform vec4 entityColor;
uniform sampler2D normals;
uniform sampler2D specular;

in vec2 texcoord;
in vec4 glcolor;
in vec3 Normal;
in mat3 TBN;

/* DRAWBUFFERS:056 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 ScreenNormals;
layout(location = 2) out vec4 SpecularTex;

#include "Includes/Settings.glsl"
//#include "Includes/Parallax.glsl"

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

    vec2 NormalTex = texture2D(normals, texcoord).xy; // z component is AO
    vec3 ScrNorm = normalize(TBN * vec3(NormalTex*2.0-1.0, (1./NormalMapStrength)*sqrt(1.0 - dot(NormalTex, NormalTex))));
    ScrNorm = Normal;
    ScreenNormals = vec4((ScrNorm+1.)/2.,1.);

    vec4 Data = texture(specular, texcoord);
    SpecularTex = vec4(pow(1.-(Data.r), 2.0), Data.g, Data.a*float(Data.a!=1.0), 1);
    
	if (color.a < 0.1) {
		discard;
	}
}