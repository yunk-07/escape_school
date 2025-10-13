// game/optimized_game_state.dart
// 性能优化的游戏状态管理器

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escape_from_school/data/mapData.dart';
import 'package:escape_from_school/data/props.dart';
import 'package:escape_from_school/data/shop.dart';
import 'package:escape_from_school/data/manData.dart';
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
  final OptimizedPlayerPosition playerPosition;
  final OptimizedMovementState movementState;
  final List<List<String>> map;
  final List<Point<int>> chestPositions;
  final List<Item> playerInventory;
  final Set<Point<int>> visibleTiles;
  final List<List<bool>> visibleMap;
  final String explorationResult;
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
  
  // 移动距离计算相关状态
  final OptimizedPlayerPosition? lastPosition;  // 上一次位置，用于计算移动距离
  final double accumulatedDistance;             // 累积移动距离
  
  // 生命值变化检测相关状态
  final double? lastHp;                         // 上一次的生命值，用于检测变化
  final bool shouldShowDamageEffect;            // 是否应该显示伤害效果
  final double lastDamageAmount;                // 最后一次的伤害量
  
  // 平滑视野动画相关状态
  final int lastAnimationFrame;                 // 最后一次动画帧标识，用于触发重绘

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
    this.explorationResult = '',
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
    this.lastPosition,
    this.accumulatedDistance = 0.0,
    this.lastHp,
    this.shouldShowDamageEffect = false,
    this.lastDamageAmount = 0.0,
    this.lastAnimationFrame = 0,
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
    String? explorationResult,
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
    OptimizedPlayerPosition? lastPosition,
    double? accumulatedDistance,
    double? lastHp,
    bool? shouldShowDamageEffect,
    double? lastDamageAmount,
    int? lastAnimationFrame,
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
      explorationResult: explorationResult ?? this.explorationResult,
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
      lastPosition: lastPosition ?? this.lastPosition,
      accumulatedDistance: accumulatedDistance ?? this.accumulatedDistance,
      lastHp: lastHp ?? this.lastHp,
      shouldShowDamageEffect: shouldShowDamageEffect ?? this.shouldShowDamageEffect,
      lastDamageAmount: lastDamageAmount ?? this.lastDamageAmount,
      lastAnimationFrame: lastAnimationFrame ?? this.lastAnimationFrame,
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

/// 优化的游戏状态管理器
class OptimizedGameStateNotifier extends StateNotifier<OptimizedGameState> {
  Timer? _movementTimer;
  Timer? _visionUpdateTimer;
  Timer? _unstuckTimer;
  Timer? _hungerTimer;
  Timer? _smoothVisionTimer; // 平滑视野动画定时器
  late VisionSystem _visionSystem;
  late EnhancedVisionSystem _enhancedVisionSystem; // 增强版视野系统
  late SmoothVisionManager _smoothVisionManager; // 平滑视野管理器
  
