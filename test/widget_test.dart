import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_flutter/glass/glass_quality.dart';

void main() {
  test('GlassQuality shader values are ordered', () {
    expect(GlassQuality.full.shaderValue, 0);
    expect(GlassQuality.medium.shaderValue, 1);
    expect(GlassQuality.minimal.shaderValue, 2);
  });

  test('minimal quality disables blur and dispersion', () {
    expect(GlassQuality.minimal.enableBlur, false);
    expect(GlassQuality.minimal.enableDispersion, false);
  });

  test('full quality enables all effects', () {
    expect(GlassQuality.full.enableBlur, true);
    expect(GlassQuality.full.enableDispersion, true);
  });
}
