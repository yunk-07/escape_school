// game/optimized_game_state.dart
// 性能优化的游戏状态管理器

import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escape_from_school/data/mapData.dart';
import 'package:escape_from_school/data/props.dart';
import 'package:escape_from_school/data/shop.dart';
import 'package:escape_from_school/data/manData.dart';
import 'package:escape_from_school/data/skill_data.dart';
import 'package:escape_from_school/game/vision.dart';
import 'package:escape_from_school/game/enhanced_vision.dart';
import 'package:escape_from_school/game/ghost.dart';
import 'package:escape_from_school/game/smooth_vision.dart';

/// 游戏页面类型枚举
enum GamePage {
  game,      // 主游戏页面
  inventory, // 背包页面
  shop,      // 商店页面
  character, // 角色信息页面
}

/// 播报消息类型枚举
enum BroadcastMessageType {
  damage,     // 伤害消息
  heal,       // 治疗消息
  item,       // 物品相关消息
  system,     // 系统消息
}

/// 播报消息类
@immutable
class BroadcastMessage {
  final String text;
  final BroadcastMessageType type;
  final DateTime timestamp;
  final Duration displayDuration;

  const BroadcastMessage({
    required this.text,
    required this.type,
    required this.timestamp,
    this.displayDuration = const Duration(seconds: 3),
  });

  bool get isExpired => DateTime.now().difference(timestamp) > displayDuration;
}

/// 优化的玩家位置类
@immutable
class OptimizedPlayerPosition {
  final double x;
  final double y;
  final bool facingRight;

  const OptimizedPlayerPosition({
    required this.x,
    required this.y,
    this.facingRight = true,
  });

