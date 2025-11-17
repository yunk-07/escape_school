// ui_theme.dart
// 新文件作用：提供通用进度条的立体背景与填充渐变（供 HP/饱食度/精神值使用）

import 'package:flutter/material.dart';

/// UI 主题工具：进度条相关渐变
class UITheme {
  /// 关键区域：条形背景渐变（立体基底）
  /// 顶部偏深、底部偏浅，制造轻微 3D 阴影感
  static Gradient progressBackground() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF272A2F),
        Color(0xFF3A3F46),
      ],
    );
  }

  /// 关键区域：条形填充渐变（末端亮度与层次）
  /// 以传入颜色为主体，前端更亮、后端更深，并带少许高光对比
  static Gradient progressFill(Color base) {
    final Color light = _tint(base, 0.35);
    final Color mid = _tint(base, 0.15);
    final Color dark = _shade(base, 0.15);
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        light,
        mid,
        base,
        dark,
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
  }

  // —— 辅助：颜色微调（避免额外依赖） ——
  static Color _tint(Color c, double amount) {
    amount = amount.clamp(0.0, 1.0);
    final int a = (c.a * 255).round();
    final int r = (c.r * 255).round();
    final int g = (c.g * 255).round();
    final int b = (c.b * 255).round();
    return Color.fromARGB(
      a,
      r + ((255 - r) * amount).round(),
      g + ((255 - g) * amount).round(),
      b + ((255 - b) * amount).round(),
    );
  }

  static Color _shade(Color c, double amount) {
    amount = amount.clamp(0.0, 1.0);
    final int a = (c.a * 255).round();
    final int r = (c.r * 255).round();
    final int g = (c.g * 255).round();
    final int b = (c.b * 255).round();
    return Color.fromARGB(
      a,
      (r * (1 - amount)).round(),
      (g * (1 - amount)).round(),
      (b * (1 - amount)).round(),
    );
  }
}