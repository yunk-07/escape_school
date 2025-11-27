// utils/level_color_manager.dart
// 等级颜色统一管理文件
// 作用：集中管理项目中所有等级颜色相关的逻辑，便于统一修改和维护

import 'package:flutter/material.dart';

class LevelColorManager {
  /// 获取物品等级对应的颜色
  /// [level]: 物品等级 (1-7)
  /// 返回: 对应等级的Color对象
  static Color getItemLevelColor(int level) {
    final clampedLevel = level.clamp(1, 7);

    switch (clampedLevel) {
      case 1: // 无色等级
        return const Color(0xFFC0C0C0); // 银色
      case 2: // 绿色等级
        return const Color(0xFF4CAF50); // 绿色
      case 3: // 蓝色等级
        return const Color(0xFF2196F3); // 蓝色
      case 4: // 紫色等级
        return const Color(0xFF9C27B0); // 紫色
      case 5: // 金色等级 (原Lv7颜色)
        return const Color(0xFFFFD700); // 金色
      case 6: // 红色等级
        return const Color(0xFFF44336); // 红色
      case 7: // 橙色等级 (原Lv5颜色)
        return const Color(0xFFFF9800); // 橙色
      default:
        return const Color.fromARGB(255, 0, 0, 0); // 违禁
    }
  }

  /// 获取等级颜色名称（用于调试或显示）
  /// [level]: 物品等级 (1-7)
  /// 返回: 颜色名称字符串
  static String getLevelColorName(int level) {
    final clampedLevel = level.clamp(1, 7);

    switch (clampedLevel) {
      case 1:
        return '无色';
      case 2:
        return '绿色';
      case 3:
        return '蓝色';
      case 4:
        return '紫色';
      case 5:
        return '金色';
      case 6:
        return '红色';
      case 7:
        return '橙色';
      default:
        return '无色';
    }
  }

  /// 获取等级颜色对应的十六进制字符串
  /// [level]: 物品等级 (1-7)
  /// 返回: 十六进制颜色字符串（如"#FF0000"）
  static String getLevelColorHex(int level) {
    final color = getItemLevelColor(level);
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// 获取等级颜色对应的RGB值
  /// [level]: 物品等级 (1-7)
  /// 返回: 包含r、g、b值的Map
  static Map<String, int> getLevelColorRGB(int level) {
    final color = getItemLevelColor(level);
    return {'r': color.red, 'g': color.green, 'b': color.blue};
  }

  /// 获取等级颜色对应的ARGB值
  /// [level]: 物品等级 (1-7)
  /// 返回: 包含a、r、g、b值的Map
  static Map<String, int> getLevelColorARGB(int level) {
    final color = getItemLevelColor(level);
    return {
      'a': color.alpha,
      'r': color.red,
      'g': color.green,
      'b': color.blue,
    };
  }

  /// 获取等级颜色对应的透明度版本
  /// [level]: 物品等级 (1-7)
  /// [opacity]: 透明度 (0.0-1.0)
  /// 返回: 带透明度的Color对象
  static Color getLevelColorWithOpacity(int level, double opacity) {
    final color = getItemLevelColor(level);
    return color.withOpacity(opacity);
  }

  /// 获取等级颜色对应的withValues版本
  /// [level]: 物品等级 (1-7)
  /// [alpha]: 透明度 (0-255)
  /// 返回: 带透明度的Color对象
  static Color getLevelColorWithAlpha(int level, int alpha) {
    final color = getItemLevelColor(level);
    return color.withAlpha(alpha);
  }

  /// 获取等级颜色对应的渐变颜色列表
  /// [level]: 物品等级 (1-7)
  /// [count]: 渐变颜色数量
  /// 返回: 渐变颜色列表
  static List<Color> getLevelGradientColors(int level, {int count = 3}) {
    final baseColor = getItemLevelColor(level);
    final colors = <Color>[];

    for (int i = 0; i < count; i++) {
      final factor = i / (count - 1);
      final alpha = (255 * (1.0 - factor * 0.5)).toInt();
      colors.add(baseColor.withAlpha(alpha));
    }

    return colors;
  }
}
