#version 430 compatibility
#include "Includes/Settings.glsl"
#include "Includes/Blur.glsl"
#include "Includes/Depth.glsl"

uniform sampler2D depthtex1;
uniform sampler2D colortex0;
/*
    const bool colortex0MipmapEnabled = true;
*/

in vec2 texcoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 color;

void main(){
    #ifdef DOF
        float focus = abs(pow(LinearDepthFast(texture(depthtex1, vec2(0.5)).r), 0.5)-pow(LinearDepthFast(texture(depthtex1, texcoord).r) , 0.5))/1.0;
        focus = clamp(focus, 0.0, 1.0);
        color = mix(texture(colortex0, texcoord), MultiSampleLODBlur(colortex0, texcoord, focus, 4.0*focus, 4), DOFStrength);
    #else
        color = texture(colortex0, texcoord);
    #endif
}