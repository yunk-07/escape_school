// game/item_spawner.dart
// 地图物品随机刷新系统 - 根据物品品质等级设置不同的刷新概率

import 'dart:math';
import '../data/props.dart';
import '../data/mapData.dart';
import 'zones.dart';

/// 物品刷新器类
/// 负责在地图上随机刷新物品，根据物品等级设置不同的刷新概率
class ItemSpawner {
  static final Random _random = Random();
  
  // 物品等级对应的刷新概率（百分比）
  // 等级越高，概率越低，呈指数递减
  static const Map<int, double> _levelProbabilities = {
    0: 40.0,  // 无色物品 - 40% (最常见)
    1: 30.0,  // 白色物品 - 30% (常见)
    2: 15.0,  // 绿色物品 - 15% (不常见)
    3: 8.0,   // 蓝色物品 - 8% (稀有)
    4: 3.0,   // 紫色物品 - 3% (非常稀有)
    5: 0.5,   // 橙色物品 - 0.5% (传说级稀有)
  };
  
  // 刷新间隔设置（秒）
  static const int _baseSpawnInterval = 30;  // 基础刷新间隔30秒
  static const int _spawnVariation = 15;     // 随机变化±15秒
  
  // 地图上同时存在的最大物品数量
  static const int _maxItemsOnMap = 20;
  
  /// 获取所有可刷新的物品（排除商店专用物品）
  static List<Item> get _spawnableItems {
    return allItems.where((item) => 
      item.id != 'book01' && // 排除学生守则（特殊物品）
      item.level >= 0        // 确保有有效等级
    ).toList();
  }
  
  /// 根据物品等级计算刷新概率
  /// 最高品质物品只有1%的概率刷新
  static double _getSpawnProbability(int level) {
    return _levelProbabilities[level] ?? 1.0;
  }

  // 关键区域：按角色概率增幅(rarityBoost)提升高品质物品的权重
  // 说明：rarityBoost 为 0.0 表示默认概率；0.1 表示高品质（等级为4/5/6）权重 +10%
  static double _applyRarityBoost(double baseWeight, int level, double rarityBoost) {
    final double boost = rarityBoost <= 0 ? 0.0 : rarityBoost;
    // 关键区域：仅对4、5、6级物品应用增幅
    if (level >= 4) {
      return baseWeight * (1.0 + boost);
    }
    return baseWeight;
  }
  
  /// 随机选择一个物品进行刷新
  /// 使用加权随机算法，高等级物品概率更低
  static Item? _selectRandomItem({double rarityBoost = 0.0}) {
    final spawnableItems = _spawnableItems;
    if (spawnableItems.isEmpty) return null;
    
    // 计算总权重（接入角色概率增幅）
    double totalWeight = 0.0;
    final weights = <Item, double>{};
    for (final item in spawnableItems) {
      final w = _applyRarityBoost(_getSpawnProbability(item.level), item.level, rarityBoost);
      weights[item] = w;
      totalWeight += w;
    }
    
    if (totalWeight <= 0) return null;
    
    // 生成随机数并选择物品
    final randomValue = _random.nextDouble() * totalWeight;
    double currentWeight = 0.0;
    for (final entry in weights.entries) {
      currentWeight += entry.value;
      if (randomValue <= currentWeight) {
        return entry.key;
      }
    }
    
    // 后备方案：返回最后一个物品
    return spawnableItems.last;
  }
  
  /// 获取地图上所有可行走的位置（草地、路径）
  static List<Point<int>> _getWalkablePositions() {
    final walkablePositions = <Point<int>>[];
    
    for (int y = 0; y < MapData.testMap.length; y++) {
      for (int x = 0; x < MapData.testMap[y].length; x++) {
        final terrain = MapData.testMap[y][x];
        // 关键区域：建筑内刷新物品更多
        // 说明：将建筑格纳入可刷新位置，并对建筑格施加更高权重（重复加入），使其刷新概率更高。
        if (terrain == 'building') {
          walkablePositions.add(Point(x, y));
          walkablePositions.add(Point(x, y));
          walkablePositions.add(Point(x, y)); // 建筑权重：3倍
        } else if (terrain == 'grass' || terrain == 'path') {
          walkablePositions.add(Point(x, y)); // 室外权重：1倍
        }
      }
    }
    
    return walkablePositions;
  }
  
