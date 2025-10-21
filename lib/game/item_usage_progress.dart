// game/item_usage_progress.dart
// 物品使用进度条组件 - 简洁的物品使用进度显示

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_from_school/game/optimized_game_state.dart';
import 'package:escape_from_school/data/props.dart';

/// 物品使用进度条组件
class ItemUsageProgress extends ConsumerWidget {
  const ItemUsageProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(optimizedGameStateProvider);
    
    // 如果没有在使用物品，不显示进度条
    if (!gameState.isUsingItem || gameState.currentUsingItem == null) {
      return const SizedBox.shrink();
    }
    
    final item = gameState.currentUsingItem!;
    final progress = gameState.itemUsageProgress;
    
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.25,
      left: MediaQuery.of(context).size.width * 0.25,
      right: MediaQuery.of(context).size.width * 0.25,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getItemTypeColor(item.type).withOpacity(0.6),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 简化的信息行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 物品名称
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // 取消按钮 - 简化版
                GestureDetector(
                  onTap: () {
                    final notifier = ref.read(optimizedGameStateProvider.notifier);
                    notifier.cancelItemUsage();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // 简化的进度条
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getItemTypeColor(item.type),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 获取物品类型颜色
  Color _getItemTypeColor(String type) {
    switch (type) {
      case 'potion':
        return Colors.green;
      case 'food':
        return Colors.orange;
      case 'tool':
        return Colors.blue;
      case 'weapon':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}