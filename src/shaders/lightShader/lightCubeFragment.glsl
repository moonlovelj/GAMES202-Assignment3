#ifdef GL_ES
precision mediump float;
#endif

uniform float uLigIntensity;
uniform vec3 uLightColor;

out highp vec4 fragColor;

void main(void) { 
    //gl_FragColor = vec4(uLightColor, 1.0); 
    fragColor = vec4(uLightColor, 1.0); 

}