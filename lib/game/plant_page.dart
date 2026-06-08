// game/plant_page.dart
// 植物详情页面：显示植物的详细信息和操作
//
// 使用方法：
// - PlantPage是用于展示植物详细信息的页面组件
// - 通过 Navigator.push() 从植物列表或地图界面导航到此页面
// - 支持植物浇水和采摘操作，操作完成后自动返回
//
// 内部键的作用：
// - plant: Plant对象，包含植物的完整信息（ID、生长阶段、种植时间等）
// - context: BuildContext，Flutter构建上下文
// - ref: WidgetRef，Riverpod状态管理引用
//
// 页面结构：
// 1. 植物基本信息卡片（图片、名称、描述）
// 2. 生长状态卡片（当前阶段、进度、种植时间）
// 3. 护理状态卡片（是否需要浇水、是否可采摘、最后浇水时间）
// 4. 操作按钮区域（浇水按钮、采摘按钮、挖除按钮）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_from_school/game/planting_system.dart';
import 'package:escape_from_school/data/props.dart';

class PlantPage extends ConsumerWidget {
  final Plant plant;

  const PlantPage({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = allItems.firstWhere((item) => item.id == plant.itemId);

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text('植物详情'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 植物图片和基本信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 植物图片
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(_getCurrentStageImage(item, plant)),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 植物名称和描述
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    item.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 生长状态信息
            _buildStatusCard(context, '生长状态', [
              _buildStatusItem('当前阶段', _getStageName(plant.stage)),
              _buildStatusItem(
                '生长进度',
                '${(plant.growthProgress * 100).toInt()}%',
              ),
              _buildStatusItem('种植时间', _formatTime(plant.plantedTime)),
            ]),

            const SizedBox(height: 16),

            // 护理状态信息
            _buildStatusCard(context, '护理状态', [
              _buildStatusItem('是否需要浇水', plant.needsWater ? '是' : '否'),
              _buildStatusItem('是否可采摘', plant.isHarvestable ? '是' : '否'),
              if (plant.lastWateredTime != null)
                _buildStatusItem('最后浇水', _formatTime(plant.lastWateredTime!)),
            ]),

            const SizedBox(height: 20),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 浇水按钮
                ElevatedButton.icon(
                  onPressed: () => _waterPlant(context, ref),
                  icon: const Icon(Icons.water_drop, color: Colors.white),
                  label: Text(plant.needsWater ? '浇水' : '已浇水'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: plant.needsWater ? Colors.blue[500] : Colors.grey[500],
                    foregroundColor: Colors.white,
                  ),
                ),

                // 采摘按钮
                ElevatedButton.icon(
                  onPressed: plant.isHarvestable ? () => _harvestPlant(context, ref) : null,
                  icon: const Icon(Icons.eco, color: Colors.white),
                  label: const Text('采摘'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: plant.isHarvestable ? Colors.orange[500] : Colors.grey[500],
                    foregroundColor: Colors.white,
                  ),
                ),

                // 挖除按钮
                ElevatedButton.icon(
                  onPressed: () => _removePlant(context, ref),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('挖除'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[500],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 浇水方法
  void _waterPlant(BuildContext context, WidgetRef ref) async {
    try {
      // 调用种植系统的浇水方法
      final plantingSystemNotifier = ref.read(plantingSystemProvider.notifier);
      final success = plantingSystemNotifier.waterPlantWithBonus(plant.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('植物已浇水（消耗6饱食度，1精神值，生长速度+10%）'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('浇水失败：植物不存在或资源不足'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('浇水失败: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 采摘方法
  void _harvestPlant(BuildContext context, WidgetRef ref) {
    try {
      // 调用种植系统的采摘方法
      final plantingSystemNotifier = ref.read(plantingSystemProvider.notifier);
      final harvestedItems = plantingSystemNotifier.harvestPlant(plant.id);

      if (harvestedItems.isNotEmpty) {
        final itemNames = harvestedItems.map((item) => item.name).join('、');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('你收获了：$itemNames'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('采摘失败：植物尚未成熟或无法采摘。'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('采摘时发生错误：$e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 挖除方法
  void _removePlant(BuildContext context, WidgetRef ref) {
    try {
      // 调用种植系统的挖除方法
      final plantingSystemNotifier = ref.read(plantingSystemProvider.notifier);
      final success = plantingSystemNotifier.removePlant(plant.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已成功挖除植物。'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('挖除失败：植物不存在或资源不足。'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('挖除时发生错误：$e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 获取植物当前阶段的图片路径
  String _getCurrentStageImage(Item item, Plant plant) {
    final plantParams = item.plantParams!;
    final stageImages = plantParams['stageImages'] as List<String>? ?? [];

    if (stageImages.isNotEmpty && plant.currentStage < stageImages.length) {
      return stageImages[plant.currentStage];
    }

    return item.image; // 默认使用物品图片
  }

  // 获取阶段名称
  String _getStageName(PlantStage stage) {
    switch (stage) {
      case PlantStage.seed:
        return '种子期';
      case PlantStage.sprout:
        return '发芽期';
      case PlantStage.growing:
        return '生长期';
      case PlantStage.mature:
        return '成熟期';
      case PlantStage.withered:
        return '枯萎期';
    }
  }

  // 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }

  Widget _buildStatusCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
