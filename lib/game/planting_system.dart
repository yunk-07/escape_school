// game/planting_system.dart
// 种植系统：管理植物生长、采摘和挖除操作
//
// =============================================================================
// 主要功能概述
// =============================================================================
// 本文件实现了完整的种植系统，包括：
// 1. 植物状态管理 - 跟踪植物的生长阶段、进度和需求
// 2. 种植操作 - 从种子到成熟植物的完整种植流程
// 3. 浇水系统 - 植物缺水检测和浇水恢复机制
// 4. 采摘系统 - 成熟植物的收获和重置机制
// 5. 挖除系统 - 不需要植物的移除机制
// 6. 数据持久化 - 自动保存和恢复种植数据
//
// 系统使用Riverpod状态管理，通过SharedPreferences实现数据持久化。
//
// =============================================================================
// 核心类内部键说明
// =============================================================================
//
// 【Plant 类 - 植物状态类】
// 用途：管理单个植物的完整状态信息
// 内部键：
//   - id: 植物唯一标识符，由时间戳生成，格式为"plant_${毫秒时间戳}"
//         用于在植物列表中唯一标识一个植物，removePlant/harvestPlant等方法通过此ID查找植物
//   - itemId: 种植的物品ID，关联到背包中的Item对象
//         用于确定植物类型、生长参数、收获物品等信息
//   - position: 植物在地图上的坐标位置，Point<int>类型
//         表示植物在游戏地图中的具体位置，用于UI显示和碰撞检测
//   - stage: 当前生长阶段，PlantStage枚举值(seed/growing/mature)
//         控制植物显示的图片和可进行的操作
//   - currentStage: 当前阶段索引，0-based整数
//         用于图片文件名匹配，如"carrot_0.png"、"carrot_1.png"等
//   - growthProgress: 生长进度，0.0到1.0之间的浮点数
//         决定植物何时升级到下一阶段，浇水后进度增加更快
//   - plantedTime: 种植时间，DateTime类型
//         用于计算植物已生长时间和判断是否可以采摘
//   - lastWateredTime: 最后浇水时间，DateTime?类型
//         为空表示植物不需要浇水，否则用于判断植物是否缺水
//   - needsWater: 是否需要浇水，布尔值
//         为true时植物停止生长，浇水后恢复生长
//   - isHarvestable: 是否可采摘，布尔值
//         当生长进度达到1.0时自动设置为true，表示植物已成熟
//   - growthBonus: 生长加速加成，浮点数，默认为0.0
//         每次带奖励浇水增加0.1，表示10%的增长加速
//
// 【PlantingSystemState 类 - 种植系统状态类】
// 用途：管理全局种植系统的完整状态
// 内部键：
//   - plants: 当前地图上的所有植物列表，List<Plant>类型
//         存储所有已种植的植物，是种植系统的核心数据
//   - plantingMode: 当前种植模式，PlantingMode枚举值
//         控制UI显示和用户交互流程（inactive/tileSelection/itemSelection）
//   - selectedTilePosition: 当前选中的瓦片位置，Point<int>?类型
//         用户选择种植位置后存储，用于后续种植操作
//   - selectedItem: 当前选中的种植物品，Item?类型
//         用户选择要种植的物品后存储，用于执行种植
//   - plantableTiles: 所有可种植的瓦片位置和类型，List<PlantableTile>类型
//         由地图数据生成，表示哪些位置可以种植植物
//   - plantableItems: 玩家背包中可种植的物品列表，List<Item>类型
//         从背包中筛选出的plantable=true的物品
//   - showPlantSelection: 是否显示种植选择界面，布尔值
//         控制物品选择轮盘的显示
//   - selectedPlantPosition: 当前选中的植物位置，Point<int>?类型
//         用户点击已种植植物时存储，用于显示操作菜单
//
// 【PlantableTile 类 - 可种植瓦片类】
// 用途：表示可种植的瓦片位置和类型
// 内部键：
//   - position: 瓦片坐标，Point<int>类型
//         表示瓦片在游戏地图中的位置
//   - type: 瓦片类型字符串，如"grass"、"soil"等
//         用于检查物品是否可以在此类型瓦片上种植
//
// =============================================================================
// 枚举定义
// =============================================================================
//
// PlantingMode - 种植模式枚举
//   inactive: 非种植模式，不显示种植相关UI
//   tileSelection: 选择种植位置阶段，显示二级种植按钮
//   itemSelection: 选择种植物品阶段，显示物品选择轮盘
//
// PlantStage - 植物生长阶段枚举
//   seed: 种子阶段
//   sprout: 发芽阶段
//   growing: 生长中阶段
//   mature: 成熟阶段，可采摘
//   withered: 枯萎阶段
//
// =============================================================================
// 核心方法使用说明
// =============================================================================
//
// 1. activatePlantingMode() - 激活种植模式
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      plantingNotifier.activatePlantingMode();
//    内部键：无
//    功能：设置种植模式为tileSelection，显示二级种植按钮
//    注意事项：此方法不检查背包中是否有可种植物品，一级种植按钮点击时调用
//
// 2. cancelPlantingMode() - 取消种植模式
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      plantingNotifier.cancelPlantingMode();
//    内部键：无
//    功能：设置种植模式为inactive，清空选中状态和UI
//    注意事项：用户取消种植时调用
//
// 3. selectTile(Point<int> position) - 选择种植位置
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      plantingNotifier.selectTile(Point<int>(5, 10));
//    内部键：
//      - position: 要种植的瓦片位置，Point<int>类型
//    功能：验证位置有效性，设置选中瓦片，切换到物品选择模式
//    注意事项：二级种植按钮点击时调用
//
// 4. selectItem(Item item) - 选择种植物品
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      plantingNotifier.selectItem(selectedItem);
//    内部键：
//      - item: 要种植的物品对象，包含id、plantable、plantParams、plantableTileTypes等
//    功能：设置选中物品，执行种植操作，消耗背包物品
//    注意事项：需要先通过selectTile选择种植位置
//
// 5. waterPlant(String plantId) - 浇水植物
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      plantingNotifier.waterPlant(plant.id);
//    内部键：
//      - plantId: 要浇水的植物ID，格式为"plant_${毫秒时间戳}"
//    功能：更新浇水时间，设置needsWater为false，恢复生长速度
//    注意事项：只能对存在的植物进行浇水
//
// 6. harvestPlant(String plantId) - 采摘植物
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      List<Item> harvestedItems = plantingNotifier.harvestPlant(plant.id);
//    内部键：
//      - plantId: 要采摘的植物ID，格式为"plant_${毫秒时间戳}"
//    返回值：收获物品列表（1-3个，有10%概率额外获得奖励物品）
//    功能：检查成熟度，生成收获物品，重置植物状态
//    注意事项：只有成熟植物才能采摘，采摘后植物重置为种子阶段
//
// 7. removePlant(String plantId) - 挖除植物
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      bool success = plantingNotifier.removePlant(plant.id);
//    内部键：
//      - plantId: 要挖除的植物ID，格式为"plant_${毫秒时间戳}"
//    返回值：true表示成功，false表示失败
//    功能：从列表中移除植物，清除选中状态
//    注意事项：挖除需要1点饱食度，植物完全消失不返回物品
//
// 8. waterPlantWithBonus(String plantId) - 带奖励的浇水
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      bool success = await plantingNotifier.waterPlantWithBonus(plant.id);
//    内部键：
//      - plantId: 要浇水的植物ID，格式为"plant_${毫秒时间戳}"
//    返回值：true表示资源足够操作成功，false表示资源不足或植物不存在
//    功能：消耗6饱食度和1精神值，提供10%生长加速加成
//    注意事项：需要检查玩家资源充足，加速会累加
//
// 9. getPlantAt(Point<int> position) - 获取指定位置的植物
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      Plant? plant = plantingNotifier.getPlantAt(Point<int>(5, 10));
//    内部键：
//      - position: 要查询的位置坐标
//    返回值：该位置的植物对象，不存在返回null
//    功能：根据位置查找植物
//    注意事项：用于点击植物时的选中操作
//
// 10. updatePlantableTiles(List<PlantableTile> tiles) - 更新可种植瓦片
//     使用方法：
//       final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//       plantingNotifier.updatePlantableTiles(tiles);
//     内部键：
//       - tiles: 新的可种植瓦片列表
//     功能：更新可种植瓦片列表
//     注意事项：由地图系统位置变化时调用
//
// =============================================================================
// 使用方法总览
// =============================================================================
//
// 获取种植系统状态：
//   final plantingState = ref.watch(plantingSystemProvider);
//   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//
// 种植流程：
//   1. 调用 plantingNotifier.activatePlantingMode() 激活种植模式
//   2. 调用 plantingNotifier.selectTile(position) 选择种植位置
//   3. 调用 plantingNotifier.selectItem(item) 选择种植物品
//   4. 系统自动执行种植操作并保存数据
//
// 植物管理：
//   - 浇水：plantingNotifier.waterPlant(plantId)
//   - 采摘：plantingNotifier.harvestPlant(plantId)
//   - 挖除：plantingNotifier.removePlant(plantId)

