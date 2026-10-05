# Liquid Glass Flutter

用 Flutter 实现的**液态玻璃（Liquid Glass）**效果示例，覆盖 **Android API 24（Android 7.0）到 API 35（Android 15）**，实现真实的折射、RGB 色散、Fresnel 边缘高光与触摸动态光照，并在低端设备上自动降级。

## 效果

- **真实折射**：基于 SDF 圆角矩形 + 中心差分法线 + 圆弧剖面高度场，玻璃下方内容随透镜曲率发生像素偏移。
- **RGB 色散**：RGB 三通道以不同偏移量采样背景，模拟玻璃对不同波长光的折射率差异。
- **Fresnel 边缘高光**：边缘法线越倾斜反射越强，形成玻璃边缘的自然高光。
- **触摸动态光照**：手指按下时，玻璃上出现跟随手指的暖色光斑。
- **自动降级**：按 API 级别与 `isLowRamDevice` 动态选择质量等级，低端机不崩溃、不 OOM。

## 项目结构

```
liquid_glass_flutter/
├── lib/
│   ├── main.dart                        # 入口：检测设备质量 + 预加载着色器
│   ├── glass/
│   │   ├── liquid_glass_widget.dart     # 核心玻璃组件（背景捕获 + CustomPaint）
│   │   ├── glass_shader_program.dart    # 着色器加载管理（单例）
│   │   └── glass_quality.dart           # GlassQuality 质量分级枚举
│   └── pages/
│       ├── home_page.dart               # 首页：单个玻璃卡片
│       ├── tabbar_demo.dart             # 悬浮玻璃底部 TabBar
│       └── card_demo.dart               # 玻璃卡片列表
├── shaders/
│   ├── liquid_glass.frag                # 液态玻璃片元着色器
│   ├── blur_horizontal.frag             # 水平高斯模糊 Pass
│   └── blur_vertical.frag               # 垂直高斯模糊 Pass
└── android/app/build.gradle             # minSdk 24 / targetSdk 35
```

## 运行

```bash
flutter pub get
flutter run --release
```

构建 APK：

```bash
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

## 质量分级与降级表现

| 等级 | 设备 | 渲染后端 | 模糊分辨率 | 色散 | 触摸光照 |
|------|------|----------|-----------|------|---------|
| `full` | API 29+ | Impeller Vulkan | 1/2 | 完整 RGB 色散 | 有 |
| `medium` | API 26–28 | Impeller OpenGL ES | 1/4 | 简化色散 | 有 |
| `minimal` | API 24–25 / 低内存 | `BackdropFilter` 兜底 | 跳过 GPU 模糊 | 无 | 无 |

- 质量等级通过原生 `MethodChannel` 读取 `Build.VERSION.SDK_INT` 与 `ActivityManager.isLowRamDevice` 后确定。
- `minimal` 模式使用 Flutter 内置 `BackdropFilter`（`ImageFilter.blur`）+ 半透明边框，零离屏缓冲，保证低内存设备不 OOM。
- 当着色器尚未加载或背景捕获失败时，也会自动回退到该兜底渲染。

## 关键技术点

- 着色器通过 `pubspec.yaml` 的 `shaders:` 声明，Flutter **构建期自动交叉编译**到 Vulkan / OpenGL ES，无需手写 `#version`。
- OpenGL ES 后端在着色器内通过 `#if defined(IMPELLER_TARGET_OPENGLES)` 处理纹理 **Y 轴翻转**。
- 背景捕获使用 `RepaintBoundary` + `boundary.toImage(pixelRatio: 1)`，捕获图作为 `sampler2D` 传入着色器。
- 模糊采用**可分离高斯**（水平 + 垂直两趟），在降分辨率 FBO 上执行以降低填充率压力。

## 平台配置

- `minSdkVersion 24`，`targetSdkVersion 35`，`compileSdk 35`。
- `AndroidManifest.xml` 设置 `io.flutter.embedding.android.EnableImpeller=true`。

## 说明

本仓库为**示例程序**；可复用的液态玻璃库见另一个仓库（`flutter_liquid_glass`）。
