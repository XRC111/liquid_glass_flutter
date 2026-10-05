import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'glass_quality.dart';
import 'glass_shader_program.dart';

/// 液态玻璃核心组件。
///
/// 通过捕获玻璃下方的背景内容（[RepaintBoundary] + [toImage]），
/// 交给 GPU 片元着色器实现折射、色散、Fresnel 边缘高光和触摸光照。
///
/// 用法：
/// ```dart
/// final bgKey = GlobalKey();
/// // 背景包 RepaintBoundary(key: bgKey)
/// GlassWidget(
///   captureKey: bgKey,
///   cornerRadius: 24,
///   quality: GlassQuality.full,
///   child: Text('玻璃上的内容'),
/// )
/// ```
class GlassWidget extends StatefulWidget {
  const GlassWidget({
    super.key,
    required this.captureKey,
    this.child,
    this.cornerRadius = 24,
    this.refractionHeight = 12,
    this.refractionAmount = 1,
    this.quality = GlassQuality.full,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
  });

  /// 背景 [RepaintBoundary] 的 key，用于捕获玻璃下方内容。
  final GlobalKey captureKey;

  /// 玻璃上方显示的子内容。
  final Widget? child;

  /// 圆角半径。
  final double cornerRadius;

  /// 折射高度场厚度（控制透镜边缘过渡宽度）。
  final double refractionHeight;

  /// 折射强度（0 = 无折射，1 = 标准，>1 = 夸张）。
  final double refractionAmount;

  /// 渲染质量分级。
  final GlassQuality quality;

  /// 显式宽度/高度；为 null 时按子内容或父约束自适应。
  final double? width;
  final double? height;

  /// 内边距。
  final EdgeInsets padding;

  /// 点击回调（同时用于触发触摸光照）。
  final VoidCallback? onTap;

  /// 边框颜色（minimal 质量使用）。
  final Color? borderColor;

  @override
  State<GlassWidget> createState() => _GlassWidgetState();
}

class _GlassWidgetState extends State<GlassWidget> with SingleTickerProviderStateMixin {
  ui.Image? _backgroundImage;
  Offset _touchPos = const Offset(-1, -1);
  late AnimationController _controller;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _controller.addListener(_scheduleCapture);
    // 首帧后捕获背景
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureBackground());
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundImage?.dispose();
    super.dispose();
  }

  /// 从 [RepaintBoundary] 捕获背景为 [ui.Image]。
  Future<void> _captureBackground() async {
    if (_capturing) return;
    final ctx = widget.captureKey.currentContext;
    if (ctx == null) return;
    final boundary = ctx.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    _capturing = true;
    try {
      // pixelRatio 用 1 保持逻辑像素坐标一致
      final image = await boundary.toImage(pixelRatio: 1);
      final old = _backgroundImage;
      _backgroundImage = image;
      old?.dispose();
      if (mounted) setState(() {});
    } catch (_) {
      // 捕获失败（可能边界尚未布局），下一帧重试
    } finally {
      _capturing = false;
    }
  }

  void _scheduleCapture() {
    // 动画驱动定期刷新背景（背景可能在滚动/变化）
    if (_controller.value < 0.02) _captureBackground();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _touchPos = details.localPosition);
  }

  void _handleTapEnd() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _touchPos = const Offset(-1, -1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final glass = _buildGlass();
    return GestureDetector(
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? (_) { _handleTapEnd(); widget.onTap!(); } : null,
      onTapCancel: widget.onTap != null ? () => _handleTapEnd() : null,
      child: widget.width != null || widget.height != null
          ? SizedBox(
              width: widget.width,
              height: widget.height,
              child: glass,
            )
          : glass,
    );
  }

  Widget _buildGlass() {
    // minimal 质量或着色器未就绪：用内置 BackdropFilter 兜底
    if (widget.quality == GlassQuality.minimal ||
        !GlassShaderProgram.instance.isLoaded ||
        _backgroundImage == null) {
      return _buildFallback();
    }
    return CustomPaint(
      painter: _GlassPainter(
        background: _backgroundImage!,
        quality: widget.quality,
        cornerRadius: widget.cornerRadius,
        refractionHeight: widget.refractionHeight,
        refractionAmount: widget.refractionAmount,
        touchPos: _touchPos,
        time: _controller.value,
      ),
      child: Padding(
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }

  /// 兜底渲染：BackdropFilter 模糊 + 半透明 + 边框高光（全 API 兼容）。
  Widget _buildFallback() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.cornerRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(widget.cornerRadius),
            border: Border.all(
              color: widget.borderColor ?? Colors.white.withOpacity(0.35),
              width: 1.2,
            ),
          ),
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({
    required this.background,
    required this.quality,
    required this.cornerRadius,
    required this.refractionHeight,
    required this.refractionAmount,
    required this.touchPos,
    required this.time,
  });

  final ui.Image background;
  final GlassQuality quality;
  final double cornerRadius;
  final double refractionHeight;
  final double refractionAmount;
  final Offset touchPos;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = GlassShaderProgram.instance.createGlassShader();

    // Float uniforms（按着色器声明顺序）
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, size.width / 2)   // glassCenter X
      ..setFloat(3, size.height / 2)  // glassCenter Y
      ..setFloat(4, size.width / 2)   // halfSize X
      ..setFloat(5, size.height / 2)  // halfSize Y
      ..setFloat(6, cornerRadius)
      ..setFloat(7, refractionHeight)
      ..setFloat(8, refractionAmount)
      ..setFloat(9, touchPos.dx)
      ..setFloat(10, touchPos.dy)
      ..setFloat(11, time)
      ..setFloat(12, quality.shaderValue.toDouble())
      ..setImageSampler(0, background);

    final rect = Offset.zero & size;
    // 圆角裁剪，避免着色器外部区域露出
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, Paint()..shader = shader);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassPainter old) =>
      old.background != background ||
      old.touchPos != touchPos ||
      old.time != time ||
      old.quality != quality;
}
