import 'package:flutter/material.dart';

import '../glass/glass_quality.dart';
import '../glass/liquid_glass_widget.dart';

/// 演示首页：锐利内容上的液态玻璃卡片。
///
/// 背景特意用「边缘锐利的色块 + 文字 + 细分割线」，
/// 这样玻璃的模糊、折射和边缘高光才看得见（软渐变光斑只会显得更软）。
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.quality});

  final GlassQuality quality;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey _bgKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(key: _bgKey, child: const _SharpBackground()),
          // 玻璃卡片
          SafeArea(
            child: Center(
              child: GlassWidget(
                captureKey: _bgKey,
                quality: widget.quality,
                cornerRadius: 28,
                width: 320,
                height: 210,
                onTap: () {},
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liquid Glass',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '磨砂模糊 · 透镜折射 · RGB 色散\n点击卡片，边缘高光跟随手指',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 锐利背景：网格色块 + 标题文字 + 细线，模拟真实界面内容。
class _SharpBackground extends StatelessWidget {
  const _SharpBackground();

  @override
  Widget build(BuildContext context) {
    final items = [
      const _SharpRow(color: Color(0xFFEF4444), title: '快讯 · 行业动态'),
      const _SharpRow(color: Color(0xFF3B82F6), title: '科技 · 新机发布'),
      const _SharpRow(color: Color(0xFF10B981), title: '生活 · 假期随手拍'),
      const _SharpRow(color: Color(0xFFF59E0B), title: '财经 · 市场观察'),
      const _SharpRow(color: Color(0xFF8B5CF6), title: 'AI · 模型进展'),
      const _SharpRow(color: Color(0xFFEC4899), title: '摄影 · 人像技巧'),
    ];
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 80),
          for (final w in [
            ...items,
            const Divider(height: 1, thickness: 1, color: Color(0xFFCBD5E0)),
          ]) ...[w],
        ],
      ),
    );
  }
}

class _SharpRow extends StatelessWidget {
  const _SharpRow({required this.color, required this.title});
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // 锐利的纯色小方块（非软渐变）
          Container(
            width: 80,
            height: 80,
            color: color,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  color: const Color(0xFF94A3B8),
                  width: 160,
                ),
                const SizedBox(height: 5),
                Container(
                  height: 8,
                  color: const Color(0xFFCBD5E1),
                  width: 100,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
