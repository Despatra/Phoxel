#define DEPTH
uniform float near;
uniform float far;

float LinearDepthFast(in float nonlin){
    return (near*far) / (nonlin * (near-far) + far);
}