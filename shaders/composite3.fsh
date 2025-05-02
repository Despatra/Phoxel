#version 430 compatibility
#include "Includes/Settings.glsl"
#include "Includes/FXAA.glsl"

uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex5; // Normals
/*
    const bool colortex0MipmapEnabled = true;
*/

in vec2 texcoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 color;

void main(){
    #if (AA == 1)
        color = FXAA(colortex0, depthtex1, colortex5, texcoord, 1.5/ViewSize, (AAStrength*0.6)+0.4);
    #else
        color = texture(colortex0, texcoord);
    #endif
}