import 'package:flutter/material.dart';

import '../glass/glass_quality.dart';
import '../glass/liquid_glass_widget.dart';

/// 演示首页：彩色背景上的单个液态玻璃卡片。
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
          // 背景：渐变 + 彩色圆形，便于观察折射和色散
          RepaintBoundary(
            key: _bgKey,
            child: const _ColorfulBackground(),
          ),
          // 玻璃卡片
          SafeArea(
            child: Center(
              child: GlassWidget(
                captureKey: _bgKey,
                quality: widget.quality,
                cornerRadius: 28,
                width: 300,
                height: 200,
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
                    SizedBox(height: 8),
                    Text(
                      '真实折射 · 色散 · 边缘高光\n点击查看触摸光照',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
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

/// 彩色背景：多色渐变 + 装饰圆形，让玻璃折射效果清晰可见。
class _ColorfulBackground extends StatelessWidget {
  const _ColorfulBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E1065),
            Color(0xFF4C1D95),
            Color(0xFF831843),
            Color(0xFF1E3A8A),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 80,
            left: 40,
            child: _blob(140, const Color(0xFFF472B6)),
          ),
          Positioned(
            top: 300,
            right: 30,
            child: _blob(180, const Color(0xFF38BDF8)),
          ),
          Positioned(
            bottom: 120,
            left: 60,
            child: _blob(160, const Color(0xFFFBBF24)),
          ),
          Positioned(
            bottom: 280,
            right: 100,
            child: _blob(100, const Color(0xFF34D399)),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.9), color.withOpacity(0.1)],
        ),
      ),
    );
  }
}
