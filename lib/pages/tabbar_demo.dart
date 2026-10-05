import 'package:flutter/material.dart';

import '../glass/glass_quality.dart';
import '../glass/liquid_glass_widget.dart';

/// 底部 TabBar 演示：悬浮液态玻璃导航栏。
class TabBarDemo extends StatefulWidget {
  const TabBarDemo({super.key, required this.quality});

  final GlassQuality quality;

  @override
  State<TabBarDemo> createState() => _TabBarDemoState();
}

class _TabBarDemoState extends State<TabBarDemo> {
  final GlobalKey _bgKey = GlobalKey();
  int _index = 0;

  static const _icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.favorite_rounded,
    Icons.person_rounded,
  ];
  static const _labels = ['首页', '发现', '喜欢', '我的'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            key: _bgKey,
            child: _ScrollingBackground(index: _index),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                child: GlassWidget(
                  captureKey: _bgKey,
                  quality: widget.quality,
                  cornerRadius: 32,
                  height: 72,
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_icons.length, (i) {
                      final active = i == _index;
                      return GestureDetector(
                        onTap: () => setState(() => _index = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _icons[i],
                                color: active ? Colors.white : Colors.white60,
                                size: 26,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _labels[i],
                                style: TextStyle(
                                  color:
                                      active ? Colors.white : Colors.white60,
                                  fontSize: 11,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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

/// 可滚动彩色背景（模拟真实内容，玻璃导航栏折射滚动内容）。
class _ScrollingBackground extends StatelessWidget {
  const _ScrollingBackground({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 120),
        itemCount: 20,
        itemBuilder: (context, i) {
          final hue = (i * 47 + index * 60) % 360;
          return Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.55).toColor(),
                  HSLColor.fromAHSL(1, (hue + 40) % 360, 0.7, 0.4)
                      .toColor(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
