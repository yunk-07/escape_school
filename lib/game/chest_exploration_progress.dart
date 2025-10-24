// game/chest_exploration_progress.dart
// 宝箱探索进度条组件 - 简洁的宝箱探索进度显示

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'optimized_game_state.dart';

/// 宝箱探索进度条组件
class ChestExplorationProgress extends ConsumerWidget {
  const ChestExplorationProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(optimizedGameStateProvider);
    
    // 如果没有在探索宝箱，不显示进度条
    if (!gameState.isExploringChest) {
      return const SizedBox.shrink();
    }
    
    final progress = gameState.chestExplorationProgress;
    
    // 获取剩余时间
    final gameStateNotifier = ref.read(optimizedGameStateProvider.notifier);
    final remainingTime = gameStateNotifier.getChestExplorationRemainingTime();
    
    return Positioned(
      top: 200, // 物品使用进度条下方（物品进度条top: 150 + height: 40 + 间距: 10）
      right: 80, // 与播报框右对齐
      width: 200, // 与播报框同宽
      child: Stack(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                // 进度条
                Expanded(
                  child: Container(
                    height: 20,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Stack(
                      children: [
                        // 进度填充
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                        ),
                        // 探索文本居中显示
                        Center(
                          child: Text(
                            '探索宝箱中...',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            
                const SizedBox(width: 8),
                
                // 正方形取消按钮
                GestureDetector(
                  onTap: () {
                    final notifier = ref.read(optimizedGameStateProvider.notifier);
                    notifier.cancelChestExploration();
                  },
                  child: Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        '取消探索',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 倒计时显示在右上角，避免与取消按钮重叠
           Positioned(
             top: 2,
             right: 75, // 避免与取消按钮重叠
             child: Text(
               '${remainingTime.toStringAsFixed(1)}s',
               style: const TextStyle(
                 color: Colors.white,
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 shadows: [
                   Shadow(
                     offset: Offset(1, 1),
                     blurRadius: 2,
                     color: Colors.black,
                   ),
                 ],
               ),
             ),
           ),
        ],
      ),
    );
  }
}