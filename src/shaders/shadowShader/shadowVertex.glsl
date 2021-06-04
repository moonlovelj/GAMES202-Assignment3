in vec3 aVertexPosition;
in vec3 aNormalPosition;
in vec2 aTextureCoord;

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uLightVP;

out highp vec3 vNormal;
out highp vec2 vTextureCoord;
out highp float vDepth;

void main(void) {
  vNormal = aNormalPosition;
  vTextureCoord = aTextureCoord;

  gl_Position = uLightVP * uModelMatrix * vec4(aVertexPosition, 1.0);
  vDepth = gl_Position.z;
}