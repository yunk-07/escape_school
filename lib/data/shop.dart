// data/shop.dart
import 'dart:math';
import 'dart:ui';

import 'package:escape_from_school/data/props.dart';

class Shop {
  Point position;
  List<ShopItem> items;
  DateTime lastPriceChange;
  DateTime lastRefreshTime; // 新增：最后刷新时间
  Duration refreshInterval; // 新增：刷新间隔
  List<Item> shopItemsPool; // 商店专用物品池
  final List<VoidCallback> _listeners = [];

  Shop({
    required this.position,
    required this.items,
    required this.lastPriceChange,
    Duration? refreshInterval,
  }) : lastRefreshTime = DateTime.now(),
        refreshInterval = refreshInterval ?? Duration(seconds: 90 + Random().nextInt(61) - 30),
        shopItemsPool = allItems.where((item) => item.availableInShop).toList() {
    // 确保初始刷新时间设置正确
    if (items.isEmpty) {
      refreshItems();
    }
  }

  // 创建商店专用物品池
  static List<Item> _createShopItemsPool() {
    return allItems.where((item) => item.availableInShop).toList();
  }

  void refreshItems() {
    final random = Random();
    // 只在刷新间隔未明确设置时才重新计算（90秒±30秒随机浮动）
    // 如果已经设置了自定义刷新间隔，则保持不变

    // 1. 随机保留1个未售完商品（如果有）
    List<ShopItem> remainingItems = [];
    if (items.isNotEmpty) {
      final inStockItems = items.where((item) => item.stock > 0).toList();
      if (inStockItems.isNotEmpty) {
        remainingItems = [inStockItems[random.nextInt(inStockItems.length)]];
      }
    }

    // 2. 计算需要新增的数量 (确保总数3-5个)
    final targetCount = 3 + random.nextInt(3);
    final newItemCount = max(0, targetCount - remainingItems.length);

    // 3. 从专用物品池生成新商品
    final availableItems = List<Item>.from(shopItemsPool)
      ..removeWhere((item) => remainingItems.any((i) => i.item.id == item.id))
      ..shuffle(random);

    final newItems = availableItems.take(newItemCount).map((item) => ShopItem(
      item: item,
      price: _calculatePrice(item.basePrice),
      stock: 1 + random.nextInt(4),
    )).toList();

    // 4. 更新商品列表
    items = [...remainingItems, ...newItems];
    lastRefreshTime = DateTime.now();
    lastPriceChange = DateTime.now();

    print('商店刷新完成 - 时间: ${DateTime.now()}, 商品数: ${items.length}');
    notifyListeners();
  }

  // 获取下次刷新时间
  DateTime getNextRefreshTime() {
    return lastRefreshTime.add(refreshInterval);
  }

  // 获取距离下次刷新的剩余时间
  Duration getTimeUntilNextRefresh() {
    final nextRefreshTime = getNextRefreshTime();
    final now = DateTime.now();
    final remaining = nextRefreshTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // 检查是否需要刷新
  bool shouldRefresh() {
    return DateTime.now().isAfter(getNextRefreshTime());
  }

  // 添加监听机制
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // 计算商品价格（考虑随机浮动）
  static int _calculatePrice(int basePrice) {
    // 如果基础价格为0，直接返回0
    if (basePrice == 0) return 0;
    
    final random = Random();
    // 基础浮动范围：-10%到+20%
    int variation = random.nextInt(31) - 10;
    // 确保最低价格为原价的50%，最高为200%
    return (basePrice * (100 + variation) ~/ 100).clamp(basePrice ~/ 2, basePrice * 2);
  }
}



class ShopItem {
  final Item item;
  final int price; // 原价
  int currentPrice; // 当前价格
  int stock; // 库存

  ShopItem({
    required this.item,
    required this.price,
    required this.stock,
  }) : currentPrice = price;
}
