#version 420 compatibility

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 Normal;
out vec3 ScreenTexCoord;
vec3 ViewPos;
out vec3 ViewDir;
out float WaterDepth;

vec3 ProjectNDivide(mat4 ProjectionMatrix, vec3 Position){
    vec4 Hpos = ProjectionMatrix*vec4(Position, 1);
    return Hpos.xyz/Hpos.w;
}

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
    Normal = gl_Normal;
    ViewPos = (gl_ModelViewMatrix*gl_Vertex).xyz;
    ViewDir = normalize(mat3(gbufferModelViewInverse)*ViewPos);
    ScreenTexCoord = ProjectNDivide(gbufferProjection, ViewPos) * 0.5 + 0.5;
    WaterDepth = (ViewPos.z);
}