#include <flutter/runtime_effect.glsl>

// ── 液态玻璃片元着色器 ──────────────────────────────────────────────────────
// SDF 圆角矩形 → 梯度法线 → 高度场折射 → RGB 色散 → Fresnel 边缘高光 → 触摸光照
// Flutter 编译期自动交叉编译到 Vulkan / OpenGL ES，无需手写 #version。

precision highp float;

// ── Uniforms（声明顺序 = setFloat/setImageSampler 槽位顺序）──────────────────
uniform vec2  uSize;               // 绘制区域尺寸（逻辑像素）        [0,1]
uniform vec2  uGlassCenter;        // 玻璃中心坐标                    [2,3]
uniform vec2  uGlassHalfSize;      // 玻璃半尺寸                      [4,5]
uniform float uCornerRadius;       // 圆角半径                        [6]
uniform float uRefractionHeight;   // 折射高度场厚度                  [7]
uniform float uRefractionAmount;   // 折射强度                        [8]
uniform vec2  uTouchPos;           // 触摸位置（-1 = 未触摸）         [9,10]
uniform float uTime;               // 动画时间（秒）                  [11]
uniform float uQuality;            // 质量等级（0=full 1=medium 2=minimal）[12]

uniform sampler2D uBackground;     // 背景捕获纹理                    sampler 0

out vec4 fragColor;

// ── SDF 圆角矩形：返回点 p 到圆角矩形的有符号距离 ──────────────────────────
float sdRoundRect(vec2 p, vec2 halfSize, float radius) {
    vec2 d = abs(p) - halfSize + radius;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

// ── 高度场：SDF 转 0..1 的透镜高度（圆弧剖面）──────────────────────────────
float heightField(float sd, float thickness) {
    float t = clamp(-sd / thickness, 0.0, 1.0);
    // 圆弧剖面：边缘薄、中心厚，模拟凸透镜
    return sqrt(max(0.0, 2.0 * t - t * t));
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // OpenGL ES 后端 Y 轴翻转处理
    vec2 uv = fragCoord / uSize;
#if defined(IMPELLER_TARGET_OPENGLES)
    uv.y = 1.0 - uv.y;
#endif

    vec2 p = fragCoord - uGlassCenter;
    float sd = sdRoundRect(p, uGlassHalfSize, uCornerRadius);

    // 玻璃外部：丢弃（alpha=0）
    float edge = 1.5;
    float alpha = 1.0 - smoothstep(-edge, edge, sd);
    if (alpha <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    // ── 中心差分计算法线梯度 ────────────────────────────────────────────────
    float eps = 1.0;
    float hx = sdRoundRect(p + vec2(eps, 0.0), uGlassHalfSize, uCornerRadius);
    float hy = sdRoundRect(p + vec2(0.0, eps), uGlassHalfSize, uCornerRadius);
    vec2 grad = vec2(hx - sd, hy - sd);
    float gradLen = length(grad);
    vec2 normal = gradLen > 1e-6 ? grad / gradLen : vec2(0.0, 0.0);

    // ── 高度场折射 ──────────────────────────────────────────────────────────
    float h = heightField(sd, uRefractionHeight);
    float refractStrength = h * uRefractionAmount;

    // ── RGB 三通道分离色散（medium 质量简化色散）────────────────────────────
    float dispR, dispG, dispB;
    if (uQuality < 1.5) {
        // full / medium：三通道不同偏移量产生色散
        dispR = 0.030;
        dispG = 0.020;
        dispB = 0.010;
    } else {
        // minimal：无色散，统一偏移
        dispR = dispG = dispB = 0.015;
    }

    vec2 uvR = uv + normal * refractStrength * dispR;
    vec2 uvG = uv + normal * refractStrength * dispG;
    vec2 uvB = uv + normal * refractStrength * dispB;

    vec3 bgColor = vec3(
        texture(uBackground, clamp(uvR, 0.0, 1.0)).r,
        texture(uBackground, clamp(uvG, 0.0, 1.0)).g,
        texture(uBackground, clamp(uvB, 0.0, 1.0)).b
    );

    // ── 玻璃本体着色（轻微冷色调 + 透明度）─────────────────────────────────
    vec3 glassTint = vec3(0.96, 0.98, 1.02);
    vec3 color = bgColor * glassTint;

    // ── Fresnel 边缘高光 ────────────────────────────────────────────────────
    // 视线假设从正上方入射，边缘法线越倾斜 Fresnel 越强
    float fresnel = pow(clamp(gradLen / eps, 0.0, 1.0), 2.5);
    float edgeHighlight = fresnel * 0.35;
    color += vec3(edgeHighlight);

    // ── 触摸位置动态光照 ────────────────────────────────────────────────────
    if (uTouchPos.x >= 0.0 && uQuality < 1.5) {
        float touchDist = length(fragCoord - uTouchPos);
        float touchGlow = exp(-touchDist * touchDist / 8000.0) * 0.25;
        // 触摸光偏暖色
        color += vec3(touchGlow * 1.1, touchGlow * 1.0, touchGlow * 0.85);
    }

    // ── minimal 质量：跳过复杂效果，仅半透明 + 边缘高光 ─────────────────────
    if (uQuality > 1.5) {
        color = mix(bgColor, vec3(1.0), 0.08);
        color += vec3(fresnel * 0.25);
    }

    // ── 边缘抗锯齿 alpha ────────────────────────────────────────────────────
    fragColor = vec4(color, alpha * 0.92);
}
