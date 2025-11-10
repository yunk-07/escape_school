// game/chest_search_overlay.dart
// 新文件作用：宝箱搜索页面的叠加层UI，左侧为玩家背包，右侧为宝箱内容；
// 支持拖拽或点击将宝箱物品放入背包，关闭后未转移物品掉落到地上。
// 关键区域：逐个搜索动画——仅对“当前待揭示的首个物品”显示旋转搜索图标覆盖，其余待揭示显示蒙版。

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'optimized_game_state.dart';
import 'package:escape_from_school/data/props.dart';

class ChestSearchOverlay extends ConsumerStatefulWidget {
  const ChestSearchOverlay({Key? key}) : super(key: key);

  @override
  ConsumerState<ChestSearchOverlay> createState() => _ChestSearchOverlayState();
}

class _ChestSearchOverlayState extends ConsumerState<ChestSearchOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    // 关键区域：旋转控制器——持续旋转，用于“当前搜索中的物品”覆盖图标
    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(optimizedGameStateProvider);
    final notifier = ref.read(optimizedGameStateProvider.notifier);

    // 未打开搜索页面则不显示
    if (!gameState.isChestSearchOpen) {
      return const SizedBox.shrink();
    }

    // 关键区域：整页叠加层，拦截交互
    return Positioned.fill(
      child: Container(
        // 关键区域：整页叠加层采用径向渐变，增强空间感与层次
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.black.withOpacity(0.85),
              Colors.black.withOpacity(0.70),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 顶部：标题与关闭按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.search, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '宝箱搜索',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        notifier.closeChestSearch();
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('关闭', style: TextStyle(color: Colors.white)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 主体：左右两栏
                Expanded(
                  child: Row(
                    children: [
                      // 左侧：玩家背包
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            // 美化：左侧面板采用柔和渐变背景 + 阴影，增强立体感
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blueGrey.shade900.withOpacity(0.87),
                                Colors.blueGrey.shade800.withOpacity(0.76),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blueGrey.shade400.withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 6)),
                              BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 6, offset: const Offset(-1, -1)),
                            ],
                          ),
                          // 关键区域：面板前景高光（与背包页面一致），增强质感
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.06),
                                Colors.transparent,
                                Colors.white.withOpacity(0.02),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _panelHeader('玩家背包', Icons.inventory_2, Colors.cyan),
                              const Divider(height: 1, color: Colors.white24),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: _buildInventoryGrid(gameState, notifier),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 右侧：宝箱内容
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            // 美化：右侧面板采用柔和渐变背景 + 阴影，增强立体感
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black.withOpacity(0.88),
                                Colors.black.withOpacity(0.79),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withOpacity(0.6)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.50), blurRadius: 16, offset: const Offset(0, 7)),
                              BoxShadow(color: Colors.amber.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          ),
                          // 关键区域：面板前景高光（与背包页面一致），增强质感
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.06),
                                Colors.transparent,
                                Colors.white.withOpacity(0.02),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 关键区域：Material Icons 无“宝箱”图标，使用库存图标替代，避免编译错误
                              _panelHeader('宝箱', Icons.inventory_2, Colors.amber),
                              const Divider(height: 1, color: Colors.white24),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: _buildChestGrid(gameState, notifier),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _panelHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          // 关键区域：标题采用“胶囊标签”风格（参考背包页面）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.28),
                  (color == Colors.amber ? Colors.orange.shade800 : Colors.cyan.shade800).withOpacity(0.32),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: (color == Colors.amber ? Colors.amberAccent : Colors.cyanAccent).withOpacity(0.35), width: 1),
            ),
            child: Text(title, style: TextStyle(color: (color == Colors.amber ? Colors.amberAccent : Colors.cyanAccent).withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 左侧背包网格：显示现有物品，并作为 DragTarget 接收宝箱物品
  Widget _buildInventoryGrid(OptimizedGameState gameState, OptimizedGameStateNotifier notifier) {
    final capacity = gameState.inventoryCapacity;
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: capacity,
      itemBuilder: (context, index) {
        final bool hasItem = index < gameState.playerInventory.length;
        final Item? currentItem = hasItem ? gameState.playerInventory[index] : null;
        return DragTarget<Item>(
          onWillAccept: (data) => true,
          onAccept: (draggedItem) {
            notifier.transferChestItemToInventoryAtSlot(draggedItem, index);
          },
          builder: (context, candidate, rejected) {
            final hovering = candidate.isNotEmpty;
            return Container(
              decoration: BoxDecoration(
                color: hasItem ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hovering ? Colors.cyanAccent.withOpacity(0.8) : Colors.white24,
                  width: 1,
                ),
              ),
              child: hasItem ? _inventoryItemTile(currentItem!) : _emptySlotTile(index),
            );
          },
        );
      },
    );
  }

  Widget _inventoryItemTile(Item item) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            // 关键区域：背包格子使用柔和渐变与内边距，提升立体与饱满度
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.04),
                  Colors.black.withOpacity(0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            // 关键区域：前景高光叠加（与背包页面一致）
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.transparent,
                  Colors.white.withOpacity(0.03),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: item.image.isNotEmpty
                  ? Image.asset(
                      item.image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => Icon(_typeIcon(item.type), color: Colors.white, size: 18),
                    )
                  : Icon(_typeIcon(item.type), color: Colors.white, size: 18),
            ),
          ),
        ),
        Positioned(
          top: 2,
          left: 2,
          right: 2,
          child: Text(
            item.name,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500, shadows: [
              Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.black),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (item.count > 1)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24)),
              child: Text('${item.count}', style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
      ],
    );
  }

  Widget _emptySlotTile(int index) {
    return Center(
      child: Text(
        '${index + 1}',
        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
      ),
    );
  }

  // 右侧宝箱网格：显示已揭示的物品，支持点击和拖拽到左侧背包
  Widget _buildChestGrid(OptimizedGameState gameState, OptimizedGameStateNotifier notifier) {
    final visibleItems = gameState.chestVisibleItems;
    final pendingItems = gameState.chestPendingItems;
    final totalCount = visibleItems.length + pendingItems.length;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // 关键区域：揭示瞬间“突进”动画
        // 使用 AnimatedSwitcher 在待揭示 → 已揭示切换时执行 scale 过渡
        final bool isRevealed = index < visibleItems.length;
        Widget tileChild;
        String tileKey;

        if (isRevealed) {
          // 已揭示物品：可点击、可拖拽
          final item = visibleItems[index];
          tileChild = Draggable<Item>(
            data: item,
            feedback: _dragFeedback(item),
            childWhenDragging: Opacity(opacity: 0.4, child: _chestItemTile(item, notifier)),
            child: _chestItemTile(item, notifier),
          );
          tileKey = 'revealed-${item.name}-${index}';
        } else {
          // 待揭示物品：首个显示旋转搜索覆盖，其余显示静态蒙版
          final pendingIndex = index - visibleItems.length;
          final isActiveSearching = pendingIndex == 0; // 仅首个待揭示显示旋转
          final Item? currentPendingItem = isActiveSearching && pendingItems.isNotEmpty ? pendingItems.first : null;
          // 关键区域：未揭示物品不显示任何级别颜色，仅使用中性样式
          tileChild = _pendingItemTile(currentPendingItem, isActiveSearching);
          tileKey = 'pending-${pendingIndex}';
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(animation);
            return ScaleTransition(scale: scaleAnim, child: child);
          },
          child: KeyedSubtree(key: ValueKey(tileKey), child: tileChild),
        );
      },
    );
  }

  // 关键区域：宝箱物品瓷砖——点击快速放入背包
  Widget _chestItemTile(Item item, OptimizedGameStateNotifier notifier) {
    return InkWell(
      onTap: () => notifier.transferChestItemToInventory(item),
      child: Container(
        decoration: BoxDecoration(
          // 关键区域：已揭示物品采用渐变背景 + 等级边框与阴影，增强立体感
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getItemLevelColor(item.level).withOpacity(0.18),
              Colors.black.withOpacity(0.30),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          // 关键区域：已揭示物品按等级着色边框与阴影
          border: Border.all(color: _getItemLevelColor(item.level).withOpacity(0.85), width: 1),
          boxShadow: [
            BoxShadow(color: _getItemLevelColor(item.level).withOpacity(0.24), blurRadius: 7, offset: const Offset(0, 3)),
            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 6)),
          ],
        ),
        // 关键区域：前景高光叠加（与背包页面一致）
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.transparent,
              Colors.white.withOpacity(0.03),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: item.image.isNotEmpty
                    ? Image.asset(
                        item.image,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => Icon(_typeIcon(item.type), color: Colors.white, size: 20),
                      )
                    : Icon(_typeIcon(item.type), color: Colors.white, size: 20),
              ),
            ),
            Positioned(
              top: 2,
              left: 2,
              right: 2,
              child: Text(
                item.count > 1 ? '${item.name} x ${item.count}' : item.name,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, shadows: [
                  Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.black),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.count > 1)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24)),
                  child: Text('${item.count}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 关键区域：待揭示物品蒙版——首个显示旋转搜索图标，其余显示静态蒙版
  // 修改：未揭示阶段不显示颜色，但动画强度随物品等级增大（不泄露具体颜色，仅变化动效）
  Widget _pendingItemTile(Item? item, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        // 关键区域：待揭示阶段使用中性渐变，不泄露任何等级颜色
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900.withOpacity(0.40),
            Colors.black.withOpacity(0.30),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      // 关键区域：前景高光叠加（与背包页面一致）
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.transparent,
            Colors.white.withOpacity(0.03),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 模糊蒙版效果（简化：弱透明层）
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.14)),
          ),
          // 旋转搜索图标（仅当前项）
          Center(
            child: isActive
                ? AnimatedBuilder(
                    animation: _spinController,
                    builder: (context, child) {
                      // 关键区域：动画强度随物品等级增大（level 1..7）
                      final int lvl = (item?.level ?? 1).clamp(1, 7);
                      final double speedFactor = 0.8 + (lvl - 1) * 0.18; // 0.8 .. 1.88
                      final double glow = 3.0 + (lvl - 1) * 1.5; // 3 .. 12
                      final double size = 22 + (lvl - 1) * 2.5; // 22 .. 37.0
                      final double pulse = 1.0 + (lvl * 0.02) * math.sin(_spinController.value * 2 * math.pi);
                      return Container(
                        width: size + 8,
                        height: size + 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.amber.withOpacity(0.35), blurRadius: glow, spreadRadius: 0.0),
                          ],
                        ),
                        child: Transform.scale(
                          scale: pulse,
                          child: Transform.rotate(
                            angle: _spinController.value * 2 * math.pi * speedFactor,
                            child: Icon(Icons.search, color: Colors.amber, size: size),
                          ),
                        ),
                      );
                    },
                  )
                : const Icon(Icons.search, color: Colors.white24, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _dragFeedback(Item item) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          // 关键区域：拖拽反馈采用渐变与等级边框，提升立体与辨识度
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getItemLevelColor(item.level).withOpacity(0.28),
              Colors.black.withOpacity(0.25),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          // 关键区域：拖拽反馈边框按等级着色
          border: Border.all(color: _getItemLevelColor(item.level).withOpacity(0.9)),
          boxShadow: [
            BoxShadow(color: _getItemLevelColor(item.level).withOpacity(0.30), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: item.image.isNotEmpty
              ? Image.asset(
                  item.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => Icon(_typeIcon(item.type), color: Colors.white, size: 18),
                )
              : Icon(_typeIcon(item.type), color: Colors.white, size: 18),
        ),
      ),
    );
  }

  // 关键区域：按物品等级返回颜色（与背包页面/结算页保持一致）
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

  IconData _typeIcon(String type) {
    switch (type) {
      case '装备':
        return Icons.security;
      case '物品':
        return Icons.inventory_2;
      case 'potion':
        return Icons.local_pharmacy;
      case 'food':
        return Icons.restaurant;
      case 'tool':
        return Icons.build;
      case 'weapon':
        return Icons.security;
      case 'book':
        return Icons.menu_book;
      default:
        return Icons.inventory_2;
    }
  }
}