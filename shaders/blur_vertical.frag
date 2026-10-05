#include <flutter/runtime_effect.glsl>

// ── 垂直高斯模糊 Pass（可分离模糊第二趟）────────────────────────────────────
// 接水平 Pass 输出，沿 Y 轴 9 采样高斯核

precision highp float;

uniform vec2  uSize;          // 当前纹理分辨率                  [0,1]
uniform float uRadius;        // 模糊半径（像素）                 [2]
uniform sampler2D uTexture;   // 输入纹理（水平 Pass 输出）        sampler 0

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;
#if defined(IMPELLER_TARGET_OPENGLES)
    uv.y = 1.0 - uv.y;
#endif

    vec2 texel = 1.0 / uSize;
    vec4 sum = vec4(0.0);
    float totalWeight = 0.0;

    for (int i = -4; i <= 4; i++) {
        float fi = float(i);
        float weight = exp(-(fi * fi) / (2.0 * uRadius * uRadius + 0.001));
        sum += texture(uTexture, clamp(uv + vec2(0.0, fi * texel.y), 0.0, 1.0)) * weight;
        totalWeight += weight;
    }

    fragColor = sum / totalWeight;
}
