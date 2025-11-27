// game/safe_search_overlay.dart
// 新文件作用：保险箱专属搜索页面叠加层UI，左侧为玩家背包，右侧为保险箱内容；
// 与宝箱页面分离，采用蓝灰金属主题与独立布局，仅在探索保险箱时显示。

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'optimized_game_state.dart';
import 'package:escape_from_school/data/props.dart';
import 'package:escape_from_school/utils/level_color_manager.dart';

class SafeSearchOverlay extends ConsumerStatefulWidget {
  const SafeSearchOverlay({Key? key}) : super(key: key);

  @override
  ConsumerState<SafeSearchOverlay> createState() => _SafeSearchOverlayState();
}

class _SafeSearchOverlayState extends ConsumerState<SafeSearchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
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

    if (!gameState.isChestSearchOpen) {
      return const SizedBox.shrink();
    }

    final bool isSafe =
        gameState.currentExploringChest != null &&
        gameState.safePositions.contains(gameState.currentExploringChest!);
    if (!isSafe) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.blueGrey.shade900.withValues(alpha: 0.90),
              Colors.blueGrey.shade800.withValues(alpha: 0.75),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.lock,
                          color: Colors.lightBlueAccent,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '保险箱搜索',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        notifier.closeChestSearch();
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text(
                        '关闭',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.withValues(alpha: 0.28),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blueGrey.shade900.withValues(
                                  alpha: 0.87,
                                ),
                                Colors.blueGrey.shade800.withValues(
                                  alpha: 0.76,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Colors.blueGrey.shade400.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(-1, -1),
                              ),
                            ],
                          ),
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.06),
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.02),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _panelHeader(
                                '玩家背包',
                                Icons.inventory_2,
                                Colors.cyan,
                              ),
                              const Divider(height: 1, color: Colors.white24),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: _buildInventoryGrid(
                                    gameState,
                                    notifier,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blueGrey.shade900.withValues(
                                  alpha: 0.88,
                                ),
                                Colors.blueGrey.shade800.withValues(
                                  alpha: 0.79,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Colors.lightBlueAccent.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.50),
                                blurRadius: 16,
                                offset: const Offset(0, 7),
                              ),
                              BoxShadow(
                                color: Colors.lightBlueAccent.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.06),
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.02),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _panelHeader(
                                '保险箱',
                                Icons.lock,
                                Colors.lightBlueAccent,
                              ),
                              const Divider(height: 1, color: Colors.white24),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: _buildSafeGrid(gameState, notifier),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.28),
                  Colors.cyan.shade800.withValues(alpha: 0.32),
                ],
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.cyanAccent.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid(
    OptimizedGameState gameState,
    OptimizedGameStateNotifier notifier,
  ) {
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
        final Item? currentItem =
            hasItem ? gameState.playerInventory[index] : null;
        return DragTarget<Item>(
          onWillAcceptWithDetails: (details) => true,
          onAccept: (draggedItem) {
            notifier.transferChestItemToInventoryAtSlot(draggedItem, index);
          },
          builder: (context, candidate, rejected) {
            final hovering = candidate.isNotEmpty;
            return Container(
              decoration: BoxDecoration(
                color:
                    hasItem
                        ? Colors.black.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color:
                      hovering
                          ? Colors.cyanAccent.withValues(alpha: 0.8)
                          : Colors.white24,
                  width: 1,
                ),
              ),
              child:
                  hasItem
                      ? _inventoryItemTile(currentItem!)
                      : _emptySlotTile(index),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.03),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child:
                  item.image.isNotEmpty
                      ? Image.asset(
                        item.image,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stack) => Icon(
                              _typeIcon(item.type),
                              color: Colors.white,
                              size: 18,
                            ),
                      )
                      : Icon(
                        _typeIcon(item.type),
                        color: Colors.white,
                        size: 18,
                      ),
            ),
          ),
        ),
        Positioned(
          top: 2,
          left: 2,
          right: 2,
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
        if (item.count > 1)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                '${item.count}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptySlotTile(int index) {
    return Center(
      child: Text(
        '${index + 1}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildSafeGrid(
    OptimizedGameState gameState,
    OptimizedGameStateNotifier notifier,
  ) {
    final visibleItems = gameState.chestVisibleItems;
    final pendingItems = gameState.chestPendingItems;
    final totalCount = visibleItems.length + pendingItems.length;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        final bool isRevealed = index < visibleItems.length;
        Widget tileChild;
        String tileKey;

        if (isRevealed) {
          final item = visibleItems[index];
          tileChild = Draggable<Item>(
            data: item,
            feedback: _dragFeedback(item),
            childWhenDragging: Opacity(
              opacity: 0.4,
              child: _safeItemTile(item, notifier),
            ),
            child: _safeItemTile(item, notifier),
          );
          tileKey = 'revealed-${item.name}-${index}';
        } else {
          final pendingIndex = index - visibleItems.length;
          final isActiveSearching = pendingIndex == 0;
          final Item? currentPendingItem =
              isActiveSearching && pendingItems.isNotEmpty
                  ? pendingItems.first
                  : null;
          tileChild = _pendingItemTile(currentPendingItem, isActiveSearching);
          tileKey = 'pending-${pendingIndex}';
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final scaleAnim = Tween<double>(
              begin: 0.82,
              end: 1.0,
            ).animate(animation);
            return ScaleTransition(scale: scaleAnim, child: child);
          },
          child: KeyedSubtree(key: ValueKey(tileKey), child: tileChild),
        );
      },
    );
  }

  Widget _safeItemTile(Item item, OptimizedGameStateNotifier notifier) {
    return InkWell(
      onTap: () => notifier.transferChestItemToInventory(item),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getItemLevelColor(item.level).withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.30),
            ],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Colors.lightBlueAccent.withValues(alpha: 0.85),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.lightBlueAccent.withValues(alpha: 0.24),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.transparent,
              Colors.white.withValues(alpha: 0.03),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child:
                    item.image.isNotEmpty
                        ? Image.asset(
                          item.image,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stack) => Icon(
                                _typeIcon(item.type),
                                color: Colors.white,
                                size: 20,
                              ),
                        )
                        : Icon(
                          _typeIcon(item.type),
                          color: Colors.white,
                          size: 20,
                        ),
              ),
            ),
            Positioned(
              top: 2,
              left: 2,
              right: 2,
              child: Text(
                item.count > 1 ? '${item.name} x ${item.count}' : item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
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
            if (item.count > 1)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${item.count}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pendingItemTile(Item? item, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F24), Color(0xFF0F1418)],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.lightBlueAccent.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.lightBlueAccent.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
            Colors.white.withValues(alpha: 0.03),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.14)),
          ),
          Center(
            child:
                isActive
                    ? AnimatedBuilder(
                      animation: _spinController,
                      builder: (context, child) {
                        final int lvl = (item?.level ?? 1).clamp(1, 7);
                        final double speedFactor = 1.0;
                        final double baseGlow = 3.0 + (lvl - 1) * 1.5;
                        final double size = 22 + (lvl - 1) * 2.5;
                        final double dotSize = 4.0 + (lvl * 0.4);
                        return Container(
                          width: size + 8,
                          height: size + 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.lightBlueAccent.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: baseGlow,
                                spreadRadius: 0.0,
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle:
                                _spinController.value *
                                2 *
                                math.pi *
                                speedFactor,
                            child: SizedBox(
                              width: size,
                              height: size,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  width: dotSize,
                                  height: dotSize,
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlueAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.lightBlueAccent
                                            .withValues(alpha: 0.45),
                                        blurRadius: baseGlow,
                                        spreadRadius: 0.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                    : const SizedBox.shrink(),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getItemLevelColor(item.level).withValues(alpha: 0.28),
              Colors.black.withValues(alpha: 0.25),
            ],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Colors.lightBlueAccent.withValues(alpha: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.lightBlueAccent.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child:
              item.image.isNotEmpty
                  ? Image.asset(
                    item.image,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stack) => Icon(
                          _typeIcon(item.type),
                          color: Colors.white,
                          size: 18,
                        ),
                  )
                  : Icon(_typeIcon(item.type), color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Color _getItemLevelColor(int level) {
    return LevelColorManager.getItemLevelColor(level);
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'equipment':
        return Icons.security;
      case 'item':
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
