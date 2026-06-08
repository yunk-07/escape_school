// game/tile_plant_button.dart
// 二级种植按钮：在瓦片上显示可种植的物品选择
//
// 使用方法：
// - TilePlantButton是用于在游戏地图的可种植瓦片上显示种植按钮的组件
// - 只在瓦片选择模式下显示（plantingMode == PlantingMode.tileSelection）
// - 自动筛选并只显示在玩家视野范围内的可种植瓦片
// - 点击按钮后进入物品选择模式，允许玩家选择要种植的物品
// - 使用增强版视野系统计算真正的可见范围
//
// 内部键的作用：
// - plantingState: PlantingSystemNotifier状态，包含种植模式、可种植瓦片等信息
// - gameState: OptimizedGameState状态，包含玩家位置、地图、视野等游戏状态
// - screenSize: Size对象，表示屏幕尺寸，用于计算中心位置
// - tileSize: double类型，固定值为40.0，表示瓦片的像素大小
// - mapOffsetX/Y: double类型，地图偏移量，计算瓦片在屏幕上的实际位置
// - playerGrid: Point<int>对象，玩家当前所在的瓦片坐标
// - enhancedVision: EnhancedVisionSystem实例，增强版视野系统
// - visibleTileSet: Set<Point<int>>，当前可见的瓦片坐标集合
//
// 功能特点：
// 1. 智能可见性过滤：只显示玩家真正能看到且可种植的瓦片
// 2. 绿色半透明设计：使用绿色作为主色调，表示可种植状态
// 3. 动态位置计算：根据玩家位置和地图偏移量实时计算按钮位置
// 4. 交互反馈：点击后进入物品选择模式，触发种植流程的下一步
// 5. 视野范围计算：结合理智值和氧气值计算实际可见范围

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './planting_system.dart';
import './optimized_game_state.dart';
import './enhanced_vision.dart';

class TilePlantButton extends ConsumerWidget {
  const TilePlantButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantingState = ref.watch(plantingSystemProvider);
    final gameState = ref.watch(optimizedGameStateProvider);

    // 只在瓦片选择模式下显示二级种植按钮
    if (plantingState.plantingMode != PlantingMode.tileSelection) {
      return const SizedBox.shrink();
    }

    if (plantingState.plantableTiles.isEmpty) {
      return const SizedBox.shrink();
    }

    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final double centerX = screenSize.width / 2;
    final double centerY = screenSize.height / 2;

    // 计算瓦片尺寸和地图偏移量
    final double tileSize = 40.0;
    final double mapOffsetX = centerX - (gameState.playerPosition.x * tileSize);
    final double mapOffsetY = centerY - (gameState.playerPosition.y * tileSize);

    // 使用增强版视野系统获取可见的瓦片（包含所有可见级别）
    final playerGrid = gameState.playerPosition.toPoint();
    final currentSanity = (gameState.characterStats['san'] ?? 100).toDouble();
    final maxSanity = 250.0;
    final currentOxygen = gameState.currentOxygen;
    final maxOxygen = gameState.actualMaxOxygen;
    final oxygenRatio = maxOxygen > 0 ? currentOxygen / maxOxygen : 1.0;

    final enhancedVision = EnhancedVisionSystem(map: gameState.map);
    final visibleTilesWithLevel = enhancedVision.getVisibleTilesWithLevel(
      playerGrid,
      sanityValue: currentSanity,
      maxSanity: maxSanity,
      oxygenVisionMultiplier: oxygenRatio,
    );

    // 将所有可见的瓦片转换为集合（包括完全可见和部分可见）
    final visibleTileSet = visibleTilesWithLevel
        .entries
        .where((entry) => 
            entry.value == TileVisibility.fullyVisible ||
            entry.value == TileVisibility.partiallyVisible ||
            entry.value == TileVisibility.visibleWithFogDecoration ||
            entry.value == TileVisibility.partiallyVisibleWithFogDecoration)
        .map((entry) => entry.key)
        .toSet();

    return Stack(
      children: plantingState.plantableTiles
          .where((tile) => visibleTileSet.contains(tile.position)) // 只显示在可见范围内的瓦片
          .map((tile) {
        // 计算瓦片在屏幕上的位置
        final screenX = tile.position.x * tileSize + mapOffsetX;
        final screenY = tile.position.y * tileSize + mapOffsetY;

        return Positioned(
          left: screenX.toDouble(),
          top: screenY.toDouble(),
          child: GestureDetector(
            onTap: () {
              // 选择瓦片，进入物品选择模式
              ref.read(plantingSystemProvider.notifier).selectTile(tile.position);
            },
            child: Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}