  /// 检查位置是否适合刷新物品
  /// 避免在玩家附近、宝箱附近或已有物品的位置刷新
  static bool _isValidSpawnPosition(
    Point<int> position,
    Point<int> playerPosition,
    List<Point<int>> chestPositions,
    Map<Point<int>, List<dynamic>> existingGroundItems,
  ) {
    // 检查是否已有物品
    if (existingGroundItems.containsKey(position)) {
      return false;
    }
    
    // 检查是否距离玩家太近（至少3格距离）
    final distanceToPlayer = sqrt(
      pow(position.x - playerPosition.x, 2) + 
      pow(position.y - playerPosition.y, 2)
    );
    if (distanceToPlayer < 3.0) {
      return false;
    }
    
    // 检查是否距离宝箱太近（至少2格距离）
    for (final chestPos in chestPositions) {
      final distanceToChest = sqrt(
        pow(position.x - chestPos.x, 2) + 
        pow(position.y - chestPos.y, 2)
      );
      if (distanceToChest < 2.0) {
        return false;
      }
    }
    
    return true;
  }
  
  /// 尝试在地图上刷新一个随机物品
  /// 返回刷新的物品和位置，如果刷新失败则返回null
  static MapEntry<Point<int>, Item>? trySpawnItem(
    Point<int> playerPosition,
    List<Point<int>> chestPositions,
    Map<Point<int>, List<dynamic>> existingGroundItems,
    {double rarityBoost = 0.0}
  ) {
    // 检查地图上的物品数量是否已达上限
    if (existingGroundItems.length >= _maxItemsOnMap) {
      return null;
    }
    
    // 选择要刷新的物品
    final selectedItem = _selectRandomItem(rarityBoost: rarityBoost);
    if (selectedItem == null) {
      return null;
    }
    
    // 获取所有可行走的位置
    final walkablePositions = _getWalkablePositions();
    if (walkablePositions.isEmpty) {
      return null;
    }
    
    // 过滤出有效的刷新位置
    final validPositions = walkablePositions.where((pos) => 
      _isValidSpawnPosition(pos, playerPosition, chestPositions, existingGroundItems)
    ).toList();
    
    if (validPositions.isEmpty) {
      return null;
    }
    
    // 随机选择一个有效位置
    final spawnPosition = validPositions[_random.nextInt(validPositions.length)];
    
    return MapEntry(spawnPosition, selectedItem);
  }
  
  /// 计算下次刷新的时间间隔（秒）
  /// 基础间隔30秒，随机变化±15秒
  static int getNextSpawnInterval() {
    return _baseSpawnInterval + _random.nextInt(_spawnVariation * 2 + 1) - _spawnVariation;
  }
  
  /// 获取物品等级的显示名称
  static String getLevelDisplayName(int level) {
    switch (level) {
      case 0: return '无色';
      case 1: return '白色';
      case 2: return '绿色';
      case 3: return '蓝色';
      case 4: return '紫色';
      case 5: return '橙色';
      case 6: return '红色';
      default: return '未知';
    }
  }
  
  /// 获取物品等级对应的颜色
  static String getLevelColor(int level) {
    switch (level) {
      case 0: return '#808080'; // 灰色
      case 1: return '#FFFFFF'; // 白色
      case 2: return '#00FF00'; // 绿色
      case 3: return '#0080FF'; // 蓝色
      case 4: return '#8000FF'; // 紫色
      case 5: return '#FF8000'; // 橙色
      case 6: return '#FF0000'; // 红色
      default: return '#808080'; // 默认灰色
    }
  }
  
