// 挖除功能调试工具
// 
// 使用方法：
// 1. 在应用中按压开发者快捷键（需要添加相关快捷键实现）
// 2. 或直接调用 DebugRemovePlantService.debugRemovePlant() 方法
// 
// 功能说明：
// - 提供挖除功能的调试信息
// - 检查饱食度状态
// - 验证植物列表
// - 提供手动移除植物的方法

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/planting_system.dart';
import '../game/optimized_game_state.dart';

/// 挖除功能调试服务类
/// 
/// 提供挖除植物功能的调试信息和手动操作
class DebugRemovePlantService {
  /// 调试挖除植物功能
  static void debugRemovePlant(BuildContext context, WidgetRef ref, String plantId) {
    try {
      // 打印当前游戏状态
      final gameState = ref.read(optimizedGameStateProvider);
      final characterStats = gameState.characterStats;
      final currentFood = characterStats['food'] ?? 0;
      debugPrint('=== 挖除功能调试信息 ===');
      debugPrint('植物ID: $plantId');
      debugPrint('当前饱食度: $currentFood');
      debugPrint('是否足够挖除: ${currentFood >= 1 ? "是" : "否"}');

      // 打印当前植物列表
      final plantingState = ref.read(plantingSystemProvider);
      debugPrint('当前植物列表:');
      if (plantingState.plants.isEmpty) {
        debugPrint('  - 植物列表为空');
      } else {
        for (var plant in plantingState.plants) {
          debugPrint('  - ${plant.id}: ${plant.itemId}');
        }
      }

      // 尝试挖除
      debugPrint('尝试挖除...');
      final plantingSystemNotifier = ref.read(plantingSystemProvider.notifier);
      final success = plantingSystemNotifier.removePlant(plantId);
      debugPrint('挖除结果: ${success ? "成功" : "失败"}');

      // 显示结果
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('挖除结果: ${success ? "成功" : "失败"}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('调试挖除功能时发生错误: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('调试时发生错误: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}