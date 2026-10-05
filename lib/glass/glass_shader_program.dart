import 'dart:ui' as ui;

import 'glass_quality.dart';

/// 着色器加载管理器：负责加载、缓存 FragmentProgram，并提供着色器实例。
///
/// 所有玻璃组件共享同一个 [GlassShaderProgram] 单例，避免重复编译着色器。
class GlassShaderProgram {
  GlassShaderProgram._();

  static final GlassShaderProgram instance = GlassShaderProgram._();

  ui.FragmentProgram? _glassProgram;
  ui.FragmentProgram? _blurHProgram;
  ui.FragmentProgram? _blurVProgram;

  bool _loaded = false;

  /// 着色器是否已加载完成。
  bool get isLoaded => _loaded;

  /// 从 assets 加载全部着色器程序。应在 app 启动时调用（或在 [GlassWidget] 首次构建前）。
  Future<void> load() async {
    if (_loaded) return;
    final results = await Future.wait([
      ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag'),
      ui.FragmentProgram.fromAsset('shaders/blur_horizontal.frag'),
      ui.FragmentProgram.fromAsset('shaders/blur_vertical.frag'),
    ]);
    _glassProgram = results[0];
    _blurHProgram = results[1];
    _blurVProgram = results[2];
    _loaded = true;
  }

  /// 创建液态玻璃片元着色器实例。
  ui.FragmentShader createGlassShader() {
    final p = _glassProgram;
    if (p == null) {
      throw StateError('着色器未加载，请先 await GlassShaderProgram.instance.load()');
    }
    return p.fragmentShader();
  }

  /// 创建水平模糊着色器实例。
  ui.FragmentShader createBlurHorizontalShader() {
    final p = _blurHProgram;
    if (p == null) {
      throw StateError('水平模糊着色器未加载');
    }
    return p.fragmentShader();
  }

  /// 创建垂直模糊着色器实例。
  ui.FragmentShader createBlurVerticalShader() {
    final p = _blurVProgram;
    if (p == null) {
      throw StateError('垂直模糊着色器未加载');
    }
    return p.fragmentShader();
  }
}

/// 根据设备信息推断合适的 [GlassQuality]。
///
/// [sdkInt] 为 Android API 级别，[isLowRam] 表示系统是否判定为低内存设备。
GlassQuality resolveQuality({
  required int sdkInt,
  bool isLowRam = false,
}) {
  if (isLowRam) return GlassQuality.minimal;
  if (sdkInt >= 29) return GlassQuality.full;
  if (sdkInt >= 26) return GlassQuality.medium;
  return GlassQuality.minimal;
}
