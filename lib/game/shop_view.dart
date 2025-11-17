/**
 * 独立的商店视图组件
 * 
 * 功能：
 * - 独立管理商店状态，避免受到其他游戏状态变化影响
 * - 只监听商店相关的状态变化
 * - 提供流畅的商店交互体验
 * - 美化的现代UI设计
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'optimized_game_state.dart';

/// 商店可见性状态选择器 - 只监听商店显示状态
final shopVisibilityProvider = Provider<bool>((ref) {
  return ref.watch(optimizedGameStateProvider.select((state) => state.showShop));
}, dependencies: [optimizedGameStateProvider]);

/// 商店数据选择器 - 只监听商店数据变化
final shopDataProvider = Provider<dynamic>((ref) {
  return ref.watch(optimizedGameStateProvider.select((state) => state.schoolShop));
}, dependencies: [optimizedGameStateProvider]);

/// 玩家金币选择器 - 只监听金币变化
final playerGoldProvider = Provider<int>((ref) {
  return ref.watch(optimizedGameStateProvider.select((state) => 
    (state.characterStats['gold'] ?? 0).toInt()));
}, dependencies: [optimizedGameStateProvider]);

/// 商店刷新时间选择器 - 监听商店刷新时间变化
final shopRefreshTimeProvider = Provider<Duration?>((ref) {
  final shop = ref.watch(shopDataProvider);
  if (shop == null) return null;
  return shop.getTimeUntilNextRefresh();
}, dependencies: [shopDataProvider]);

/// 商店特定状态选择器 - 组合精确的状态选择器
final shopStateProvider = Provider<ShopState>((ref) {
  return ShopState(
    isVisible: ref.watch(shopVisibilityProvider),
    shop: ref.watch(shopDataProvider),
    playerGold: ref.watch(playerGoldProvider),
  );
}, dependencies: [shopVisibilityProvider, shopDataProvider, playerGoldProvider]);

/// 商店状态数据类
class ShopState {
  final bool isVisible;
  final dynamic shop;
  final int playerGold;

  ShopState({
    required this.isVisible,
    required this.shop,
    required this.playerGold,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopState &&
        other.isVisible == isVisible &&
        other.shop == shop &&
        other.playerGold == playerGold;
  }

  @override
  int get hashCode => Object.hash(isVisible, shop, playerGold);
}

/// 独立的商店视图组件
class ShopView extends ConsumerWidget {
  const ShopView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 只监听商店可见性，避免其他状态变化导致重建
    final isVisible = ref.watch(shopVisibilityProvider);
    
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    // 当商店可见时，渲染商店内容
    return const _ShopContent();
  }
}

/// 商店内容组件 - 独立管理商店内容状态
class _ShopContent extends ConsumerWidget {
  const _ShopContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopDataProvider);
    final playerGold = ref.watch(playerGoldProvider);
    
    // 创建ShopState对象
    final shopState = ShopState(
      isVisible: true, // 已经在父组件中检查过可见性
      shop: shop,
      playerGold: playerGold,
    );

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2D3748),
                  const Color(0xFF1A202C),
                ],
              ),
              // 关键区域：统一圆角为5
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // 商店标题栏
                _buildShopHeader(context, ref),
                // 商店内容
                _buildShopContent(context, ref, shopState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建商店标题栏
  Widget _buildShopHeader(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(optimizedGameStateProvider);
    final playerGold = gameState.characterStats['gold']?.toInt() ?? 0;
    
    // 关键区域：标题栏美化（更柔和的渐变、阴影层次）；统一圆角为5
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade700.withValues(alpha: 0.95),
            Colors.orange.shade600.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        // 关键区域：标题栏阴影微调以增强立体感
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：商店标题和刷新时间
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  // 统一圆角为5
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '商店',
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
                  // 刷新时间倒计时
                  _buildRefreshTimer(ref),
                ],
              ),
            ],
          ),
          
          // 右侧：金币显示和退出按钮
          Row(
            children: [
              // 金币显示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.yellow.shade600,
                      Colors.amber.shade500,
                    ],
                  ),
                  // 统一圆角为5
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.yellow.shade300, width: 1.5),
                  // 关键区域：金币徽标阴影增强立体感
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        // 统一圆角为5
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$playerGold',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // 退出按钮
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade600,
                      Colors.red.shade700,
                    ],
                  ),
                  // 统一圆角为5
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.red.shade300, width: 1),
                  // 关键区域：退出按钮阴影微调
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // 统一圆角为5
                    borderRadius: BorderRadius.circular(5),
                    onTap: () {
                      ref.read(optimizedGameStateProvider.notifier).toggleShop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建商店内容
  Widget _buildShopContent(BuildContext context, WidgetRef ref, ShopState shopState) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            // 商品列表 - 现在占据主要空间
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  // 统一圆角为5
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 简化的商品列表标题
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '可购买物品',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // 商品网格 - 改为横向长方形布局
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 每行显示2个商品
                          childAspectRatio: 2.5, // 横向长方形比例
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: shopState.shop.items.length,
                        itemBuilder: (context, index) {
                          final item = shopState.shop.items[index];
                          return _buildShopItem(context, ref, item, shopState.playerGold, index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个商品项
  Widget _buildShopItem(BuildContext context, WidgetRef ref, dynamic item, int playerGold, int index) {
    // item已经是ShopItem类型，不需要转换
    final canAfford = playerGold >= item.currentPrice;
    final isInStock = item.stock > 0;
    final canBuy = canAfford && isInStock;

    // 关键区域：价格浮动计算与颜色（基于基础原价 basePrice）
    final int basePrice = item.item.basePrice;
    final int currentPrice = item.currentPrice;
    final bool hasBase = basePrice > 0;
    final int diffPct = hasBase ? (((currentPrice - basePrice) * 100) / basePrice).round() : 0;
    final bool isDown = hasBase && diffPct < 0;
    final bool isUp = hasBase && diffPct > 0;
    final Color priceColor = isDown
        ? Colors.greenAccent.shade200
        : isUp
            ? Colors.redAccent.shade200
            : Colors.white;

    // 关键区域：商品卡片整体美化（柔和渐变、边框与阴影）
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.6),
              ],
            ),
            // 统一圆角为5
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: canBuy 
                  ? Colors.green.withValues(alpha: 0.6) 
                  : isInStock 
                      ? Colors.orange.withValues(alpha: 0.4)
                      : Colors.red.withValues(alpha: 0.4),
              width: 2,
            ),
            // 关键区域：商品卡片阴影增强立体感
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
            // 左侧：商品图片
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                // 统一圆角为5
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  // 关键区域：按物品等级着色图片边框
                  color: _getItemLevelColor(item.item.level).withValues(alpha: 0.85),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                // 统一圆角为5
                borderRadius: BorderRadius.circular(5),
                child: Image.asset(
                  item.item.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey.shade600,
                            Colors.grey.shade800,
                          ],
                        ),
                        // 统一圆角为5
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(
                        Icons.inventory,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 中间：商品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 商品名称
                  Text(
                    item.item.name,
                    style: TextStyle(
                      // 关键区域：按物品等级着色名称
                      color: _getItemLevelColor(item.item.level),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 商品描述
                  Text(
                    item.item.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // 关键区域：价格与库存（含原价划线与当前价颜色）
                  // 视觉优化：更细的边框与更柔和的渐变与阴影
                  Row(
                    children: [
                      // 价格标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade600.withValues(alpha: 0.95),
                              Colors.amber.shade400.withValues(alpha: 0.95),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          // 统一圆角为5
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: Colors.amber.shade200.withValues(alpha: 0.7),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            // 原价（划线）+ 当前价（红/绿）
                            // 说明：避免使用集合 if，兼容旧 Dart 版本解析
                            Visibility(
                              visible: hasBase,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$basePrice',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 10,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ),
                            Text(
                              '$currentPrice',
                              style: TextStyle(
                                color: priceColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // 库存状态
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isInStock
                                ? [
                                    Colors.blue.shade600.withValues(alpha: 0.85),
                                    Colors.blue.shade400.withValues(alpha: 0.85),
                                  ]
                                : [
                                    Colors.red.shade600.withValues(alpha: 0.85),
                                    Colors.red.shade400.withValues(alpha: 0.85),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          // 统一圆角为5
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          isInStock ? '库存: ${item.stock}' : '售罄',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 右侧：购买按钮
            SizedBox(
              width: 80,
              height: 36,
              child: ElevatedButton(
                onPressed: canBuy ? () {
                  ref.read(optimizedGameStateProvider.notifier).buyItem(item);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canBuy ? Colors.green.shade600 : Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade700,
                  disabledForegroundColor: Colors.grey.shade400,
                  // 关键区域：按钮立体感
                  elevation: canBuy ? 6 : 1,
                  shadowColor: canBuy ? Colors.green.withValues(alpha: 0.45) : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    // 统一圆角为5
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(
                      color: canBuy 
                          ? Colors.green.shade400.withValues(alpha: 0.6)
                          : Colors.grey.shade500.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                // 交互优化：文案与阴影仅在可购买时强调
                child: Text(
                  canBuy ? '购买' : (isInStock ? '金币不足' : '售罄'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    shadows: canBuy ? [
                      const Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ] : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
        // 关键区域：右上角涨跌幅徽标（⬆️/⬇️ + 百分比）
        // 说明：为避免列表内内联 if 导致语法冲突，改用 Align + Offstage 控制显示与定位。
        Align(
          alignment: Alignment.topRight,
          child: Offstage(
            offstage: !(hasBase && diffPct != 0),
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  // 统一圆角为5
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  diffPct > 0 ? '⬆️${diffPct.abs()}%' : '⬇️${diffPct.abs()}%',
                  style: TextStyle(
                    color: diffPct > 0 ? Colors.redAccent.shade200 : Colors.greenAccent.shade200,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建刷新时间倒计时显示
  Widget _buildRefreshTimer(WidgetRef ref) {
    return const ShopRefreshTimer();
  }
}

/// 商店刷新时间倒计时组件
class ShopRefreshTimer extends ConsumerStatefulWidget {
  const ShopRefreshTimer({Key? key}) : super(key: key);

  @override
  ConsumerState<ShopRefreshTimer> createState() => _ShopRefreshTimerState();
}

class _ShopRefreshTimerState extends ConsumerState<ShopRefreshTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 启动定时器，每秒更新一次
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // 强制重建组件以更新倒计时
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(shopDataProvider);
    if (shop == null) {
      return const SizedBox.shrink();
    }

    final timeUntilRefresh = shop.getTimeUntilNextRefresh();
    final minutes = timeUntilRefresh.inMinutes;
    final seconds = timeUntilRefresh.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.refresh,
            color: Colors.white.withValues(alpha: 0.8),
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            '刷新: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// 关键区域：商店页面等级颜色映射（按用户指定标准）
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
      return Colors.red.shade400; // 红色
    default:
      return Colors.grey.shade600; // 默认无色
  }
}