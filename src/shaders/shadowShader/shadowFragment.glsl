#ifdef GL_ES
//#extension GL_EXT_draw_buffers: enable
precision highp float;
#endif

uniform vec3 uCameraPos;

in highp vec3 vNormal;
in highp vec2 vTextureCoord;
in highp float vDepth;

layout(location = 0) out highp vec4 fragColor;
layout(location = 1) out highp vec4 oDepth;
layout(location = 2) out highp vec4 oNormal;
layout(location = 3)out highp vec4 oShadow;
layout(location = 4) out highp vec4 oPosWorld;

vec4 EncodeFloatRGBA(float v) {
  vec4 enc = vec4(1.0, 255.0, 65025.0, 160581375.0) * v;
  enc = fract(enc);
  enc -= enc.yzww * vec4(1.0/255.0,1.0/255.0,1.0/255.0,0.0);
  return enc;
}

void main(){
  //gl_FragData[0] = vec4(vec3(gl_FragCoord.z) * 100.0, 1.0);
  // gl_FragData[0] = EncodeFloatRGBA(gl_FragCoord.z * 100.0);
  fragColor = vec4(vec3(vDepth) * 100.0, 1.0);
}