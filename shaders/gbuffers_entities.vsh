#version 420 compatibility

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 Normal;
out mat3 TBN;

in vec3 at_tangent;

uniform mat4 gbufferModelViewInverse;

mat3 CalculateTBN(){
    vec3 tangent  = normalize(at_tangent.xyz);
    vec3 binormal = normalize(-cross(gl_Normal, at_tangent.xyz));
    
    tangent  = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix *  tangent);
    binormal =           mat3(gbufferModelViewInverse) * gl_NormalMatrix * binormal ;
    
    vec3 normal = normalize(cross(-tangent, binormal));
    
    binormal = cross(tangent, normal); // Orthogonalize binormal
    
    return mat3(tangent, binormal, normal);
}

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
    Normal = gl_Normal;
    TBN = CalculateTBN();
}