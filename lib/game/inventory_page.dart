// game/inventory_page.dart
// 背包页面组件 - 保持原布局，显示角色信息和背包物品，支持物品图片和确认框

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_from_school/game/optimized_game_state.dart';
import 'package:escape_from_school/data/props.dart';
import 'package:escape_from_school/game/music.dart';

/// 背包页面组件 - 原布局风格
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  // 拖拽状态管理
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(optimizedGameStateProvider);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.shade400.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 15,
                spreadRadius: 3,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // 标题栏
              _buildHeader(context, ref),
              // 主要内容区域
              Expanded(
                child: Row(
                  children: [
                    // 左侧：角色信息面板
                    Expanded(
                      flex: 2,
                      child: _buildCharacterInfoPanel(gameState),
                    ),
                    // 分隔线
                    Container(
                      width: 1,
                      color: Colors.blue.shade400.withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    // 右侧：背包物品区域
                    Expanded(
                      flex: 3,
                      child: _buildInventoryPanel(gameState, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade700,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧：健康模块 (对应下方角色信息面板 flex: 2)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.withOpacity(0.4), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Colors.green.shade300, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '健康',
                    style: TextStyle(
                      color: Colors.green.shade100,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 分隔线 (对应下方的分隔线)
          Container(
            width: 1,
            height: 20,
            color: Colors.blue.shade400.withOpacity(0.3),
          ),
          
          // 右侧：背包模块和退出按钮 (对应下方背包物品区域 flex: 3)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // 背包标题
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, color: Colors.amber.shade300, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '背包',
                          style: TextStyle(
                            color: Colors.amber.shade100,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                
                // 退出按钮
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.shade600,
                        Colors.red.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade400.withOpacity(0.6), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        final notifier = ref.read(optimizedGameStateProvider.notifier);
                        notifier.toggleInventory();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              '退出',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建角色信息面板
  Widget _buildCharacterInfoPanel(OptimizedGameState gameState) {
    final stats = gameState.characterStats;
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 只显示角色属性，移除头像和名字
            _buildCharacterStats(stats),
          ],
        ),
      ),
    );
  }



  /// 构建角色属性统计
  Widget _buildCharacterStats(Map<String, dynamic> stats) {
    // 计算最近鬼距离并映射为接近度因子（0-1）
    final gameState = ref.watch(optimizedGameStateProvider);
    final playerGrid = gameState.playerPosition.toPoint();
    double minGhostDistance = double.infinity;
    for (final ghost in gameState.ghostManager.ghosts) {
      if (ghost.position != null && !ghost.isInvisible) {
        final gp = ghost.position!.toPoint();
        final dx = (playerGrid.x - gp.x).toDouble();
        final dy = (playerGrid.y - gp.y).toDouble();
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < minGhostDistance) minGhostDistance = d;
      }
    }
    const double dangerRange = 25.0; // 在25格内开始显著影响心跳
    final double proximityFactor = minGhostDistance.isFinite
        ? ((dangerRange - minGhostDistance) / dangerRange).clamp(0.0, 1.0)
        : 0.0;
    // 背包打开时也根据接近度触发/更新心跳音效
    MusicManager().updateHeartbeat(proximityFactor);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 属性详情标题和心电图
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '属性详情',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 动态心电图组件
              ECGWidget(
                width: 100,
                height: 50,
                healthPercentage: _calculateHealthPercentage(stats),
                stressLevel: _calculateStressLevel(stats),
                proximityFactor: proximityFactor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 生命值 - 显示小数点后两位
          _buildStatRow('生命值', '${_formatToTwoDigits(stats['hp'])}/${_formatToTwoDigits(stats['maxHp'])}', 
                       Icons.favorite, Colors.red),
          
          // 理智值 - 显示小数点后两位
          _buildStatRow('理智值', '${_formatToTwoDigits(stats['san'])}/${_formatToTwoDigits(stats['maxSan'])}', 
                       Icons.psychology, Colors.blue),
          
          // 饱食度 - 显示小数点后两位
          _buildStatRow('饱食度', '${_formatToTwoDigits(stats['food'])}', 
                       Icons.restaurant, Colors.green),
          
          // 肺活量（氧气值）
          _buildOxygenStatRow(),
          
          // 金币 - 显示小数点后两位
          _buildStatRow('金币', '${_formatToTwoDigits(stats['gold'])}', 
                       Icons.monetization_on, Colors.yellow),
          
          // 移动速度 - 显示小数点后两位
          _buildStatRow('移动速度', '${_formatToTwoDigits(stats['moveSpeed']?.toInt() ?? 100)}', 
                       Icons.directions_run, Colors.orange),
        ],
      ),
    );
  }

  /// 构建单个属性行
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建氧气值（肺活量）属性行
  Widget _buildOxygenStatRow() {
    return Consumer(
      builder: (context, WidgetRef ref, child) {
        final gameState = ref.watch(optimizedGameStateProvider);
        final currentOxygen = gameState.currentOxygen;
        final maxOxygen = gameState.actualMaxOxygen;
        
        return _buildStatRow(
          '肺活量', 
          '${_formatToTwoDigits(maxOxygen)}',
          Icons.air,
          Colors.cyan,
        );
      },
    );
  }

  /// 构建背包物品面板
  Widget _buildInventoryPanel(OptimizedGameState gameState, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 背包物品网格
          Expanded(
            flex: 4,
            child: _buildInventoryGrid(gameState, ref),
          ),
          
          const SizedBox(height: 12),
          
          // 垃圾桶拖拽区域 - 只在拖拽时显示
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isDragging ? 60 : 0,
            child: _isDragging ? _buildTrashCanArea(ref) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// 构建空背包提示
  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade700.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade500.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '背包是空的',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '去探索世界寻找物品吧！',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建背包物品网格
  Widget _buildInventoryGrid(OptimizedGameState gameState, WidgetRef ref) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10, // 10列布局
        crossAxisSpacing: 4, // 统一边距
        mainAxisSpacing: 4,  // 统一边距
        childAspectRatio: 1.0, // 正方形比例
      ),
      itemCount: gameState.inventoryCapacity, // 固定显示背包容量数量的格子
      itemBuilder: (context, index) {
        // 如果索引小于实际物品数量，显示物品；否则显示空格子
        if (index < gameState.playerInventory.length) {
          final item = gameState.playerInventory[index];
          return _buildInventoryItem(item, ref, context);
        } else {
          return _buildEmptySlot(index, ref);
        }
      },
    );
  }

  /// 构建背包物品
  Widget _buildInventoryItem(Item item, WidgetRef ref, BuildContext context) {
    return DragTarget<Item>(
      onAccept: (Item draggedItem) {
        // 交换物品位置
        final notifier = ref.read(optimizedGameStateProvider.notifier);
        final inventory = ref.read(optimizedGameStateProvider).playerInventory;
        final fromIndex = inventory.indexWhere((i) => i.id == draggedItem.id);
        final toIndex = inventory.indexWhere((i) => i.id == item.id);
        if (fromIndex != -1 && toIndex != -1 && fromIndex != toIndex) {
          notifier.moveItemInInventory(fromIndex, toIndex);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;
        
        return Container(
          decoration: isHovering ? BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.yellow.withOpacity(0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ) : null,
          child: LongPressDraggable<Item>(
            data: item,
            onDragStarted: () {
              setState(() {
                _isDragging = true;
              });
            },
            onDragEnd: (details) {
              setState(() {
                _isDragging = false;
              });
            },
            onDraggableCanceled: (velocity, offset) {
              setState(() {
                _isDragging = false;
              });
            },
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 40, // 缩小拖拽反馈尺寸适应10列布局
                height: 40,
                decoration: BoxDecoration(
                  color: _getItemLevelColor(item.level).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getItemLevelColor(item.level),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getItemLevelColor(item.level).withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 物品图片 - 占据整个容器
                    Positioned.fill(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: item.image.isNotEmpty
                            ? Image.asset(
                                item.image,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    _getItemTypeIcon(item.type),
                                    color: Colors.white,
                                    size: 12, // 缩小图标尺寸适应10列布局
                                  );
                                },
                              )
                            : Icon(
                                _getItemTypeIcon(item.type),
                                color: Colors.white,
                                size: 12, // 缩小图标尺寸适应10列布局
                              ),
                      ),
                    ),
                    
                    // 物品名称 - 左上角重叠显示
                     Positioned(
                       top: 1,
                       left: 1,
                       right: 8, // 为可能的数量显示留出空间
                       child: Text(
                         item.name,
                         style: const TextStyle(
                           color: Colors.white,
                           fontSize: 6, // 缩小文字尺寸适应10列布局
                           fontWeight: FontWeight.w500,
                           shadows: [
                             Shadow(
                               offset: Offset(0.3, 0.3),
                               blurRadius: 0.5,
                               color: Colors.black,
                             ),
                           ],
                         ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                  ],
                ),
              ),
            ),
            childWhenDragging: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.drag_indicator,
                  color: Colors.grey,
                  size: 24,
                ),
              ),
            ),
            child: GestureDetector(
              onTap: () => _showUseItemDialog(context, item, item.count, ref),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _getItemLevelColor(item.level).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getItemLevelColor(item.level),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getItemLevelColor(item.level).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // 物品图片 - 占据整个容器
                        Positioned.fill(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: item.image.isNotEmpty
                                ? Image.asset(
                                    item.image,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        _getItemTypeIcon(item.type),
                                        color: Colors.white,
                                        size: 20,
                                      );
                                    },
                                  )
                                : Icon(
                                    _getItemTypeIcon(item.type),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                        
                        // 物品名称 - 左上角重叠显示
                        Positioned(
                          top: 2,
                          left: 2,
                          right: 20, // 为右上角数量显示留出空间
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  offset: Offset(0.5, 0.5),
                                  blurRadius: 1.0,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 数量显示 - 右上角
                  if (item.count > 1)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getItemLevelColor(item.level),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '${item.count}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建空的背包格子
  Widget _buildEmptySlot(int index, WidgetRef ref) {
    return DragTarget<Item>(
      onAccept: (Item item) {
        // 移动物品到这个空位置
        final notifier = ref.read(optimizedGameStateProvider.notifier);
        final inventory = ref.read(optimizedGameStateProvider).playerInventory;
        final fromIndex = inventory.indexWhere((i) => i.id == item.id);
        if (fromIndex != -1) {
          notifier.moveItemInInventory(fromIndex, index);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;
        
        return Container(
          decoration: BoxDecoration(
            color: isHovering 
                ? Colors.blue.withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isHovering 
                  ? Colors.blue.withOpacity(0.6)
                  : Colors.grey.withOpacity(0.3),
              width: isHovering ? 2 : 1,
            ),
          ),
          // 简洁风格，不显示任何图标
        );
      },
    );
  }

  /// 显示使用物品确认对话框
  void _showUseItemDialog(BuildContext context, Item item, int quantity, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: _getItemTypeColor(item.type).withOpacity(0.5)),
          ),
          title: Row(
            children: [
              // 物品图片
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getItemTypeColor(item.type).withOpacity(0.3)),
                ),
                child: item.image.isNotEmpty
                    ? Image.asset(
                        item.image,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            _getItemTypeIcon(item.type),
                            color: _getItemTypeColor(item.type),
                            size: 24,
                          );
                        },
                      )
                    : Icon(
                        _getItemTypeIcon(item.type),
                        color: _getItemTypeColor(item.type),
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '数量: $quantity',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 物品描述
              Text(
                item.description,
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              
              // 物品效果
              if (item.effects.isNotEmpty) ...[
                const Text(
                  '使用效果:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...item.effects.entries.map((effect) {
                  final effectName = _getEffectName(effect.key);
                  final effectValue = effect.value;
                  final isPositive = effectValue > 0;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          _getEffectIcon(effect.key),
                          color: isPositive ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$effectName: ${isPositive ? '+' : ''}$effectValue',
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _dropItem(item, ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('丢弃'),
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _useItem(item, ref);
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getItemTypeColor(item.type),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('使用'),
            ),
          ],
        );
      },
    );
  }

  /// 使用物品
  void _useItem(Item item, WidgetRef ref) {
    final notifier = ref.read(optimizedGameStateProvider.notifier);
    notifier.useItem(item);
  }

  /// 丢弃物品
  void _dropItem(Item item, WidgetRef ref) {
    final notifier = ref.read(optimizedGameStateProvider.notifier);
    notifier.dropItemFromInventory(item);
  }

  /// 构建垃圾桶拖拽区域
  Widget _buildTrashCanArea(WidgetRef ref) {
    return DragTarget<Item>(
      onAccept: (Item item) {
        // 拖拽物品到垃圾桶时丢弃物品
        _dropItem(item, ref);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 60,
          decoration: BoxDecoration(
            color: isHovering 
                ? Colors.red.shade600.withOpacity(0.8)
                : Colors.grey.shade800.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
               color: isHovering 
                   ? Colors.red.shade400
                   : Colors.grey.shade600,
               width: 2,
             ),
            boxShadow: isHovering ? [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline,
                color: isHovering ? Colors.white : Colors.grey.shade400,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isHovering ? '松开以丢弃物品' : '拖拽物品到此处丢弃',
                style: TextStyle(
                  color: isHovering ? Colors.white : Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 获取物品等级颜色
  Color _getItemLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.grey.shade600; // 无色
      case 2:
        return Colors.green.shade400; // 绿色
      case 3:
        return Colors.blue.shade400; // 蓝色
      case 4:
        return Colors.purple.shade400; // 紫色
      case 5:
        return Colors.amber.shade400; // 金色
      case 6:
        return Colors.orange.shade400; // 橙色
      case 7:
        return Colors.red.shade400; // 红色
      default:
        return Colors.grey.shade600; // 默认无色
    }
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

  /// 获取物品类型图标
  IconData _getItemTypeIcon(String type) {
    switch (type) {
      case 'potion':
        return Icons.local_pharmacy;
      case 'food':
        return Icons.restaurant;
      case 'tool':
        return Icons.build;
      case 'weapon':
        return Icons.security;
      default:
        return Icons.inventory_2;
    }
  }

  /// 获取效果名称
  String _getEffectName(String effectKey) {
    switch (effectKey) {
      case 'hp':
        return '生命值';
      case 'san':
        return '理智值';
      case 'food':
        return '饱食度';
      case 'moveSpeed':
        return '移动速度';
      case 'gold':
        return '资产';
      case 'oxygenBonus':
        return '肺活量';
      default:
        return effectKey;
    }
  }

  /// 获取效果图标
  IconData _getEffectIcon(String effectKey) {
    switch (effectKey) {
      case 'hp':
        return Icons.favorite;
      case 'san':
        return Icons.psychology;
      case 'food':
        return Icons.restaurant;
      case 'moveSpeed':
        return Icons.directions_run;
      case 'gold':
        return Icons.monetization_on;
      case 'oxygenBonus':
        return Icons.air;
      default:
        return Icons.help;
    }
  }

  /// 格式化数值为小数点后两位显示
  String _formatToTwoDigits(dynamic value) {
    if (value == null) return '0.00';
    
    double doubleValue;
    if (value is double) {
      doubleValue = value;
    } else if (value is int) {
      doubleValue = value.toDouble();
    } else {
      doubleValue = 0.0;
    }
    
    // 显示小数点后两位
    return doubleValue.toStringAsFixed(2);
  }

  /// 计算健康百分比（基于生命值和理智值）
  double _calculateHealthPercentage(Map<String, dynamic> stats) {
    final hp = stats['hp'] ?? 0.0;
    final maxHp = stats['maxHp'] ?? 100.0;
    final san = stats['san'] ?? 0.0;
    final maxSan = stats['maxSan'] ?? 100.0;
    
    // 综合生命值和理智值计算健康百分比
    final hpPercentage = maxHp > 0 ? hp / maxHp : 0.0;
    final sanPercentage = maxSan > 0 ? san / maxSan : 0.0;
    
    // 取两者的平均值作为整体健康状况
    return ((hpPercentage + sanPercentage) / 2).clamp(0.0, 1.0);
  }

  /// 计算压力水平（基于饱食度和氧气值）
  double _calculateStressLevel(Map<String, dynamic> stats) {
    final food = stats['food'] ?? 100.0;
    final oxygen = stats['oxygen'] ?? 100.0;
    final maxOxygen = stats['maxOxygen'] ?? 100.0;
    
    // 饱食度越低，压力越大
    final foodStress = food < 50 ? (50 - food) / 50 : 0.0;
    
    // 氧气值越低，压力越大
    final oxygenPercentage = maxOxygen > 0 ? oxygen / maxOxygen : 1.0;
    final oxygenStress = oxygenPercentage < 0.5 ? (0.5 - oxygenPercentage) / 0.5 : 0.0;
    
    // 取较高的压力值
    return math.max(foodStress, oxygenStress).clamp(0.0, 1.0);
  }
}

/// 动态心电图组件
class ECGWidget extends StatefulWidget {
  final double width;
  final double height;
  final double healthPercentage; // 健康百分比 (0.0 - 1.0)
  final double stressLevel; // 压力水平 (0.0 - 1.0)
  final double proximityFactor; // 鬼接近度 (0.0 - 1.0)

  const ECGWidget({
    Key? key,
    this.width = 120,
    this.height = 60,
    required this.healthPercentage,
    required this.stressLevel,
    this.proximityFactor = 0.0,
  }) : super(key: key);

  @override
  State<ECGWidget> createState() => _ECGWidgetState();
}

class _ECGWidgetState extends State<ECGWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<double> _ecgPoints = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _generateECGPoints();
    
    // 根据健康状态调整动画速度
    final duration = _getAnimationDuration();
    _animationController = AnimationController(
      duration: duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    
    _animationController.addListener(() {
      setState(() {
        _currentIndex = (_animation.value * (_ecgPoints.length - 1)).round();
      });
    });
    
    _animationController.repeat();
  }

  @override
  void didUpdateWidget(ECGWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.healthPercentage != widget.healthPercentage ||
        oldWidget.stressLevel != widget.stressLevel ||
        oldWidget.proximityFactor != widget.proximityFactor) {
      _generateECGPoints();
      
      // 更新动画速度
      final newDuration = _getAnimationDuration();
      if (_animationController.duration != newDuration) {
        _animationController.duration = newDuration;
      }
    }
  }

  Duration _getAnimationDuration() {
    // 新模式：心率主要由鬼接近度驱动（越近越快）
    const int baseSpeed = 2000; // ms，远离鬼时的速度
    const int minSpeed = 800;   // ms，鬼靠近时的最快速度
    final double p = widget.proximityFactor.clamp(0.0, 1.0);
    final int speed = (baseSpeed - (baseSpeed - minSpeed) * p).round();
    return Duration(milliseconds: speed);
  }

  void _generateECGPoints() {
    _ecgPoints.clear();
    final pointCount = 50;
    
    for (int i = 0; i < pointCount; i++) {
      double point = 0.5; // 基线
      
      // 生成心电图波形
      if (i % 15 == 5) { // P波
        point += 0.1 * widget.healthPercentage;
      } else if (i % 15 == 8) { // Q波
        point -= 0.05 * widget.healthPercentage;
      } else if (i % 15 == 9) { // R波（主峰）
        point += 0.4 * widget.healthPercentage;
      } else if (i % 15 == 10) { // S波
        point -= 0.1 * widget.healthPercentage;
      } else if (i % 15 == 12) { // T波
        point += 0.15 * widget.healthPercentage;
      }
      
      // 新模式抖动：以鬼接近度为主，压力为辅
      final double jitterBase = widget.proximityFactor * 0.15;
      final double jitterStress = widget.stressLevel * 0.05;
      final noise = (math.Random().nextDouble() - 0.5) * (jitterBase + jitterStress);
      point += noise;
      
      // 确保点在合理范围内
      point = point.clamp(0.0, 1.0);
      _ecgPoints.add(point);
    }
  }

  Color _getECGColor() {
    // 新模式：颜色主要由鬼接近度决定（越近越偏红）
    final p = widget.proximityFactor.clamp(0.0, 1.0);
    if (p < 0.33) return Colors.green;
    if (p < 0.66) return Colors.yellow;
    if (p < 0.85) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getECGColor().withOpacity(0.5),
          width: 1,
        ),
      ),
      child: CustomPaint(
        painter: ECGPainter(
          points: _ecgPoints,
          currentIndex: _currentIndex,
          color: _getECGColor(),
        ),
        size: Size(widget.width, widget.height),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// 心电图绘制器
class ECGPainter extends CustomPainter {
  final List<double> points;
  final int currentIndex;
  final Color color;

  ECGPainter({
    required this.points,
    required this.currentIndex,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fadePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final fadePath = Path();

    // 绘制心电图线条
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - (points[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fadePath.moveTo(x, y);
      } else {
        if (i <= currentIndex) {
          path.lineTo(x, y);
        } else {
          fadePath.lineTo(x, y);
        }
      }
    }

    // 绘制已经过的部分（亮色）
    canvas.drawPath(path, paint);
    
    // 绘制未到达的部分（暗色）
    canvas.drawPath(fadePath, fadePaint);

    // 绘制当前位置的脉冲点
    if (currentIndex < points.length) {
      final currentX = (currentIndex / (points.length - 1)) * size.width;
      final currentY = size.height - (points[currentIndex] * size.height);
      
      final pulsePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(currentX, currentY), 3.0, pulsePaint);
    }

    // 绘制网格线
    final gridPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // 水平网格线
    for (int i = 1; i < 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 垂直网格线
    for (int i = 1; i < 6; i++) {
      final x = (i / 6) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}