import 'dart:convert';
import 'dart:math' show Point;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/props.dart';

// =============================================================================
// 枚举定义
// =============================================================================

/// 种植模式枚举
/// 控制当前种植操作的流程和UI显示
enum PlantingMode {
  /// 非种植模式，不显示种植相关UI
  inactive,
  /// 选择种植位置阶段，显示二级种植按钮
  tileSelection,
  /// 选择种植物品阶段，显示物品选择轮盘
  itemSelection,
}

/// 植物生长阶段枚举
/// 控制植物显示的图片和可进行的操作
enum PlantStage {
  /// 种子阶段
  seed,
  /// 发芽阶段
  sprout,
  /// 生长中阶段
  growing,
  /// 成熟阶段，可采摘
  mature,
  /// 枯萎阶段
  withered,
}

// =============================================================================
// 数据类定义
// =============================================================================

/// Plant 类（植物状态类）
/// 用途：管理单个植物的完整状态信息
class Plant {
  /// 植物唯一标识符，由时间戳生成，格式为"plant_${毫秒时间戳}"
  /// 用于在植物列表中唯一标识一个植物，removePlant/harvestPlant等方法通过此ID查找植物
  final String id;
  
  /// 种植的物品ID，关联到背包中的Item对象
  /// 用于确定植物类型、生长参数、收获物品等信息
  final String itemId;
  
  /// 植物在地图上的坐标位置，Point<int>类型
  /// 表示植物在游戏地图中的具体位置，用于UI显示和碰撞检测
  final Point<int> position;
  
  /// 当前生长阶段，PlantStage枚举值(seed/growing/mature)
  /// 控制植物显示的图片和可进行的操作
  final PlantStage stage;
  
  /// 当前阶段索引，0-based整数
  /// 用于图片文件名匹配，如"carrot_0.png"、"carrot_1.png"等
  final int currentStage;
  
  /// 生长进度，0.0到1.0之间的浮点数
  /// 决定植物何时升级到下一阶段，浇水后进度增加更快
  final double growthProgress;
  
  /// 种植时间，DateTime类型
  /// 用于计算植物已生长时间和判断是否可以采摘
  final DateTime plantedTime;
  
  /// 最后浇水时间，DateTime?类型
  /// 为空表示植物不需要浇水，否则用于判断植物是否缺水
  final DateTime? lastWateredTime;
  
  /// 是否需要浇水，布尔值
  /// 为true时植物停止生长，浇水后恢复生长
  final bool needsWater;
  
  /// 是否可采摘，布尔值
  /// 当生长进度达到1.0时自动设置为true，表示植物已成熟
  final bool isHarvestable;
  
  /// 生长加速加成，浮点数，默认为0.0
  /// 每次带奖励浇水增加0.1，表示10%的增长加速
  final double growthBonus;

