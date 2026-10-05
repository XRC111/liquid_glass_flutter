import 'package:flutter/material.dart';

import '../glass/glass_quality.dart';
import '../glass/liquid_glass_widget.dart';

/// 卡片列表演示：多个液态玻璃卡片覆盖在彩色背景上。
class CardDemo extends StatelessWidget {
  const CardDemo({super.key, required this.quality});

  final GlassQuality quality;

  @override
  Widget build(BuildContext context) {
    final bgKey = GlobalKey();
    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            key: bgKey,
            child: const _GradientBackground(),
          ),
          SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              itemCount: 8,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassWidget(
                  captureKey: bgKey,
                  quality: quality,
                  cornerRadius: 22,
                  onTap: () {},
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.bubble_chart_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '玻璃卡片 #${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '折射背景内容，边缘 Fresnel 高光',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E1B4B),
            Color(0xFF0F766E),
            Color(0xFF7C2D12),
            Color(0xFF1E293B),
          ],
          stops: [0, 0.35, 0.7, 1],
        ),
      ),
    );
  }
}
