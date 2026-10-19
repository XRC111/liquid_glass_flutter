<div align="center">

# Liquid Glass Flutter（初版示例）

**用 Flutter 片元着色器实现的液态玻璃效果 —— 折射、RGB 色散、Fresnel 边缘高光**

Android API 24 → 35，按设备能力自动降级。

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20API%2024%2B-3DDC84?style=flat-square)](#兼容性)

</div>

---

> **仓库状态**：这是该效果系列的**初版示例**。后续版本已拆分并重写：
>
> - 组件库（推荐）：[liquid_glass_library](https://github.com/XRC111/liquid_glass_library)
> - 新版示例：[liquid_glass_demo](https://github.com/XRC111/liquid_glass_demo)
>
> 本仓库保留作为对照与历史记录，不再更新。

## 效果

- **真实折射**：SDF 圆角矩形 + 中心差分法线 + 圆弧剖面高度场，玻璃下方内容随透镜曲率偏移
- **RGB 色散**：R/G/B 三通道以不同偏移量采样背景
- **Fresnel 边缘高光**：边缘法线越倾斜，反射越强
- **触摸动态光照**：按下时出现跟随手指的暖色光斑
- **自动降级**：按 API 级别与 `isLowRamDevice` 选择质量档位

## 运行

```bash
flutter pub get
flutter run --release

# 构建 APK
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

## 兼容性

| 档位 | 设备 | 后端 | 模糊 | 色散 | 触摸光照 |
| --- | --- | --- | --- | --- | --- |
| `full` | API 29+ | Impeller Vulkan | 1/2 分辨率 | 完整 RGB 色散 | 有 |
| `medium` | API 26–28 | Impeller OpenGL ES | 1/4 分辨率 | 简化色散 | 有 |
| `minimal` | API 24–25 / 低内存 | `BackdropFilter` 兜底 | 跳过 GPU 模糊 | 无 | 无 |

- 质量等级通过 `MethodChannel` 读取 `SDK_INT` 与 `isLowRamDevice` 后确定
- `minimal` 使用内置 `BackdropFilter` + 半透明边框，零离屏缓冲
- 着色器未加载或背景捕获失败时同样回退

## 项目结构

```
lib/
├── main.dart                        # 入口：检测质量 + 预加载着色器
├── glass/
│   ├── liquid_glass_widget.dart     # 核心玻璃组件（背景捕获 + CustomPaint）
│   ├── glass_shader_program.dart    # 着色器加载（单例）
│   └── glass_quality.dart           # 质量分级枚举
└── pages/
    ├── home_page.dart               # 单个玻璃卡片
    ├── tabbar_demo.dart             # 悬浮玻璃底栏
    └── card_demo.dart               # 玻璃卡片列表
shaders/
├── liquid_glass.frag
├── blur_horizontal.frag
└── blur_vertical.frag
```

## 关键技术点

- 着色器通过 `pubspec.yaml` 的 `shaders:` 声明，构建期自动交叉编译到 Vulkan / OpenGL ES
- OpenGL ES 后端在着色器内用 `#if defined(IMPELLER_TARGET_OPENGLES)` 处理纹理 Y 轴翻转
- 背景捕获：`RepaintBoundary` + `boundary.toImage(pixelRatio: 1)`，作为 `sampler2D` 传入
- 模糊：可分离高斯（水平 + 垂直两趟），在降分辨率 FBO 上执行

## 平台配置

- `minSdk 24` / `targetSdk 35` / `compileSdk 35`
- `AndroidManifest.xml` 设置 `io.flutter.embedding.android.EnableImpeller=true`

## License

MIT