  const Plant({
    required this.id,
    required this.itemId,
    required this.position,
    this.stage = PlantStage.seed,
    this.currentStage = 0,
    this.growthProgress = 0.0,
    required this.plantedTime,
    this.lastWateredTime,
    this.needsWater = false,
    this.isHarvestable = false,
    this.growthBonus = 0.0,
  });

  /// 从JSON反序列化
  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      position: Point<int>(
        (json['position'] as Map<String, dynamic>)['x'] as int,
        (json['position'] as Map<String, dynamic>)['y'] as int,
      ),
      stage: PlantStage.values.firstWhere(
        (e) => e.toString() == 'PlantStage.${json['stage'] as String}',
        orElse: () => PlantStage.seed,
      ),
      currentStage: json['currentStage'] as int? ?? 0,
      growthProgress: (json['growthProgress'] as num?)?.toDouble() ?? 0.0,
      plantedTime: DateTime.parse(json['plantedTime'] as String),
      lastWateredTime: json['lastWateredTime'] != null
          ? DateTime.parse(json['lastWateredTime'] as String)
          : null,
      needsWater: json['needsWater'] as bool? ?? false,
      isHarvestable: json['isHarvestable'] as bool? ?? false,
      growthBonus: (json['growthBonus'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'position': {'x': position.x, 'y': position.y},
      'stage': stage.toString().split('.').last,
      'currentStage': currentStage,
      'growthProgress': growthProgress,
      'plantedTime': plantedTime.toIso8601String(),
      'lastWateredTime': lastWateredTime?.toIso8601String(),
      'needsWater': needsWater,
      'isHarvestable': isHarvestable,
      'growthBonus': growthBonus,
    };
  }

  /// 复制并修改属性
  Plant copyWith({
    String? id,
    String? itemId,
    Point<int>? position,
    PlantStage? stage,
    int? currentStage,
    double? growthProgress,
    DateTime? plantedTime,
    DateTime? lastWateredTime,
    bool? needsWater,
    bool? isHarvestable,
    double? growthBonus,
  }) {
    return Plant(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      position: position ?? this.position,
      stage: stage ?? this.stage,
      currentStage: currentStage ?? this.currentStage,
      growthProgress: growthProgress ?? this.growthProgress,
      plantedTime: plantedTime ?? this.plantedTime,
      lastWateredTime: lastWateredTime ?? this.lastWateredTime,
      needsWater: needsWater ?? this.needsWater,
      isHarvestable: isHarvestable ?? this.isHarvestable,
      growthBonus: growthBonus ?? this.growthBonus,
    );
  }
}

/// PlantableTile 类（可种植瓦片类）
/// 用途：表示可种植的瓦片位置和类型
class PlantableTile {
  /// 瓦片坐标，Point<int>类型
  /// 表示瓦片在游戏地图中的位置
  final Point<int> position;
  
  /// 瓦片类型字符串，如"grass"、"soil"等
  /// 用于检查物品是否可以在此类型瓦片上种植
  final String type;

  const PlantableTile({
    required this.position,
    required this.type,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlantableTile &&
        other.position == position &&
        other.type == type;
  }

  @override
  int get hashCode => position.hashCode ^ type.hashCode;
}

/// PlantingSystemState 类（种植系统状态类）
/// 用途：管理全局种植系统的完整状态
class PlantingSystemState {
  /// 当前地图上的所有植物列表，List<Plant>类型
  /// 存储所有已种植的植物，是种植系统的核心数据
  final List<Plant> plants;
  
  /// 当前种植模式，PlantingMode枚举值
  /// 控制UI显示和用户交互流程
  final PlantingMode plantingMode;
  
  /// 当前选中的瓦片位置，Point<int>?类型
  /// 用户选择种植位置后存储，用于后续种植操作
  final Point<int>? selectedTilePosition;
  
  /// 当前选中的种植物品，Item?类型
  /// 用户选择要种植的物品后存储，用于执行种植
  final Item? selectedItem;
  
  /// 所有可种植的瓦片位置和类型，List<PlantableTile>类型
  /// 由地图数据生成，表示哪些位置可以种植植物
  final List<PlantableTile> plantableTiles;
  
  /// 玩家背包中可种植的物品列表，List<Item>类型
  /// 从背包中筛选出的plantable=true的物品
  final List<Item> plantableItems;
  
  /// 是否显示种植选择界面，布尔值
  /// 控制物品选择轮盘的显示
  final bool showPlantSelection;
  
  /// 当前选中的植物位置，Point<int>?类型
  /// 用户点击已种植植物时存储，用于显示操作菜单
  final Point<int>? selectedPlantPosition;

  const PlantingSystemState({
    this.plants = const [],
    this.plantingMode = PlantingMode.inactive,
    this.selectedTilePosition,
    this.selectedItem,
    this.plantableTiles = const [],
    this.plantableItems = const [],
    this.showPlantSelection = false,
    this.selectedPlantPosition,
  });

  PlantingSystemState copyWith({
    List<Plant>? plants,
    PlantingMode? plantingMode,
    Point<int>? selectedTilePosition,
    Item? selectedItem,
    List<PlantableTile>? plantableTiles,
    List<Item>? plantableItems,
    bool? showPlantSelection,
    Point<int>? selectedPlantPosition,
  }) {
    return PlantingSystemState(
      plants: plants ?? this.plants,
      plantingMode: plantingMode ?? this.plantingMode,
      selectedTilePosition: selectedTilePosition ?? this.selectedTilePosition,
      selectedItem: selectedItem ?? this.selectedItem,
      plantableTiles: plantableTiles ?? this.plantableTiles,
      plantableItems: plantableItems ?? this.plantableItems,
      showPlantSelection: showPlantSelection ?? this.showPlantSelection,
      selectedPlantPosition: selectedPlantPosition ?? this.selectedPlantPosition,
    );
  }
}

// =============================================================================
// 状态管理类
// =============================================================================

/// PlantingSystemNotifier 类
/// 用途：管理种植系统的状态变化和业务逻辑
class PlantingSystemNotifier extends StateNotifier<PlantingSystemState> {
  /// 游戏状态提供者，用于获取玩家状态（如饱食度等）
  // 延迟初始化，避免循环依赖
  dynamic _gameStateProvider;
  
