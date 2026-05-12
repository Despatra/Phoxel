#version 430 compatibility
/*
    Defines:
    PASS_VERTEX - Sets to vertex shader
    PASS_FRAGMENT - Sets to fragment shader
    PASS_STYLE_GBUFFERS - Uses a gbuffers setup
    PASS_STYLE_COMPOSITE - Uses a screen space setup
*/

#ifdef PASS_VERTEX
    // Out //
    #ifdef PASS_STYLE_GBUFFERS
        out vec2 TexCoord;
        out vec2 LightmapCoord;
        out vec4 GLColor;
        out vec3 ViewPosition;
    #endif
    #ifdef PASS_STYLE_COMPOSITE
        out vec2 FragCoord;
    #endif

    // Code //
    void main(){
        gl_Position = ftransform();
        #ifdef PASS_STYLE_GBUFFERS
            TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
            LightmapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
            GLColor = gl_Color;
            ViewPosition = (gl_ModelViewMatrix * gl_Vertex).xyz;
        #endif
        #ifdef PASS_STYLE_COMPOSITE
            FragCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        #endif
    }
#endif

#ifdef PASS_FRAGMENT
    // Textures //
    #ifdef PASS_STYLE_GBUFFERS
        uniform sampler2D gtexture;
        uniform sampler2D lightmap;
    #endif
    #ifdef PASS_STYLE_COMPOSITE
        uniform sampler2D colortex0;
    #endif

    // Uniforms //
    uniform float alphaTestRef;
    uniform float fogStart;
    uniform float fogEnd;
    uniform float far;
    uniform vec3 fogColor;

    // In //
    in vec2 TexCoord;
    #ifdef PASS_STYLE_GBUFFERS
        in vec2 LightmapCoord;
        in vec4 GLColor;
        in vec3 ViewPosition;
    #endif

    // Out //
    /* RENDERTARGETS: 0 */
    layout (location = 0) out vec4 FragColor;

    // Code //
    void main(){
        #ifdef PASS_STYLE_GBUFFERS
            FragColor = texture(gtexture, TexCoord);
            FragColor *= texture(lightmap, LightmapCoord) * GLColor;

            float Distance = length(ViewPosition);
            float CylDistance = max(length(ViewPosition.xz), abs(ViewPosition.y));
            FragColor.rgb = mix(FragColor.rgb, fogColor, max(
                smoothstep(fogStart, fogEnd, Distance),
                smoothstep(far - clamp(0.1*far, 4.0, 64.0), far, CylDistance)
            ));
        #endif
        #ifdef PASS_STYLE_COMPOSITE
            FragColor = texture(colortex0, TexCoord);
        #endif

        if (FragColor.a < alphaTestRef) discard;
    }
#endif