  OptimizedPlayerPosition copyWith({
    double? x,
    double? y,
    bool? facingRight,
  }) {
    return OptimizedPlayerPosition(
      x: x ?? this.x,
      y: y ?? this.y,
      facingRight: facingRight ?? this.facingRight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptimizedPlayerPosition &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          facingRight == other.facingRight;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ facingRight.hashCode;
}

/// 优化的移动状态类
@immutable
class OptimizedMovementState {
  final double velocityX;
  final double velocityY;
  final double joystickX;
  final double joystickY;
  final double joystickIntensity;
  final bool isMoving;

  const OptimizedMovementState({
    this.velocityX = 0.0,
    this.velocityY = 0.0,
    this.joystickX = 0.0,
    this.joystickY = 0.0,
    this.joystickIntensity = 0.0,
    this.isMoving = false,
  });

  OptimizedMovementState copyWith({
    double? velocityX,
    double? velocityY,
    double? joystickX,
    double? joystickY,
    double? joystickIntensity,
    bool? isMoving,
  }) {
    return OptimizedMovementState(
      velocityX: velocityX ?? this.velocityX,
      velocityY: velocityY ?? this.velocityY,
      joystickX: joystickX ?? this.joystickX,
      joystickY: joystickY ?? this.joystickY,
      joystickIntensity: joystickIntensity ?? this.joystickIntensity,
      isMoving: isMoving ?? this.isMoving,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptimizedMovementState &&
          runtimeType == other.runtimeType &&
          velocityX == other.velocityX &&
          velocityY == other.velocityY &&
          joystickX == other.joystickX &&
          joystickY == other.joystickY &&
          joystickIntensity == other.joystickIntensity &&
          isMoving == other.isMoving;

  @override
  int get hashCode =>
      velocityX.hashCode ^
      velocityY.hashCode ^
      joystickX.hashCode ^
      joystickY.hashCode ^
      joystickIntensity.hashCode ^
      isMoving.hashCode;
}

/// 优化的游戏状态类
@immutable
class OptimizedGameState {
  final Map<String, dynamic> characterStats; // 当前角色状态（HP、理智值等）
  // 注意：characterStats是不可变的，但其内部的Map内容可能会被修改
  final OptimizedPlayerPosition playerPosition;
  final OptimizedMovementState movementState;
  final List<List<String>> map;
  final List<Point<int>> chestPositions;
  final List<Item> playerInventory;
  final Set<Point<int>> visibleTiles;
  final List<List<bool>> visibleMap;
  final bool showInventory;
  final bool showCharacterInfo;
  final bool showShop;
  final Shop? schoolShop;
  final GhostManager ghostManager;
  final bool isGameOver;
  final String deathReason;
  final GamePage currentPage;
  
  // 脱离卡死相关状态
  final bool isNoClipMode;              // 是否处于无视地形模式
  final DateTime? noClipEndTime;        // 无视地形模式结束时间
  final DateTime? unstuckCooldownEnd;   // 脱离卡死冷却结束时间
  final bool isWaitingForMovement;      // 是否正在等待玩家移动以开始冷却
  final DateTime? unstuckActivatedTime; // 脱离卡死激活时间
  
  // 移动距离计算相关状态
  final OptimizedPlayerPosition? lastPosition;  // 上一次位置，用于计算移动距离
  final double accumulatedDistance;             // 累积移动距离
  
  // 生命值变化检测相关状态
  final double? lastHp;                         // 上一次的生命值，用于检测变化
  final bool shouldShowDamageEffect;            // 是否应该显示伤害效果
  final double lastDamageAmount;                // 最后一次的伤害量
  
  // 平滑视野动画相关状态
  final int lastAnimationFrame;                 // 最后一次动画帧标识，用于触发重绘
  
  // 播报消息相关状态
  final List<BroadcastMessage> broadcastMessages; // 播报消息列表
  
  // 技能系统相关状态
  final List<Skill> characterSkills;              // 角色拥有的技能列表
  final Map<String, SkillState> skillStates;      // 技能状态映射
  final String? currentCastingSkillId;            // 当前正在施法的技能ID
  final double castingProgress;                   // 施法进度 (0.0 - 1.0)
  
  // 物品使用相关状态
  final bool isUsingItem;                         // 是否正在使用物品
  final Item? currentUsingItem;                   // 当前正在使用的物品
  final double itemUsageProgress;                 // 物品使用进度 (0.0 - 1.0)
  final DateTime? itemUsageStartTime;             // 物品使用开始时间
  
  // 宝箱探索相关状态
  final bool isExploringChest;                    // 是否正在探索宝箱
  final Point<int>? currentExploringChest;        // 当前正在探索的宝箱位置
  final double chestExplorationProgress;          // 宝箱探索进度 (0.0 - 1.0)
  final DateTime? chestExplorationStartTime;      // 宝箱探索开始时间
  
  // 游戏时间相关状态
  final DateTime gameStartTime;                   // 游戏开始时间
  final DateTime? gameEndTime;                    // 游戏结束时间
  
  // 死亡时数据快照
  final Map<String, dynamic>? deathTimeStats;     // 死亡时的角色状态快照
  final List<Item>? deathTimeInventory;           // 死亡时的背包物品快照

  const OptimizedGameState({
    required this.characterStats,
    required this.playerPosition,  
    required this.movementState,
    required this.map,
    required this.chestPositions,
    required this.playerInventory,
    required this.visibleTiles,
    required this.visibleMap,
    required this.ghostManager,
    this.showInventory = false,
    this.showCharacterInfo = false,
    this.showShop = false,
    this.schoolShop,
    this.isGameOver = false,
    this.deathReason = '',
    this.currentPage = GamePage.game,
    this.isNoClipMode = false,
    this.noClipEndTime,
    this.unstuckCooldownEnd,
    this.isWaitingForMovement = false,
    this.unstuckActivatedTime,
    this.lastPosition,
    this.accumulatedDistance = 0.0,
    this.lastHp,
    this.shouldShowDamageEffect = false,
    this.lastDamageAmount = 0.0,
    this.lastAnimationFrame = 0,
    this.broadcastMessages = const [],
    this.characterSkills = const [],
    this.skillStates = const {},
    this.currentCastingSkillId,
    this.castingProgress = 0.0,
    this.isUsingItem = false,
    this.currentUsingItem,
    this.itemUsageProgress = 0.0,
    this.itemUsageStartTime,
    this.isExploringChest = false,
    this.currentExploringChest,
    this.chestExplorationProgress = 0.0,
    this.chestExplorationStartTime,
    required this.gameStartTime,
    this.gameEndTime,
    this.deathTimeStats,
    this.deathTimeInventory,
  });

  OptimizedGameState copyWith({
    Map<String, dynamic>? characterStats,
    OptimizedPlayerPosition? playerPosition,
    OptimizedMovementState? movementState,
    List<List<String>>? map,
    List<Point<int>>? chestPositions,
    List<Item>? playerInventory,
    Set<Point<int>>? visibleTiles,
    List<List<bool>>? visibleMap,
    GhostManager? ghostManager,
    bool? showInventory,
    bool? showCharacterInfo,
    bool? showShop,
    Shop? schoolShop,
    bool? isGameOver,
    String? deathReason,
    GamePage? currentPage,
    bool? isNoClipMode,
    DateTime? noClipEndTime,
    DateTime? unstuckCooldownEnd,
    bool? isWaitingForMovement,
    DateTime? unstuckActivatedTime,
    OptimizedPlayerPosition? lastPosition,
    double? accumulatedDistance,
    double? lastHp,
    bool? shouldShowDamageEffect,
    double? lastDamageAmount,
    int? lastAnimationFrame,
    List<BroadcastMessage>? broadcastMessages,
    List<Skill>? characterSkills,
    Map<String, SkillState>? skillStates,
    String? currentCastingSkillId,
    double? castingProgress,
    bool? isUsingItem,
    Item? currentUsingItem,
    double? itemUsageProgress,
    DateTime? itemUsageStartTime,
    bool? isExploringChest,
    Point<int>? currentExploringChest,
    double? chestExplorationProgress,
    DateTime? chestExplorationStartTime,
    DateTime? gameStartTime,
    DateTime? gameEndTime,
    Map<String, dynamic>? deathTimeStats,
    List<Item>? deathTimeInventory,
  }) {
    return OptimizedGameState(
      characterStats: characterStats ?? this.characterStats,
      playerPosition: playerPosition ?? this.playerPosition,
      movementState: movementState ?? this.movementState,
      map: map ?? this.map,
      chestPositions: chestPositions ?? this.chestPositions,
      playerInventory: playerInventory ?? this.playerInventory,
      visibleTiles: visibleTiles ?? this.visibleTiles,
      visibleMap: visibleMap ?? this.visibleMap,
      ghostManager: ghostManager ?? this.ghostManager,
      showInventory: showInventory ?? this.showInventory,
      showCharacterInfo: showCharacterInfo ?? this.showCharacterInfo,
      showShop: showShop ?? this.showShop,
      schoolShop: schoolShop ?? this.schoolShop,
      isGameOver: isGameOver ?? this.isGameOver,
      deathReason: deathReason ?? this.deathReason,
      currentPage: currentPage ?? this.currentPage,
      isNoClipMode: isNoClipMode ?? this.isNoClipMode,
      noClipEndTime: noClipEndTime ?? this.noClipEndTime,
      unstuckCooldownEnd: unstuckCooldownEnd ?? this.unstuckCooldownEnd,
      isWaitingForMovement: isWaitingForMovement ?? this.isWaitingForMovement,
      unstuckActivatedTime: unstuckActivatedTime ?? this.unstuckActivatedTime,
      lastPosition: lastPosition ?? this.lastPosition,
      accumulatedDistance: accumulatedDistance ?? this.accumulatedDistance,
      lastHp: lastHp ?? this.lastHp,
      shouldShowDamageEffect: shouldShowDamageEffect ?? this.shouldShowDamageEffect,
      lastDamageAmount: lastDamageAmount ?? this.lastDamageAmount,
      lastAnimationFrame: lastAnimationFrame ?? this.lastAnimationFrame,
      broadcastMessages: broadcastMessages ?? this.broadcastMessages,
      characterSkills: characterSkills ?? this.characterSkills,
      skillStates: skillStates ?? this.skillStates,
      currentCastingSkillId: currentCastingSkillId ?? this.currentCastingSkillId,
      castingProgress: castingProgress ?? this.castingProgress,
      isUsingItem: isUsingItem ?? this.isUsingItem,
      currentUsingItem: currentUsingItem ?? this.currentUsingItem,
      itemUsageProgress: itemUsageProgress ?? this.itemUsageProgress,
      itemUsageStartTime: itemUsageStartTime ?? this.itemUsageStartTime,
      isExploringChest: isExploringChest ?? this.isExploringChest,
      currentExploringChest: currentExploringChest ?? this.currentExploringChest,
      chestExplorationProgress: chestExplorationProgress ?? this.chestExplorationProgress,
      chestExplorationStartTime: chestExplorationStartTime ?? this.chestExplorationStartTime,
      gameStartTime: gameStartTime ?? this.gameStartTime,
      gameEndTime: gameEndTime ?? this.gameEndTime,
      deathTimeStats: deathTimeStats ?? this.deathTimeStats,
      deathTimeInventory: deathTimeInventory ?? this.deathTimeInventory,
    );
  }
}

/// 创建初始角色状态的辅助方法
Map<String, dynamic> _createInitialCharacterStats(Map<String, dynamic> characterData) {
  return {
    'name': characterData['name'],
    'hp': (characterData['hp'] as num).toDouble(),
    'maxHp': (characterData['hp'] as num).toDouble(),
    'san': (characterData['san'] as num).toDouble(),
    'maxSan': (characterData['san'] as num).toDouble(),
    'food': (characterData['food'] as num).toDouble(),
    'moveSpeed': characterData['moveSpeed'],
    'gold': (characterData['gold'] as num).toDouble(),
    'image': characterData['image'],
  };
}

/// 初始化角色技能列表
  List<Skill> _initializeCharacterSkills(String? characterName) {
    if (characterName == null || characterName.isEmpty) {
      return [];
    }
    
    final skills = CharacterSkills.getSkillsForCharacter(characterName);
    return skills;
  }

/// 初始化技能状态映射
Map<String, SkillState> _initializeSkillStates(String? characterName) {
  if (characterName == null || characterName.isEmpty) {
    return {};
  }
  
  final skills = CharacterSkills.getSkillsForCharacter(characterName);
  final skillStates = <String, SkillState>{};
  
  for (final skill in skills) {
    skillStates[skill.id] = SkillState(skillId: skill.id);
  }
  
  return skillStates;
}

/// 优化的游戏状态管理器
class OptimizedGameStateNotifier extends StateNotifier<OptimizedGameState> {
  Timer? _movementTimer;
  Timer? _visionUpdateTimer;
  Timer? _unstuckTimer;
  Timer? _hungerTimer;
  Timer? _smoothVisionTimer; // 平滑视野动画定时器
  Timer? _skillCooldownTimer; // 技能冷却时间更新定时器
  Timer? _gameLoopTimer; // 独立的游戏循环定时器，确保UI定期刷新
  Timer? _deathCheckTimer; // 独立的死亡判定定时器
  Timer? _itemUsageTimer; // 物品使用进度定时器
  Timer? _chestExplorationTimer; // 宝箱探索进度定时器
  late VisionSystem _visionSystem;
  late EnhancedVisionSystem _enhancedVisionSystem; // 增强版视野系统
  late SmoothVisionManager _smoothVisionManager; // 平滑视野管理器
  
  // 状态更新锁，防止竞争条件
  bool _isUpdatingStats = false;
  
  // 性能优化参数
  static const double _acceleration = 8.0;
  static const double _friction = 6.0;
  static const double _deltaTime = 0.016; // 16ms
  static const int _visionUpdateInterval = 100; // 视野更新间隔(ms)
  static const int _smoothVisionUpdateInterval = 16; // 平滑视野动画间隔(ms) - 60fps
  
  // 缓存变量以减少重复计算
  Point<int>? _lastPlayerGridPosition;
  Set<Point<int>>? _cachedVisibleTiles;

  OptimizedGameStateNotifier(Map<String, dynamic> characterData) : super(
    OptimizedGameState(
      characterStats: _createInitialCharacterStats(characterData),
      playerPosition: const OptimizedPlayerPosition(x: 10.0, y: 10.0, facingRight: true),
      movementState: const OptimizedMovementState(),
      map: MapData.testMap,
      chestPositions: [], // 初始为空，将在 _initializeGame 中随机生成
      playerInventory: [], // 玩家从空背包开始
      visibleTiles: {},
      visibleMap: List.generate(
        MapData.testMap.length,
        (y) => List.generate(MapData.testMap[0].length, (x) => false),
      ),
      ghostManager: GhostManager(map: MapData.testMap),
      showInventory: false,
      showCharacterInfo: false,
      showShop: false,
      isGameOver: false,
      deathReason: '',
      characterSkills: _initializeCharacterSkills(characterData['name']),
      skillStates: _initializeSkillStates(characterData['name']),
      gameStartTime: DateTime.now(),
      gameEndTime: null,
    ),
  ) {
    _initializeGame();
  }

  void _initializeGame() {
    _visionSystem = VisionSystem(map: MapData.testMap);
    _enhancedVisionSystem = EnhancedVisionSystem(map: MapData.testMap); // 初始化增强版视野系统
    _smoothVisionManager = SmoothVisionManager(); // 初始化平滑视野管理器
    _initializeShop();
    _initializeGhosts();
    _setRandomPlayerSpawn();
    _initializeChests(); // 初始化随机宝箱位置
    _startMovementTimer();
    _startVisionUpdateTimer();
    _startSmoothVisionTimer(); // 启动平滑视野动画定时器
    _startUnstuckTimer();
    _startHungerTimer();
    _startSkillCooldownTimer(); // 启动技能冷却定时器
    _startGameLoopTimer(); // 启动独立的游戏循环定时器
    _startDeathCheckTimer(); // 启动独立的死亡判定定时器
    _updateVision();
  }

  /// 初始化鬼
  void _initializeGhosts() {
    final walkablePositions = _getWalkablePositions();
    if (walkablePositions.isNotEmpty) {
      // 先在地图中心附近添加一个普通鬼
      final mapCenterX = state.map[0].length ~/ 2;
      final mapCenterY = state.map.length ~/ 2;
      final ghostPosition = Point(mapCenterX, mapCenterY);
      
      // 确保鬼的位置是可行走的
      Point<int> validGhostPosition = ghostPosition;
      if (state.map[ghostPosition.y][ghostPosition.x] == 'wall' || 
          state.map[ghostPosition.y][ghostPosition.x] == 'water') {
        // 如果中心位置不可行走，找一个附近的可行走位置
        for (final pos in walkablePositions) {
          final distance = _calculateDistance(pos, ghostPosition);
          if (distance < 10) {
            validGhostPosition = pos;
            break;
          }
        }
      }
      
      final ghost = NormalGhost(position: validGhostPosition);
      state.ghostManager.addGhost(ghost);
    }
  }

  /// 获取所有可行走的位置
  List<Point<int>> _getWalkablePositions() {
    final walkablePositions = <Point<int>>[];
    final map = state.map;
    
    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        if (map[y][x] != 'wall' && map[y][x] != 'water') {
          walkablePositions.add(Point(x, y));
        }
      }
    }
    
    return walkablePositions;
  }

  /// 定义地图中的出生区域
  /// 每个区域包含一个矩形范围和优先级
  static const List<Map<String, dynamic>> _spawnZones = [
    // 左上角草地区域
    {
      'name': '北部草原',
      'minX': 2,
      'maxX': 12,
      'minY': 1,
      'maxY': 10,
      'preferredTerrain': ['grass', 'path'],
      'priority': 1,
    },
    // 右上角区域
    {
      'name': '东北部',
      'minX': 80,
      'maxX': 100,
      'minY': 1,
      'maxY': 15,
      'preferredTerrain': ['grass', 'path'],
      'priority': 1,
    },
    // 中部大草原
    {
      'name': '中央平原',
      'minX': 35,
      'maxX': 65,
      'minY': 35,
      'maxY': 50,
      'preferredTerrain': ['grass', 'path'],
      'priority': 2,
    },
    // 左下角区域
    {
      'name': '西南部',
      'minX': 2,
      'maxX': 20,
      'minY': 70,
      'maxY': 85,
      'preferredTerrain': ['grass', 'path'],
      'priority': 1,
    },
    // 右下角区域
    {
      'name': '东南部',
      'minX': 80,
      'maxX': 100,
      'minY': 70,
      'maxY': 85,
      'preferredTerrain': ['grass', 'path'],
      'priority': 1,
    },
    // 中下部区域
    {
      'name': '南部平原',
      'minX': 30,
      'maxX': 70,
      'minY': 75,
      'maxY': 85,
      'preferredTerrain': ['grass', 'path'],
      'priority': 2,
    },
    // 左中部区域
    {
      'name': '西部区域',
      'minX': 2,
      'maxX': 15,
      'minY': 40,
      'maxY': 60,
      'preferredTerrain': ['grass', 'path'],
      'priority': 2,
    },
    // 右中部区域
    {
      'name': '东部区域',
      'minX': 85,
      'maxX': 100,
      'minY': 40,
      'maxY': 60,
      'preferredTerrain': ['grass', 'path'],
      'priority': 2,
    },
  ];

  /// 设置玩家随机出生位置，在整个地图的不同区域随机选择
  void _setRandomPlayerSpawn() {
    final random = Random();
    Point<int>? validSpawnPoint;
    int attempts = 0;
    const maxAttempts = 200; // 增加尝试次数
    const minDistanceFromGhost = 30.0; // 减少最小距离，让出生点更分散
     const maxDistanceFromGhost = 80.0; // 添加最大距离限制，避免过于远离

    // 首先尝试从预定义的出生区域中选择
    final shuffledZones = List.from(_spawnZones)..shuffle(random);
    
    for (final zone in shuffledZones) {
      final zonePositions = _getPositionsInZone(zone);
      if (zonePositions.isEmpty) continue;

      // 在当前区域中尝试找到合适的出生点
      for (int zoneAttempts = 0; zoneAttempts < 50 && validSpawnPoint == null; zoneAttempts++) {
        final candidatePosition = zonePositions[random.nextInt(zonePositions.length)];
        
        if (_isValidSpawnPosition(candidatePosition, minDistanceFromGhost, maxDistanceFromGhost)) {
          validSpawnPoint = candidatePosition;
          break;
        }
      }
      
      if (validSpawnPoint != null) break;
    }

    // 如果预定义区域都不合适，回退到全地图随机搜索
    if (validSpawnPoint == null) {
      final walkablePositions = _getWalkablePositions();
      
      while (validSpawnPoint == null && attempts < maxAttempts) {
        final candidatePosition = walkablePositions[random.nextInt(walkablePositions.length)];
        
        if (_isValidSpawnPosition(candidatePosition, minDistanceFromGhost, maxDistanceFromGhost)) {
          validSpawnPoint = candidatePosition;
        }
        
        attempts++;
      }
    }

    // 如果还是找不到合适的位置，找一个距离鬼适中的位置
    if (validSpawnPoint == null) {
      validSpawnPoint = _findBalancedSpawnPosition();
    }

    // 最后的后备方案
    validSpawnPoint ??= Point(10, 10);

    // 更新玩家位置
    state = state.copyWith(
      playerPosition: OptimizedPlayerPosition(
        x: validSpawnPoint.x.toDouble(),
        y: validSpawnPoint.y.toDouble(),
        facingRight: true,
      ),
    );
  }

  /// 获取指定区域内的所有可行走位置
  List<Point<int>> _getPositionsInZone(Map<String, dynamic> zone) {
    final positions = <Point<int>>[];
    final map = state.map;
    final preferredTerrain = List<String>.from(zone['preferredTerrain']);
    
    final minX = (zone['minX'] as int).clamp(0, map[0].length - 1);
    final maxX = (zone['maxX'] as int).clamp(0, map[0].length - 1);
    final minY = (zone['minY'] as int).clamp(0, map.length - 1);
    final maxY = (zone['maxY'] as int).clamp(0, map.length - 1);
    
    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        final terrain = map[y][x];
        // 优先选择偏好地形，但也接受其他可行走地形
        if (preferredTerrain.contains(terrain) || 
            (terrain != 'wall' && terrain != 'water' && terrain != 'building')) {
          positions.add(Point(x, y));
        }
      }
    }
    
    return positions;
  }

