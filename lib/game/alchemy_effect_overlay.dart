// 作用：炼金抽奖特效覆盖层（关闭炼金页面后显示轮播抽奖，减速停在结果，点击放入背包）
// 关键区域：基于 Riverpod 读取 showAlchemyEffect / alchemyCandidates / alchemyResultItem
// 关键区域：逐步增加间隔的轮播减速逻辑，最终特写展示结果

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escape_from_school/game/optimized_game_state.dart';
import 'package:escape_from_school/data/props.dart';

class AlchemyEffectOverlay extends ConsumerStatefulWidget {
  const AlchemyEffectOverlay({super.key});

  @override
  ConsumerState<AlchemyEffectOverlay> createState() => _AlchemyEffectOverlayState();
}

class _AlchemyEffectOverlayState extends ConsumerState<AlchemyEffectOverlay> {
  // 关键区域：改为水平“从右往左”轮播滚动，通过 ScrollController 控制
  final ScrollController _scrollController = ScrollController();
  static const double _itemWidth = 120; // 卡片固定宽度
  static const double _itemSpacing = 12; // 卡片间距
  static const int _repeatRounds = 3; // 轨道重复次数
  bool _hasStopped = false;
  bool _spinStarted = false;
  // 关键区域：缓存一次生成的轨道，避免滚动过程中物品内容变化
  List<Item> _trackItems = <Item>[];
  math.Random? _rng;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 关键区域：启动水平轮播滚动，缓慢减速并在中心停在结果物品
  void _startCarousel(double viewportWidth, List<Item> candidates, Item result) {
    if (_spinStarted || candidates.isEmpty) return;
    // 关键区域：确保 ScrollController 已附加到 ListView 后再执行滚动
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startCarousel(viewportWidth, candidates, result);
      });
      return;
    }
    setState(() {
      _spinStarted = true;
      _hasStopped = false;
    });
    // 关键区域：至少滚过10个物品——前段长度为 max(L,10)（整数）
    final int L = candidates.length;
    final int base = (L >= 10) ? L : 10; // 第二段起始索引（混合段长度）
    final int localTarget = candidates.indexWhere((it) => it.id == result.id);
    final int targetIndex = (localTarget >= 0) ? (base + localTarget) : base;
    final double cardExtent = _itemWidth + _itemSpacing;
    // 关键区域：由于我们在第一个元素加入了 leftPadding，使 index=0 在 offset=0 时居中，
    // 所以将目标物品居中只需滚动到 targetIndex * cardExtent。
    final double centerOffset = targetIndex * cardExtent;
    _scrollController.jumpTo(0);
    _scrollController
        .animateTo(
          centerOffset,
          // 关键区域：动画时长至少 5 秒
          duration: const Duration(milliseconds: 5200),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (!mounted) return;
          setState(() => _hasStopped = true);
        });
  }

  Color _levelColor(int level) {
    switch (level) {
      case 1:
        return Colors.grey.shade600;
      case 2:
        return Colors.green.shade400;
      case 3:
        return Colors.blue.shade400;
      case 4:
        return Colors.purple.shade400;
      case 5:
        return Colors.amber.shade400;
      case 6:
        return Colors.red.shade400;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 关键区域：在 build 中监听 showAlchemyEffect，避免 Riverpod 断言（不可在 initState 中使用 listen）
    ref.listen<bool>(
      optimizedGameStateProvider.select((s) => s.showAlchemyEffect),
      (prev, next) {
        if (next == true) {
          setState(() {
            _spinStarted = false;
            _hasStopped = false;
            // 关键区域：特效开启时重置轨道缓存与随机源（保持一次生成）
            _trackItems = <Item>[];
            _rng = math.Random();
          });
        }
      },
    );
    final bool show = ref.watch(
      optimizedGameStateProvider.select((s) => s.showAlchemyEffect == true),
    );
    if (!show) return const SizedBox.shrink();

    final List<Item> candidates = ref.watch(
      optimizedGameStateProvider.select((s) => s.alchemyCandidates),
    );
    final Item? result = ref.watch(
      optimizedGameStateProvider.select((s) => s.alchemyResultItem),
    );

    // 关键区域：启动逻辑由 ref.listen 在 build 中统一处理，避免重复启动

    if (candidates.isEmpty || result == null) {
      return const SizedBox.shrink();
    }
    final Color levelColor = _levelColor(result.level);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double viewportWidth = constraints.maxWidth;
            // 关键区域：候选长度用于构建混合段与停靠索引（保持整数）
            final int L = candidates.length;
    // 关键区域：读取炼金等级概率权重（防御性回退）
    // 注意：避免因空值导致类型异常，空或非法时回退为 {}
    final dynamic gsDyn = ref.watch(optimizedGameStateProvider);
    final Map<int, int> levelWeights =
        (gsDyn.alchemyLevelWeights is Map<int, int>)
            ? (gsDyn.alchemyLevelWeights as Map<int, int>)
            : const <int, int>{};

    // 关键区域：按照等级权重生成混合段（各等级按权重出现）
    List<Item> _weightedMix(int count) {
      final List<Item> mixed = <Item>[];
      final List<int> levels = levelWeights.keys.toList()..sort();
      final int total = levels.fold<int>(0, (acc, lvl) => acc + (levelWeights[lvl] ?? 0));
      final rng = _rng ??= math.Random();
      for (int i = 0; i < count; i++) {
        if (total <= 0) {
          // 权重为空时回退到候选列表
          mixed.add(candidates[i % L]);
          continue;
        }
        final int roll = rng.nextInt(total);
        int acc = 0;
        int chosenLevel = levels.first;
        for (final lvl in levels) {
          acc += levelWeights[lvl] ?? 0;
          if (roll < acc) {
            chosenLevel = lvl;
            break;
          }
        }
        // 关键区域：从全量物品池中挑选对应等级的物品（排除金币）
        final pool = allItems.where((it) => it.type == '物品' && it.level == chosenLevel && it.id != 'gold').toList();
        if (pool.isNotEmpty) {
          mixed.add(pool[rng.nextInt(pool.length)]);
        } else {
          // 若该等级无物品，回退到候选列表
          mixed.add(candidates[i % L]);
        }
      }
      return mixed;
    }

    // 关键区域：构建水平轮播轨道（混合段 + 候选段 + 混合段），中段用于最终停靠
    // 关键区域：混合段长度为 max(L,10)（保持为 int，避免 num/double）
    final int segmentLen = (L >= 10) ? L : 10;
    if (_trackItems.isEmpty) {
      // 关键区域：仅在首次构建或特效开启时生成一次，避免滚动中内容变化
      _trackItems = <Item>[
        ..._weightedMix(segmentLen),
        ...candidates,
        ..._weightedMix(segmentLen),
      ];
    }
    final List<Item> trackItems = _trackItems;

            if (!_spinStarted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _startCarousel(viewportWidth, candidates, result);
              });
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                // 关键区域：背后两条横向平行的发光线（美观装饰）
                // 关键区域：增大两条线的垂直间距，并按炼金等级着色
                IgnorePointer(
                  ignoring: true,
                  child: Align(
                    alignment: const Alignment(0, -0.28),
                    child: FractionallySizedBox(
                      widthFactor: 0.88,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(
                            colors: [
                              levelColor.withOpacity(0.0),
                              levelColor.withOpacity(0.70),
                              levelColor.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: levelColor.withOpacity(0.45),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: true,
                  child: Align(
                    alignment: const Alignment(0, 0.28),
                    child: FractionallySizedBox(
                      widthFactor: 0.88,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(
                            colors: [
                              levelColor.withOpacity(0.0),
                              levelColor.withOpacity(0.70),
                              levelColor.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: levelColor.withOpacity(0.45),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trackItems.length,
                    itemBuilder: (context, index) {
                      final Item it = trackItems[index];
                      // 关键区域：滚动项不显示名称与等级，仅显示图像
                      final Color color = _levelColor(it.level);
                      return Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? (viewportWidth / 2 - _itemWidth / 2) : 0,
                          right: _itemSpacing,
                        ),
                        child: Container(
                          width: _itemWidth,
                          height: 220,
                          decoration: BoxDecoration(
                            // 关键区域：取消物品背后黑色正方形蒙版
                            color: Colors.transparent,
                            // 关键区域：炼金页面圆角统一为 5
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  // 关键区域：炼金页面圆角统一为 5
                                  borderRadius: BorderRadius.circular(5),
                                  child: (it.image.isNotEmpty)
                                      ? Image.asset(
                                          it.image,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory, color: Colors.white, size: 48),
                                        )
                                      : const Icon(Icons.inventory, color: Colors.white, size: 48),
                                ),
                                // 关键区域：名称与等级在滚动中不显示
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 关键区域：取消中心边框高亮框，物品无边框

                // 关键区域：顶部居中显示最终物品名称与Lv，名称带对应等级颜色的下划线
                if (_hasStopped)
                  Positioned(
                    top: 40,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          result.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: levelColor,
                            decorationThickness: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lv${result.level}',
                          style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                // 关键区域：动画完成后的特写与发光效果
                if (_hasStopped) ...[
                  // 发光背景（按等级颜色）
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: _itemWidth + 160,
                      height: _itemWidth + 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [levelColor.withOpacity(0.55), Colors.transparent],
                          stops: const [0.0, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: levelColor.withOpacity(0.45),
                            blurRadius: 60,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 结果物品特写卡片
                  // 关键区域：最终特写出现动画（淡入+缩放），采用 AnimatedSwitcher
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Align(
                      alignment: Alignment.center,
                      child: AnimatedScale(
                        scale: 1.15,
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            // 关键区域：取消最终特写背后黑色正方形蒙版，仅保留圆形辐射光
                            color: Colors.transparent,
                            // 关键区域：炼金页面圆角统一为 5
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  // 关键区域：炼金页面圆角统一为 5
                                  borderRadius: BorderRadius.circular(5),
                                  child: (result.image.isNotEmpty)
                                      ? Image.asset(
                                          result.image,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory, color: Colors.white, size: 84),
                                        )
                                      : const Icon(Icons.inventory, color: Colors.white, size: 84),
                                ),
                                // 关键区域：最终物品名称与等级改在顶部显示，这里仅展示图像
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                if (_hasStopped)
                  Positioned(
                    bottom: 40,
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(optimizedGameStateProvider.notifier).finalizeAlchemyEffect();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: Colors.teal.withOpacity(0.45),
                          // 关键区域：炼金页面圆角统一为 5
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('放入背包'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}