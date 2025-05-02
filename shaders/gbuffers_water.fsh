#version 420 compatibility

uniform float frameTimeCounter;
uniform sampler2D noisetex;
uniform sampler2D depthtex1;
uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform float near;
uniform float far;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 Normal;
in vec3 ScreenTexCoord;
in vec3 ViewDir;
in float WaterDepth;

/* DRAWBUFFERS:056 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 ScreenNormals;
layout(location = 2) out vec4 SpecularTex;

float DepthFast(in float tex){
    return (near*far) / (tex * (near-far) + far);
}

vec3 ProjectNDivide(mat4 ProjectionMatrix, vec3 Position){
    vec4 Hpos = ProjectionMatrix*vec4(Position, 1);
    return Hpos.xyz/Hpos.w;
}

vec2 ToScreenSpace(in vec3 RayOrgn){
    float RayDepth = abs(RayOrgn.z);
    vec3 RayNDC = ProjectNDivide(gbufferProjection, RayOrgn);
    vec3 RayScreenPos = RayNDC*0.5+0.5;
    vec3 RayScreenView = mat3(gbufferModelViewInverse)*ProjectNDivide(gbufferProjectionInverse,vec3(RayScreenPos.xy,texture(depthtex1,RayScreenPos.xy))*2.-1.);
    return RayScreenPos.xy;
}

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	color *= texture(lightmap, lmcoord);
    
    float SolidDepth = DepthFast(texture(depthtex1, ScreenTexCoord.xy).r);

    //color.a = clamp(1.0*(pow(abs(WaterDepth-SolidDepth), 0.25)/4.0), 0.5, 1.0);
    ScreenNormals = vec4(Normal*0.5 + 0.5, 1);
    SpecularTex = vec4(0,1,0,1); //hardcode

	if (color.a < 0.1) {
		discard;
	}
}