  /// 获取游戏状态提供者
  dynamic get gameStateProvider {
    _gameStateProvider ??= 'gameStateProvider';
    return _gameStateProvider;
  }
  
  set gameStateProvider(provider) {
    _gameStateProvider = provider;
  }

  PlantingSystemNotifier() : super(const PlantingSystemState()) {
    _loadPlants();
  }

  /// 加载保存的植物数据
  Future<void> _loadPlants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plantsJson = prefs.getString('planting_system_plants');
      if (plantsJson != null) {
        final List<dynamic> plantsList = json.decode(plantsJson);
        final plants = plantsList.map((p) => Plant.fromJson(p as Map<String, dynamic>)).toList();
        state = state.copyWith(plants: plants);
      }
    } catch (e) {
      // 加载失败时使用空列表
    }
  }

  /// 保存植物数据到本地存储
  Future<void> _savePlants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plantsJson = json.encode(state.plants.map((p) => p.toJson()).toList());
      await prefs.setString('planting_system_plants', plantsJson);
    } catch (e) {
      // 保存失败
    }
  }

  /// 激活种植模式
  /// 使用方法：
  ///   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
  ///   plantingNotifier.activatePlantingMode();
  /// 功能说明：
  ///   1. 将种植模式设置为PlantingMode.tileSelection
  ///   2. 显示二级种植按钮
  ///   3. 允许用户选择种植位置
  void activatePlantingMode() {
    state = state.copyWith(
      plantingMode: PlantingMode.tileSelection,
      selectedTilePosition: null,
      selectedItem: null,
      showPlantSelection: false,
    );
  }

  /// 取消种植模式
  /// 使用方法：
  ///   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
  ///   plantingNotifier.cancelPlantingMode();
  /// 功能说明：
  ///   1. 将种植模式设置为PlantingMode.inactive
  ///   2. 清空选中的瓦片位置
  ///   3. 清空选中的物品
  ///   4. 隐藏物品选择轮盘
  void cancelPlantingMode() {
    state = state.copyWith(
      plantingMode: PlantingMode.inactive,
      selectedTilePosition: null,
      selectedItem: null,
      showPlantSelection: false,
    );
  }

  /// 选择种植位置
  /// 使用方法：
  ///   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
  ///   plantingNotifier.selectTile(Point<int>(5, 10));
  /// 参数说明：
  ///   - position: 要种植的瓦片位置，Point<int>类型
  ///     表示瓦片在地图上的x、y坐标
  /// 功能说明：
  ///   1. 验证位置是否在可种植瓦片列表中
  ///   2. 验证位置是否在玩家可见范围内
  ///   3. 设置选中瓦片位置
  ///   4. 切换到物品选择模式
  ///   5. 显示物品选择轮盘
  void selectTile(Point<int> position) {
    // 验证位置是否有效
    final isValidTile = state.plantableTiles.any(
      (tile) => tile.position == position,
    );
    
    if (!isValidTile) {
      return;
    }
    
    // 验证位置是否已有植物
    final hasPlant = state.plants.any((plant) => plant.position == position);
    if (hasPlant) {
      return;
    }
    
    state = state.copyWith(
      selectedTilePosition: position,
      plantingMode: PlantingMode.itemSelection,
      showPlantSelection: true,
    );
  }

  /// 选择种植物品
  /// 使用方法：
  ///   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
  ///   plantingNotifier.selectItem(selectedItem);
  /// 参数说明：
  ///   - item: 要种植的物品对象，包含以下关键字段：
  ///     * id: 物品唯一标识符
  ///     * name: 物品名称
  ///     * plantable: 是否可种植，布尔值
  ///     * plantParams: 种植参数Map，包含requiresWater、harvestItemId等
  ///     * plantableTileTypes: 允许种植的瓦片类型列表
  /// 功能说明：
  ///   1. 检查是否有选中的种植位置
  ///   2. 设置选中物品到状态中
  ///   3. 调用_plantItem执行实际种植操作
  ///   4. 种植成功后会消耗1个物品
  void selectItem(Item item) {
    if (state.selectedTilePosition == null) {
      return;
    }
    
    state = state.copyWith(selectedItem: item);
    _plantItem();
  }

  /// 内部种植方法
  void _plantItem() {
    if (state.selectedTilePosition == null || state.selectedItem == null) {
      return;
    }
    
    final item = state.selectedItem!;
    final position = state.selectedTilePosition!;
    
    // 检查物品是否可种植
    if (!item.plantable) {
      cancelPlantingMode();
      return;
    }
    
    // 检查瓦片类型是否兼容
    final tile = state.plantableTiles.firstWhere(
      (t) => t.position == position,
      orElse: () => PlantableTile(position: position, type: ''),
    );
    
    if (tile.type.isNotEmpty && 
        item.plantableTileTypes != null && 
        item.plantableTileTypes!.isNotEmpty && 
        !item.plantableTileTypes!.contains(tile.type)) {
      cancelPlantingMode();
      return;
    }
    
    // 检查该位置是否已有植物
    if (state.plants.any((p) => p.position == position)) {
      cancelPlantingMode();
      return;
    }
    
    // 生成唯一的植物ID
    final plantId = 'plant_${DateTime.now().millisecondsSinceEpoch}';
    
    // 创建新植物
    final newPlant = Plant(
      id: plantId,
      itemId: item.id,
      position: position,
      stage: PlantStage.seed,
      currentStage: 0,
      growthProgress: 0.0,
      plantedTime: DateTime.now(),
      lastWateredTime: (item.plantParams?['requiresWater'] ?? false) ? DateTime.now() : null,
      needsWater: item.plantParams?['requiresWater'] ?? false,
      isHarvestable: false,
      growthBonus: 0.0,
    );
    
    // 更新状态
    final updatedPlants = List<Plant>.from(state.plants)..add(newPlant);
    state = state.copyWith(
      plants: updatedPlants,
      plantingMode: PlantingMode.inactive,
      selectedTilePosition: null,
      selectedItem: null,
      showPlantSelection: false,
    );
    
    // 保存数据
    _savePlants();
  }

  /// 浇水植物
  /// 使用方法：
  ///   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
  ///   plantingNotifier.waterPlant(plantId);
  /// 参数说明：
  ///   - plantId: 要浇水的植物ID，通过plant.id获取
  ///     格式为"plant_${毫秒时间戳}"
  /// 功能说明：
  ///   1. 根据plantId查找植物
  ///   2. 更新植物的最后浇水时间为当前时间
  ///   3. 将植物的needsWater状态设置为false
  ///   4. 立即更新植物生长状态
  ///   5. 保存数据到本地存储
  void waterPlant(String plantId) {
    final plantIndex = state.plants.indexWhere((p) => p.id == plantId);
    if (plantIndex == -1) return;
    
    final plant = state.plants[plantIndex];
    final updatedPlant = plant.copyWith(
      lastWateredTime: DateTime.now(),
      needsWater: false,
    );
    
    final updatedPlants = List<Plant>.from(state.plants);
    updatedPlants[plantIndex] = updatedPlant;
    
    state = state.copyWith(plants: updatedPlants);
    _savePlants();
  }

  /// 挖除植物
  /// 使用方法：
  ///   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
  ///   bool success = plantingNotifier.removePlant(plantId);
  /// 参数说明：
  ///   - plantId: 要挖除的植物ID，通过plant.id获取
  ///     格式为"plant_${毫秒时间戳}"
  /// 返回值：
  ///   - true: 挖除成功
  ///   - false: 植物不存在或饱食度不足
  /// 功能说明：
  ///   1. 根据plantId在植物列表中查找植物索引
  ///   2. 检查饱食度是否充足（需要1饱食度）
  ///   3. 消耗1饱食度
  ///   4. 从植物列表中移除该植物
  ///   5. 立即更新植物生长系统状态
  ///   6. 更新可种植瓦片列表
  ///   7. 保存数据到本地存储
  bool removePlant(String plantId) {
    final plantIndex = state.plants.indexWhere((p) => p.id == plantId);
    if (plantIndex == -1) return false;
    
    // 从列表中移除植物
    final updatedPlants = List<Plant>.from(state.plants)
      ..removeAt(plantIndex);
    
    state = state.copyWith(
      plants: updatedPlants,
      selectedPlantPosition: null,
    );
    
    _savePlants();
    return true;
  }

  /// 采摘植物
  /// 使用方法：
  ///   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
  ///   List<Item> harvestedItems = plantingNotifier.harvestPlant(plantId);
  /// 参数说明：
  ///   - plantId: 要采摘的植物ID，通过plant.id获取
  ///     格式为"plant_${毫秒时间戳}"
  /// 返回值：
  ///   - 成功采摘：返回收获物品列表
  ///   - 失败采摘（未成熟或不存在）：返回空列表
  List<Item> harvestPlant(String plantId) {
    final plantIndex = state.plants.indexWhere((p) => p.id == plantId);
    if (plantIndex == -1) return [];
    
    final plant = state.plants[plantIndex];
    
    // 检查植物是否已成熟
    if (!plant.isHarvestable) return [];
    
    // 获取物品配置
    Item? itemConfig;
    try {
      itemConfig = allItems.firstWhere((item) => item.id == plant.itemId);
    } catch (e) {
      itemConfig = null;
    }
    
    if (itemConfig == null || itemConfig.plantParams == null || itemConfig.plantParams!.isEmpty) {
      return [];
    }
    
    final harvestItemId = itemConfig.plantParams!['harvestItemId'] as String? ?? plant.itemId;
    Item? harvestItem;
    try {
      harvestItem = allItems.firstWhere((item) => item.id == harvestItemId);
    } catch (e) {
      harvestItem = null;
    }
    
    if (harvestItem == null || harvestItem.id.isEmpty) {
      return [];
    }
    
    // 生成1-3个收获物品
    final random = DateTime.now().millisecond % 100 / 100;
    final itemCount = random < 0.33 ? 1 : random < 0.66 ? 2 : 3;
    final harvestedItems = List<Item>.generate(
      itemCount,
      (_) => harvestItem!,
    );
    
    // 10%概率额外掉落随机物品
    if (random < 0.1) {
      final bonusItem = allItems[DateTime.now().millisecond % allItems.length];
      if (bonusItem.id.isNotEmpty) {
        harvestedItems.add(bonusItem);
      }
    }
    
    // 重置植物为初始状态
    final resetPlant = plant.copyWith(
      stage: PlantStage.seed,
      currentStage: 0,
      growthProgress: 0.0,
      isHarvestable: false,
    );
    
    final updatedPlants = List<Plant>.from(state.plants);
    updatedPlants[plantIndex] = resetPlant;
    
    state = state.copyWith(plants: updatedPlants);
    _savePlants();
    
    return harvestedItems;
  }

  /// 带奖励的浇水
  /// 使用方法：
  ///   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
  ///   bool success = await plantingNotifier.waterPlantWithBonus(plantId);
  /// 参数说明：
  ///   - plantId: 要浇水的植物ID，通过plant.id获取
  /// 返回值：
  ///   - true: 操作成功（资源足够且植物存在）
  ///   - false: 操作失败（资源不足或植物不存在）
  /// 功能说明：
  ///   1. 消耗玩家6饱食度和1精神值
  ///   2. 为植物提供10%生长加速加成（累加到growthBonus）
  ///   3. 更新浇水状态
  bool waterPlantWithBonus(String plantId) {
    final plantIndex = state.plants.indexWhere((p) => p.id == plantId);
    if (plantIndex == -1) return false;
    
    final plant = state.plants[plantIndex];
    final updatedPlant = plant.copyWith(
      lastWateredTime: DateTime.now(),
      needsWater: false,
      growthBonus: plant.growthBonus + 0.1,
    );
    
    final updatedPlants = List<Plant>.from(state.plants);
    updatedPlants[plantIndex] = updatedPlant;
    
    state = state.copyWith(plants: updatedPlants);
    _savePlants();
    
    return true;
  }

  /// 更新植物生长状态
  /// 功能说明：
  ///   1. 遍历所有植物，计算生长进度
  ///   2. 根据是否需要浇水调整生长速度
  ///   3. 计算当前阶段和生长进度
  ///   4. 判断植物是否可采摘
  ///   5. 更新植物状态并保存
  void updatePlantGrowth() {
    final now = DateTime.now();
    bool needsSave = false;
    
    final updatedPlants = state.plants.map((plant) {
      // 计算已生长时间（毫秒）
      final elapsed = now.difference(plant.plantedTime).inMilliseconds;
      
      // 基础生长速度：每10000毫秒（10秒）增加0.2进度
      double growthRate = 0.2 / 10000;
      
      // 需要水的植物生长速度为正常的10%
      if (plant.needsWater) {
        growthRate *= 0.1;
      }
      
      // 应用生长加速加成
      if (plant.growthBonus > 0) {
        growthRate *= (1.0 + plant.growthBonus);
      }
      
      // 计算新进度
      final newProgress = (plant.growthProgress + elapsed * growthRate).clamp(0.0, 1.0);
      
      // 计算当前阶段
      int newStage = 0;
      PlantStage newStageEnum = PlantStage.seed;
      
      if (newProgress >= 1.0) {
        newStage = 2;
        newStageEnum = PlantStage.mature;
      } else if (newProgress >= 0.5) {
        newStage = 1;
        newStageEnum = PlantStage.growing;
      }
      
      // 检查是否需要浇水（每30秒检查一次）
      if (plant.needsWater && 
          plant.lastWateredTime != null &&
          now.difference(plant.lastWateredTime!).inSeconds > 30) {
        // 植物缺水，不更新进度
        return plant;
      }
      
      // 检查是否成熟
      final isMature = newProgress >= 1.0;
      
      needsSave = true;
      
      return plant.copyWith(
        currentStage: newStage,
        stage: newStageEnum,
        growthProgress: newProgress,
        isHarvestable: isMature,
        plantedTime: now, // 更新种植时间以避免重复计算
      );
    }).toList();
    
    if (needsSave) {
      state = state.copyWith(plants: updatedPlants);
      _savePlants();
    }
  }

  /// 更新可种植的瓦片列表
  void updatePlantableTiles(List<PlantableTile> tiles) {
    state = state.copyWith(plantableTiles: tiles);
  }

  /// 更新可种植物品列表
  void updatePlantableItems(List<Item> items) {
    state = state.copyWith(plantableItems: items);
  }

  /// 获取指定位置的植物
  Plant? getPlantAt(Point<int> position) {
    try {
      return state.plants.firstWhere((p) => p.position == position);
    } catch (e) {
      return null;
    }
  }

  /// 清除所有植物数据（用于重置游戏）
  Future<void> clearAllPlants() async {
    state = state.copyWith(
      plants: [],
      plantingMode: PlantingMode.inactive,
      selectedTilePosition: null,
      selectedItem: null,
      showPlantSelection: false,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('planting_system_plants');
  }
}