  /// 检查位置是否适合作为出生点
  bool _isValidSpawnPosition(Point<int> position, double minDistance, double maxDistance) {
    // 检查地形是否可行走
    final terrain = state.map[position.y][position.x];
    if (terrain == 'wall' || terrain == 'water') {
      return false;
    }

    // 检查与鬼的距离
    for (final ghost in state.ghostManager.ghosts) {
      if (ghost.position != null) {
        final distance = _calculateDistance(position, ghost.position!);
        if (distance < minDistance || distance > maxDistance) {
          return false;
        }
      }
    }

    return true;
  }

  /// 寻找一个距离鬼适中的位置
  Point<int> _findBalancedSpawnPosition() {
    final walkablePositions = _getWalkablePositions();
    Point<int>? bestPosition;
    double bestScore = -1;

    for (final position in walkablePositions) {
      double totalDistance = 0;
      int ghostCount = 0;

      for (final ghost in state.ghostManager.ghosts) {
        if (ghost.position != null) {
          totalDistance += _calculateDistance(position, ghost.position!);
          ghostCount++;
        }
      }

      if (ghostCount > 0) {
        final averageDistance = totalDistance / ghostCount;
        // 寻找平均距离在30-60之间的位置
        if (averageDistance >= 30 && averageDistance <= 60) {
          final score = 60 - (averageDistance - 45).abs(); // 45是理想距离
          if (score > bestScore) {
            bestScore = score;
            bestPosition = position;
          }
        }
      }
    }

    return bestPosition ?? walkablePositions.first;
  }

