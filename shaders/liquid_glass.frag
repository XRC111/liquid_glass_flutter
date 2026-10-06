#include <flutter/runtime_effect.glsl>

// ── 液态玻璃片元着色器 v3 ─────────────────────────────────────────────────
// 关键修复：uv 采样位置 = 玻璃在被捕获背景中的真实位置（不是把整张背景塞进玻璃）。
//   uv = (uGlassOrigin + localFragCoord) / uBgSize
// 这样玻璃折射的就是它屏幕正后方的内容，而不是左上角被拉伸的图。
// 同时大幅压低白雾与色散，回归"通透玻璃"质感。

precision highp float;

uniform vec2  uSize;               // 玻璃自身尺寸（逻辑像素）          [0,1]
uniform vec2  uGlassCenter;        // 玻璃中心（局部坐标）              [2,3]
uniform vec2  uGlassHalfSize;      // 玻璃半尺寸                       [4,5]
uniform float uCornerRadius;       // 圆角半径                         [6]
uniform float uThickness;         // 边缘过渡宽度                     [7]
uniform float uRefraction;        // 折射强度                         [8]
uniform vec2  uTouchPos;          // 触摸局部位置（-1=未触摸）        [9,10]
uniform float uTime;              // 时间                             [11]
uniform float uQuality;            // 0=full 1=medium 2=minimal       [12]
uniform vec2  uGlassOrigin;       // 玻璃左上角在被捕获背景中的位置   [13,14]
uniform vec2  uBgSize;            // 被捕获背景的尺寸                 [15,16]

uniform sampler2D uBackground;    // 背景捕获纹理                     sampler 0

out vec4 fragColor;

float sdRoundRect(vec2 p, vec2 h, float r) {
    vec2 d = abs(p) - h + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

// 小半径 5-tap 交叉模糊，只糊背景，半径小不拖影
vec3 blurBg(vec2 uv, float radiusPx) {
    vec2 texel = vec2(radiusPx) / uBgSize;
    vec3 c = texture(uBackground, uv).rgb * 0.40;
    c += texture(uBackground, uv + vec2( texel.x, 0.0)).rgb * 0.15;
    c += texture(uBackground, uv + vec2(-texel.x, 0.0)).rgb * 0.15;
    c += texture(uBackground, uv + vec2(0.0,  texel.y)).rgb * 0.15;
    c += texture(uBackground, uv + vec2(0.0, -texel.y)).rgb * 0.15;
    return c;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;   // 局部坐标，原点在玻璃左上角

    // 玻璃在被捕获背景中的真实采样坐标
    vec2 uv = (uGlassOrigin + fragCoord) / uBgSize;
#if defined(IMPELLER_TARGET_OPENGLES)
    uv.y = 1.0 - uv.y;
#endif

    vec2 p = fragCoord - uGlassCenter;
    float sd = sdRoundRect(p, uGlassHalfSize, uCornerRadius);

    float feather = 1.5;
    float alpha = 1.0 - smoothstep(-feather, feather, sd);
    if (alpha <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    float d = max(-sd, 0.0);
    float t = clamp(d / max(uThickness, 1.0), 0.0, 1.0);
    float bulge = sqrt(max(0.0, 2.0 * t - t * t));

    vec2 dir = p / max(uGlassHalfSize, vec2(1.0));
    float dirLen = length(dir);
    vec2 radial = dirLen > 1e-4 ? dir / dirLen : vec2(0.0, 0.0);

    // 模糊半径小一档，不再拖影
    float blurR = uQuality > 1.5 ? 0.0 : (uQuality < 0.5 ? 3.5 : 2.5);

    // 折射位移 + 极轻微 RGB 色散（真实玻璃色散很弱）
    vec2 disp = radial * bulge * uRefraction * 0.004;
    float cr, cg, cb;
    if (uQuality < 1.5) { cr = 1.04; cg = 1.0; cb = 0.96; }
    else                { cr = 1.0;   cg = 1.0; cb = 1.0; }

    vec2 uvR = clamp(uv + disp * cr, 0.0, 1.0);
    vec2 uvG = clamp(uv + disp * cg, 0.0, 1.0);
    vec2 uvB = clamp(uv + disp * cb, 0.0, 1.0);

    vec3 bgColor;
    if (blurR > 0.0) {
        bgColor = vec3(
            blurBg(uvR, blurR).r,
            blurBg(uvG, blurR).g,
            blurBg(uvB, blurR).b
        );
    } else {
        bgColor = vec3(
            texture(uBackground, uvR).r,
            texture(uBackground, uvG).g,
            texture(uBackground, uvB).b
        );
    }

    // 玻璃本体：只叠极淡冷色，保持通透，不洗白
    vec3 color = mix(bgColor, vec3(0.97, 0.98, 1.02), 0.06);

    // 平滑边缘高光（无折痕）
    float rim = exp(-(d * d) / (2.0 * 6.0 * 6.0));
    color += rim * vec3(0.45, 0.50, 0.60);

    // 上沿镜面高光
    float fromTop = fragCoord.y - (uGlassCenter.y - uGlassHalfSize.y);
    float topGlow = exp(-fromTop * fromTop / (2.0 * 12.0 * 12.0));
    color += topGlow * vec3(0.30, 0.33, 0.40);

    // 触摸暖色光
    if (uTouchPos.x >= 0.0 && uQuality < 1.5) {
        float td = length(fragCoord - uTouchPos);
        float glow = exp(-td * td / 5000.0) * 0.25;
        color += vec3(glow * 1.1, glow * 1.0, glow * 0.85);
    }

    if (uQuality > 1.5) {
        color = mix(bgColor, vec3(1.0), 0.10);
        color += rim * 0.20;
    }

    fragColor = vec4(color, alpha * 0.92);
}
