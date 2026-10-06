#include <flutter/runtime_effect.glsl>

// ── 液态玻璃片元着色器 v2 ──────────────────────────────────────────────────
// 修复点：
//  1) 内置 5-tap 交叉模糊（原模糊 shader 是死代码，现在背景直接被糊掉）
//  2) 边缘高光改为基于到边距离的平滑高斯晕染，消除原来的对角线折痕
//  3) 折射位移用「指向中心的径向方向」，平滑无折面，形成凸透镜放大感
//  4) 上沿镜面高光 + 更克制的白色罩染

precision highp float;

uniform vec2  uSize;               // 绘制区域尺寸                 [0,1]
uniform vec2  uGlassCenter;        // 玻璃中心                     [2,3]
uniform vec2  uGlassHalfSize;      // 玻璃半尺寸                   [4,5]
uniform float uCornerRadius;       // 圆角半径                     [6]
uniform float uThickness;          // 边缘过渡宽度                 [7]
uniform float uRefraction;         // 折射/放大强度                [8]
uniform vec2  uTouchPos;           // 触摸位置（-1 = 未触摸）      [9,10]
uniform float uTime;               // 时间                         [11]
uniform float uQuality;            // 0=full 1=medium 2=minimal   [12]

uniform sampler2D uBackground;    // 背景捕获纹理                 sampler 0

out vec4 fragColor;

// 圆角矩形 SDF
float sdRoundRect(vec2 p, vec2 h, float r) {
    vec2 d = abs(p) - h + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

// 在指定 UV 处做 5-tap 交叉模糊（小面积玻璃上足够得到磨砂感）
vec3 blurBg(vec2 uv, float radiusPx) {
    vec2 texel = vec2(radiusPx) / uSize;
    vec3 c = texture(uBackground, uv).rgb * 0.40;
    c += texture(uBackground, uv + vec2( texel.x, 0.0)).rgb * 0.15;
    c += texture(uBackground, uv + vec2(-texel.x, 0.0)).rgb * 0.15;
    c += texture(uBackground, uv + vec2(0.0,  texel.y)).rgb * 0.15;
    c += texture(uBackground, uv + vec2(0.0, -texel.y)).rgb * 0.15;
    return c;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    vec2 uv = fragCoord / uSize;
#if defined(IMPELLER_TARGET_OPENGLES)
    uv.y = 1.0 - uv.y;
#endif

    vec2 p = fragCoord - uGlassCenter;
    float sd = sdRoundRect(p, uGlassHalfSize, uCornerRadius);

    // 外侧丢弃
    float feather = 1.5;
    float alpha = 1.0 - smoothstep(-feather, feather, sd);
    if (alpha <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    // d = 到边缘的内距（中心大，边缘 0）
    float d = max(-sd, 0.0);
    float t = clamp(d / max(uThickness, 1.0), 0.0, 1.0);
    // 凸透镜剖面：边缘薄、中心厚
    float bulge = sqrt(max(0.0, 2.0 * t - t * t));

    // 平滑径向方向（指向玻璃中心）——无折痕
    vec2 dir = p / max(uGlassHalfSize, vec2(1.0));
    float dirLen = length(dir);
    vec2 radial = dirLen > 1e-4 ? dir / dirLen : vec2(0.0, 0.0);

    // 模糊半径（质量分级）
    float blurR = uQuality > 1.5 ? 0.0 : (uQuality < 0.5 ? 6.0 : 4.0);

    // 折射位移 + RGB 色散（三通道不同偏移）
    vec2 disp = radial * bulge * uRefraction;
    float cr, cg, cb;
    if (uQuality < 1.5) { cr = 1.15; cg = 1.0; cb = 0.85; }
    else                { cr = 1.0;  cg = 1.0; cb = 1.0; }

    vec2 uvR = clamp(uv + disp * cr * 0.012, 0.0, 1.0);
    vec2 uvG = clamp(uv + disp * cg * 0.012, 0.0, 1.0);
    vec2 uvB = clamp(uv + disp * cb * 0.012, 0.0, 1.0);

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

    // 玻璃本体：轻微提亮 + 冷色罩染（克制，不洗白）
    vec3 color = bgColor;
    color = mix(color, vec3(0.98, 0.99, 1.05), 0.10);

    // ── 平滑边缘高光（基于到边距离的高斯晕染，无对角线折痕）──────────────
    float rim = exp(-(d * d) / (2.0 * 7.0 * 7.0));
    color += rim * vec3(0.55, 0.60, 0.70);

    // ── 上沿镜面高光（玻璃质感）──────────────────────────────────────────
    float fromTop = (fragCoord.y - (uGlassCenter.y - uGlassHalfSize.y));
    float topGlow = exp(-fromTop * fromTop / (2.0 * 14.0 * 14.0));
    color += topGlow * vec3(0.35, 0.38, 0.45);

    // ── 触摸暖色光 ────────────────────────────────────────────────────────
    if (uTouchPos.x >= 0.0 && uQuality < 1.5) {
        float td = length(fragCoord - uTouchPos);
        float glow = exp(-td * td / 6000.0) * 0.30;
        color += vec3(glow * 1.1, glow * 1.0, glow * 0.85);
    }

    // minimal：几乎不做效果，仅半透 + 极淡边
    if (uQuality > 1.5) {
        color = mix(bgColor, vec3(1.0), 0.10);
        color += rim * 0.20;
    }

    fragColor = vec4(color, alpha * 0.95);
}