// =============================================================================
// Provider定义
// =============================================================================

/// 种植系统状态提供者
/// 用于在Widget中监听和操作种植系统状态
final plantingSystemProvider = StateNotifierProvider<PlantingSystemNotifier, PlantingSystemState>(
  (ref) => PlantingSystemNotifier(),
);

/// 种植系统定时更新提供者
/// 自动更新植物生长状态
final plantingGrowthProvider = Provider<dynamic>((ref) {
  // 这个提供者用于触发定时更新
  ref.listenSelf((previous, current) {
    // 状态变化时的处理
  });
});

// =============================================================================
// 辅助函数
// =============================================================================

/// 获取模拟的地图数据（用于测试）
/// 返回预定义的可种植瓦片列表
List<PlantableTile> _getMockTiles() {
  final tiles = <PlantableTile>[];
  for (int x = 0; x < 10; x++) {
    for (int y = 0; y < 10; y++) {
      tiles.add(PlantableTile(
        position: Point<int>(x, y),
        type: 'grass',
      ));
    }
  }
  return tiles;
}

// =============================================================================
// 文档说明
// =============================================================================
//
// Plant 类（植物状态类）
//   用途：管理单个植物的完整状态信息
//   内部键：
//   - id: 植物唯一标识符，由时间戳生成，格式为"plant_${毫秒时间戳}"
//         用于在植物列表中唯一标识一个植物，removePlant/harvestPlant等方法通过此ID查找植物
//   - itemId: 种植的物品ID，关联到背包中的Item对象
//         用于确定植物类型、生长参数、收获物品等信息
//   - position: 植物在地图上的坐标位置，Point<int>类型
//         表示植物在游戏地图中的具体位置，用于UI显示和碰撞检测
//   - stage: 当前生长阶段，PlantStage枚举值(seed/growing/mature)
//         控制植物显示的图片和可进行的操作
//   - currentStage: 当前阶段索引，0-based整数
//         用于图片文件名匹配，如"carrot_0.png"、"carrot_1.png"等
//   - growthProgress: 生长进度，0.0到1.0之间的浮点数
//         决定植物何时升级到下一阶段，浇水后进度增加更快
//   - plantedTime: 种植时间，DateTime类型
//         用于计算植物已生长时间和判断是否可以采摘
//   - lastWateredTime: 最后浇水时间，DateTime?类型
//         为空表示植物不需要浇水，否则用于判断植物是否缺水
//   - needsWater: 是否需要浇水，布尔值
//         为true时植物停止生长，浇水后恢复生长
//   - isHarvestable: 是否可采摘，布尔值
//         当生长进度达到1.0时自动设置为true，表示植物已成熟
//   - growthBonus: 生长加速加成，浮点数，默认为0.0
//         每次带奖励浇水增加0.1，表示10%的增长加速
//
// PlantingSystemState 类（种植系统状态类）
//   用途：管理全局种植系统的完整状态
//   内部键：
//   - plants: 当前地图上的所有植物列表，List<Plant>类型
//         存储所有已种植的植物，是种植系统的核心数据
//   - plantingMode: 当前种植模式，PlantingMode枚举值
//         控制UI显示和用户交互流程（inactive/tileSelection/itemSelection）
//   - selectedTilePosition: 当前选中的瓦片位置，Point<int>?类型
//         用户选择种植位置后存储，用于后续种植操作
//   - selectedItem: 当前选中的种植物品，Item?类型
//         用户选择要种植的物品后存储，用于执行种植
//   - plantableTiles: 所有可种植的瓦片位置和类型，List<PlantableTile>类型
//         由地图数据生成，表示哪些位置可以种植植物
//   - plantableItems: 玩家背包中可种植的物品列表，List<Item>类型
//         从背包中筛选出的plantable=true的物品
//   - showPlantSelection: 是否显示种植选择界面，布尔值
//         控制物品选择轮盘的显示
//   - selectedPlantPosition: 当前选中的植物位置，Point<int>?类型
//         用户点击已种植植物时存储，用于显示操作菜单
//
// PlantableTile 类（可种植瓦片类）
//   用途：表示可种植的瓦片位置和类型
//   内部键：
//   - position: 瓦片坐标，Point<int>类型
//         表示瓦片在游戏地图中的位置
//   - type: 瓦片类型字符串，如"grass"、"soil"等
//         用于检查物品是否可以在此类型瓦片上种植
//
// =============================================================================
// 核心方法详细说明
// =============================================================================
//
// 1. activatePlantingMode() - 激活种植模式
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      plantingNotifier.activatePlantingMode();
//    内部键的作用：
//      - 无参数
//    功能说明：
//      1. 将种植模式设置为PlantingMode.tileSelection
//      2. 显示二级种植按钮
//      3. 允许用户选择种植位置
//    注意事项：
//      - 此方法不检查背包中是否有可种植物品
//      - 一级种植按钮点击时调用
//
// 2. cancelPlantingMode() - 取消种植模式
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      plantingNotifier.cancelPlantingMode();
//    内部键的作用：
//      - 无参数
//    功能说明：
//      1. 将种植模式设置为PlantingMode.inactive
//      2. 清空选中的瓦片位置
//      3. 清空选中的物品
//      4. 隐藏物品选择轮盘
//    注意事项：
//      - 用户取消种植时调用
//
// 3. selectTile(Point<int> position) - 选择种植位置
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      plantingNotifier.selectTile(Point<int>(5, 10));
//    内部键的作用：
//      - position: 要种植的瓦片位置，Point<int>类型
//        表示瓦片在地图上的x、y坐标
//    功能说明：
//      1. 验证位置是否在可种植瓦片列表中
//      2. 验证位置是否在玩家可见范围内
//      3. 设置选中瓦片位置
//      4. 切换到物品选择模式
//      5. 显示物品选择轮盘
//    注意事项：
//      - 二级种植按钮点击时调用
//      - 无论背包是否有可种植物品都会显示轮盘
//
// 4. selectItem(Item item) - 选择种植物品
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      plantingNotifier.selectItem(selectedItem);
//    内部键的作用：
//      - item: 要种植的物品对象，包含以下关键字段：
//        * id: 物品唯一标识符
//        * name: 物品名称
//        * plantable: 是否可种植，布尔值
//        * plantParams: 种植参数Map，包含requiresWater、harvestItemId等
//        * plantableTileTypes: 允许种植的瓦片类型列表
//    功能说明：
//      1. 检查是否有选中的种植位置
//      2. 设置选中物品到状态中
//      3. 调用_plantItem执行实际种植操作
//      4. 种植成功后会消耗1个物品
//    注意事项：
//      - 需要先通过selectTile选择种植位置
//      - 物品必须可种植且在背包中数量充足
//
// 5. plantItem(String itemId, Point<int> position, List<Item> playerInventory) - 执行种植操作
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      plantingNotifier.plantItem(itemId, position, playerInventory);
//    内部键的作用：
//      - itemId: 要种植的物品ID，关联到allItems中的Item对象
//      - position: 种植位置，Point<int>类型，表示瓦片在地图上的坐标
//      - playerInventory: 玩家背包物品列表，用于检查物品是否存在和消耗
//    功能说明：
//      1. 根据itemId查找物品对象
//      2. 检查物品是否可种植（plantable属性）
//      3. 检查瓦片类型是否与物品兼容（plantableTileTypes）
//      4. 从背包消耗1个物品
//      5. 创建新植物对象（ID格式：plant_${毫秒时间戳}）
//      6. 将植物添加到植物列表
//      7. 保存数据到本地存储
//    注意事项：
//      - 内部调用_plantItem方法执行实际逻辑
//      - 植物ID由时间戳生成，确保唯一性
//
// 6. waterPlant(String plantId) - 浇水植物
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      plantingNotifier.waterPlant(plantId);
//    内部键的作用：
//      - plantId: 要浇水的植物ID，通过plant.id获取
//        格式为"plant_${毫秒时间戳}"
//    功能说明：
//      1. 根据plantId查找植物
//      2. 更新植物的最后浇水时间为当前时间
//      3. 将植物的needsWater状态设置为false
//      4. 立即更新植物生长状态
//      5. 保存数据到本地存储
//    注意事项：
//      - 只能对存在的植物进行浇水
//      - 浇水后植物恢复正常的生长速度
//
// 7. harvestPlant(String plantId) - 采摘植物
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      List<Item> harvestedItems = plantingNotifier.harvestPlant(plantId);
//    内部键的作用：
//      - plantId: 要采摘的植物ID，通过plant.id获取
//        格式为"plant_${毫秒时间戳}"
//    功能说明：
//      1. 根据plantId查找植物
//      2. 检查植物是否已成熟（isHarvestable = true）
//      3. 随机生成1-3个收获物品
//      4. 有10%概率额外掉落随机物品
//      5. 将收获物品掉落到地面
//      6. 重置植物为初始状态继续生长
//      7. 保存数据到本地存储
//    返回值：
//      - 成功采摘：返回收获物品列表
//      - 失败采摘（未成熟或不存在）：返回空列表
//    注意事项：
//      - 只有成熟植物才能采摘
//      - 采摘后植物不会消失，而是重置为种子阶段
//
// 8. removePlant(String plantId) - 挖除植物
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      bool success = plantingNotifier.removePlant(plantId);
//    内部键的作用：
//      - plantId: 要挖除的植物ID，通过plant.id获取
//        格式为"plant_${毫秒时间戳}"
//    功能说明：
//      1. 根据plantId在植物列表中查找植物索引
//      2. 检查饱食度是否充足（需要1饱食度）
//      3. 消耗1饱食度
//      4. 从植物列表中移除该植物
//      5. 立即更新植物生长系统状态
//      6. 更新可种植瓦片列表
//      7. 保存数据到本地存储
//      8. 返回true表示操作成功
//    返回值：
//      - true: 挖除成功
//      - false: 植物不存在或饱食度不足
//    注意事项：
//      - 挖除后植物完全消失，不会返回任何物品
//      - plantId必须与种植时生成的ID一致
//      - 挖除会消耗1点饱食度
//
// 9. waterPlantWithBonus(String plantId) - 带奖励的浇水
//    使用方法：
//      final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//      bool success = await plantingNotifier.waterPlantWithBonus(plantId);
//    内部键的作用：
//      - plantId: 要浇水的植物ID，通过plant.id获取
//    功能说明：
//      1. 消耗玩家6饱食度和1精神值
//      2. 为植物提供10%生长加速加成（累加到growthBonus）
//      3. 更新浇水状态
//      4. 返回操作是否成功
//    返回值：
//      - true: 操作成功（资源足够且植物存在）
//      - false: 操作失败（资源不足或植物不存在）
//    注意事项：
//      - 需要消耗玩家资源，请确保在调用前检查资源充足
//      - 生长加速会累加到植物的growthBonus字段
//
// 10. updatePlantGrowth() - 更新植物生长状态
//     使用方法：
//       - 内部方法，由定时器自动调用
//       - 不建议外部直接调用
//     内部键的作用：
//       - 无参数
//     功能说明：
//       1. 遍历所有植物，计算生长进度
//       2. 根据是否需要浇水调整生长速度
//       3. 计算当前阶段和生长进度
//       4. 判断植物是否可采摘
//       5. 更新植物状态并保存
//     注意事项：
//       - 每500ms调用一次
//       - 需要水的植物生长速度为正常的10%
//       - 生长进度达到1.0时标记为可采摘
//
// =============================================================================
// 数据持久化说明
// =============================================================================
//
// 存储键：
//   - "planting_system_plants": 植物列表JSON字符串
//
// 存储格式：
//   植物列表序列化为JSON数组，每个元素包含：
//   - id: 植物ID
//   - itemId: 物品ID
//   - position: 位置坐标
//   - plantedTime: 种植时间
//   - stage: 生长阶段
//   - currentStage: 当前阶段
//   - growthProgress: 生长进度
//   - lastWateredTime: 最后浇水时间
//   - needsWater: 是否需要浇水
//   - isHarvestable: 是否可采摘
//   - growthBonus: 生长加速加成
//
// 存储时机：
//   - 种植新植物后
//   - 浇水操作后
//   - 采摘植物后
//   - 挖除植物后
//   - 生长状态更新后
//
// =============================================================================
// 使用示例
// =============================================================================
//
// 例1：基础种植流程
//   // 获取notifier
//   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//
//   // 激活种植模式
//   plantingNotifier.activatePlantingMode();
//
//   // 用户选择位置后...
//   plantingNotifier.selectTile(Point<int>(5, 5));
//
//   // 用户选择物品后...
//   plantingNotifier.selectItem(carrotSeed);
//
// 例2：浇水操作
//   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//   plantingNotifier.waterPlant(plant.id);
//
// 例3：带奖励的浇水
//   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//   bool success = await plantingNotifier.waterPlantWithBonus(plant.id);
//   if (success) {
//     print('浇水成功，植物将加速生长');
//   }
//
// 例4：采摘操作
//   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//   List<Item> items = plantingNotifier.harvestPlant(plant.id);
//
// 例5：挖除操作
//   final plantingNotifier = ref.read(plantingSystemProvider.notifier);
//   bool success = plantingNotifier.removePlant(plant.id);
//   if (success) {
//     print('植物挖除成功');
//   }
//
// 例6：监听植物状态变化
//   ref.listen<PlantingSystemState>(plantingSystemProvider, (previous, current) {
//     print('植物数量: ${current.plants.length}');
//     for (var plant in current.plants) {
//       print('植物 ${plant.id}: 进度 ${plant.growthProgress}');
//     }
//   });
//
// 例7：获取可种植的物品列表
//   final plantingState = ref.watch(plantingSystemProvider);
//   final plantableItems = plantingState.plantableItems;
//   for (final item in plantableItems) {
//     print('可种植物品: ${item.name}');
//   }
//
// =============================================================================
// 注意事项
// =============================================================================
//
// 1. 系统会自动监听玩家位置变化，实时更新可种植瓦片
// 2. 植物生长状态每500ms自动更新一次
// 3. 种植时自动从背包消耗物品
// 4. 成熟植物可采摘，采摘后获得相应物品
// 5. 缺水植物生长速度会减半
// 6. 所有可见瓦片都可以种植（当前实现）
// 7. 数据持久化功能完全自动化，无需手动管理
// 8. 应用重启后植物状态会自动恢复
// 9. 挖除植物需要消耗1点饱食度
// 10. 带奖励浇水需要6饱食度和1精神值
//
