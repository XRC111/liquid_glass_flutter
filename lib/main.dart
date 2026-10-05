import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass/glass_quality.dart';
import 'glass/glass_shader_program.dart';
import 'pages/card_demo.dart';
import 'pages/home_page.dart';
import 'pages/tabbar_demo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 查询设备 API 级别和低内存状态，确定渲染质量
  final quality = await _detectQuality();

  // 预加载着色器
  await GlassShaderProgram.instance.load();

  runApp(LiquidGlassApp(quality: quality));
}

/// 通过平台通道读取 Android API 级别和 isLowRamDevice。
Future<GlassQuality> _detectQuality() async {
  try {
    const channel = MethodChannel('com.example.liquid_glass/device');
    final info = await channel.invokeMethod<Map>('getDeviceInfo');
    if (info == null) return GlassQuality.medium;
    final sdkInt = info['sdkInt'] as int? ?? 24;
    final isLowRam = info['isLowRam'] as bool? ?? false;
    return resolveQuality(sdkInt: sdkInt, isLowRam: isLowRam);
  } catch (_) {
    // 非 Android 或通道失败，用中等质量
    return GlassQuality.medium;
  }
}

class LiquidGlassApp extends StatelessWidget {
  const LiquidGlassApp({super.key, required this.quality});

  final GlassQuality quality;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: DemoShell(quality: quality),
    );
  }
}

/// 演示外壳：顶部切换三个演示页面，显示当前质量等级。
class DemoShell extends StatefulWidget {
  const DemoShell({super.key, required this.quality});

  final GlassQuality quality;

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(quality: widget.quality),
      TabBarDemo(quality: widget.quality),
      CardDemo(quality: widget.quality),
    ];
    return Stack(
      children: [
        pages[_page],
        // 顶部页面切换器
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _seg(0, '首页'),
                  _seg(1, 'TabBar'),
                  _seg(2, '卡片'),
                ],
              ),
            ),
          ),
        ),
        // 质量等级指示
        Positioned(
          top: MediaQuery.of(context).padding.top + 64,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '质量: ${widget.quality.name}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _seg(int index, String label) {
    final active = _page == index;
    return GestureDetector(
      onTap: () => setState(() => _page = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
