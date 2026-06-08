import 'package:flutter/material.dart';

/// Color扩展方法，提供更便捷的颜色操作
/// 主要用于设置颜色透明度和其他属性
extension ColorExtensions on Color {
  /// 设置颜色的透明度
  /// alpha: 透明度值，范围0.0-1.0
  Color withValues({double alpha = 1.0}) {
    // 将0-1范围的alpha转换为0-255范围
    final int alphaValue = (alpha.clamp(0.0, 1.0) * 255).round();
    // 将r, g, b从0-1范围转换为0-255范围
    final int redValue = (r * 255).round();
    final int greenValue = (g * 255).round();
    final int blueValue = (b * 255).round();
    return Color.fromARGB(alphaValue, redValue, greenValue, blueValue);
  }
}