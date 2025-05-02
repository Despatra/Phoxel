#define BLUR

vec4 MultiSampleLODBlur(sampler2D texture, vec2 coord, float Start, float End, int Count){
    vec4 Color = vec4(0);
    if (Start < 2.0) return textureLod(texture, coord, Start);
    for (float LOD = Start; LOD < End; LOD += (End-Start)/float(Count)){
        Color += textureLod(texture, coord, LOD);
    }
    return Color/float(Count);
}

vec4 Blur(sampler2D texture, vec2 coord, vec2 dir, float strength){
    return MultiSampleLODBlur(texture, coord, strength*1.0, strength*3.0, 4);
}