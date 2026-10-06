import 'package:flutter/material.dart';

import '../glass/glass_quality.dart';
import '../glass/liquid_glass_widget.dart';

/// 演示首页：真实信息流背景上的悬浮玻璃搜索条。
///
/// 玻璃做成小尺寸悬浮胶囊（液态玻璃的正确用法），压在图文流上，
/// 能清楚看到下方内容被磨砂 + 轻微折射，边缘高光清晰。
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
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          RepaintBoundary(key: _bgKey, child: const _FeedBackground()),
          // 悬浮玻璃搜索条
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GlassWidget(
                captureKey: _bgKey,
                quality: widget.quality,
                cornerRadius: 24,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onTap: () {},
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      '假期随手拍 · 搜索',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.mail_outline, color: Colors.white, size: 22),
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

/// 模拟真实 App 信息流：顶部 banner、图标宫格、帖子图文。
class _FeedBackground extends StatelessWidget {
  const _FeedBackground();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 120),
          // 顶部 banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
            ),
            child: const Center(
              child: Text(
                '假期随手拍\n有奖活动进行中',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 图标宫格
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _IconItem(Colors.blue, Icons.check_circle, '值得看'),
                _IconItem(Colors.orange, Icons.article, '热闻'),
                _IconItem(Colors.red, Icons.event, '活动'),
                _IconItem(Colors.lightBlue, Icons.smart_toy, 'AI'),
                _IconItem(Colors.teal, Icons.person, '人像'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 帖子卡片
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF8B5CF6),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '风月无痕_',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '现在很多人觉得手机行业不赚钱了，做车才是出路。但真相是：不是手机不赚钱，是低端品牌不赚钱。\n\n苹果、三星依然赚得盆满钵满……',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 15,
                    height: 1.6,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 180,
            color: const Color(0xFFDBEAFE),
          ),
        ],
      ),
    );
  }
}

class _IconItem extends StatelessWidget {
  const _IconItem(this.color, this.icon, this.label);
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 12,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