  /// 打印刷新概率统计信息（调试用）
  static void printSpawnStatistics() {
    print('=== 物品刷新概率统计 ===');
    final spawnableItems = _spawnableItems;
    
    // 按等级分组统计
    final levelGroups = <int, List<Item>>{};
    for (final item in spawnableItems) {
      levelGroups.putIfAbsent(item.level, () => []).add(item);
    }
    
    for (final level in levelGroups.keys.toList()..sort()) {
      final items = levelGroups[level]!;
      final probability = _getSpawnProbability(level);
      print('等级 $level (${getLevelDisplayName(level)}): ${probability}% - ${items.length}个物品');
      for (final item in items) {
        print('  - ${item.name}');
      }
    }
    
    print('刷新间隔: ${_baseSpawnInterval}±${_spawnVariation}秒');
    print('地图最大物品数: $_maxItemsOnMap');
    print('========================');
  }

  /// 为宝箱选择随机物品（使用相同的等级概率系统）
  /// 宝箱中的物品概率稍微向高等级倾斜
  static Item? selectRandomChestItem({double rarityBoost = 0.0}) {
    final chestItems = allItems.where((item) => item.level >= 0).toList();
    if (chestItems.isEmpty) return null;
    
    // 宝箱使用修改后的概率权重（高等级物品概率稍微提高）
     final chestProbabilities = <int, double>{
       0: 20.0,  // 无色物品 - 30% (降低)
       1: 20.0,  // 白色物品 - 25% (降低)
       2: 20.0,  // 绿色物品 - 20% (提高)
       3: 20.0,  // 蓝色物品 - 12% (提高)
       4: 10.0,   // 紫色物品 - 5% (提高)
       5: 8.0,   // 橙色物品 - 1% (提高)
       6: 2.0,   // 红色物品 - 0.5% (提高)
     };
    
    // 计算总权重
    double totalWeight = 0.0;
    final weights = <Item, double>{};
    for (final item in chestItems) {
      final base = chestProbabilities[item.level] ?? 1.0;
      final w = _applyRarityBoost(base, item.level, rarityBoost);
      weights[item] = w;
      totalWeight += w;
    }
    
    if (totalWeight <= 0) return null;
    
    // 生成随机数并选择物品
    final randomValue = _random.nextDouble() * totalWeight;
    double currentWeight = 0.0;
    
    for (final entry in weights.entries) {
      currentWeight += entry.value;
      if (randomValue <= currentWeight) {
        return entry.key;
      }
    }
    
    // 后备方案：返回最后一个物品
    return chestItems.last;
  }

  /// 为宝箱生成多个随机物品
  static List<Item> generateChestItems({int minItems = 1, int maxItems = 3, double rarityBoost = 0.0}) {
    final items = <Item>[];
    final itemCount = minItems + _random.nextInt(maxItems - minItems + 1);
    
    for (int i = 0; i < itemCount; i++) {
      final item = selectRandomChestItem(rarityBoost: rarityBoost);
      if (item != null) {
        items.add(item);
      }
    }
    
    // 关键区域：为每个宝箱必定生成 1-10 枚“金币”作为堆叠物品
    // 说明：金币道具为可使用物品，每次使用 +1 金币。这里以堆叠形式加入宝箱可见物品。
    try {
      final goldTemplate = allItems.firstWhere((i) => i.id == 'gold');
      final goldCount = 1 + _random.nextInt(10); // 1..10 随机数量
      items.add(Item(
        id: goldTemplate.id,
        name: goldTemplate.name,
        image: goldTemplate.image,
        description: goldTemplate.description,
        effects: goldTemplate.effects,
        type: goldTemplate.type,
        count: goldCount,
        availableInShop: goldTemplate.availableInShop,
        basePrice: goldTemplate.basePrice,
        usageTime: goldTemplate.usageTime,
        level: goldTemplate.level,
        equipmentSlot: goldTemplate.equipmentSlot,
        equipEffects: goldTemplate.equipEffects,
      ));
    } catch (_) {
      // 若未配置 gold 道具，安全跳过，不抛错
    }

    return items;
  }

