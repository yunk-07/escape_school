// data/shop.dart
import 'dart:math';

import 'package:escape_from_school/data/props.dart';

class Shop {
  Point position;
  List<ShopItem> items;
  DateTime lastPriceChange;
  DateTime lastRefreshTime; // 新增：最后刷新时间
  Duration refreshInterval; // 新增：刷新间隔

  Shop({
    required this.position,
    required this.items,
    required this.lastPriceChange,
    this.refreshInterval = const Duration(minutes: 30), // 默认30分钟刷新一次
  }) : lastRefreshTime = DateTime.now();

  // 检查是否需要刷新商品
  bool shouldRefresh() {
    return DateTime.now().difference(lastRefreshTime) >= refreshInterval;
  }

  // 刷新商店商品
  void refreshItems(List<Item> allItems) {
    final random = Random();
    final itemCount = 3 + random.nextInt(3); // 3-5个商品
    items = _generateShopItemsFromPool(allItems, itemCount);
    lastRefreshTime = DateTime.now();
    lastPriceChange = DateTime.now(); // 刷新后重置价格浮动时间
  }

  // 从物品池生成商品
  static List<ShopItem> _generateShopItemsFromPool(List<Item> allItems, int count) {
    final availableItems = allItems.where((item) => item.availableInShop).toList();
    final random = Random();

    if (availableItems.isEmpty) {
      return [/* 默认商品... */];
    }

    availableItems.shuffle(random);
    return availableItems.take(min(count, availableItems.length)).map((item) {
      return ShopItem(
        item: item,
        price: _calculatePrice(item.basePrice),
        stock: 1 + random.nextInt(4),
      );
    }).toList();
  }

  // 计算商品价格（考虑随机浮动）
  static int _calculatePrice(int basePrice) {
    final random = Random();
    // 基础浮动范围：-10%到+20%
    int variation = random.nextInt(31) - 10;
    // 确保最低价格为原价的50%，最高为200%
    return (basePrice * (100 + variation) ~/ 100).clamp(basePrice ~/ 2, basePrice * 2);
  }

// 价格浮动方法
  void fluctuatePrices() {
    final now = DateTime.now();
    if (now.difference(lastPriceChange).inMinutes >= 2) { // 每2分钟调价一次
      final rand = Random();
      for (var item in items) {
        final variation = rand.nextInt(20) - 10; // -10%到+10%的随机变化
        item.currentPrice = (item.price * (100 + variation) ~/ 100).clamp(item.price ~/ 2, item.price * 2);
      }
      lastPriceChange = now;
    }
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