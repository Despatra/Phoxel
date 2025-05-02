#version 420 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D specular;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 Normal;

/* DRAWBUFFERS:056 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 ScreenNormals;
layout(location = 2) out vec4 SpecularTex;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	color *= texture(lightmap, lmcoord);
    ScreenNormals = vec4(Normal*0.5+0.5,1);
    vec4 Data = texture(specular, texcoord);
    SpecularTex = vec4(pow((1.-Data.r), 2.0), Data.g, Data.a*float(Data.a!=1.0), 1.0);
	if (color.a < 0.1) {
		discard;
	}
}