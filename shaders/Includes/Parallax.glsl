#define PARALLAX

float GetDepth(in vec2 Coord){
    if (MaterialMode == 0){
        float color = length(textureLod(gtexture, Coord, 0.0).rgb);
        float average = length(textureLod(gtexture, Coord, (log(float(TextureRes))/log(2.0)) ).rgb);
        float gray = 1.0/(1.0+pow(2.7183, -14.0*(color-average)));
        //return clamp(-5.0*pow(gray-0.445, 2.0)-0.17+12000.0*pow(0.2*(gray-0.4), 4.0)+log(3.0*gray+10.0), 0.0, 1.0)*0.005+0.995;
        return gray*0.025+0.975;
    } else{
        return texelFetch(normals, ivec2(Coord*atlasSize), 0).a;
    }
}

vec2 performParallax(in vec3 TexDir, out float Height){
	float CurrentHeight = 1.0;
	vec2 Coord = texcoord;
	vec2 CoordOffset = floor(texcoord/TextureSize)*TextureSize;
    #ifdef BinaryPOM
        for (int i=0; i<ParallaxSamples; i++){
            float Depth = CurrentHeight-GetDepth(Coord);
            float Step = -abs(Depth) / (float(1<< (i+1) ) * Depth);
            int ParallaxSteps = int( ceil(64.0*length(TexDir.xy) / float(1<< (i+1) )) );
            for (int l=0; l<ParallaxSteps; l++){
                if (-Depth*abs(Step)/Step < 0.0) break;

                CurrentHeight += Step/float(ParallaxSteps);
                Coord += (TexDir.xy/-TexDir.z)*Step*float(ParallaxDepth)/(float(ParallaxSteps)*-60.0);
                Coord = mod(Coord-CoordOffset, TextureSize)+CoordOffset;
                Depth = CurrentHeight-GetDepth(Coord);
            }
            if (abs(Depth) < .001) break;
        }
    #else
        float Depth = CurrentHeight-GetDepth(Coord);
        int ParallaxSteps = int(ParallaxSamples * 20 * length(TexDir.xy));
        float Step = 1.0/ParallaxSteps;
        for (int i=0; i<ParallaxSteps; i++){
            if (Depth < 0.0) break;

            CurrentHeight -= Step;
            Coord += (TexDir.xy/-TexDir.z)*float(ParallaxDepth)*Step/60.0;
            Coord = mod(Coord-CoordOffset, TextureSize)+CoordOffset;
            Depth = CurrentHeight-GetDepth(Coord);
        }
    #endif
    
	Coord += 0.1*pixsize*TexDir.xy;
    Coord = mod(Coord-CoordOffset, TextureSize)+CoordOffset;

    Height = CurrentHeight;
	return Coord;
}