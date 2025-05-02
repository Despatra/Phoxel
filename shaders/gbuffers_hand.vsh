#version 420 compatibility

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 Normal;

uniform mat4 gbufferModelViewInverse;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
    Normal = mat3(gbufferModelViewInverse)*(gl_ModelViewMatrix*vec4(gl_Normal,1.0)).xyz;
}