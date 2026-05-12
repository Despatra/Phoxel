#define UTILITY_BRDF

// Code //
float BRDF_OrenNayar(vec3 Incoming, vec3 Outgoing, vec3 Normal, float Roughness){
    float NDotI = clamp(dot(Normal, Incoming), 0.0, 1.0);
    float AngleNI = acos(NDotI);

    float NDotO = clamp(dot(Normal, Outgoing), 0.0, 1.0);
    float AngleNO = acos(NDotO);

    float Alpha = max(AngleNI, AngleNO);
    float Beta = min(AngleNI, AngleNO);
    float GammaT = cos(AngleNI - AngleNO);
    float R2 = pow2(Roughness);

    float A = 1.0 - (R2 / (R2 + 0.57)) / 2.0;
    float B = 0.45 * (R2 / (R2 + 0.09));
    float C = sin(Alpha) * tan(Beta);

    return NDotO * (A + (B * max(0.0, GammaT) * C));
}

float BRDF_GetProbability(vec3 Incoming, vec3 Outgoing, HitDataStruct HitData){
    return dot(Outgoing, HitData.Normal);
    //return BRDF_OrenNayar(Incoming, Outgoing, HitData.Normal, HitData.Material.Roughness);
}