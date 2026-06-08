// game/plant_widget.dart
// 植物显示组件：显示地图上的植物及其生长状态
//
// 主要类和组件：
//
// 1. PlantWidget - 地图上的植物显示组件
//    用法：PlantWidget(plant: plant, opacity: 1.0)
//    功能：显示植物的视觉效果、生长状态、进度条和交互提示
//
// 2. PlantDetailDialog - 植物详情对话框
//    用法：showDialog(context: context, builder: (_) => PlantDetailDialog(plantId: plant.id))
//    功能：显示植物详细信息和操作按钮（浇水、采摘、挖除）
//
// =============================================================================
// 使用方法总览
// =============================================================================
//
// 获取和显示植物组件：
//   final plant = ...; // 从种植系统获取植物对象
//   PlantWidget(plant: plant, opacity: 1.0)
//
// 显示植物详情对话框：
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return PlantDetailDialog(plantId: plant.id);
//     },
//   );
//
// =============================================================================
// 核心类和组件详细说明
// =============================================================================
//
// PlantWidget 类（植物显示组件）
//   用途：在地图上显示单个植物的视觉效果和状态
//   内部键：
//   - plant: Plant对象，必填参数
//         包含植物的完整信息：id、itemId、position、stage、growthProgress等
//         用于确定显示的图片、进度条和交互行为
//   - opacity: double?类型，可选参数，默认为1.0
//         控制植物显示的透明度，用于实现渐隐等视觉效果
//
// PlantDetailDialog 类（植物详情对话框）
//   用途：显示植物详细信息并提供操作按钮
//   内部键：
//   - plantId: String类型，必填参数
//         植物的唯一标识符，格式为"plant_${毫秒时间戳}"
//         用于从种植系统状态中查找对应的植物对象
//         注意：此ID应在对话框显示前确保植物仍然存在
//
// =============================================================================
// 核心方法详细说明
// =============================================================================
//
// 1. PlantWidget.build() - 构建植物显示组件
//    使用方法：自动调用
//    内部键的作用：
//      - context: BuildContext对象，用于获取依赖和资源
//      - ref: WidgetRef对象，用于监听状态变化
//    功能说明：
//      1. 根据plant.itemId查找对应的Item对象
//      2. 从item.plantParams中获取当前生长阶段的图片
//      3. 创建植物图片容器，应用阴影和圆角效果
//      4. 在容器上方叠加生长进度条
//      5. 设置点击事件处理
//    注意事项：
//      - 植物图片会根据生长阶段自动切换
//      - 透明度效果会影响整个组件
//
// 2. PlantWidget._onPlantTap() - 植物点击事件处理
//    使用方法：点击植物时自动触发
//    内部键的作用：
//      - context: BuildContext对象，用于显示对话框
//      - ref: WidgetRef对象，可用于访问状态
//      - plant: Plant对象，包含被点击植物的信息
//    功能说明：
//      1. 调用showDialog显示PlantDetailDialog
//      2. 传递plant.id作为plantId参数
//      3. 对话框会根据plantId查找最新植物状态
//    注意事项：
//      - 确保在植物存在时调用
//      - 对话框显示前植物可能被移除（需要异常处理）
//
// 3. PlantDetailDialog.build() - 构建详情对话框UI
//    使用方法：对话框显示时自动调用
//    内部键的作用：
//      - context: BuildContext对象
//      - ref: WidgetRef对象，用于监听种植系统状态
//    功能说明：
//      1. 监听plantingSystemProvider获取最新植物列表
//      2. 根据plantId查找对应的Plant对象
//      3. 根据plant.itemId查找对应的Item对象
//      4. 构建包含植物信息、操作按钮的对话框内容
//    异常处理：
//      - 如果植物不存在，抛出Exception并显示错误
//      - 建议在调用前确保植物存在
//
// 4. PlantDetailDialog._waterPlant() - 浇水操作
//    使用方法：点击浇水按钮时触发
//    内部键的作用：
//      - context: BuildContext对象，用于获取ToplevelContext
//      - ref: WidgetRef对象，用于访问种植系统notifier
//    功能说明：
//      1. 调用plantingSystemProvider.notifier.waterPlant(plantId)
//      2. 更新植物的最后浇水时间和缺水状态
//      3. 立即更新植物生长状态
//      4. 保存数据到本地存储
//    注意事项：
//      - 浇水后植物恢复正常生长速度
//      - 效果会立即反映在UI中
//
// 5. PlantDetailDialog._harvestPlant() - 采摘操作
//    使用方法：点击采摘按钮时触发（需要植物已成熟）
//    内部键的作用：
//      - context: BuildContext对象
//      - ref: WidgetRef对象，用于访问状态和调用notifier
//    功能说明：
//      1. 检查植物是否可采摘（isHarvestable = true）
//      2. 调用harvestPlant方法执行采摘
//      3. 生成收获物品并添加到背包
//      4. 重置植物为初始状态继续生长
//      5. 关闭对话框
//    注意事项：
//      - 只有成熟植物可采摘
//      - 采摘后植物不会立即消失，而是重置
//
// 6. PlantDetailDialog._removePlant() - 挖除操作
//    使用方法：点击挖除按钮时触发
//    内部键的作用：
//      - context: BuildContext对象
//      - ref: WidgetRef对象，用于调用notifier
//    功能说明：
//      1. 调用removePlant方法移除植物
//      2. 从植物列表中删除该植物
//      3. 保存数据到本地存储
//      4. 关闭对话框
//    注意事项：
//      - 挖除操作不可逆
//      - 植物被完全移除，无法恢复
//
// =============================================================================
// 辅助方法说明
// =============================================================================
//
// 1. _getCurrentStageImage() - 获取当前阶段图片路径
//    功能：根据植物当前生长阶段返回对应的图片资源路径
//    内部键：
//      - item: Item对象，包含plantParams配置
//      - plant: Plant对象，包含currentStage索引
//    阶段索引对应关系：
//      - 0: 种子阶段（seed）
//      - 1: 生长阶段（growing）
//      - 2: 成熟阶段（mature）
//
// 2. _getGrowthStageText() - 获取生长阶段中文文本
//    功能：将PlantStage枚举值转换为可读的中文描述
//    枚举值对应：
//      - seed → "种子"
//      - growing → "生长中"
//      - mature → "成熟"
//
// 3. _formatTime() - 格式化时间显示
//    功能：将DateTime对象转换为友好格式的时间字符串
//    输出示例："2024/01/15 14:30"
//
// 4. _formatDuration() - 格式化时间间隔
//    功能：将Duration对象转换为友好的时间间隔描述
//    输出示例："2小时30分钟"
//
// 5. _getProgressColor() - 获取进度条颜色
//    功能：根据生长进度返回对应的颜色值
//    颜色映射：
//      - 0.0-0.3: 红色（初始阶段）
//      - 0.3-0.6: 橙色（早期生长）
//      - 0.6-0.9: 黄色（接近成熟）
//      - 0.9-1.0: 绿色（完全成熟）
//
// =============================================================================
// 使用示例
// =============================================================================
//
// 例1：在地图上显示植物
//   // 从种植系统获取植物列表
//   final plantingState = ref.watch(plantingSystemProvider);
//   for (var plant in plantingState.plants) {
//     PlantWidget(plant: plant);
//   }
//
// 例2：显示植物详情
//   void _showPlantDetails(BuildContext context, Plant plant) {
//     showDialog(
//       context: context,
//       builder: (context) => PlantDetailDialog(plantId: plant.id),
//     );
//   }
//
// 例3：处理植物交互
//   GestureDetector(
//     onTap: () => _showPlantDetails(context, plant),
//     child: PlantWidget(plant: plant),
//   )
//
// =============================================================================
// 注意事项
// =============================================================================
//
// 1. 植物ID唯一性：
//    - 植物ID格式为"plant_${毫秒时间戳}"
//    - 确保在操作前植物仍然存在于种植系统中
//    - 采摘后植物会重置但ID不变
//
// 2. 状态同步：
//    - PlantDetailDialog通过ref.watch实时获取最新状态
//    - 植物状态变化会自动反映在UI中
//    - 但对话框显示前植物可能被移除
//
// 3. 异常处理：
//    - 如果植物不存在会抛出Exception
//    - 建议在调用前验证植物存在性
//    - 可考虑使用try-catch包装对话框显示
//
// 4. 资源管理：
//    - 图片资源通过AssetImage加载
//    - 确保图片路径正确且资源存在
//    - 图片大小为40x40像素
//
// 5. 性能考虑：
//    - 使用ref.watch监听状态变化
//    - 避免在不必要时重建整个组件
//    - 进度条使用FractionallySizedBox实现
//
// =============================================================================
// 已知问题
// =============================================================================
//
// 1. 对话框显示时的植物存在性：
//    - 问题：植物可能在对话框构建前被移除
//    - 影响：抛出Exception: 植物不存在
//    - 解决方案：确保调用时植物存在，或添加异常处理
//
// 2. 植物ID格式验证：
//    - 问题：如果传入无效的plantId会抛出异常
//    - 影响：对话框无法正常显示
//    - 解决方案：验证plantId格式是否正确
//
// =============================================================================

