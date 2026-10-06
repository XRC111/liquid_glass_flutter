import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'glass_quality.dart';
import 'glass_shader_program.dart';

/// 液态玻璃核心组件。
///
/// 通过 [RepaintBoundary] + [RenderRepaintBoundary.toImage] 捕获玻璃正下方的背景，
/// 片元着色器按玻璃在背景中的真实位置采样，实现折射、磨砂、边缘高光。
///
/// 用法：
/// ```dart
/// final bgKey = GlobalKey();
/// Stack(children: [
///   RepaintBoundary(key: bgKey, child: MyBackground()),
///   GlassWidget(captureKey: bgKey, child: Text('玻璃上的内容')),
/// ]);
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

  final GlobalKey captureKey;
  final Widget? child;
  final double cornerRadius;
  final double refractionHeight;
  final double refractionAmount;
  final GlassQuality quality;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  State<GlassWidget> createState() => _GlassWidgetState();
}

class _GlassWidgetState extends State<GlassWidget>
    with SingleTickerProviderStateMixin {
  ui.Image? _backgroundImage;
  Offset _glassOrigin = Offset.zero; // 玻璃左上角在背景坐标系中的位置
  Size _bgSize = Size.zero;           // 被捕获背景的逻辑尺寸
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureBackground());
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundImage?.dispose();
    super.dispose();
  }

  /// 捕获背景，并同时记录玻璃在背景坐标系中的位置与背景尺寸。
  Future<void> _captureBackground() async {
    if (_capturing) return;
    final ctx = widget.captureKey.currentContext;
    if (ctx == null) return;
    final boundary = ctx.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    final glassObj = context.findRenderObject();
    if (glassObj is! RenderBox) return;
    _capturing = true;
    try {
      final image = await boundary.toImage(pixelRatio: 1);
      // 玻璃左上角在背景坐标系（逻辑像素）中的位置
      final globalTopLeft = glassObj.localToGlobal(Offset.zero);
      final localOrigin = boundary.globalToLocal(globalTopLeft);
      if (mounted) {
        setState(() {
          final old = _backgroundImage;
          _backgroundImage = image;
          old?.dispose();
          _glassOrigin = localOrigin;
          _bgSize = boundary.size;
        });
      } else {
        image.dispose();
      }
    } catch (_) {
      // 捕获失败，下一帧重试
    } finally {
      _capturing = false;
    }
  }

  void _scheduleCapture() {
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
    final g = GestureDetector(
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _handleTapEnd();
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? _handleTapEnd : null,
      child: glass,
    );
    if (widget.width != null || widget.height != null) {
      return SizedBox(width: widget.width, height: widget.height, child: g);
    }
    return g;
  }

  Widget _buildGlass() {
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
        glassOrigin: _glassOrigin,
        bgSize: _bgSize,
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );
  }

  /// 兜底：BackdropFilter 模糊 + 半透明边框（全 API 兼容）。
  Widget _buildFallback() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.cornerRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(widget.cornerRadius),
            border: Border.all(
              color: widget.borderColor ?? Colors.white.withOpacity(0.4),
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
    required this.glassOrigin,
    required this.bgSize,
  });

  final ui.Image background;
  final GlassQuality quality;
  final double cornerRadius;
  final double refractionHeight;
  final double refractionAmount;
  final Offset touchPos;
  final double time;
  final Offset glassOrigin;
  final Size bgSize;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = GlassShaderProgram.instance.createGlassShader();

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, size.width / 2)
      ..setFloat(3, size.height / 2)
      ..setFloat(4, size.width / 2)
      ..setFloat(5, size.height / 2)
      ..setFloat(6, cornerRadius)
      ..setFloat(7, refractionHeight)
      ..setFloat(8, refractionAmount)
      ..setFloat(9, touchPos.dx)
      ..setFloat(10, touchPos.dy)
      ..setFloat(11, time)
      ..setFloat(12, quality.shaderValue.toDouble())
      ..setFloat(13, glassOrigin.dx)
      ..setFloat(14, glassOrigin.dy)
      ..setFloat(15, bgSize.width)
      ..setFloat(16, bgSize.height)
      ..setImageSampler(0, background);

    final rect = Offset.zero & size;
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
      old.quality != quality ||
      old.glassOrigin != glassOrigin ||
      old.bgSize != bgSize;
}
