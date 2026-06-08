// game/global_plant_button_v2.dart
// 新版全局种植按钮：常驻显示，不被遮挡，在设置按钮下方位置
//
// 使用方法：
// - GlobalPlantButtonV2是用于在游戏主界面显示种植按钮的组件
// - 通过 ref.watch(plantingSystemProvider) 和 ref.watch(gameStateProvider) 监听状态变化
// - 点击按钮时无论背包中是否有可种植物品都可以激活种植模式
// - 使用绿色图标表示非种植状态，橙色图标表示种植模式
//
// 内部键的作用：
// - plantingState: PlantingSystemNotifier状态，包含种植模式、可种植瓦片等信息
// - gameState: OptimizedGameState状态，包含玩家位置、地图、背包等游戏状态
// - hasPlantableItems: boolean类型，表示背包中是否有可种植的物品
// - isInPlantingMode: boolean类型，表示当前是否在种植模式中
// - activatePlantingMode(): function，激活种植模式的方法
// - cancelPlantingMode(): function，取消种植模式的方法
//
// 功能特点：
// 1. 实时状态监听：监听背包变化和种植模式状态
// 2. 随时激活：无论背包中是否有可种植物品都可以激活种植模式
// 3. 视觉反馈：按钮颜色和图标会根据种植模式状态变化
// 4. 空背包处理：当背包中没有可种植物品时种植模式会自动取消

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './planting_system.dart';

class GlobalPlantButtonV2 extends ConsumerWidget {
  const GlobalPlantButtonV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听种植系统状态
    final plantingState = ref.watch(plantingSystemProvider);

    // 检查当前是否在种植模式中
    final isInPlantingMode =
        plantingState.plantingMode != PlantingMode.inactive;

    return Positioned(
      top: 100, // 在设置按钮下方位置
      right: 20, // 距离右侧20像素，不被遮挡
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isInPlantingMode
                    ? [
                      Colors.orange.shade600.withValues(alpha: 0.9),
                      Colors.orange.shade800.withValues(alpha: 0.9),
                    ]
                    : [
                      Colors.green.shade600.withValues(alpha: 0.9),
                      Colors.green.shade800.withValues(alpha: 0.9),
                    ],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color:
                isInPlantingMode
                    ? Colors.orange.shade400.withValues(alpha: 0.8)
                    : Colors.green.shade400.withValues(alpha: 0.6),
            width: isInPlantingMode ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              if (isInPlantingMode) {
                // 如果在种植模式中，点击取消
                ref.read(plantingSystemProvider.notifier).cancelPlantingMode();
              } else {
                // 如果不在种植模式中，激活种植模式
                ref.read(plantingSystemProvider.notifier).activatePlantingMode();
              }
            },
            onLongPress: () {
              // 长按显示提示信息
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isInPlantingMode 
                        ? '再次点击取消种植模式'
                        : '点击激活种植模式'
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Center(
              child: Icon(
                Icons.eco, 
                color: Colors.white, 
                size: 28
              ),
            ),
          ),
        ),
      ),
    );
  }
}
