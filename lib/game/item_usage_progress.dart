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
    
    // 获取剩余时间
    final gameStateNotifier = ref.read(optimizedGameStateProvider.notifier);
    final remainingTime = gameStateNotifier.getItemUsageRemainingTime();

    // 关键区域：进度条美化（保留角圆角度），统一为渐变+高光+阴影的立体风格
    final Color typeColor = _getItemTypeColor(item.type);
    return Positioned(
      top: 150, // 播报框下方（播报框top: 40 + height: 100 + 间距: 10）
      right: 80, // 与播报框右对齐
      width: 200, // 与播报框同宽
      child: Stack(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              // 外框背景改为柔和渐变（保留原来的圆角 4）
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.80),
                  Colors.black.withOpacity(0.65),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 6)),
                BoxShadow(color: Colors.white.withOpacity(0.06), blurRadius: 6, offset: const Offset(-1, -1)),
              ],
            ),
            // 前景高光（与整体风格一致）
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.transparent,
                  Colors.white.withOpacity(0.02),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: Row(
              children: [
                // 进度条主体（保留子进度条的角圆 2）
                Expanded(
                  child: Container(
                    height: 20,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      // 关键区域：底条中性渐变，不抢色
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.black.withOpacity(0.20),
                        ],
                      ),
                      border: Border.all(color: Colors.white24, width: 1),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2), // 保留角圆角度
                      child: Stack(
                        children: [
                          // 进度填充（颜色源自物品类型，渐变+内阴影增强立体）
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      typeColor.withOpacity(0.90),
                                      typeColor.withOpacity(0.65),
                                    ],
                                  ),
                                  border: Border(
                                    right: BorderSide(color: Colors.white.withOpacity(0.25), width: 0.8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 前景高光（不改变角圆）
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.08),
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.03),
                                    ],
                                    stops: const [0.0, 0.55, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 物品名称居中显示（提升对比度）
                          Center(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 取消按钮（保留圆角 4），样式更立体
                GestureDetector(
                  onTap: () {
                    final notifier = ref.read(optimizedGameStateProvider.notifier);
                    notifier.cancelItemUsage();
                  },
                  child: Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.shade700,
                          Colors.red.shade900,
                        ],
                      ),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1),
                      borderRadius: BorderRadius.circular(4), // 保留变角角度
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '取消使用',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 倒计时显示在右上角（提升可读性）
          Positioned(
            top: 2,
            right: 75, // 避免与取消按钮重叠
            child: Text(
              '${remainingTime.toStringAsFixed(1)}s',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 获取物品类型颜色
  Color _getItemTypeColor(String type) {
    switch (type) {
      case '装备':
        return Colors.indigo;
      case '物品':
        return Colors.amber;
      case 'potion':
        return Colors.green;
      case 'food':
        return Colors.orange;
      case 'tool':
        return Colors.blue;
      case 'weapon':
        return Colors.red;
      case 'book':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}