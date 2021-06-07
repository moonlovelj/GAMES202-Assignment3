#ifdef GL_ES
precision highp float;
#endif

// #extension GL_EXT_shader_texture_lod : enable

uniform vec3 uLightDir;
uniform vec3 uCameraPos;
uniform vec3 uLightRadiance;
uniform sampler2D uGDiffuse;
uniform sampler2D uGDepth;
uniform sampler2D uGNormalWorld;
uniform sampler2D uGShadow;
uniform sampler2D uGPosWorld;

in mat4 vWorldToScreen;
in highp vec4 vPosWorld;


out highp vec4 fragColor;

#define M_PI 3.1415926535897932384626433832795
#define TWO_PI 6.283185307
#define INV_PI 0.31830988618
#define INV_TWO_PI 0.15915494309

float Rand1(inout float p) {
  p = fract(p * .1031);
  p *= p + 33.33;
  p *= p + p;
  return fract(p);
}

vec2 Rand2(inout float p) {
  return vec2(Rand1(p), Rand1(p));
}

float InitRand(vec2 uv) {
	vec3 p3  = fract(vec3(uv.xyx) * .1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec3 SampleHemisphereUniform(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = uv.x;
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(1.0 - z*z);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = INV_TWO_PI;
  return dir;
}

vec3 SampleHemisphereCos(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = sqrt(1.0 - uv.x);
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(uv.x);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = z * INV_PI;
  return dir;
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

vec4 Project(vec4 a) {
  return a / a.w;
}

float GetDepth(vec3 posWorld) {
  vec4 pos = (vWorldToScreen * vec4(posWorld, 1.0));
  float depth = pos.z/pos.w;//(vWorldToScreen * vec4(posWorld, 1.0)).w;
  return depth;
}

/*
 * Transform point from world space to screen space([0, 1] x [0, 1])
 *
 */
vec2 GetScreenCoordinate(vec3 posWorld) {
  vec2 uv = Project(vWorldToScreen * vec4(posWorld, 1.0)).xy * 0.5 + 0.5;
  return uv;
}

float GetGBufferDepth(vec2 uv) {
  float depth = texture(uGDepth, uv).x;
  if (depth < 1e-2) {
    depth = 1000.0;
  }
  return depth;
}

// float GetGBufferDepthLod(vec2 uv, float level) {
//   float depth = textureLodEXT(uGDepth, uv, level).x;
//   if (depth < 1e-2) {
//     depth = 1000.0;
//   }
//   return depth;
// }

vec3 GetGBufferNormalWorld(vec2 uv) {
  vec3 normal = texture(uGNormalWorld, uv).xyz;
  return normal;
}

vec3 GetGBufferPosWorld(vec2 uv) {
  vec3 posWorld = texture(uGPosWorld, uv).xyz;
  return posWorld;
}

float GetGBufferuShadow(vec2 uv) {
  float visibility = texture(uGShadow, uv).x;
  return visibility;
}

vec3 GetGBufferDiffuse(vec2 uv) {
  vec3 diffuse = texture(uGDiffuse, uv).xyz;
  diffuse = pow(diffuse, vec3(2.2));
  return diffuse;
}

/*
 * Evaluate diffuse bsdf value.
 *
 * wi, wo are all in world space.
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
vec3 EvalDiffuse(vec3 wi, vec3 wo, vec2 uv) {
  vec3 N = GetGBufferNormalWorld(uv);
  vec3 kd = GetGBufferDiffuse(uv);
  float cosTheta = max(dot(wo, N), 0.0);
  return kd * cosTheta * INV_PI;
}

/*
 * Evaluate directional light with shadow map
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
vec3 EvalDirectionalLight(vec2 uv) {
  // vec3 N = GetGBufferNormalWorld(uv);
  // float cosTheta = max(0.0, dot(N, uLightDir));
  float visibility = GetGBufferuShadow(uv);
  return uLightRadiance * visibility;
}

bool RayMarch(vec3 ori, vec3 dir, out vec3 hitPos) {
  float delta = 0.5;
  vec3 current = ori + delta * dir;
  vec2 uv = GetScreenCoordinate(current); 
  for (int times = 0; times < 10000; ++times) {
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
      break;
    }

    if (GetDepth(current) > GetGBufferDepth(uv)){
       hitPos = current;
       return true;
    }
   
    current = current + delta * dir;
    uv = GetScreenCoordinate(current);
  }

  return false;
}

bool RayMarchWithMipmap(vec3 ori, vec3 dir, out vec3 hitPos) {
  return false;
}

#define SAMPLE_NUM 1

void main() {
  float s = InitRand(gl_FragCoord.xy);

  vec2 uv = GetScreenCoordinate(vPosWorld.xyz);
  vec3 normalWorld = GetGBufferNormalWorld(uv);
  vec3 L_inr = vec3(0.0);
  for(int i=0; i<SAMPLE_NUM; i++) {
    float pdf;
    float rand = Rand1(s);
    vec3 dir = SampleHemisphereCos(rand, pdf);
    //vec3 dir = SampleHemisphereUniform(rand, pdf);
    vec3 hitPos;vec3 t;vec3 b;
    LocalBasis(normalWorld, t, b);
    dir = normalize(dir.x*t+dir.y*b+dir.z*normalWorld);
    if (RayMarch(vPosWorld.xyz, dir, hitPos)) {
        L_inr += (EvalDirectionalLight(GetScreenCoordinate(hitPos)) * 
                  EvalDiffuse(normalize(vPosWorld.xyz-hitPos), uLightDir, GetScreenCoordinate(hitPos)) * 
                  EvalDiffuse(normalize(uCameraPos-vPosWorld.xyz), normalize(hitPos-vPosWorld.xyz), uv) / pdf );
    }
  }

  L_inr /= float(SAMPLE_NUM);

  vec3 L_dir = EvalDirectionalLight(uv) * EvalDiffuse(normalize(uCameraPos-vPosWorld.xyz), uLightDir, uv);
  vec3 L = L_dir + L_inr;
  L = pow(clamp(L, vec3(0.0), vec3(1.0)), vec3(1.0 / 2.2));
  // gl_FragColor = vec4(L, 1.0);
  fragColor = vec4(L, 1.0);
}