  // 性能优化参数
  static const double _maxSpeed = 2.0;
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
      chestPositions: [],
      playerInventory: [],
      visibleTiles: {},
      visibleMap: List.generate(
        MapData.testMap.length,
        (y) => List.generate(MapData.testMap[0].length, (x) => false),
      ),
      ghostManager: GhostManager(map: MapData.testMap),
      explorationResult: '',
      showInventory: false,
      showCharacterInfo: false,
      showShop: false,
      isGameOver: false,
      deathReason: '',
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
    _startMovementTimer();
    _startVisionUpdateTimer();
    _startSmoothVisionTimer(); // 启动平滑视野动画定时器
    _startUnstuckTimer();
    _startHungerTimer();
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
          print('玩家出生在: ${zone['name']} (${candidatePosition.x}, ${candidatePosition.y})');
          break;
        }
      }
      
      if (validSpawnPoint != null) break;
    }

    // 如果预定义区域都不合适，回退到全地图随机搜索
    if (validSpawnPoint == null) {
      print('预定义区域不合适，使用全地图搜索...');
      final walkablePositions = _getWalkablePositions();
      
      while (validSpawnPoint == null && attempts < maxAttempts) {
        final candidatePosition = walkablePositions[random.nextInt(walkablePositions.length)];
        
        if (_isValidSpawnPosition(candidatePosition, minDistanceFromGhost, maxDistanceFromGhost)) {
          validSpawnPoint = candidatePosition;
          print('玩家出生在: 随机位置 (${candidatePosition.x}, ${candidatePosition.y})');
        }
        
        attempts++;
      }
    }

    // 如果还是找不到合适的位置，找一个距离鬼适中的位置
    if (validSpawnPoint == null) {
      print('寻找距离鬼适中的位置...');
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
    
    print('最终出生位置: (${validSpawnPoint.x}, ${validSpawnPoint.y})');
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
    
    // 调试信息
    print('移动定时器已启动');
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

  /// 更新饥饿扣血逻辑
  void _updateHungerDamage() {
    final currentFood = state.characterStats['food'] ?? 0;
    final currentHp = state.characterStats['hp'] ?? 0;
    
    // 当饱食度为0且生命值大于0时，每秒扣1生命值
    if (currentFood <= 0 && currentHp > 0) {
      final damageAmount = 1.0; // 饥饿扣血量
      final newHp = (currentHp - damageAmount).clamp(0, state.characterStats['maxHp'] ?? 100);
      
      // 更新生命值 - 只复制数值类型的字段
      final newStats = Map<String, dynamic>.from(state.characterStats);
      newStats['hp'] = newHp.toDouble();
      
      // 检测生命值变化并触发伤害效果
      final hpChanged = currentHp != newHp;
      
      state = state.copyWith(
        characterStats: newStats,
        lastHp: currentHp.toDouble(),
        shouldShowDamageEffect: hpChanged, // 每次有伤害都触发效果
        lastDamageAmount: hpChanged ? damageAmount : 0.0,
      );
      
      // 调试信息
      if (hpChanged) {
        print('饥饿扣血: 饱食度为0，生命值从 ${currentHp.toStringAsFixed(1)} 减少到 ${newHp.toStringAsFixed(1)}');
        print('伤害效果触发: $hpChanged');
      }
      
      // 检查是否死亡
      if (newHp <= 0) {
        print('角色因饥饿死亡！');
        // 这里可以触发游戏结束逻辑
      }
    }
  }

  /// 优化的移动更新
  void _updateMovement() {
    final movement = state.movementState;
    final position = state.playerPosition;
    
    // 调试信息：检查移动状态
    if (movement.isMoving) {
      print('移动中: joystick(${movement.joystickX.toStringAsFixed(2)}, ${movement.joystickY.toStringAsFixed(2)}) 强度: ${movement.joystickIntensity.toStringAsFixed(2)}');
    }
    
    // 如果没有移动输入且速度为0，跳过计算
    if (!movement.isMoving && 
        movement.velocityX.abs() < 0.01 && 
        movement.velocityY.abs() < 0.01) {
      return;
    }
    
    // 计算基于玩家移动速度的最大速度（缓存计算结果）
    final baseSpeed = state.characterStats['moveSpeed'] ?? 100.0;
    final currentMaxSpeed = (baseSpeed / 20.0).clamp(0.5, 8.0); // 将像素/秒转换为游戏内速度单位
    
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
    
    // 检查游戏结束条件
    _checkGameOverConditions();
  }

  /// 更新视野
  void _updateVision() {
    if (kDebugMode) {
      print('_updateVision 被调用');
    }
    
    final playerGridPosition = Point(
      state.playerPosition.x.round(),
      state.playerPosition.y.round(),
    );
    
    // 如果玩家网格位置没有改变，使用缓存的视野数据
    if (_lastPlayerGridPosition == playerGridPosition && _cachedVisibleTiles != null) {
      return;
    }
    
    // 检查位置有效性
    if (playerGridPosition.x < 0 || 
        playerGridPosition.x >= state.map[0].length ||
        playerGridPosition.y < 0 || 
        playerGridPosition.y >= state.map.length) {
      return;
    }

    try {
      // 获取当前精神值
      final currentSanity = (state.characterStats['san'] ?? 100).toDouble();
      final maxSanity = (state.characterStats['maxSan'] ?? 100).toDouble();
      
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
      
      // 调试输出
      if (kDebugMode) {
        print('玩家位置: ($playerGridPosition), 可见格子数量: ${newVisibleTiles.length}');
        print('总视野瓦片数量: ${tilesWithVisibility.length}');
        if (newVisibleTiles.length < 10) {
          print('完全可见格子: $newVisibleTiles');
        }
      }
      
      // 更新缓存
      _lastPlayerGridPosition = playerGridPosition;
      _cachedVisibleTiles = newVisibleTiles;
      
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
      
      state = state.copyWith(
        visibleTiles: newVisibleTiles,
        visibleMap: newVisibleMap,
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
    print('摇杆移动: x=$x, y=$y, intensity=$intensity');
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

  /// 切换到背包页面
  void toggleInventory() {
    if (state.currentPage == GamePage.inventory) {
      // 如果当前在背包页面，返回游戏页面
      state = state.copyWith(currentPage: GamePage.game);
    } else {
      // 否则切换到背包页面
      state = state.copyWith(currentPage: GamePage.inventory);
    }
  }

  /// 切换角色信息面板显示
  void toggleCharacterInfo() {
    state = state.copyWith(showCharacterInfo: !state.showCharacterInfo);
  }

  /// 切换商店显示
  void toggleShop() {
    state = state.copyWith(showShop: !state.showShop);
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
    
    return true; // 购买成功
  }

  /// 触发游戏结束
  void triggerGameOver(String reason) {
    state = state.copyWith(
      isGameOver: true,
      deathReason: reason,
    );
    
    // 停止所有计时器
    _movementTimer?.cancel();
    _visionUpdateTimer?.cancel();
  }



  /// 根据地形类型扣除角色状态
  void _applyTerrainEffects(String terrainType, double distance) {
    if (distance <= 0) return;
    
    final currentStats = Map<String, dynamic>.from(state.characterStats);
    final random = Random();
    
    // 计算移动格数（每格约为1个单位距离）
    final gridsMoved = distance;
    
    switch (terrainType) {
      case 'grass': // 草地
        for (int i = 0; i < gridsMoved.ceil(); i++) {
          // 随机扣除0.5-1饱食度
          final foodDeduction = 0.5 + random.nextDouble() * 0.5;
          currentStats['food'] = ((currentStats['food'] ?? 0) - foodDeduction).clamp(0, 100);
          
          // 随机扣除0-1精神值
          final sanDeduction = random.nextDouble();
          currentStats['san'] = ((currentStats['san'] ?? 0) - sanDeduction).clamp(0, currentStats['maxSan'] ?? 100);
        }
        break;
        
      case 'building': // 建筑里
        for (int i = 0; i < gridsMoved.ceil(); i++) {
          // 随机扣除0.2-1饱食度
          final foodDeduction = 0.2 + random.nextDouble() * 0.8;
          currentStats['food'] = ((currentStats['food'] ?? 0) - foodDeduction).clamp(0, 100);
          
          // 随机扣除0.8-2精神值
          final sanDeduction = 0.8 + random.nextDouble() * 1.2;
          currentStats['san'] = ((currentStats['san'] ?? 0) - sanDeduction).clamp(0, currentStats['maxSan'] ?? 100);
        }
        break;
        
      case 'woods': // 树林里
        for (int i = 0; i < gridsMoved.ceil(); i++) {
          // 随机扣除0.5-1饱食度
          final foodDeduction = 0.5 + random.nextDouble() * 0.5;
          currentStats['food'] = ((currentStats['food'] ?? 0) - foodDeduction).clamp(0, 100);
          
          // 随机扣除0-1精神值
          final sanDeduction = random.nextDouble();
          currentStats['san'] = ((currentStats['san'] ?? 0) - sanDeduction).clamp(0, currentStats['maxSan'] ?? 100);
          
          // 随机扣除0-0.5生命值
          final hpDeduction = random.nextDouble() * 0.5;
          currentStats['hp'] = ((currentStats['hp'] ?? 0) - hpDeduction).clamp(0, currentStats['maxHp'] ?? 100);
        }
        break;
        
      case 'path': // 路上
        for (int i = 0; i < gridsMoved.ceil(); i++) {
          // 随机扣除0.2-0.5饱食度
          final foodDeduction = 0.2 + random.nextDouble() * 0.3;
          currentStats['food'] = ((currentStats['food'] ?? 0) - foodDeduction).clamp(0, 100);
          
          // 随机恢复0-0.5精神值
          final sanRecovery = random.nextDouble() * 0.5;
          currentStats['san'] = ((currentStats['san'] ?? 0) + sanRecovery).clamp(0, currentStats['maxSan'] ?? 100);
        }
        break;
        
      default:
        // 其他地形类型暂时不扣除状态
        break;
    }
    
    // 更新角色状态
    state = state.copyWith(characterStats: currentStats);
    
    // 调试输出
    print('地形效果: $terrainType, 移动距离: ${distance.toStringAsFixed(2)}, 饱食度: ${currentStats['food']?.toStringAsFixed(1)}, 精神值: ${currentStats['san']?.toStringAsFixed(1)}, 生命值: ${currentStats['hp']?.toStringAsFixed(1)}');
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

    final position = state.playerPosition;
    final character = state.characterStats;
    
    // 检查生命值
    if (character['hp'] != null && character['hp'] <= 0) {
      triggerGameOver('生命值耗尽');
      return;
    }
    
    // 检查理智值
    if (character['san'] != null && character['san'] <= 0) {
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
      final remainingSeconds = state.unstuckCooldownEnd!.difference(now).inSeconds;
      print('脱离卡死功能冷却中，剩余时间: ${remainingSeconds}秒');
      return;
    }
    
    print('激活脱离卡死模式: 1秒无视地形移动');
    
    // 激活无视地形模式，持续1秒
    final noClipEndTime = now.add(const Duration(seconds: 1));
    // 设置60秒冷却时间
    final cooldownEndTime = now.add(const Duration(seconds: 60));
    
    state = state.copyWith(
      isNoClipMode: true,
      noClipEndTime: noClipEndTime,
      unstuckCooldownEnd: cooldownEndTime,
    );
    
    print('脱离卡死激活成功: 无视地形移动1秒，冷却60秒');
  }

  /// 寻找最近的可移动空地
  Point<int>? _findNearestEmptySpace(int startX, int startY) {
    final mapHeight = state.map.length;
    final mapWidth = state.map[0].length;
    
    print('搜索安全位置: 地图大小 ${mapWidth}x${mapHeight}, 起始位置: ($startX, $startY)');
    
    // 首先检查当前位置是否已经是可移动的
    if (_isEmptySpace(startX, startY)) {
      print('当前位置已经是安全位置: ($startX, $startY)');
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
            final distance = (newX - startX).abs() + (newY - startY).abs();
            print('找到安全位置: ($newX, $newY), 距离: $distance');
            return newPoint;
          }
          
          // 如果不是空地，加入队列继续搜索
          queue.add(newPoint);
        }
      }
    }
    
    // 如果没有找到空地，尝试寻找任何非墙壁位置
    print('未找到空地，寻找任何可通行位置...');
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (state.map[y][x] != 'wall' && state.map[y][x] != 'water') {
          print('找到可通行位置: ($x, $y) - ${state.map[y][x]}');
          return Point(x, y);
        }
      }
    }
    
    // 最后的备选方案：返回地图中心
    final centerX = mapWidth ~/ 2;
    final centerY = mapHeight ~/ 2;
    print('使用地图中心作为备选: ($centerX, $centerY)');
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
      explorationResult: '',
      showInventory: false,
      showCharacterInfo: false,
      showShop: false,
      isGameOver: false,
      deathReason: '',
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

  /// 获取平滑视野管理器
  SmoothVisionManager? get smoothVisionManager => _smoothVisionManager;

  @override
  void dispose() {
    _movementTimer?.cancel();
    _visionUpdateTimer?.cancel();
    _smoothVisionTimer?.cancel();
    _unstuckTimer?.cancel();
    _hungerTimer?.cancel();
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