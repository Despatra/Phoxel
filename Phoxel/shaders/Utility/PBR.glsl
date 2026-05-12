#define UTILITY_PBR

// Dependencies //
#ifndef UTILITY_RANDOM
    #include Random.glsl
#endif

// Code //
float PBR_GetPOMDepth(vec2 GTexCoord){
    GTexCoord = fract(GTexCoord) * TextureSize + BottomCoord;
    return texelFetch(normals, ivec2(GTexCoord*atlasSize), 0).a;
}

// Returns t where there's an intersection
float PBR_Parallax(inout vec2 GTexCoord, vec3 TexDir, float Depth){
    if (PBR_GetPOMDepth(GTexCoord) == 1.0) return 0.0;
    int Samples = int(max(8, Materials_POM_Samples * sqrt(1.0 - abs(TexDir.z))));

    vec3 Coord = vec3((GTexCoord - BottomCoord) / TextureSize, 1.0);
    vec3 Step = vec3(TexDir.xy * Depth / -TexDir.z, -1.0) / float(Samples);

    float NoiseOffset = RN_IGN_GetFloat();
    Coord += Step * NoiseOffset;

    for (int i = 0; i < Samples; i++){
        Coord += Step;
        if (PBR_GetPOMDepth(Coord.xy) >= Coord.z) break;
    }

    GTexCoord = fract(Coord.xy) * TextureSize + BottomCoord;
	return (1.0 - Coord.z) * Depth;
}