  // 关键区域：建筑内高品质物品概率提升（宝箱）
  // 说明：当宝箱位于建筑地形（MapData.testMap[y][x] == 'building'）时，提高高等级物品的选择权重。
  static Item? selectRandomChestItemAt(Point<int> chestPosition, {double rarityBoost = 0.0}) {
    final chestItems = allItems.where((item) => item.level >= 0).toList();
    if (chestItems.isEmpty) return null;

    // 基础宝箱概率（原有设定：略向高等级倾斜）
    final baseChestProbabilities = <int, double>{
      0: 20.0,
      1: 20.0,
      2: 20.0,
      3: 20.0,
      4: 10.0,
      5: 8.0,
      6: 2.0,
    };

    // 建筑内倍率：降低低品质，提升高品质
    // 注：倍率仅在建筑地形生效，其他地形倍率为 1.0
    final buildingMultipliers = <int, double>{
      0: 0.7,
      1: 0.85,
      2: 1.2,
      3: 1.5,
      4: 1.8,
      5: 2.2,
      6: 2.5,
    };

    final terrain = MapData.testMap[chestPosition.y][chestPosition.x];
    final inBuilding = terrain == 'building';

    double totalWeight = 0.0;
    final weights = <Item, double>{};
    for (final item in chestItems) {
      final base = baseChestProbabilities[item.level] ?? 1.0;
      final multiplier = inBuilding ? (buildingMultipliers[item.level] ?? 1.0) : 1.0;
      final w = _applyRarityBoost(base * multiplier, item.level, rarityBoost);
      weights[item] = w;
      totalWeight += w;
    }

    if (totalWeight <= 0) return null;

    final randomValue = _random.nextDouble() * totalWeight;
    double currentWeight = 0.0;
    for (final entry in weights.entries) {
      currentWeight += entry.value;
      if (randomValue <= currentWeight) {
        return entry.key;
      }
    }

    return chestItems.last;
  }

  /// 根据宝箱位置生成多个随机物品（建筑内提升高品质概率）
  static List<Item> generateChestItemsAtPosition(Point<int> chestPosition, {int minItems = 1, int maxItems = 3, double rarityBoost = 0.0}) {
    final items = <Item>[];
    final itemCount = minItems + _random.nextInt(maxItems - minItems + 1);

    for (int i = 0; i < itemCount; i++) {
      final item = selectRandomChestItemAt(chestPosition, rarityBoost: rarityBoost);
      if (item != null) {
        items.add(item);
      }
    }

    final zoneName = getZoneNameAt(chestPosition.x, chestPosition.y);
    if (zoneName == '校长办公室') {
      if (_random.nextDouble() < 0.25) {
        try {
          final t = allItems.firstWhere((i) => i.id == 'goldbar');
          items.add(Item(
            id: t.id,
            name: t.name,
            image: t.image,
            description: t.description,
            effects: t.effects,
            type: t.type,
            count: 1,
            availableInShop: t.availableInShop,
            basePrice: t.basePrice,
            usageTime: t.usageTime,
            level: t.level,
            equipmentSlot: t.equipmentSlot,
            equipEffects: t.equipEffects,
          ));
        } catch (_) {}
      }
    }

    // 同步保留金币堆叠逻辑
    try {
      final goldTemplate = allItems.firstWhere((i) => i.id == 'gold');
      final goldCount = 1 + _random.nextInt(10);
      items.add(Item(
        id: goldTemplate.id,
        name: goldTemplate.name,
        image: goldTemplate.image,
        description: goldTemplate.description,
        effects: goldTemplate.effects,
        type: goldTemplate.type,
        count: goldCount,
        availableInShop: goldTemplate.availableInShop,
        basePrice: goldTemplate.basePrice,
        usageTime: goldTemplate.usageTime,
        level: goldTemplate.level,
        equipmentSlot: goldTemplate.equipmentSlot,
        equipEffects: goldTemplate.equipEffects,
      ));
    } catch (_) {}

    return items;
  }
}