import 'package:escape_from_school/game/optimized_game_state.dart';
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
    // 注意：传递plantId而不是plant快照，确保获取最新状态
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlantDetailDialog(plantId: plant.id);
      },
    );
  }
}

class PlantDetailDialog extends ConsumerWidget {
  final String plantId;

  const PlantDetailDialog({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从种植系统获取最新植物状态，而不是使用过时的快照
    final plantingState = ref.watch(plantingSystemProvider);
    
    // 查找植物，如果不存在则返回空对话框
    final plantIndex = plantingState.plants.indexWhere((p) => p.id == plantId);
    if (plantIndex == -1) {
      // 植物已被移除，关闭对话框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }
    
    final plant = plantingState.plants[plantIndex];
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
      // 从种植系统获取最新植物状态
      final plantingState = ref.watch(plantingSystemProvider);
      final plant = plantingState.plants.firstWhere(
        (p) => p.id == plantId,
        orElse: () => throw Exception('植物不存在'),
      );
      print('_waterPlant方法被调用 - plantId: $plantId');
      
      // 调用种植系统的浇水方法
      final plantingSystemNotifier = ref.read(plantingSystemProvider.notifier);
      print('准备调用waterPlantWithBonus');
      final success = plantingSystemNotifier.waterPlantWithBonus(plant.id);
      print('waterPlantWithBonus返回结果: $success');

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
      print('浇水方法发生异常: $e');
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
      // 从种植系统获取最新植物状态
      final plantingState = ref.watch(plantingSystemProvider);
      final plant = plantingState.plants.firstWhere(
        (p) => p.id == plantId,
        orElse: () => throw Exception('植物不存在'),
      );
      
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
      // 从种植系统获取最新植物状态
      final plantingState = ref.watch(plantingSystemProvider);
      final plant = plantingState.plants.firstWhere(
        (p) => p.id == plantId,
        orElse: () => throw Exception('植物不存在'),
      );
      print('_removePlant方法被调用 - plantId: $plantId');
      
      // 调用种植系统的挖除方法
      final plantingSystemNotifier = ref.read(plantingSystemProvider.notifier);
      print('准备调用removePlant');
      final success = plantingSystemNotifier.removePlant(plant.id);
      print('removePlant返回结果: $success');

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
      print('挖除方法发生异常: $e');
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
