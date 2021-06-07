#ifdef GL_ES
//#extension GL_EXT_draw_buffers: enable
precision highp float;
#endif

uniform sampler2D uKd;
uniform sampler2D uNt;
uniform sampler2D uShadowMap;

in mat4 vWorldToLight;
in highp vec2 vTextureCoord;
in highp vec4 vPosWorld;
in highp vec3 vNormalWorld;
in highp float vDepth;

layout(location = 0) out highp vec4 okd;
layout(location = 1) out highp vec4 oDepth;
layout(location = 2) out highp vec4 oNormal;
layout(location = 3) out highp vec4 oShadow;
layout(location = 4) out highp vec4 oPosWorld;

float SimpleShadowMap(vec3 posWorld,float bias){
  vec4 posLight = vWorldToLight * vec4(posWorld, 1.0);
  posLight = vec4(posLight.x/posLight.w, posLight.y/posLight.w, posLight.z/posLight.w, 1.0);
  vec2 shadowCoord = clamp(posLight.xy * 0.5 + 0.5, vec2(0.0), vec2(1.0));
  float depthSM = texture(uShadowMap, shadowCoord).x;
  float depth = posLight.z;//(posLight.z * 0.5 + 0.5) * 100.0;
  return step(0.0, depthSM - depth + bias);
}

void LocalBasis(vec3 n, out vec3 b1, out vec3 b2) {
  float sign_ = sign(n.z);
  if (n.z == 0.0) {
    sign_ = 1.0;
  }
  float a = -1.0 / (sign_ + n.z);
  float b = n.x * n.y * a;
  b1 = vec3(1.0 + sign_ * n.x * n.x * a, sign_ * b, -sign_ * n.x);
  b2 = vec3(b, sign_ + n.y * n.y * a, -n.y);
}

vec3 ApplyTangentNormalMap() {
  vec3 t, b;
  LocalBasis(vNormalWorld, t, b);
  vec3 nt = texture(uNt, vTextureCoord).xyz * 2.0 - 1.0;
  nt = normalize(nt.x * t + nt.y * b + nt.z * vNormalWorld);
  return nt;
}

void main(void) {
  vec3 kd = texture(uKd, vTextureCoord).rgb;
  // gl_FragData[0] = vec4(kd, 1.0);
  // gl_FragData[1] = vec4(vec3(vDepth), 1.0);
  // gl_FragData[2] = vec4(ApplyTangentNormalMap(), 1.0);
  // gl_FragData[3] = vec4(vec3(SimpleShadowMap(vPosWorld.xyz, 1e-2)), 1.0);
  // gl_FragData[4] = vec4(vec3(vPosWorld.xyz), 1.0);

  okd = vec4(kd, 1.0);
  oDepth = vec4(vec3(vDepth), 1.0);
  oNormal = vec4(ApplyTangentNormalMap(), 1.0);
  oShadow = vec4(vec3(SimpleShadowMap(vPosWorld.xyz, 1e-4)), 1.0);
  oPosWorld = vec4(vec3(vPosWorld.xyz), 1.0);
}
