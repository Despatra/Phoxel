#version 430 compatibility
#include Utility/Common.glsl

#define PASS_STYLE_GBUFFERS
#define PASS_VERTEX

// Uniforms //
uniform int Dimension;
uniform int renderStage;

// In //
in vec2 mc_midTexCoord;

// Out //
out vec2 TexCoord;
out vec4 GLColor;

// Code //
void main(){
	gl_Position = ftransform();
	TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	GLColor = gl_Color;


    //if (any(greaterThan(TexCoord, mc_midTexCoord))) return;
    
    vec2 TextureSize = 2.0 * (mc_midTexCoord - TexCoord);
    
    // mc_midTexCorod is broken, so we bruteforce
    TextureSize = vec2(0.125, 0.25);
    if (renderStage == MC_RENDER_STAGE_MOON) TextureSize = -TextureSize;
    if (Dimension == 2) TextureSize *= 2.0;

    vec4 Coords = vec4(TexCoord, TexCoord+TextureSize);
    if (Dimension == 2) {
        // End Flash
        TextureData.EndFlashCoords = Coords;
    } else {
        // Overworld
        if (renderStage == MC_RENDER_STAGE_SUN){
            // Sun
            TextureData.SunCoords = Coords;
        }
        if (renderStage == MC_RENDER_STAGE_MOON){
            // Moon
            TextureData.MoonCoords = Coords;
        }
    }
}