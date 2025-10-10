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
            // 顶部标题栏
            _buildHeader(context, gameStateNotifier),
            
            // 背包内容区域
            Expanded(
              child: _buildInventoryContent(gameState),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部标题栏
  Widget _buildHeader(BuildContext context, OptimizedGameStateNotifier gameStateNotifier) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              gameStateNotifier.toggleInventory(); // 返回游戏页面
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          
          // 标题
          const Text(
            '背包',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const Spacer(),
          
          // 背包图标
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.brown[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.backpack,
              color: Colors.white,
              size: 24,
            ),
          ),
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