// game/plant_widget.dart
// 植物显示组件：显示地图上的植物及其生长状态
//
// 使用方法：
// - PlantWidget是用于在游戏地图上显示植物的组件
// - 通常嵌入在游戏主界面的Stack布局中，Positioned定位
// - 支持点击事件，点击后显示植物详情弹窗
// - 自动显示植物的生长状态、进度条和护理指示器
//
// 内部键的作用：
// - plant: Plant对象，包含植物的完整信息（ID、生长阶段、进度等）
// - position: Offset对象，表示植物在屏幕上的位置坐标
// - item: Item对象，通过plant.itemId获取，包含植物的基础属性
// - plantParams: Map对象，包含植物的种植参数
//
// 图片显示逻辑：
// 1. 植物图片根据当前生长阶段显示不同图片
// 2. 成熟时显示stageImages数组中的第三个图片（索引为2）
// 3. 生长进度达到100%时，currentStage会自动设置为stages-1
// 4. fallback机制：如果stageImages不可用，则使用item.image作为默认图片
//
// 视觉元素：
// 1. 植物图片：根据当前生长阶段显示不同图片（成熟时显示最后阶段图片）
// 2. 浇水状态指示器：蓝色水滴图标，表示需要浇水
// 3. 生长进度条：底部显示生长进度百分比
// 4. 成熟状态指示器：金色星星图标，表示可采摘
// 5. 阴影效果：增加视觉深度

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_from_school/game/planting_system.dart';
import 'package:escape_from_school/data/props.dart';
import 'package:escape_from_school/utils/color_extensions.dart';

class PlantWidget extends ConsumerWidget {
  final Plant plant;
  final double? opacity;

  const PlantWidget({super.key, required this.plant, this.opacity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = allItems.firstWhere((item) => item.id == plant.itemId);
    final plantParams = item.plantParams!;

    // 获取当前生长阶段的图片
    final currentStageImage =
        plantParams['stageImages']?[plant.currentStage] ?? item.image;

    return GestureDetector(
      onTap: () => _onPlantTap(context, ref, plant),
      child: Opacity(
        opacity: opacity ?? 1.0, // 应用透明度效果
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(currentStageImage),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
               color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildPlantOverlay(plant, item),
        ),
      ),
    );
  }

  Widget _buildPlantOverlay(Plant plant, Item item) {
    return Stack(
      children: [
        // 生长进度条
        Positioned(
          bottom: -8,
          left: 0,
          right: 0,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
             color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: plant.growthProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: _getProgressColor(plant.growthProgress),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.6) return Colors.orange;
    if (progress < 0.9) return Colors.yellow;
    return Colors.green;
  }

  void _onPlantTap(BuildContext context, WidgetRef ref, Plant plant) {
    // 显示植物详情弹窗
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlantDetailDialog(plant: plant);
      },
    );
  }
}

class PlantDetailDialog extends ConsumerWidget {
  final Plant plant;

  const PlantDetailDialog({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = allItems.firstWhere((item) => item.id == plant.itemId);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8, // 限制最大高度为屏幕高度的80%
        child: SingleChildScrollView(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 植物图片
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_getCurrentStageImage(item, plant)),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                       color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
                  if (plant.lastWateredTime != null)
                    _buildStatusItem(
                      '最后浇水',
                      _formatTime(plant.lastWateredTime!),
                    ),
                  _buildStatusItem('生长周期', _getGrowthCycleText(item)),
                ]),
                const SizedBox(height: 12),

                // 收获信息
                _buildStatusCard(context, '收获信息', [
                  _buildStatusItem('收获物', _getHarvestInfo(item)),
                  _buildStatusItem(
                    '成熟倒计时',
                    _getHarvestCountdownText(plant, item),
                  ),
                ]),
                const SizedBox(height: 12),

                // 护理状态信息
                _buildStatusCard(context, '护理状态', [
                  _buildStatusItem('是否需要浇水', plant.needsWater ? '是' : '否'),
                  _buildStatusItem('是否可采摘', plant.isHarvestable ? '是' : '否'),
                  if (item.plantParams?.containsKey('requiresWater') ?? false)
                    _buildStatusItem('浇水频率', _getWateringIntervalText(item)),
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
                        backgroundColor:
                            plant.needsWater
                                ? Colors.blue[500]
                                : Colors.grey[500],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),

                    // 采摘按钮
                    ElevatedButton.icon(
                      onPressed:
                          plant.isHarvestable
                              ? () => _harvestPlant(context, ref)
                              : null,
                      icon: const Icon(Icons.eco, color: Colors.white),
                      label: const Text('采摘'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            plant.isHarvestable
                                ? Colors.orange[500]
                                : Colors.grey[500],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 关闭按钮
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green[700],
                  ),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
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
        // 关闭对话框并显示成功提示
        Navigator.of(context).pop();
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
        // 关闭对话框并显示成功提示
        Navigator.of(context).pop();
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
        // 关闭对话框并显示成功提示
        Navigator.of(context).pop();
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
        return '种子期 (1/4)';
      case PlantStage.sprout:
        return '发芽期 (2/4)';
      case PlantStage.growing:
        return '生长期 (3/4)';
      case PlantStage.mature:
        return '成熟期 (4/4)';
      case PlantStage.withered:
        return '枯萎期';
    }
  }

  // 获取生长周期文本
  String _getGrowthCycleText(Item item) {
    if (item.plantParams != null &&
        item.plantParams!.containsKey('growthTimeMs')) {
      final int growthTimeMs = item.plantParams!['growthTimeMs'];
      return _formatDuration(growthTimeMs);
    }
    return '未知';
  }

  // 获取收获信息文本
  String _getHarvestInfo(Item item) {
    if (item.plantParams != null) {
      final String harvestItemName = item.name;
      final int harvestCount =
          item.plantParams!.containsKey('harvestCount')
              ? item.plantParams!['harvestCount']
              : 1;
      return '$harvestItemName x$harvestCount';
    }
    return '未知';
  }

  // 获取浇水间隔文本
  String _getWateringIntervalText(Item item) {
    if (item.plantParams != null &&
        item.plantParams!.containsKey('waterIntervalMs')) {
      final int waterIntervalMs = item.plantParams!['waterIntervalMs'];
      return _formatDuration(waterIntervalMs);
    }
    return '不需要浇水';
  }

  // 获取成熟倒计时文本
  String _getHarvestCountdownText(Plant plant, Item item) {
    if (!plant.isHarvestable &&
        item.plantParams != null &&
        item.plantParams!.containsKey('growthTimeMs')) {
      final int totalGrowthTimeMs = item.plantParams!['growthTimeMs'];
      final DateTime now = DateTime.now();
      final Duration elapsedTime = now.difference(plant.plantedTime);
      final int remainingTimeMs = (totalGrowthTimeMs -
              elapsedTime.inMilliseconds)
          .clamp(0, totalGrowthTimeMs);

      if (remainingTimeMs == 0) {
        return '即将成熟';
      }

      return _formatDuration(remainingTimeMs);
    }
    return plant.isHarvestable ? '已成熟' : '未知';
  }

  // 格式化持续时间
  String _formatDuration(int milliseconds) {
    final Duration duration = Duration(milliseconds: milliseconds);
    final int seconds = duration.inSeconds % 60;
    final int minutes = duration.inMinutes % 60;
    final int hours = duration.inHours;

    if (hours > 0) {
      return '$hours小时$minutes分钟';
    } else if (minutes > 0) {
      return '$minutes分钟$seconds秒';
    } else {
      return '$seconds秒';
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
