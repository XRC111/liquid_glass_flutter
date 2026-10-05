/// 液态玻璃渲染质量分级。
///
/// 根据设备 API 级别和运行时内存动态选择，低端设备自动降级以保证帧率和稳定性。
enum GlassQuality {
  /// 全质量：API 29+（Vulkan），全分辨率 + RGB 色散 + 触摸动态光照。
  full(0),

  /// 中等质量：API 26-28（OpenGL ES），1/2 分辨率 + 简化色散。
  medium(1),

  /// 最低质量：API 24-25 或低内存设备，跳过 GPU 模糊，
  /// 仅半透明叠加 + Fresnel 边缘高光。
  minimal(2);

  const GlassQuality(this.shaderValue);

  /// 传给着色器 uQuality uniform 的数值。
  final int shaderValue;

  /// 是否启用背景模糊 Pass。
  bool get enableBlur => this != GlassQuality.minimal;

  /// 是否启用 RGB 色散。
  bool get enableDispersion => this == GlassQuality.full;

  /// 是否启用触摸动态光照。
  bool get enableTouchLighting => this != GlassQuality.minimal;

  /// 模糊 Pass 的分辨率缩放比例。
  /// full 用 1/2（Vulkan 性能足够），medium 用 1/4（减少 GLES 填充率压力）。
  double get blurScale {
    switch (this) {
      case GlassQuality.full:
        return 0.5;
      case GlassQuality.medium:
        return 0.25;
      case GlassQuality.minimal:
        return 0.0; // 不执行模糊
    }
  }

  /// 模糊半径（逻辑像素）。
  double get blurRadius {
    switch (this) {
      case GlassQuality.full:
        return 8.0;
      case GlassQuality.medium:
        return 6.0;
      case GlassQuality.minimal:
        return 0.0;
    }
  }
}
