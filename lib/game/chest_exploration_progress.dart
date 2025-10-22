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
    
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.25,
      left: MediaQuery.of(context).size.width * 0.2,
      right: MediaQuery.of(context).size.width * 0.2,
      child: Row(
        children: [
          // 长方形白色进度条
          Expanded(
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(4),
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
    );
  }
}