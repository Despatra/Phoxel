#version 430 compatibility
#include "Includes/Settings.glsl"

in vec2 texcoord;

/* DRAWBUFFERS:7 */
layout(location = 0) out vec4 color;

layout(std430, binding = 0) buffer LightBuffer {
    int LightIndex;
};

void main(){
    color = vec4(0);
    LightIndex = 0;
}