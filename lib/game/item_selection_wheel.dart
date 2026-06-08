/// game/item_selection_wheel.dart
/// 物品选择轮盘：显示可种植的物品选择界面
///
/// 【功能说明】
/// ItemSelectionWheel 是一个物品选择组件，用于在种植模式下让用户从可选物品列表中选择要种植的物品。
/// 该组件以圆形轮盘的形式展示所有可种植物品，用户点击物品图标即可选择并种植。
///
/// 【内部键(Key)说明】
/// - super.key: 传递给父类 ConsumerWidget 的键，用于 Flutter 的元素重建和状态管理
///
/// 【主要方法说明】
///
/// 1. build(BuildContext context, WidgetRef ref)
///    - 组件的构建方法，根据当前种植状态返回对应的 UI
///    - 参数说明：
///      - context: BuildContext，提供构建上下文信息
///      - ref: WidgetRef，用于读取和监听 Riverpod 状态提供者
///    - 返回值：根据种植模式返回物品选择轮盘或空组件
///    - 状态监听：监听 plantingSystemProvider 的状态变化，包括：
///      - plantingMode: 当前种植模式，为 itemSelection 时显示轮盘
///      - selectedTilePosition: 当前选中的瓦片位置
///      - plantableTiles: 可种植的瓦片列表
///      - plantableItems: 可种植的物品列表
///    - 处理逻辑：
///      - 检查是否为物品选择模式，否则返回空组件
///      - 获取当前选中的瓦片信息
///      - 根据是否有可种植物品显示不同的 UI
///      - 监听背景点击事件以取消种植模式
///
/// 2. _buildCircularItems(List<Item> items, BuildContext context, WidgetRef ref)
///    - 构建圆形排列的物品选择图标列表
///    - 参数说明：
///      - items: 要展示的物品列表 (Item 类型)
///      - context: BuildContext，用于获取主题和尺寸信息
///      - ref: WidgetRef，用于处理物品选择事件
///    - 返回值：物品组件的 Positioned 定位列表
///    - 实现逻辑：
///      - 计算圆形路径上的物品位置
///      - 使用三角函数 (cos, sin) 确定每个物品的 x, y 坐标
///      - 为每个物品创建圆形图标容器
///      - 添加交互：点击物品图标时调用种植系统选择该物品
///    - 布局参数：
///      - 圆盘半径：120.0
///      - 图标容器大小：60x60
///      - 中心点坐标：(200, 200)
///
/// 3. _getShortName(String fullName)
///    - 截取物品名称的简短表示
///    - 参数说明：
///      - fullName: 完整的物品名称字符串
///    - 返回值：截取后的简短名称
///    - 名称处理逻辑：
///      - 4 字符以内直接返回原名称
///      - 超过 4 字符则截取前 4 个字符
///    - 用途：圆形轮盘空间有限，需显示简短名称以保持 UI 整洁
///
/// 【依赖说明】
/// - flutter_riverpod: 状态管理 (ConsumerWidget, WidgetRef, ref.watch/read)
/// - planting_system.dart: 种植系统状态管理 (plantingSystemProvider, PlantingMode, PlantableTile)
/// - props.dart: Item 数据类型定义
/// - dart:math: 数学计算 (Point, pi, cos, sin) 用于圆形布局计算
///
/// 【使用场景】
/// 适用于游戏中的物品选择交互，常见于农场种植、园艺模拟等类型的游戏。
/// 提供直观的圆形选择界面，用户可以快速浏览并选择要种植的物品。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' show Point, pi, cos, sin;
import './planting_system.dart';
import '../data/props.dart'; // 导入Item类型

class ItemSelectionWheel extends ConsumerWidget {
  const ItemSelectionWheel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantingState = ref.watch(plantingSystemProvider);

    // 只在物品选择模式下显示物品选择轮盘
    if (plantingState.plantingMode != PlantingMode.itemSelection) {
      return const SizedBox.shrink();
    }

    if (plantingState.selectedTilePosition == null) {
      return const SizedBox.shrink();
    }

    // 获取选中的瓦片信息
    final selectedTile = plantingState.plantableTiles.firstWhere(
      (tile) => tile.position == plantingState.selectedTilePosition,
      orElse: () => const PlantableTile(position: Point(0, 0), type: ''),
    );

    if (selectedTile.type.isEmpty) {
      return const SizedBox.shrink();
    }

    // 现在所有瓦片都可以种植，直接使用所有可种植物品
    final supportedItems = plantingState.plantableItems.toList();

    // 如果没有可种植物品，显示提示信息
    if (supportedItems.isEmpty) {
      return Stack(
        children: [
          // 半透明背景
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // 点击背景取消选择
                ref.read(plantingSystemProvider.notifier).cancelPlantingMode();
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          
          // 提示信息弹窗
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 80,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '没有可种植物品',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '您的背包中没有可种植的物品。\n请先获取种子或其他可种植物品。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(plantingSystemProvider.notifier).cancelPlantingMode();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[500],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        // 半透明背景
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              // 点击背景取消选择
              ref.read(plantingSystemProvider.notifier).cancelPlantingMode();
            },
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ),
        
        // 圆盘选择器
        Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 圆盘背景
                Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.green[300]!,
                      width: 3,
                    ),
                  ),
                ),
                
                // 标题
                Positioned(
                  top: 20,
                  child: Text(
                    '选择种植物品',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // 瓦片信息
                Positioned(
                  top: 55,
                  child: Text(
                    '瓦片类型: ${selectedTile.type}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                
                // 圆盘物品选择
                ..._buildCircularItems(supportedItems, context, ref),
                
                // 取消按钮
                Positioned(
                  bottom: 20,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(plantingSystemProvider.notifier).cancelPlantingMode();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildCircularItems(List<Item> items, BuildContext context, WidgetRef ref) {
    final itemCount = items.length;
    final radius = 120.0; // 圆盘半径
    final angleStep = 2 * pi / itemCount; // 每个物品的角度间隔
    
    List<Widget> widgets = [];
    
    for (int i = 0; i < itemCount; i++) {
      final item = items[i];
      final angle = i * angleStep;
      final x = radius * cos(angle);
      final y = radius * sin(angle);
      
      widgets.add(
        Positioned(
          left: 200 + x - 30, // 中心点200, 调整位置使图标居中
          top: 200 + y - 30,
          child: GestureDetector(
            onTap: () {
              // 选择物品并种植
              ref.read(plantingSystemProvider.notifier).selectItem(item);
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.green[400]!,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 物品图标
                  Icon(
                    Icons.eco,
                    color: Colors.green[600],
                    size: 24,
                  ),
                  // 物品名称（简写）
                  Text(
                    _getShortName(item.name),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.green[800],
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }
  
  String _getShortName(String fullName) {
    if (fullName.length <= 4) {
      return fullName;
    }
    // 取前4个字符
    return fullName.substring(0, 4);
  }
}