#define UTILITY_SPACE_CONVERSION

// Uniforms //
uniform mat4 gbufferModelView;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferProjectionInverse;

uniform vec3 previousCameraPosition;
uniform vec3 cameraPosition;

uniform float near;
uniform float far;

// Constants //
mat4 gbufferPreviousProjectionInverse = inverse(gbufferPreviousProjection);
mat4 gbufferPreviousModelViewInverse = inverse(gbufferPreviousModelView);

vec3 EyeCameraPosition = cameraPosition + gbufferModelViewInverse[3].xyz;
vec3 CameraOffset = previousCameraPosition - cameraPosition;

// Code //
// Common //
float LinearizeDepthFast(float x){
    return (near*far) / (x * (near-far) + far);
}

vec3 ProjectAndDivide(mat4 Matrix, vec3 Position){
    vec4 HPosition = Matrix * vec4(Position, 1.0);
    return HPosition.xyz / HPosition.w;
}

ivec3 SC_RelativeToVoxel(vec3 RelativePos){
    return ivec3(floor(RelativePos + fract(EyeCameraPosition))) + ivec3(VoxelArea / 2);
}

vec3 SC_VoxelToRelative(vec3 VoxelPos){
    return VoxelPos - (float(VoxelArea / 2) + fract(EyeCameraPosition));
}

vec3 SC_ScreenToRelative(vec3 ScreenPos){
    vec3 NDCPos = ScreenPos * 2.0 - 1.0;
    vec3 ViewPos = ProjectAndDivide(gbufferProjectionInverse, NDCPos);
    return (gbufferModelViewInverse * vec4(ViewPos, 1.0)).xyz;
}

vec3 SC_RelativeToScreen(vec3 RelativePos){
    vec3 ViewPos = (gbufferModelView * vec4(RelativePos, 1.0)).xyz;
    vec3 NDCPos = ProjectAndDivide(gbufferProjection, ViewPos);
    return (NDCPos + 1.0) / 2.0;
}

vec3 SC_RelativeToView(vec3 RelativePos){
    return (gbufferModelView * vec4(RelativePos, 1.0)).xyz;
}

vec3 SC_ScreenToPrevScreen(vec3 ScreenPos){
    vec3 NDCPos = ScreenPos * 2.0 - 1.0;
    vec3 ViewPos = ProjectAndDivide(gbufferProjectionInverse, NDCPos);
    vec3 RelativePos = (gbufferModelViewInverse * vec4(ViewPos, 1.0)).xyz;
    vec3 PrevRelativePos = RelativePos - CameraOffset;
    vec3 PrevViewPos = (gbufferPreviousModelView * vec4(PrevRelativePos, 1.0)).xyz;
    vec3 PrevNDCPos = ProjectAndDivide(gbufferPreviousProjection, PrevViewPos);
    return (PrevNDCPos + 1.0) / 2.0;
}

vec3 SC_PrevScreenToRelative(vec3 PrevScreenPos){
    vec3 NDCPos = PrevScreenPos * 2.0 - 1.0;
    vec3 ViewPos = ProjectAndDivide(gbufferPreviousProjectionInverse, NDCPos);
    return (gbufferPreviousModelViewInverse * vec4(ViewPos, 1.0)).xyz;
}