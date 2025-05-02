#define AAINCLUDE
#ifndef DEPTH
    #include "Depth.glsl"
#endif
#ifndef BLUR
    #include "Blur.glsl"
#endif

vec2 GetEdgeDirection(sampler2D depthtex, sampler2D normaltex, vec2 coord, vec2 range){
    vec2 DepthDiff = vec2(
        LinearDepthFast(texture(depthtex, coord+vec2(range.x,0.0)).r)-LinearDepthFast(texture(depthtex, coord-vec2(range.x,0.0)).r),
        LinearDepthFast(texture(depthtex, coord+vec2(0.0,range.y)).r)-LinearDepthFast(texture(depthtex, coord-vec2(0.0,range.y)).r)
    );
    vec3 NormDiff = texture(normaltex, coord+(range/1.0)).rgb-texture(normaltex, coord-(range/1.0)).rgb;
    bool Edge = (length(NormDiff)>0.01 || length(DepthDiff) > 0.5);
    return DepthDiff*float(Edge);
}

vec4 FXAA(sampler2D maintex, sampler2D depthtex, sampler2D normaltex, vec2 coord, vec2 range, float strength){
    vec2 Dir = GetEdgeDirection(depthtex, normaltex, coord, range);
    return mix(texture(maintex, coord), Blur(maintex, coord, Dir, min(float(length(Dir)>0.01), 1.0)), strength*min(length(Dir),1.0));
}