  /// 计算两点之间的距离
  double _calculateDistance(Point<int> point1, Point<int> point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// 初始化商店
  void _initializeShop() {
    // 在地图中找到商店位置（假设在坐标 (5, 5)）
    final shopPosition = Point<int>(5, 5);
    final shop = Shop(
      position: shopPosition,
      items: [],
      lastPriceChange: DateTime.now(),
    );
    
    // 刷新商店商品
    shop.refreshItems();
    
    state = state.copyWith(schoolShop: shop);
  }

  /// 启动移动定时器
  void _startMovementTimer() {
    // 先取消现有定时器
    _movementTimer?.cancel();
    
    // 启动新的移动定时器
    _movementTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateMovement();
    });
    
  }

  /// 启动视野更新定时器（降低频率以提高性能）
  void _startVisionUpdateTimer() {
    _visionUpdateTimer = Timer.periodic(
      const Duration(milliseconds: _visionUpdateInterval), 
      (timer) {
        _updateVision();
      }
    );
  }

  /// 启动平滑视野动画定时器（高频率更新以保证流畅性）
  void _startSmoothVisionTimer() {
    _smoothVisionTimer = Timer.periodic(
      const Duration(milliseconds: _smoothVisionUpdateInterval), 
      (timer) {
        _updateSmoothVisionAnimations();
      }
    );
  }

  /// 启动脱离卡死状态更新定时器
  void _startUnstuckTimer() {
    _unstuckTimer = Timer.periodic(
      const Duration(milliseconds: 100), // 每100ms检查一次
      (timer) {
        _updateUnstuckState();
      }
    );
  }

  /// 启动饥饿扣血定时器
  void _startHungerTimer() {
    _hungerTimer = Timer.periodic(
      const Duration(seconds: 1), // 每秒检查一次
      (timer) {
        _updateHungerDamage();
      }
    );
  }

  /// 启动技能冷却时间更新定时器
  void _startSkillCooldownTimer() {
    _skillCooldownTimer = Timer.periodic(
      const Duration(milliseconds: 100), // 每100ms更新一次冷却状态
      (timer) {
        _updateSkillCooldowns();
      }
    );
  }

  /// 启动独立的游戏循环定时器
  void _startGameLoopTimer() {
    _gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: 500), // 每500ms强制刷新一次UI
      (timer) {
        _updateGameLoop();
      }
    );
  }

  /// 启动独立的死亡判定定时器
  void _startDeathCheckTimer() {
    _deathCheckTimer = Timer.periodic(
      const Duration(milliseconds: 200), // 每200ms检查一次死亡条件
      (timer) {
        _checkGameOverConditions();
      }
    );
  }

  /// 独立的游戏循环更新，确保UI定期刷新
  void _updateGameLoop() {
    // 强制触发UI更新，确保技能倒计时、视野等元素能够实时显示
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // 通过更新动画帧计数器来强制触发UI刷新
    // 这确保了即使玩家不移动，UI也会定期更新
    state = state.copyWith(
      lastAnimationFrame: currentTime,
    );
  }

  /// 更新脱离卡死状态
  void _updateUnstuckState() {
    final now = DateTime.now();
    bool needsUpdate = false;
    
    // 检查无视地形模式是否应该结束
    if (state.isNoClipMode && 
        state.noClipEndTime != null && 
        now.isAfter(state.noClipEndTime!)) {
      state = state.copyWith(
        isNoClipMode: false,
        noClipEndTime: null,
      );
      needsUpdate = true;
      print('无视地形模式已结束');
    }
    
    // 如果有更新，触发UI刷新
    if (needsUpdate) {
      // 状态已经更新，StateNotifier会自动通知监听者
    }
  }

  /// 安全更新角色状态，防止竞争条件
  void _safeUpdateCharacterStats(Map<String, dynamic> Function(Map<String, dynamic>) updateFunction, String debugInfo) {
    if (_isUpdatingStats) {
      return;
    }
    
    _isUpdatingStats = true;
    try {
      // 获取最新状态
      final currentStats = Map<String, dynamic>.from(state.characterStats);
      
      // 应用更新函数
      final updatedStats = updateFunction(currentStats);
      
      // 更新状态
      state = state.copyWith(characterStats: updatedStats);
    } finally {
      _isUpdatingStats = false;
    }
  }

  /// 更新饥饿扣血逻辑
  void _updateHungerDamage() {
    _safeUpdateCharacterStats((currentStats) {
      final currentFood = currentStats['food'] ?? 0;
      final currentHp = currentStats['hp'] ?? 0;
      

      
      // 当饱食度为0且生命值大于0时，每秒扣1生命值
      if (currentFood <= 0 && currentHp > 0) {
        final damageAmount = 1.0; // 饥饿扣血量
        final newHp = (currentHp - damageAmount).clamp(0, currentStats['maxHp'] ?? 100);
        

        
        // 检测生命值变化并触发伤害效果
        final hpChanged = currentHp != newHp;
        
        if (hpChanged) {
          // 更新生命值
          final updatedStats = Map<String, dynamic>.from(currentStats);
          updatedStats['hp'] = newHp.toDouble();
          
          // 更新其他状态
          state = state.copyWith(
            lastHp: currentHp.toDouble(),
            shouldShowDamageEffect: true,
            lastDamageAmount: damageAmount,
          );
          
          // 添加饥饿伤害播报消息
          addBroadcastMessage(
            '饥饿扣血 -${damageAmount.toStringAsFixed(1)}',
            BroadcastMessageType.damage,
          );
          
          // 检查是否死亡
          if (newHp <= 0) {
            // 这里可以触发游戏结束逻辑
          }
          
          return updatedStats;
        }
      }
      
      // 没有变化，返回原状态
      return currentStats;
    }, '饥饿系统扣血');
  }

  /// 优化的移动更新
  void _updateMovement() {
    final movement = state.movementState;
    final position = state.playerPosition;
    
    // 如果没有移动输入且速度为0，跳过计算
    if (!movement.isMoving && 
        movement.velocityX.abs() < 0.01 && 
        movement.velocityY.abs() < 0.01) {
      return;
    }
    
    // 计算基于玩家移动速度的最大速度（缓存计算结果）
    final baseSpeed = state.characterStats['moveSpeed'] ?? 100.0;
    final currentMaxSpeed = (baseSpeed / 20.0).clamp(0.1, double.infinity); // 移除上限，只保留最小值0.1防止零速度
    
    // 计算目标速度
    final targetVelocityX = movement.joystickX * currentMaxSpeed * movement.joystickIntensity;
    final targetVelocityY = movement.joystickY * currentMaxSpeed * movement.joystickIntensity;
    
    // 应用加速度或摩擦力
    double newVelocityX, newVelocityY;
    
    if (movement.isMoving) {
      // 加速到目标速度
      newVelocityX = movement.velocityX + (targetVelocityX - movement.velocityX) * _acceleration * _deltaTime;
      newVelocityY = movement.velocityY + (targetVelocityY - movement.velocityY) * _acceleration * _deltaTime;
    } else {
      // 应用摩擦力减速
      newVelocityX = movement.velocityX * (1.0 - _friction * _deltaTime);
      newVelocityY = movement.velocityY * (1.0 - _friction * _deltaTime);
      
      // 速度很小时直接停止
      if (newVelocityX.abs() < 0.01) newVelocityX = 0.0;
      if (newVelocityY.abs() < 0.01) newVelocityY = 0.0;
    }
    
    // 计算新位置
    final newX = position.x + newVelocityX * _deltaTime;
    final newY = position.y + newVelocityY * _deltaTime;
    
    // 改进的碰撞检测 - 支持滑动移动
    double finalX = position.x;
    double finalY = position.y;
    double finalVelocityX = newVelocityX;
    double finalVelocityY = newVelocityY;
    
    // 首先尝试完整移动
    if (_canMoveToPosition(newX, newY)) {
      finalX = newX;
      finalY = newY;
    } else {
      // 如果无法完整移动，尝试分别在X轴和Y轴上移动（滑动效果）
      bool canMoveX = _canMoveToPosition(newX, position.y);
      bool canMoveY = _canMoveToPosition(position.x, newY);
      
      if (canMoveX) {
        // 可以在X轴移动
        finalX = newX;
        finalY = position.y;
        // 保持X轴速度，停止Y轴速度
        finalVelocityY = 0.0;
      } else if (canMoveY) {
        // 可以在Y轴移动
        finalX = position.x;
        finalY = newY;
        // 保持Y轴速度，停止X轴速度
        finalVelocityX = 0.0;
      } else {
        // 两个方向都无法移动，停止所有速度
        finalX = position.x;
        finalY = position.y;
        finalVelocityX = 0.0;
        finalVelocityY = 0.0;
      }
    }
    
    // 创建新位置对象
    final newPosition = position.copyWith(x: finalX, y: finalY);
    final newMovement = movement.copyWith(
      velocityX: finalVelocityX,
      velocityY: finalVelocityY,
    );
    
    // 只有位置真正改变时才更新状态和应用地形效果
    if (newPosition != position || newMovement != movement) {
      // 检查是否需要开始脱离卡死冷却
      if (newPosition != position && state.isWaitingForMovement) {
        _startUnstuckCooldown();
      }
      
      // 计算移动距离
      double movementDistance = 0.0;
      if (newPosition != position) {
        movementDistance = _calculateMovementDistance(position, newPosition);
        
        // 累积移动距离
        final newAccumulatedDistance = state.accumulatedDistance + movementDistance;
        
        // 当累积距离达到1格时，应用地形效果
        if (newAccumulatedDistance >= 1.0) {
          final currentTerrain = _getCurrentTerrain();
          final gridsToProcess = newAccumulatedDistance.floor();
          
          // 应用地形效果
          _applyTerrainEffects(currentTerrain, gridsToProcess.toDouble());
          
          // 重置累积距离，保留小数部分
          final remainingDistance = newAccumulatedDistance - gridsToProcess;
          
          // 更新状态，包括新的累积距离
          state = state.copyWith(
            playerPosition: newPosition,
            movementState: newMovement,
            lastPosition: position,
            accumulatedDistance: remainingDistance,
          );
        } else {
          // 距离不足1格，只更新位置和累积距离
          state = state.copyWith(
            playerPosition: newPosition,
            movementState: newMovement,
            lastPosition: position,
            accumulatedDistance: newAccumulatedDistance,
          );
        }
      } else {
        // 位置没变，只更新移动状态
        state = state.copyWith(
          movementState: newMovement,
        );
      }
    }
  }

  /// 更新视野
  void _updateVision() {

    final playerGridPosition = Point(
      state.playerPosition.x.round(),
      state.playerPosition.y.round(),
    );
    
    // 检查是否需要强制更新视野（基于时间或精神值变化）
    final currentSanity = (state.characterStats['san'] ?? 100).toDouble();
    final maxSanity = (state.characterStats['maxSan'] ?? 100).toDouble();
    
    // 如果玩家网格位置没有改变且精神值没有显著变化，可以跳过视野计算
    // 但仍然需要更新平滑视野动画，所以不能完全跳过
    bool positionChanged = _lastPlayerGridPosition != playerGridPosition;
    
    // 即使位置没有变化，也要定期更新视野以支持动态效果
    // 这里我们移除了过于严格的缓存机制
    
    // 检查位置有效性
    if (playerGridPosition.x < 0 || 
        playerGridPosition.x >= state.map[0].length ||
        playerGridPosition.y < 0 || 
        playerGridPosition.y >= state.map.length) {
      return;
    }

    try {
      // 使用增强版视野系统获取带有可见性级别的瓦片（传递精神值）
      final tilesWithVisibility = _enhancedVisionSystem.getVisibleTilesWithLevel(
        playerGridPosition,
        sanityValue: currentSanity,
        maxSanity: maxSanity,
      );
      
      // 提取完全可见的瓦片用于兼容性
      final newVisibleTiles = tilesWithVisibility.entries
          .where((entry) => entry.value == TileVisibility.fullyVisible)
          .map((entry) => entry.key)
          .toSet();
      
      // 更新缓存（只在位置改变时更新位置缓存）
      if (positionChanged) {
        _lastPlayerGridPosition = playerGridPosition;
        _cachedVisibleTiles = newVisibleTiles;
      }
      
      // 更新已探索区域
      final newVisibleMap = List.generate(
        state.visibleMap.length,
        (y) => List<bool>.from(state.visibleMap[y]),
      );
      
      for (final tile in newVisibleTiles) {
        if (tile.y >= 0 && tile.y < newVisibleMap.length &&
            tile.x >= 0 && tile.x < newVisibleMap[0].length) {
          newVisibleMap[tile.y][tile.x] = true;
        }
      }
      
      // 更新平滑视野管理器，使用新的可见性级别系统
      _smoothVisionManager.updateVisionWithLevels(tilesWithVisibility);
      
      // 始终更新状态以确保UI能够响应视野变化
      // 即使位置没有改变，精神值或其他因素可能影响视野
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      state = state.copyWith(
        visibleTiles: newVisibleTiles,
        visibleMap: newVisibleMap,
        lastAnimationFrame: currentTime, // 强制触发UI更新
      );
    } catch (e) {
      if (kDebugMode) {
        print('视野计算错误: $e');
      }
    }
  }

  /// 更新平滑视野动画
  void _updateSmoothVisionAnimations() {
    final needsRepaint = _smoothVisionManager.updateAnimations();
    
    // 如果动画有更新，触发重绘
    if (needsRepaint) {
      // 通过更新一个无关紧要的状态来触发重绘
      // 这里我们可以使用一个专门的动画帧计数器
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      state = state.copyWith(
        // 添加一个动画帧标识，用于触发重绘
        lastAnimationFrame: currentTime,
      );
    }
  }

  /// 精确的碰撞检测 - 优化贴墙移动体验
  bool _canMoveToPosition(double x, double y) {
    // 检查是否处于无视地形模式
    if (state.isNoClipMode) {
      final now = DateTime.now();
      // 检查无视地形模式是否已过期
      if (state.noClipEndTime != null && now.isAfter(state.noClipEndTime!)) {
        // 无视地形模式已过期，关闭该模式
        state = state.copyWith(
          isNoClipMode: false,
          noClipEndTime: null,
        );
        print('无视地形模式已结束');
      } else {
        // 仍在无视地形模式中，只检查地图边界
        final gridX = x.floor();
        final gridY = y.floor();
        return gridX >= 0 && gridX < state.map[0].length &&
               gridY >= 0 && gridY < state.map.length;
      }
    }
    
    // 计算角色的碰撞半径
    // sizeScale = 0.6, collisionScale = 0.8
    // 实际碰撞半径 = 0.6 * 0.8 * 0.5 = 0.24 瓦片单位
    const sizeScale = 0.6;
    const collisionScale = 0.8;
    final characterHalfSize = sizeScale * collisionScale * 0.5;
    
    // 添加水平偏移量，让角色更容易贴墙移动
    // 左边判定向左偏移，右边判定也向左偏移
    final horizontalOffset = 0.2; // 向左偏移0.2瓦片单位，接近角色半径大小
    
    final samplePoints = [
      Point(x, y), // 中心点
      // 四个角点 - 添加水平偏移优化贴墙体验
      Point(x - characterHalfSize - horizontalOffset, y - characterHalfSize), // 左上角（向左偏移）
      Point(x + characterHalfSize - horizontalOffset, y - characterHalfSize), // 右上角（向左偏移）
      Point(x - characterHalfSize - horizontalOffset, y + characterHalfSize), // 左下角（向左偏移）
      Point(x + characterHalfSize - horizontalOffset, y + characterHalfSize), // 右下角（向左偏移）
      // 四个边缘中点 - 添加水平偏移
      Point(x - characterHalfSize - horizontalOffset, y), // 左边缘中点（向左偏移）
      Point(x + characterHalfSize - horizontalOffset, y), // 右边缘中点（向左偏移）
      Point(x, y - characterHalfSize), // 上边缘中点（保持不变）
      Point(x, y + characterHalfSize), // 下边缘中点（保持不变）
    ];
    
    // 检查每个采样点是否在有效范围内且不与墙壁碰撞
    for (final point in samplePoints) {
      final gridX = point.x.floor();
      final gridY = point.y.floor();
      
      // 边界检查
      if (gridX < 0 || gridX >= state.map[0].length ||
          gridY < 0 || gridY >= state.map.length) {
        return false;
      }
      
      // 墙壁碰撞检测
      if (state.map[gridY][gridX] == 'wall') {
        return false;
      }
    }
    
    return true;
  }

  /// 摇杆移动
  void onJoystickMove(double x, double y, double intensity) {
    // 如果正在使用物品或探索宝箱，禁止移动
    if (state.isUsingItem || state.isExploringChest) {
      return;
    }
    
    final movement = state.movementState;
    final position = state.playerPosition;
    
    final newMovement = movement.copyWith(
      joystickX: x,
      joystickY: y,
      joystickIntensity: intensity,
      isMoving: intensity > 0.1,
    );
    
    final newPosition = position.copyWith(
      facingRight: x.abs() > 0.1 ? x > 0 : position.facingRight,
    );
    
    // 只有状态真正改变时才更新
    if (newMovement != movement || newPosition != position) {
      state = state.copyWith(
        movementState: newMovement,
        playerPosition: newPosition,
      );
    }
  }

  /// 摇杆停止
  void onJoystickStop() {
    final movement = state.movementState;
    
    final newMovement = movement.copyWith(
      joystickX: 0.0,
      joystickY: 0.0,
      joystickIntensity: 0.0,
      isMoving: false,
    );
    
    if (newMovement != movement) {
      state = state.copyWith(movementState: newMovement);
    }
  }

  /// 切换背包显示
  void toggleInventory() {
    state = state.copyWith(showInventory: !state.showInventory);
  }

  /// 打开背包
  void openInventory() {
    state = state.copyWith(showInventory: true);
  }

  /// 关闭背包
  void closeInventory() {
    state = state.copyWith(showInventory: false);
  }

  /// 切换角色信息面板显示
  void toggleCharacterInfo() {
    state = state.copyWith(showCharacterInfo: !state.showCharacterInfo);
  }

  /// 切换商店显示
  void toggleShop() {
    state = state.copyWith(showShop: !state.showShop);
  }

  /// 检查玩家是否靠近宝箱
  bool isNearChest() {
    // 玩家像素坐标转换为网格坐标
    // 注意：玩家初始位置(10.0, 10.0)对应网格(0, 0)，所以需要先减去偏移量
    final playerGridX = ((state.playerPosition.x - 10.0) / 40).round();
    final playerGridY = ((state.playerPosition.y - 10.0) / 40).round();
    final playerPos = Point(playerGridX, playerGridY);
    
    print('isNearChest - 玩家位置: 像素(${state.playerPosition.x}, ${state.playerPosition.y}), 网格($playerGridX, $playerGridY)');
    print('isNearChest - 宝箱数量: ${state.chestPositions.length}');
    
    for (final chestPos in state.chestPositions) {
      final distance = _calculateDistance(playerPos, chestPos);
      print('isNearChest - 宝箱位置: (${chestPos.x}, ${chestPos.y}), 距离: $distance');
      if (distance <= 1.5) { // 允许1.5格的交互距离
        print('isNearChest - 玩家靠近宝箱，距离: $distance <= 1.5');
        return true;
      }
    }
    print('isNearChest - 玩家不靠近任何宝箱');
    return false;
  }

  /// 打开指定位置的宝箱（点击时使用）
  void openChestAtPosition(Point<int> chestPosition) {
    
    // 检查宝箱是否存在
    if (!state.chestPositions.contains(chestPosition)) {
      print('openChestAtPosition - 宝箱不存在于指定位置');
      return;
    }

    // 如果已经在探索宝箱，则取消当前探索
    if (state.isExploringChest) {
      cancelChestExploration();
    }
    
    // 开始宝箱探索进度
    state = state.copyWith(
      isExploringChest: true,
      currentExploringChest: chestPosition,
      chestExplorationProgress: 0.0,
      chestExplorationStartTime: DateTime.now(),
    );
    
    // 启动宝箱探索计时器
    _startChestExplorationTimer(chestPosition);
    
    // 显示开始探索的消息
    addBroadcastMessage('开始探索宝箱...', BroadcastMessageType.item);
    print('openChestAtPosition - 开始探索宝箱: (${chestPosition.x}, ${chestPosition.y})');
  }

  /// 打开宝箱（原有的距离检查方法）
  void openChest() {
    print('openChest - 开始执行');
    if (!isNearChest()) {
      print('openChest - 玩家不靠近宝箱，退出');
      return;
    }
    
    final playerGridX = ((state.playerPosition.x - 10.0) / 40).round();
    final playerGridY = ((state.playerPosition.y - 10.0) / 40).round();
    final playerPos = Point(playerGridX, playerGridY);
    
    print('openChest - 玩家位置: ($playerGridX, $playerGridY)');
    
    // 找到最近的宝箱
    Point<int>? nearestChest;
    double minDistance = double.infinity;
    
    for (final chestPos in state.chestPositions) {
      final distance = _calculateDistance(playerPos, chestPos);
      print('openChest - 检查宝箱: (${chestPos.x}, ${chestPos.y}), 距离: $distance');
      if (distance <= 1.5 && distance < minDistance) {
        minDistance = distance;
        nearestChest = chestPos;
        print('openChest - 找到更近的宝箱: (${chestPos.x}, ${chestPos.y}), 距离: $distance');
      }
    }
    
    if (nearestChest != null) {
      print('openChest - 找到最近宝箱: (${nearestChest.x}, ${nearestChest.y}), 距离: $minDistance');
      
      // 使用进度条机制打开宝箱
      openChestAtPosition(nearestChest);
    } else {
      print('openChest - 未找到可打开的宝箱');
    }
  }

  /// 获取宝箱随机物品
  List<Item> _getRandomChestItems() {
    final random = math.Random();
    final items = <Item>[];
    
    // 随机获得1-3个物品
    final itemCount = 1 + random.nextInt(3);
    
    for (int i = 0; i < itemCount; i++) {
      // 从所有物品中随机选择
      if (allItems.isNotEmpty) {
        final randomItem = allItems[random.nextInt(allItems.length)];
        items.add(randomItem);
      }
    }
    
    return items;
  }

  /// 获取适合放置宝箱的位置（只在草地和路径上）
  List<Point<int>> _getChestSuitablePositions() {
    final suitablePositions = <Point<int>>[];
    
    for (int y = 0; y < MapData.testMap.length; y++) {
      for (int x = 0; x < MapData.testMap[y].length; x++) {
        final terrain = MapData.testMap[y][x];
        // 只在草地和路径上放置宝箱，避免墙体、水域、建筑等
        if (terrain == 'grass' || terrain == 'path') {
          suitablePositions.add(Point(x, y));
        }
      }
    }
    
    return suitablePositions;
  }

  /// 随机生成宝箱位置
  List<Point<int>> _generateRandomChestPositions({int chestCount = 5}) {
    final random = math.Random();
    final suitablePositions = _getChestSuitablePositions();
    final chestPositions = <Point<int>>[];
    
    if (suitablePositions.isEmpty) {
      print('警告：没有找到适合放置宝箱的位置');
      return chestPositions;
    }
    
    // 确保不会生成超过可用位置数量的宝箱
    final maxChests = math.min(chestCount, suitablePositions.length);
    
    // 随机选择不重复的位置
    final selectedPositions = <Point<int>>[];
    while (selectedPositions.length < maxChests) {
      final randomIndex = random.nextInt(suitablePositions.length);
      final position = suitablePositions[randomIndex];
      
      // 确保位置不重复
      if (!selectedPositions.contains(position)) {
        selectedPositions.add(position);
      }
    }
    
    return selectedPositions;
  }

  /// 初始化宝箱位置
  void _initializeChests() {
    final initialChestPositions = _generateRandomChestPositions(chestCount: 5);
    state = state.copyWith(chestPositions: initialChestPositions);
    print('初始化宝箱位置，数量：${initialChestPositions.length}');
  }

  /// 刷新宝箱位置（在宝箱被打开后调用）
  void _refreshChestPositions() {
    final newChestPositions = _generateRandomChestPositions(chestCount: 5);
    state = state.copyWith(chestPositions: newChestPositions);
    print('宝箱位置已刷新，新位置: ${newChestPositions.map((p) => '(${p.x}, ${p.y})').join(', ')}');
  }

  /// 购买商品
  bool buyItem(ShopItem shopItem) {
    final character = state.characterStats;
    final currentMoney = character['gold'] ?? 0;
    
    // 检查是否有足够的金币和库存
    if (currentMoney < shopItem.currentPrice || shopItem.stock <= 0) {
      return false; // 金币不足或库存不足
    }
    
    // 扣除金币
    final updatedCharacter = Map<String, dynamic>.from(character);
    updatedCharacter['gold'] = currentMoney - shopItem.currentPrice;
    
    // 添加物品到背包
    final newInventory = List<Item>.from(state.playerInventory);
    newInventory.add(shopItem.item);
    
    // 减少商品库存
    shopItem.stock--;
    
    // 更新状态
    state = state.copyWith(
      characterStats: updatedCharacter,
      playerInventory: newInventory,
    );
    
    // 添加购买成功的播报消息
    addBroadcastMessage(
      '购买了 ${shopItem.item.name}',
      BroadcastMessageType.item,
    );
    
    return true; // 购买成功
  }

  /// 开始使用物品（启动进度条）
  bool useItem(Item item) {
    // 检查是否已经在使用物品
    if (state.isUsingItem) {
      return false; // 已经在使用物品，不能同时使用多个
    }
    
    // 检查物品是否在背包中
    final inventory = List<Item>.from(state.playerInventory);
    final itemIndex = inventory.indexWhere((i) => i.id == item.id);
    
    if (itemIndex == -1) {
      return false; // 物品不在背包中
    }
    
    // 关闭背包页面
    state = state.copyWith(showInventory: false);
    
    // 开始使用物品
    state = state.copyWith(
      isUsingItem: true,
      currentUsingItem: item,
      itemUsageProgress: 0.0,
      itemUsageStartTime: DateTime.now(),
    );
    
    // 启动物品使用计时器
    _startItemUsageTimer(item);
    
    // 添加开始使用物品的播报消息
    addBroadcastMessage(
      '开始使用 ${item.name}...',
      BroadcastMessageType.item,
    );
    
    return true; // 开始使用成功
  }
  
  /// 启动物品使用计时器
  void _startItemUsageTimer(Item item) {
    _itemUsageTimer?.cancel(); // 取消之前的计时器
    
    const updateInterval = Duration(milliseconds: 50); // 20fps更新
    final totalDuration = Duration(milliseconds: item.usageTime);
    
    _itemUsageTimer = Timer.periodic(updateInterval, (timer) {
      if (!state.isUsingItem || state.currentUsingItem?.id != item.id) {
        timer.cancel();
        return;
      }
      
      final elapsed = DateTime.now().difference(state.itemUsageStartTime!);
      final progress = (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
      
      if (progress >= 1.0) {
        // 使用完成，应用物品效果
        timer.cancel();
        _completeItemUsage(item);
      } else {
        // 更新进度
        state = state.copyWith(itemUsageProgress: progress);
      }
    });
  }

  /// 启动宝箱探索计时器
  void _startChestExplorationTimer(Point<int> chestPosition) {
    _chestExplorationTimer?.cancel(); // 取消之前的计时器
    
    const updateInterval = Duration(milliseconds: 50); // 20fps更新
    const totalDuration = Duration(seconds: 3); // 宝箱探索需要3秒
    
    _chestExplorationTimer = Timer.periodic(updateInterval, (timer) {
      if (!state.isExploringChest || state.currentExploringChest != chestPosition) {
        timer.cancel();
        return;
      }
      
      final elapsed = DateTime.now().difference(state.chestExplorationStartTime!);
      final progress = (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
      
      if (progress >= 1.0) {
        // 探索完成，打开宝箱
        timer.cancel();
        _completeChestExploration(chestPosition);
      } else {
        // 更新进度
        state = state.copyWith(chestExplorationProgress: progress);
      }
    });
  }

  /// 完成宝箱探索，获得物品
  void _completeChestExploration(Point<int> chestPosition) {
    // 检查宝箱是否仍然存在
    if (!state.chestPositions.contains(chestPosition)) {
      // 宝箱已经不存在，重置状态
      state = state.copyWith(
        isExploringChest: false,
        currentExploringChest: null,
        chestExplorationProgress: 0.0,
        chestExplorationStartTime: null,
      );
      return;
    }
    
    // 移除已打开的宝箱
    final updatedChestPositions = List<Point<int>>.from(state.chestPositions);
    updatedChestPositions.remove(chestPosition);
    
    // 随机获得物品
    final randomItems = _getRandomChestItems();
    print('_completeChestExploration - 获得物品: ${randomItems.map((item) => item.name).toList()}');
    
    final updatedInventory = List<Item>.from(state.playerInventory);
    updatedInventory.addAll(randomItems);
    
    // 更新状态
    state = state.copyWith(
      chestPositions: updatedChestPositions,
      playerInventory: updatedInventory,
      isExploringChest: false,
      currentExploringChest: null,
      chestExplorationProgress: 0.0,
      chestExplorationStartTime: null,
    );
    
    // 显示获得物品的消息
    final itemNames = randomItems.map((item) => item.name).join('、');
    addBroadcastMessage('打开宝箱获得：$itemNames', BroadcastMessageType.item, duration: const Duration(seconds: 3));
    print('_completeChestExploration - 显示消息: 打开宝箱获得：$itemNames');
    
    // 自动刷新宝箱位置，保持地图上始终有宝箱
    _refreshChestPositions();
  }
  
  /// 完成物品使用，应用效果
  void _completeItemUsage(Item item) {
    // 检查物品是否在背包中
    final inventory = List<Item>.from(state.playerInventory);
    final itemIndex = inventory.indexWhere((i) => i.id == item.id);
    
    if (itemIndex == -1) {
      // 物品不在背包中，取消使用
      cancelItemUsage();
      return;
    }
    
    // 应用物品效果
    final character = Map<String, dynamic>.from(state.characterStats);
    bool hasEffect = false;
    
    item.effects.forEach((effectType, value) {
      switch (effectType) {
        case 'hp':
          final currentHp = character['hp'] ?? 100;
          final newHp = (currentHp + value).clamp(0, 100);
          character['hp'] = newHp;
          hasEffect = true;
          break;
        case 'food':
          final currentFood = character['food'] ?? 100;
          final newFood = (currentFood + value).clamp(0, 100);
          character['food'] = newFood;
          hasEffect = true;
          break;
        case 'san':
          final currentSan = character['san'] ?? 100;
          final newSan = (currentSan + value).clamp(0, double.infinity); // 移除上限限制，允许突破上限
          character['san'] = newSan;
          hasEffect = true;
          break;
        case 'moveSpeed':
          final currentSpeed = character['moveSpeed'] ?? 100;
          final newSpeed = (currentSpeed + value).clamp(1, double.infinity); // 移除上限，只保留最小值1防止负速度
          character['moveSpeed'] = newSpeed;
          hasEffect = true;
          break;
        case 'gold':
          final currentGold = character['gold'] ?? 0;
          final newGold = (currentGold + value).clamp(0, 999999);
          character['gold'] = newGold;
          hasEffect = true;
          break;
      }
    });
    
    if (hasEffect) {
      // 从背包中移除物品（如果数量大于1，则减少数量）
      if (item.count > 1) {
        inventory[itemIndex] = Item(
          id: item.id,
          name: item.name,
          image: item.image,
          description: item.description,
          effects: item.effects,
          type: item.type,
          count: item.count - 1,
          availableInShop: item.availableInShop,
          basePrice: item.basePrice,
          usageTime: item.usageTime,
        );
      } else {
        inventory.removeAt(itemIndex);
      }
      
      // 更新游戏状态
      state = state.copyWith(
        characterStats: character,
        playerInventory: inventory,
        isUsingItem: false,
        currentUsingItem: null,
        itemUsageProgress: 0.0,
        itemUsageStartTime: null,
      );
      
      // 添加使用完成的播报消息
      addBroadcastMessage(
        '使用了 ${item.name}',
        BroadcastMessageType.item,
      );
    } else {
      // 没有效果，取消使用
      cancelItemUsage();
    }
  }
  
  /// 取消物品使用
  void cancelItemUsage() {
    if (!state.isUsingItem) return;
    
    final item = state.currentUsingItem;
    
    // 取消计时器
    _itemUsageTimer?.cancel();
    
    // 消耗物品但不应用效果
    if (item != null) {
      final inventory = List<Item>.from(state.playerInventory);
      final itemIndex = inventory.indexWhere((i) => i.id == item.id);
      
      if (itemIndex != -1) {
        if (item.count > 1) {
          inventory[itemIndex] = Item(
            id: item.id,
            name: item.name,
            image: item.image,
            description: item.description,
            effects: item.effects,
            type: item.type,
            count: item.count - 1,
            availableInShop: item.availableInShop,
            basePrice: item.basePrice,
            usageTime: item.usageTime,
          );
        } else {
          inventory.removeAt(itemIndex);
        }
        
        // 更新背包
        state = state.copyWith(playerInventory: inventory);
        
        // 添加取消使用的播报消息
        addBroadcastMessage(
          '取消使用 ${item.name}，物品已消耗',
          BroadcastMessageType.item,
        );
      }
    }
    
    // 重置物品使用状态
    state = state.copyWith(
      isUsingItem: false,
      currentUsingItem: null,
      itemUsageProgress: 0.0,
      itemUsageStartTime: null,
    );
  }

  /// 取消宝箱探索
  void cancelChestExploration() {
    if (!state.isExploringChest) return;
    
    // 取消计时器
    _chestExplorationTimer?.cancel();
    
    // 重置宝箱探索状态，但不移除宝箱
    state = state.copyWith(
      isExploringChest: false,
      currentExploringChest: null,
      chestExplorationProgress: 0.0,
      chestExplorationStartTime: null,
    );
    
    // 添加取消探索的播报消息
    addBroadcastMessage(
      '取消探索宝箱',
      BroadcastMessageType.item,
    );
  }

  /// 触发游戏结束
  void triggerGameOver(String reason) {
    // 添加游戏结束的播报消息
    addBroadcastMessage(
      '游戏结束: $reason',
      BroadcastMessageType.system,
    );
    
    // 保存死亡时的数据快照
    final deathTimeStats = Map<String, dynamic>.from(state.characterStats);
    final deathTimeInventory = List<Item>.from(state.playerInventory);
    
    state = state.copyWith(
      isGameOver: true,
      deathReason: reason,
      gameEndTime: DateTime.now(),
      deathTimeStats: deathTimeStats,
      deathTimeInventory: deathTimeInventory,
    );
    
    // 停止所有计时器
    _movementTimer?.cancel();
    _visionUpdateTimer?.cancel();
    _deathCheckTimer?.cancel(); // 停止死亡判定定时器
  }



  /// 根据地形类型扣除角色状态
  void _applyTerrainEffects(String terrainType, double distance) {
    if (distance <= 0) return;
    
    // 检查是否有技能正在施法，施法期间不消耗饱食度和精神值
    final isAnyCasting = state.skillStates.values.any((skillState) => skillState.isCasting);
    if (isAnyCasting) {
      return;
    }
    
    _safeUpdateCharacterStats((currentStats) {
      final updatedStats = Map<String, dynamic>.from(currentStats);
      final random = Random();
      
      // 计算移动格数（每格约为1个单位距离）
      final gridsMoved = distance;
      
      switch (terrainType) {
        case 'grass': // 草地
          for (int i = 0; i < gridsMoved.ceil(); i++) {
            // 随机扣除0.5-1饱食度
            final foodDeduction = 0.5 + random.nextDouble() * 0.5;
            updatedStats['food'] = ((updatedStats['food'] ?? 0) - foodDeduction).clamp(0, 100);
            
            // 随机扣除0-1精神值
            final sanDeduction = random.nextDouble();
            updatedStats['san'] = ((updatedStats['san'] ?? 0) - sanDeduction).clamp(0, double.infinity); // 只限制下限，允许突破上限
          }
          break;
          
        case 'building': // 建筑里
          for (int i = 0; i < gridsMoved.ceil(); i++) {
            // 随机扣除0.2-1饱食度
            final foodDeduction = 0.2 + random.nextDouble() * 0.8;
            updatedStats['food'] = ((updatedStats['food'] ?? 0) - foodDeduction).clamp(0, 100);
            
            // 随机扣除0.8-2精神值
            final sanDeduction = 0.8 + random.nextDouble() * 1.2;
            updatedStats['san'] = ((updatedStats['san'] ?? 0) - sanDeduction).clamp(0, double.infinity); // 只限制下限，允许突破上限
          }
          break;
          
        case 'woods': // 树林里
          for (int i = 0; i < gridsMoved.ceil(); i++) {
            // 随机扣除0.5-1饱食度
            final foodDeduction = 0.5 + random.nextDouble() * 0.5;
            updatedStats['food'] = ((updatedStats['food'] ?? 0) - foodDeduction).clamp(0, 100);
            
            // 随机扣除0-1精神值
            final sanDeduction = random.nextDouble();
            updatedStats['san'] = ((updatedStats['san'] ?? 0) - sanDeduction).clamp(0, double.infinity); // 只限制下限，允许突破上限
            
            // 随机扣除0-0.5生命值
            final hpDeduction = random.nextDouble() * 0.5;
            updatedStats['hp'] = ((updatedStats['hp'] ?? 0) - hpDeduction).clamp(0, updatedStats['maxHp'] ?? 100);
          }
          break;
          
        case 'path': // 路上
          for (int i = 0; i < gridsMoved.ceil(); i++) {
            // 随机扣除0.2-0.5饱食度
            final foodDeduction = 0.2 + random.nextDouble() * 0.3;
            updatedStats['food'] = ((updatedStats['food'] ?? 0) - foodDeduction).clamp(0, 100);
            
            // 随机恢复0-0.5精神值
            final sanRecovery = random.nextDouble() * 0.5;
            updatedStats['san'] = ((updatedStats['san'] ?? 0) + sanRecovery).clamp(0, double.infinity); // 允许恢复时突破上限
          }
          break;
          
        default:
          // 其他地形类型暂时不扣除状态
          break;
      }
      
      return updatedStats;
    }, '移动系统地形效果-$terrainType');
  }

  /// 获取当前位置的地形类型
  String _getCurrentTerrain() {
    final position = state.playerPosition;
    final gridX = position.x.round().clamp(0, state.map[0].length - 1);
    final gridY = position.y.round().clamp(0, state.map.length - 1);
    
    return state.map[gridY][gridX];
  }

  /// 计算两点之间的距离
  double _calculateMovementDistance(OptimizedPlayerPosition from, OptimizedPlayerPosition to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// 检查游戏结束条件
  void _checkGameOverConditions() {
    // 如果游戏已经结束，立即停止判定
    if (state.isGameOver) {
      _deathCheckTimer?.cancel();
      return;
    }

    final position = state.playerPosition;
    final character = state.characterStats;
    
    // 检查生命值
    if (character['hp'] != null && character['hp'] <= 0) {
      _deathCheckTimer?.cancel(); // 立即停止死亡判定定时器
      triggerGameOver('生命值耗尽');
      return;
    }
    
    // 检查理智值
    if (character['san'] != null && character['san'] <= 0) {
      _deathCheckTimer?.cancel(); // 立即停止死亡判定定时器
      triggerGameOver('理智崩溃');
      return;
    }
    
    // 检查是否走到了特殊位置（比如出口）
    final gridX = position.x.round();
    final gridY = position.y.round();
    
    if (gridX >= 0 && gridX < state.map[0].length && 
        gridY >= 0 && gridY < state.map.length) {
      final tile = state.map[gridY][gridX];
      
      // 如果走到了特殊的结束位置
      if (tile == 'exit') {
        _deathCheckTimer?.cancel(); // 立即停止死亡判定定时器
        triggerGameOver('成功逃离学校！');
        return;
      }
    }
  }

  /// 脱离卡死功能 - 激活1秒无视地形移动模式
  void unstuckPlayer() {
    // 检查是否已经被 dispose
    if (!mounted) {
      print('unstuckPlayer: OptimizedGameStateNotifier 已被 dispose，跳过执行');
      return;
    }
    
    final now = DateTime.now();
    
    // 检查是否在冷却期间
    if (state.unstuckCooldownEnd != null && now.isBefore(state.unstuckCooldownEnd!)) {
      return;
    }
    
    // 激活无视地形模式，持续1秒
    final noClipEndTime = now.add(const Duration(seconds: 1));
    
    state = state.copyWith(
      isNoClipMode: true,
      noClipEndTime: noClipEndTime,
      isWaitingForMovement: true,  // 等待玩家移动以开始冷却
      unstuckActivatedTime: now,   // 记录激活时间
      unstuckCooldownEnd: null,    // 清除之前的冷却时间
    );
  }

  /// 开始脱离卡死冷却计时
  void _startUnstuckCooldown() {
    if (!state.isWaitingForMovement) return;
    
    final now = DateTime.now();
    final cooldownEndTime = now.add(const Duration(seconds: 60));
    
    state = state.copyWith(
      isWaitingForMovement: false,
      unstuckCooldownEnd: cooldownEndTime,
    );
  }

  /// 寻找最近的可移动空地
  Point<int>? _findNearestEmptySpace(int startX, int startY) {
    final mapHeight = state.map.length;
    final mapWidth = state.map[0].length;
    
    // 首先检查当前位置是否已经是可移动的
    if (_isEmptySpace(startX, startY)) {
      return Point(startX, startY);
    }
    
    // 使用广度优先搜索找到最近的空地
    final visited = <Point<int>>{};
    final queue = <Point<int>>[];
    
    queue.add(Point(startX, startY));
    visited.add(Point(startX, startY));
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      
      // 检查8个方向的相邻位置（包括对角线）
      final directions = [
        Point(0, -1),  // 上
        Point(0, 1),   // 下
        Point(-1, 0),  // 左
        Point(1, 0),   // 右
        Point(-1, -1), // 左上
        Point(1, -1),  // 右上
        Point(-1, 1),  // 左下
        Point(1, 1),   // 右下
      ];
      
      for (final direction in directions) {
        final newX = current.x + direction.x;
        final newY = current.y + direction.y;
        final newPoint = Point(newX, newY);
        
        // 检查边界和是否已访问
        if (newX >= 0 && newX < mapWidth &&
            newY >= 0 && newY < mapHeight &&
            !visited.contains(newPoint)) {
          
          visited.add(newPoint);
          
          // 检查这个位置是否是可移动的空地
          if (_isEmptySpace(newX, newY)) {
            return newPoint;
          }
          
          // 如果不是空地，加入队列继续搜索
          queue.add(newPoint);
        }
      }
    }
    
    // 如果没有找到空地，尝试寻找任何非墙壁位置
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (state.map[y][x] != 'wall' && state.map[y][x] != 'water') {
          return Point(x, y);
        }
      }
    }
    
    // 最后的备选方案：返回地图中心
    final centerX = mapWidth ~/ 2;
    final centerY = mapHeight ~/ 2;
    return Point(centerX, centerY);
  }

  /// 检查指定位置是否是可移动的空地
  bool _isEmptySpace(int x, int y) {
    if (x < 0 || x >= state.map[0].length || y < 0 || y >= state.map.length) {
      return false;
    }
    
    final tile = state.map[y][x];
    
    // 不可通行的地块类型
    final impassableTiles = {'wall', 'water', 'building'};
    
    // 如果不是不可通行的地块，则认为是可移动的
    // 这包括：grass, path, woods, exit, door, shop, chest 等
    return !impassableTiles.contains(tile);
  }

  /// 重置游戏状态
  void resetGame() {
    // 检查是否已经被 dispose，如果是则直接返回
    if (!mounted) {
      return;
    }
    
    // 停止所有计时器
    _movementTimer?.cancel();
    _visionUpdateTimer?.cancel();
    
    // 重置状态到初始值
    final currentCharacterStats = state.characterStats;
    final characterName = currentCharacterStats['name'] as String?;
    state = OptimizedGameState(
      characterStats: _createInitialCharacterStats(currentCharacterStats),
      playerPosition: const OptimizedPlayerPosition(x: 10.0, y: 10.0, facingRight: true),
      movementState: const OptimizedMovementState(),
      map: MapData.testMap,
      chestPositions: [],
      playerInventory: [],
      visibleTiles: {},
      visibleMap: List.generate(
        MapData.testMap.length,
        (y) => List.generate(MapData.testMap[0].length, (x) => false),
      ),
      ghostManager: GhostManager(map: MapData.testMap),
      showInventory: false,
      showCharacterInfo: false,
      showShop: false,
      isGameOver: false,
      deathReason: '',
      characterSkills: _initializeCharacterSkills(characterName),
      skillStates: _initializeSkillStates(characterName),
      gameStartTime: DateTime.now(),
      gameEndTime: null,
    );
    
    // 重新初始化游戏
    _initializeGame();
  }

  /// 重置伤害效果状态
  void resetDamageEffect() {
    state = state.copyWith(
      shouldShowDamageEffect: false,
      lastDamageAmount: 0.0,
    );
  }

  /// 添加播报消息
  void addBroadcastMessage(String text, BroadcastMessageType type, {Duration? duration}) {
    // 检查是否已存在相同的消息（相同文本和类型，且未过期）
    final now = DateTime.now();
    BroadcastMessage? existingMessage;
    try {
      existingMessage = state.broadcastMessages.firstWhere(
        (message) => 
          message.text == text && 
          message.type == type && 
          now.difference(message.timestamp) <= message.displayDuration,
      );
    } catch (e) {
      existingMessage = null;
    }
    
    // 如果找到相同且未过期的消息，则不添加新消息
    if (existingMessage != null) {
      return;
    }
    
    final message = BroadcastMessage(
      text: text,
      type: type,
      timestamp: DateTime.now(),
      displayDuration: duration ?? const Duration(seconds: 3),
    );
    
    final updatedMessages = List<BroadcastMessage>.from(state.broadcastMessages)
      ..add(message);
    
    // 限制消息数量，最多保留10条
    if (updatedMessages.length > 10) {
      updatedMessages.removeAt(0);
    }
    
    state = state.copyWith(broadcastMessages: updatedMessages);
  }

  /// 清理过期的播报消息
  void cleanupExpiredMessages() {
    final now = DateTime.now();
    final activeMessages = state.broadcastMessages
        .where((message) => now.difference(message.timestamp) <= message.displayDuration)
        .toList();
    
    if (activeMessages.length != state.broadcastMessages.length) {
      state = state.copyWith(broadcastMessages: activeMessages);
    }
  }

  /// 清除所有播报消息
  void clearAllBroadcastMessages() {
    state = state.copyWith(broadcastMessages: []);
  }



  /// 获取平滑视野管理器
  SmoothVisionManager? get smoothVisionManager => _smoothVisionManager;

  // ===== 技能系统相关方法 =====
  
  /// 使用技能
  void useSkill(String skillId) {
    final skillState = state.skillStates[skillId];
    if (skillState == null) {
      return;
    }
    
    // 获取技能数据
    final skill = SkillData.getSkillById(skillId);
    if (skill == null) {
      return;
    }
    
    // 检查技能是否在冷却中
    if (skillState.isOnCooldown(skill.cooldownSeconds)) {
      final remainingTime = skillState.getRemainingCooldown(skill.cooldownSeconds);
      addBroadcastMessage(
        '技能冷却中，剩余 $remainingTime 秒',
        BroadcastMessageType.system,
      );
      return;
    }
    
    // 检查技能是否正在使用中
    if (skillState.isCurrentlyCasting) {
      addBroadcastMessage(
        '技能正在使用中',
        BroadcastMessageType.system,
      );
      return;
    }
    
    // 开始使用技能
    _startSkillExecution(skill, skillState);
  }
  
  /// 开始执行技能
  void _startSkillExecution(Skill skill, SkillState skillState) {

    final now = DateTime.now();
    
    // 更新技能状态为施法状态
    final updatedSkillStates = Map<String, SkillState>.from(state.skillStates);
    updatedSkillStates[skill.id] = skillState.copyWith(
      isCasting: true,
      castStartTime: now,
    );
    
    state = state.copyWith(
      skillStates: updatedSkillStates,
      currentCastingSkillId: skill.id,
      castingProgress: 0.0,
    );

    
    // 添加技能开始使用的播报消息
    addBroadcastMessage(
      '开始使用技能: ${skill.name}',
      BroadcastMessageType.system,
    );
    
    // 设置技能执行完成的定时器
    Timer(Duration(seconds: skill.castTimeSeconds), () {
      _completeSkillExecution(skill);
    });
  }
  
  /// 完成技能执行
  void _completeSkillExecution(Skill skill) {
    final now = DateTime.now();
    final skillState = state.skillStates[skill.id];
    
    if (skillState == null || !skillState.isCurrentlyCasting) {
      return;
    }
    
    // 先更新技能状态：结束施法状态，开始冷却
    final updatedSkillStates = Map<String, SkillState>.from(state.skillStates);
    updatedSkillStates[skill.id] = skillState.copyWith(
      isCasting: false,
      castStartTime: null,
      lastUsedTime: now,
    );
    
    // 更新技能状态到当前state中，清除施法状态
    state = state.copyWith(
      skillStates: updatedSkillStates,
      currentCastingSkillId: null,
      castingProgress: 0.0,
    );
    
    // 应用技能效果（这会进一步更新state）
    _applySkillEffects(skill);
    
    // 添加技能完成的播报消息
    addBroadcastMessage(
      '技能 ${skill.name} 使用完成',
      BroadcastMessageType.system,
    );
  }
  
  /// 应用技能效果
  void _applySkillEffects(Skill skill) {
    // 特殊处理烹饪技能
    if (skill.id == 'cooking') {
      _applyCookingSkillEffect(skill);
      return;
    }
    
    final effect = skill.effect;
    final newStats = Map<String, dynamic>.from(state.characterStats);
    
    // 应用技能效果并收集结果消息
    final effectResults = effect.apply();
    final messages = <String>[];
    
    // 处理各种效果
    effectResults.forEach((effectType, value) {
      switch (effectType) {
        case 'health':
          final currentHp = (newStats['hp'] ?? 0).toDouble();
          final maxHp = (newStats['maxHp'] ?? 100).toDouble();
          final newHp = (currentHp + value).clamp(0, maxHp);
          newStats['hp'] = newHp;
          messages.add('恢复生命值 +$value (${currentHp.toStringAsFixed(1)} → ${newHp.toStringAsFixed(1)})');
          break;
        case 'sanity':
          final currentSan = (newStats['san'] ?? 0).toDouble();
          final maxSan = (newStats['maxSan'] ?? 100).toDouble();
          final newSan = (currentSan + value).clamp(0, double.infinity); // 允许技能恢复时突破上限
          newStats['san'] = newSan;
          messages.add('恢复精神值 +$value (${currentSan.toStringAsFixed(1)} → ${newSan.toStringAsFixed(1)})');
          break;
        case 'food':
          final currentFood = (newStats['food'] ?? 0).toDouble();
          final maxFood = 100.0; // 饱食度最大值固定为100
          final newFood = (currentFood + value).clamp(0, maxFood);
          newStats['food'] = newFood;
          messages.add('恢复饱食度 +${value.toStringAsFixed(1)} (${currentFood.toStringAsFixed(1)} → ${newFood.toStringAsFixed(1)})');
          break;
        case 'gold':
          final currentGold = (newStats['gold'] ?? 0).toDouble();
          final newGold = currentGold + value;
          newStats['gold'] = newGold;
          messages.add('获得金币 +$value (${currentGold.toStringAsFixed(0)} → ${newGold.toStringAsFixed(0)})');
          break;
        case 'damage':
          // 伤害效果暂时不实现
          break;
      }
    });
    
    // 创建播报消息列表
    final broadcastMessages = <BroadcastMessage>[];
    for (final message in messages) {
      broadcastMessages.add(BroadcastMessage(
        text: message,
        type: BroadcastMessageType.heal,
        timestamp: DateTime.now(),
        displayDuration: const Duration(seconds: 3),
      ));
    }
    
    // 合并现有播报消息
    final updatedMessages = List<BroadcastMessage>.from(state.broadcastMessages)
      ..addAll(broadcastMessages);
    
    // 限制消息数量
    while (updatedMessages.length > 10) {
      updatedMessages.removeAt(0);
    }
    
    // 一次性更新所有状态，确保状态变化被正确传播
    state = state.copyWith(
      characterStats: newStats,
      broadcastMessages: updatedMessages,
      // 使用动画帧标识确保状态变化被检测到
      lastAnimationFrame: state.lastAnimationFrame + 1,
    );
  }

  /// 应用烹饪技能特殊效果
  void _applyCookingSkillEffect(Skill skill) {
    // 确保获取最新的游戏状态
    final currentState = state;
    final newStats = Map<String, dynamic>.from(currentState.characterStats);
    final messages = <String>[];
    final random = Random();
    
    // 烹饪技能：不需要食物，等待施法时间后获得随机属性
    messages.add('烹饪完成！制作了美味的料理');
    
    // 随机生命值 1-10
    final hpGain = random.nextInt(10) + 1;
    final currentHp = (newStats['hp'] ?? 0).toDouble();
    final maxHp = (newStats['maxHp'] ?? 100).toDouble();
    final newHp = (currentHp + hpGain).clamp(0, maxHp);
    newStats['hp'] = newHp;
    messages.add('恢复生命值 +$hpGain (${currentHp.toStringAsFixed(1)} → ${newHp.toStringAsFixed(1)})');
    
    // 随机精神值 1-10
    final sanGain = random.nextInt(10) + 1;
    final currentSan = (newStats['san'] ?? 0).toDouble();
    final maxSan = (newStats['maxSan'] ?? 100).toDouble();
    final newSan = (currentSan + sanGain).clamp(0, double.infinity); // 允许恢复时突破上限
    newStats['san'] = newSan;
    messages.add('恢复精神值 +$sanGain (${currentSan.toStringAsFixed(1)} → ${newSan.toStringAsFixed(1)})');
    
    // 随机饱食度 10-50
    final foodGain = random.nextInt(41) + 10; // 10-50的随机数
    final currentFood = (newStats['food'] ?? 0).toDouble();
    final maxFood = 100.0; // 饱食度最大值固定为100
    final newFood = (currentFood + foodGain).clamp(0, maxFood);
    newStats['food'] = newFood;
    messages.add('恢复饱食度 +$foodGain (${currentFood.toStringAsFixed(1)} → ${newFood.toStringAsFixed(1)})');
    
    // 立即更新状态并强制通知UI
    
    // 创建播报消息列表
    final broadcastMessages = <BroadcastMessage>[];
    for (final message in messages) {
      broadcastMessages.add(BroadcastMessage(
        text: message,
        type: BroadcastMessageType.heal,
        timestamp: DateTime.now(),
        displayDuration: const Duration(seconds: 3),
      ));
    }
    
    // 合并现有播报消息
    final updatedMessages = List<BroadcastMessage>.from(state.broadcastMessages)
      ..addAll(broadcastMessages);
    
    // 限制消息数量
    while (updatedMessages.length > 10) {
      updatedMessages.removeAt(0);
    }
    
    // 使用copyWith确保状态更新被正确传播，一次性更新所有状态
    final oldState = state;
    state = state.copyWith(
      characterStats: newStats,
      broadcastMessages: updatedMessages,
      // 使用动画帧标识确保状态变化被检测到
      lastAnimationFrame: state.lastAnimationFrame + 1,
    );
    

  }



  /// 取消技能施法
  void cancelSkillCasting() {
    
    // 查找当前正在施法的技能
    String? castingSkillId;
    SkillState? castingSkillState;
    
    for (final entry in state.skillStates.entries) {
      if (entry.value.isCurrentlyCasting) {
        castingSkillId = entry.key;
        castingSkillState = entry.value;
        break;
      }
    }
    
    if (castingSkillId == null || castingSkillState == null) {
      return;
    }
    
    // 获取技能数据
    final skill = SkillData.getSkillById(castingSkillId);
    if (skill == null) {
      return;
    }
    
    final now = DateTime.now();
    
    // 更新技能状态：结束施法，设置一半冷却时间
    final updatedSkillStates = Map<String, SkillState>.from(state.skillStates);
    updatedSkillStates[castingSkillId] = castingSkillState.copyWith(
      isCasting: false,
      castStartTime: null,
      lastUsedTime: now, // 设置为当前时间，这样冷却时间会是一半
    );
    
    // 更新游戏状态
    state = state.copyWith(
      skillStates: updatedSkillStates,
      currentCastingSkillId: null,
      castingProgress: 0.0,
    );
    
    // 添加取消施法的播报消息
    addBroadcastMessage(
      '取消施法: ${skill.name}（冷却时间减半）',
      BroadcastMessageType.system,
    );
  }

  /// 更新技能冷却状态和施法进度
  void _updateSkillCooldowns() {
    final now = DateTime.now();
    bool hasUpdates = false;
    final updatedSkillStates = Map<String, SkillState>.from(state.skillStates);
    String? currentCastingSkillId;
    double castingProgress = 0.0;
    
    // 检查所有技能的冷却状态和施法进度
    updatedSkillStates.forEach((skillId, skillState) {
      // 检查施法进度
      if (skillState.isCurrentlyCasting && skillState.castStartTime != null) {
        final skill = SkillData.getSkillById(skillId);
        if (skill != null) {
          final castDuration = Duration(seconds: skill.castTimeSeconds);
          final elapsed = now.difference(skillState.castStartTime!);
          final progress = (elapsed.inMilliseconds / castDuration.inMilliseconds).clamp(0.0, 1.0);
          
          currentCastingSkillId = skillId;
          castingProgress = progress;
          hasUpdates = true;
          
          // 如果施法时间已完成，这里不处理，让定时器处理
        }
      }
      // 如果技能正在冷却中，检查是否已经冷却完成
      if (skillState.lastUsedTime != null) {
        final skill = SkillData.getSkillById(skillId);
        if (skill != null) {
          final timeSinceLastUse = now.difference(skillState.lastUsedTime!);
          final cooldownDuration = Duration(seconds: skill.cooldownSeconds);
          
          // 检查冷却状态变化，强制更新UI以显示倒计时
          hasUpdates = true; // 始终标记为有更新，确保UI能显示实时倒计时
          
          // 如果冷却时间已过，可以清除lastUsedTime（可选）
          if (timeSinceLastUse >= cooldownDuration && skillState.lastUsedTime != null) {
            // 技能冷却完成，可以选择清除lastUsedTime或保留用于UI显示
            // 这里我们保留lastUsedTime，让UI层决定如何显示
          }
        }
      }
    });
    
    // 强制更新状态以触发UI刷新，确保技能倒计时和施法进度能实时显示
    if (hasUpdates || state.skillStates.isNotEmpty) {
      // 通过更新一个时间戳来强制触发UI刷新
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      state = state.copyWith(
        skillStates: updatedSkillStates,
        currentCastingSkillId: currentCastingSkillId,
        castingProgress: castingProgress,
        lastAnimationFrame: currentTime, // 使用动画帧计数器来触发UI更新
      );
    }
  }
  
  /// 获取技能状态（用于UI显示）
  SkillState? getSkillState(String skillId) {
    return state.skillStates[skillId];
  }
  
  /// 获取角色的技能列表
  List<Skill> getCharacterSkills() {
    return state.characterSkills;
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _visionUpdateTimer?.cancel();
    _smoothVisionTimer?.cancel();
    _unstuckTimer?.cancel();
    _hungerTimer?.cancel();
    _skillCooldownTimer?.cancel();
    _gameLoopTimer?.cancel();
    _deathCheckTimer?.cancel();
    _itemUsageTimer?.cancel();
    _chestExplorationTimer?.cancel();
    super.dispose();
  }
}

/// 优化的游戏状态提供者
final optimizedGameStateProvider = StateNotifierProvider<OptimizedGameStateNotifier, OptimizedGameState>((ref) {
  // 使用厨师角色作为默认角色
  return OptimizedGameStateNotifier(manData[0]); // 使用manData中的第一个角色（厨师）
});

/// 优化的玩家位置提供者
final optimizedPlayerPositionProvider = Provider<OptimizedPlayerPosition>((ref) {
  return ref.watch(optimizedGameStateProvider).playerPosition;
});

/// 优化的移动状态提供者
final optimizedMovementStateProvider = Provider<OptimizedMovementState>((ref) {
  return ref.watch(optimizedGameStateProvider).movementState;
});

/// 优化的可见区域提供者
final optimizedVisibleTilesProvider = Provider<Set<Point<int>>>((ref) {
  return ref.watch(optimizedGameStateProvider).visibleTiles;
});