// 作用：炼金界面覆盖层（选择两件材料进行合成，并可关闭）
// 关键区域：覆盖大部分屏幕、显示物品图标、按等级着色
// 关键区域：基于 Riverpod 状态的显示控制与材料选择交互

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escape_from_school/game/optimized_game_state.dart';
import 'package:escape_from_school/data/props.dart';

class AlchemyView extends ConsumerStatefulWidget {
  const AlchemyView({super.key});

  @override
  ConsumerState<AlchemyView> createState() => _AlchemyViewState();
}

class _AlchemyViewState extends ConsumerState<AlchemyView> {
  final List<int> _selected = <int>[]; // 关键区域：材料选择（固定选择10件）

  // 关键区域：炼金页面等级颜色映射（与商店相似风格）
  Color _levelColor(int level) {
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
        return Colors.red.shade400; // 红色
      default:
        return Colors.grey.shade600; // 默认无色
    }
  }

  void _toggleSelect(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        if (_selected.length < 2) {
          _selected.add(index);
        } else {
          // 保持最多两格：替换最早选择
          _selected.removeAt(0);
          _selected.add(index);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 关键区域：防御性读取，避免 Null 导致的 bool 类型错误
    final bool show = ref.watch(
      optimizedGameStateProvider.select((s) => s.showAlchemy == true),
    );

    if (!show) return const SizedBox.shrink();

    final List<Item> inventory = ref.watch(
      optimizedGameStateProvider.select((s) => s.playerInventory),
    );

    // 关键区域：展开显示（不堆叠），并排除金币
    final List<Item> displayItems = <Item>[];
    final List<int> displayToInventoryIndex = <int>[];
    for (int invIdx = 0; invIdx < inventory.length; invIdx++) {
      final item = inventory[invIdx];
      // 关键区域：金币与 Level6 不参与炼金
      if (item.id == 'gold' || item.name == '金币') continue;
      if (item.level == 6) continue;
      final int copies = item.count;
      for (int c = 0; c < copies; c++) {
        displayItems.add(item);
        displayToInventoryIndex.add(invIdx);
      }
    }

    // 关键区域：当选择满10件时，计算可能产出等级的几率（(level+1) 权重），并按等级颜色显示
    List<TextSpan>? probabilitySpans;
    if (_selected.length == 10) {
      final Map<int, int> levelWeights = <int, int>{};
      for (final di in _selected) {
        final int invIdx = displayToInventoryIndex[di];
        final int outLevel = (inventory[invIdx].level + 1).clamp(1, 7);
        levelWeights[outLevel] = (levelWeights[outLevel] ?? 0) + 1;
      }
      final List<int> sortedLevels = levelWeights.keys.toList()..sort((a, b) => b.compareTo(a));
      if (sortedLevels.isNotEmpty) {
        final List<TextSpan> spans = <TextSpan>[];
        spans.add(TextSpan(
          text: '几率：',
          style: TextStyle(
            color: Colors.tealAccent.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ));
        for (int i = 0; i < sortedLevels.length; i++) {
          final int lvl = sortedLevels[i];
          final int count = levelWeights[lvl] ?? 0;
          final int pct = ((count / 10) * 100).round();
          spans.add(TextSpan(
            text: 'Lv$lvl $pct%'
                + (i < sortedLevels.length - 1 ? ' · ' : ''),
            style: TextStyle(
              color: _levelColor(lvl),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ));
        }
        probabilitySpans = spans;
      }
    }

    // 关键区域：覆盖大部分屏幕，风格与商店相似
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D3748),
                  Color(0xFF1A202C),
                ],
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.tealAccent.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // 关键区域：标题栏（右侧关闭按钮）
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.teal.shade700.withOpacity(0.95),
                        Colors.teal.shade600.withOpacity(0.95),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.science, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            '炼金机',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 关键区域：实时显示已选中物品数量（最多10）
                          Text(
                            '已选 ${_selected.length}/10',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade600,
                              Colors.red.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.red.shade300, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(5),
                            onTap: () => ref.read(optimizedGameStateProvider.notifier).toggleAlchemy(),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 关键区域：物品网格（图标 + 名称 + 计数；按等级着色）
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6, // 每行显示六个物品
                          childAspectRatio: 2.2, // 长方形卡片（宽高比更大）
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: displayItems.length,
                        itemBuilder: (context, i) {
                          final item = displayItems[i];
                          final bool selected = _selected.contains(i);
                          final Color levelColor = _levelColor(item.level);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_selected.contains(i)) {
                                  _selected.remove(i);
                                } else {
                                  if (_selected.length < 10) {
                                    _selected.add(i);
                                  }
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.black.withOpacity(0.35),
                                    Colors.black.withOpacity(0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: selected ? Colors.tealAccent : levelColor.withOpacity(0.8),
                                  width: selected ? 2 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.45),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 左上角：名称（按等级着色）
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: levelColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // 右上角：缩略图
                                    ClipRRect(
                                      // 关键区域：炼金页面统一圆角为 5
                                      borderRadius: BorderRadius.circular(5),
                                      child: Image.asset(
                                        item.image,
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.inventory,
                                            color: Colors.white.withOpacity(0.8),
                                            size: 20,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // 关键区域：操作区（合成 / 关闭）
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      const Spacer(),
                      // 关键区域：几率提示（当选择满10件时显示，靠近按钮）
                      if (probabilitySpans != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              children: probabilitySpans!,
                            ),
                          ),
                        ),
                      // 右侧炼金按钮
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _selected.length == 10
                              ? () {
                                  final selectedInv = _selected
                                      .map((di) => displayToInventoryIndex[di])
                                      .toList();
                                  ref
                                      .read(optimizedGameStateProvider.notifier)
                                      .startAlchemyEffectByIndicesList(selectedInv);
                                  setState(() => _selected.clear());
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade700,
                            disabledForegroundColor: Colors.grey.shade400,
                            elevation: _selected.length == 2 ? 6 : 1,
                            shadowColor: Colors.teal.withOpacity(0.45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          ),
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('合成'),
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
}