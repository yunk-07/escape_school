// game/inventory_page.dart
// 背包页面组件 - 保持原布局，显示角色信息和背包物品，支持物品图片和确认框

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_from_school/game/optimized_game_state.dart';
import 'package:escape_from_school/data/props.dart';

/// 背包页面组件 - 原布局风格
class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(optimizedGameStateProvider);
    
    return Positioned.fill(
      child: Container(
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
              borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text(
                '角色信息 & 背包',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 16),
              iconSize: 16,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                final notifier = ref.read(optimizedGameStateProvider.notifier);
                notifier.toggleInventory();
              },
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '属性详情',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 生命值 - 只显示后两位数
          _buildStatRow('生命值', '${_formatToTwoDigits(stats['hp'])}/${_formatToTwoDigits(stats['maxHp'])}', 
                       Icons.favorite, Colors.red),
          
          // 理智值 - 只显示后两位数
          _buildStatRow('理智值', '${_formatToTwoDigits(stats['san'])}/${_formatToTwoDigits(stats['maxSan'])}', 
                       Icons.psychology, Colors.blue),
          
          // 饱食度 - 只显示后两位数
          _buildStatRow('饱食度', '${_formatToTwoDigits(stats['food'])}', 
                       Icons.restaurant, Colors.green),
          
          // 金币 - 只显示后两位数
          _buildStatRow('金币', '${_formatToTwoDigits(stats['gold'])}', 
                       Icons.monetization_on, Colors.yellow),
          
          // 移动速度 - 只显示后两位数
          _buildStatRow('移动速度', '${_formatToTwoDigits(stats['moveSpeed']?.toInt() ?? 100)}', 
                       Icons.directions_run, Colors.orange),
        ],
      ),
    );
  }

  /// 构建单个属性行
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建背包物品面板
  Widget _buildInventoryPanel(OptimizedGameState gameState, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 背包标题
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(
                '背包物品',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${gameState.playerInventory.length} 件物品',
                style: TextStyle(
                  color: Colors.blue.shade300,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 背包物品网格
          Expanded(
            child: gameState.playerInventory.isEmpty
                ? _buildEmptyInventory()
                : _buildInventoryGrid(gameState, ref),
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
              borderRadius: BorderRadius.circular(50),
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
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.9,
      ),
      itemCount: gameState.playerInventory.length,
      itemBuilder: (context, index) {
        final item = gameState.playerInventory[index];
        return _buildInventoryItem(item, ref, context);
      },
    );
  }

  /// 构建单个背包物品
  Widget _buildInventoryItem(Item item, WidgetRef ref, BuildContext context) {
    return GestureDetector(
      onTap: () => _showUseItemDialog(context, item, item.count, ref),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getItemTypeColor(item.type).withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _getItemTypeColor(item.type).withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 物品图片
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(4),
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
            ),
            
            // 物品名称
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            // 数量显示
            if (item.count > 1)
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getItemTypeColor(item.type),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'x${item.count}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
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
            borderRadius: BorderRadius.circular(16),
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
        return '金币';
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
      default:
        return Icons.help;
    }
  }

  /// 格式化数值为后两位数显示
  String _formatToTwoDigits(dynamic value) {
    if (value == null) return '00';
    
    int intValue;
    if (value is double) {
      intValue = value.round();
    } else if (value is int) {
      intValue = value;
    } else {
      intValue = 0;
    }
    
    // 只显示后两位数
    return (intValue % 100).toString().padLeft(2, '0');
  }
}