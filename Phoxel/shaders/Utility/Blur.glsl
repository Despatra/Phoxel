#define UTILITY_BLUR

// Dependencies //
#ifndef UTILITY_RANDOM
    #include Random.glsl
#endif

// Code //
vec3 Blur_GetSample(sampler2D Texture, vec2 Coord, float Radius, int Samples){
    float nOffset = RN_IGN_GetFloat();
    float aOffset = RN_IGN_GetFloat();

	const float Phi = (1.0 + sqrt(5.0)) / 2.0; // Golden Ratio
	float AngleStep = 2.0*Pi * (1.0 - 1.0/Phi);
	vec2 Step = Radius / ScreenSize;

	vec3 Total = vec3(0.0);
	for (int n = 0; n < Samples; n++){
		float i = n + nOffset;
		float Offset = sqrt(i / (Samples + nOffset));
		float Angle = (AngleStep * i) + (aOffset * 2.0*Pi);
		vec2 SampleOffset = pow(Offset, 2.0) * Step * vec2(sin(Angle), cos(Angle));
		vec2 SampleCoord = Coord + SampleOffset;

		vec3 Sample = texture(Texture, SampleCoord).rgb;

		Total += Sample;
	}

	return Total / Samples;
}