// game/inventory_page.dart
// 独立的背包页面组件

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_from_school/game/optimized_game_state.dart';
import 'package:escape_from_school/data/props.dart';

/// 背包页面组件
class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(optimizedGameStateProvider);
    final gameStateNotifier = ref.read(optimizedGameStateProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏 - 削弱高度
            _buildHeader(context, gameStateNotifier),
            
            // 主要内容区域 - 背包和角色面板并排显示
            Expanded(
              child: Row(
                children: [
                  // 左侧：角色面板
                  Expanded(
                    flex: 2,
                    child: _buildCharacterPanel(gameState),
                  ),
                  
                  // 分隔线
                  Container(
                    width: 1,
                    color: Colors.grey[700],
                  ),
                  
                  // 右侧：背包内容
                  Expanded(
                    flex: 3,
                    child: _buildInventoryContent(gameState),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部标题栏 - 削弱高度
  Widget _buildHeader(BuildContext context, OptimizedGameStateNotifier gameStateNotifier) {
    return Container(
      height: 60, // 从80减少到60
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // 减少垂直padding
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            onPressed: () {
              gameStateNotifier.closeInventory(); // 关闭背包返回游戏页面
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24, // 稍微减小图标
            ),
          ),
          const SizedBox(width: 12),
          
          // 标题
          const Text(
            '背包 & 角色',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20, // 从24减少到20
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const Spacer(),
          
          // 背包图标
          Container(
            padding: const EdgeInsets.all(6), // 减少padding
            decoration: BoxDecoration(
              color: Colors.brown[700],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.backpack,
              color: Colors.white,
              size: 20, // 减小图标
            ),
          ),
        ],
      ),
    );
  }

  /// 构建角色面板
  Widget _buildCharacterPanel(OptimizedGameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 角色面板标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade800,
                  Colors.blue.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '角色信息',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 角色详细信息
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 角色基本信息
                  _buildCharacterBasicInfo(gameState),
                  const SizedBox(height: 16),
                  // 角色属性
                  _buildCharacterStats(gameState),
                  const SizedBox(height: 16),
                  // 角色技能
                  _buildCharacterSkills(gameState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建角色基本信息
  Widget _buildCharacterBasicInfo(OptimizedGameState gameState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // 角色头像
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.blue.shade300, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                gameState.characterStats['image'] ?? 'images/man/cook.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 30),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // 角色名称
          Text(
            gameState.characterStats['name'] ?? '未知角色',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          
          // 角色描述
          Text(
            gameState.characterStats['description'] ?? '无描述',
            style: TextStyle(
              color: Colors.blue.shade200,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建角色属性
  Widget _buildCharacterStats(OptimizedGameState gameState) {
    final stats = gameState.characterStats;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '属性',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // 生命值
          _buildStatRow('生命值', '${stats['hp']?.toInt()}/${stats['maxHp']?.toInt()}', 
                       Icons.favorite, Colors.red),
          
          // 理智值
          _buildStatRow('理智值', '${stats['san']?.toInt()}/${stats['maxSan']?.toInt()}', 
                       Icons.psychology, Colors.blue),
          
          // 饱食度
          _buildStatRow('饱食度', '${stats['food']?.toInt()}', 
                       Icons.restaurant, Colors.green),
          
          // 金币
          _buildStatRow('金币', '${stats['gold']?.toInt()}', 
                       Icons.monetization_on, Colors.yellow),
        ],
      ),
    );
  }

  /// 构建属性行
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
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

  /// 构建角色技能
  Widget _buildCharacterSkills(OptimizedGameState gameState) {
    final skills = gameState.characterSkills;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '技能',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          if (skills.isEmpty)
            const Text(
              '暂无技能',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            )
          else
            ...skills.map((skill) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.purple, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      skill.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${skill.cooldownSeconds}s',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  /// 构建背包内容区域
  Widget _buildInventoryContent(OptimizedGameState gameState) {
    final inventory = gameState.playerInventory;
    
    if (inventory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '背包是空的',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 每行4个物品
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: inventory.length,
        itemBuilder: (context, index) {
          final item = inventory[index];
          return _buildInventoryItem(item);
        },
      ),
    );
  }

  /// 构建单个背包物品
  Widget _buildInventoryItem(Item item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[600]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 物品图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getItemColor(item.type),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getItemIcon(item.type),
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 物品名称
          Text(
            item.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // 数量（如果大于1）
          if (item.count > 1)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${item.count}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 根据物品类型获取颜色
  Color _getItemColor(String type) {
    switch (type) {
      case 'food':
        return Colors.green[700]!;
      case 'tool':
        return Colors.blue[700]!;
      case 'weapon':
        return Colors.red[700]!;
      case 'book':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  /// 根据物品类型获取图标
  IconData _getItemIcon(String type) {
    switch (type) {
      case 'food':
        return Icons.restaurant;
      case 'tool':
        return Icons.build;
      case 'weapon':
        return Icons.security;
      case 'book':
        return Icons.book;
      default:
        return Icons.inventory_2;
    }
  }
}