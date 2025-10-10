// game/optimized_game_state.dart
// 性能优化的游戏状态管理器

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escape_from_school/data/mapData.dart';
import 'package:escape_from_school/data/props.dart';
import 'package:escape_from_school/data/shop.dart';
import 'package:escape_from_school/data/character_config.dart';
import 'package:escape_from_school/game/vision.dart';
import 'package:escape_from_school/game/ghost.dart';

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
  final CharacterConfig characterConfig;     // 角色配置
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

  const OptimizedGameState({
    required this.characterConfig,
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
  });

  OptimizedGameState copyWith({
    CharacterConfig? characterConfig,
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
  }) {
    return OptimizedGameState(
      characterConfig: characterConfig ?? this.characterConfig,
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
    );
  }
}

/// 创建初始角色状态的辅助方法
Map<String, dynamic> _createInitialCharacterStats(CharacterConfig config) {
  return {
    'name': config.name,
    'hp': config.maxHp,
    'maxHp': config.maxHp,
    'san': config.maxSan,
    'maxSan': config.maxSan,
    'food': config.initialFood,
    'att': config.attack,
    '金币': config.initialGold,
    'image': config.imagePath,
  };
}

/// 优化的游戏状态管理器
class OptimizedGameStateNotifier extends StateNotifier<OptimizedGameState> {
  Timer? _movementTimer;
  Timer? _visionUpdateTimer;
  late VisionSystem _visionSystem;
  
  // 性能优化参数
  static const double _maxSpeed = 2.0;
  static const double _acceleration = 8.0;
  static const double _friction = 6.0;
  static const double _deltaTime = 0.016; // 16ms
  static const int _visionUpdateInterval = 100; // 视野更新间隔(ms)
  
  // 缓存变量以减少重复计算
  Point<int>? _lastPlayerGridPosition;
  Set<Point<int>>? _cachedVisibleTiles;

  OptimizedGameStateNotifier(String characterId) : super(
    OptimizedGameState(
      characterConfig: CharacterConfigs.getCharacterById(characterId) ?? CharacterConfigs.allCharacters.first,
      characterStats: _createInitialCharacterStats(CharacterConfigs.getCharacterById(characterId) ?? CharacterConfigs.allCharacters.first),
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
    _initializeShop();
    _initializeGhosts();
    _setRandomPlayerSpawn();
    _startMovementTimer();
    _startVisionUpdateTimer();
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
    
    // 计算基于玩家数值的最大速度（缓存计算结果）
    final attBonus = state.characterStats['att'] * 0.1;
    final currentMaxSpeed = (_maxSpeed + attBonus).clamp(0.5, 8.0);
    
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
    
    // 更新位置和速度
    final newPosition = position.copyWith(x: finalX, y: finalY);
    final newMovement = movement.copyWith(
      velocityX: finalVelocityX,
      velocityY: finalVelocityY,
    );
    
    // 只有位置或速度真正改变时才更新状态
    if (newPosition != position || newMovement != movement) {
      state = state.copyWith(
        playerPosition: newPosition,
        movementState: newMovement,
      );
    }
    
    // 检查游戏结束条件
    _checkGameOverConditions();
  }

  /// 优化的视野更新（使用缓存）
  void _updateVision() {
    final playerGridPosition = Point<int>(
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
      final newVisibleTiles = _visionSystem.getVisibleTiles(playerGridPosition);
      
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

  /// 精确的碰撞检测 - 优化贴墙移动体验
  bool _canMoveToPosition(double x, double y) {
    // 计算角色的碰撞半径
    // sizeScale = 0.6, collisionScale = 0.8
    // 实际碰撞半径 = 0.6 * 0.8 * 0.5 = 0.24 瓦片单位
    final characterHalfSize = state.characterConfig.sizeScale * state.characterConfig.collisionScale * 0.5;
    
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
    final currentMoney = character['金币'] ?? 0;
    
    // 检查是否有足够的金币和库存
    if (currentMoney < shopItem.currentPrice || shopItem.stock <= 0) {
      return false; // 金币不足或库存不足
    }
    
    // 扣除金币
    final updatedCharacter = Map<String, dynamic>.from(character);
    updatedCharacter['金币'] = currentMoney - shopItem.currentPrice;
    
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

  /// 脱离卡死功能 - 将角色传送到最近的空地
  void unstuckPlayer() {
    final currentPosition = state.playerPosition;
    final currentX = currentPosition.x.round();
    final currentY = currentPosition.y.round();
    
    print('脱离卡死: 当前位置 ($currentX, $currentY)');
    
    // 搜索最近的空地
    Point<int>? nearestEmptySpace = _findNearestEmptySpace(currentX, currentY);
    
    if (nearestEmptySpace != null) {
      print('找到安全位置: (${nearestEmptySpace.x}, ${nearestEmptySpace.y})');
      
      // 传送到最近的空地
      final newPosition = state.playerPosition.copyWith(
        x: nearestEmptySpace.x.toDouble(),
        y: nearestEmptySpace.y.toDouble(),
      );
      
      // 停止当前移动
      final newMovement = state.movementState.copyWith(
        velocityX: 0.0,
        velocityY: 0.0,
        isMoving: false,
      );
      
      state = state.copyWith(
        playerPosition: newPosition,
        movementState: newMovement,
      );
      
      // 更新视野
      _updateVision();
      
      print('脱离卡死成功: 传送到 (${nearestEmptySpace.x}, ${nearestEmptySpace.y})');
    } else {
      print('脱离卡死失败: 未找到安全位置');
    }
  }

  /// 寻找最近的空地
  Point<int>? _findNearestEmptySpace(int startX, int startY) {
    final mapHeight = state.map.length;
    final mapWidth = state.map[0].length;
    
    print('搜索安全位置: 地图大小 ${mapWidth}x${mapHeight}');
    
    // 使用广度优先搜索找到最近的空地
    final visited = <Point<int>>{};
    final queue = <Point<int>>[];
    
    queue.add(Point(startX, startY));
    visited.add(Point(startX, startY));
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      
      // 检查当前位置是否是空地
      if (_isEmptySpace(current.x, current.y)) {
        print('找到空地: (${current.x}, ${current.y})');
        return current;
      }
      
      // 检查四个方向的相邻位置
      final directions = [
        Point(0, -1), // 上
        Point(0, 1),  // 下
        Point(-1, 0), // 左
        Point(1, 0),  // 右
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

  /// 检查指定位置是否是空地
  bool _isEmptySpace(int x, int y) {
    if (x < 0 || x >= state.map[0].length || y < 0 || y >= state.map.length) {
      return false;
    }
    
    final tile = state.map[y][x];
    // 空地包括：草地、门、商店等可通行区域
    return tile == 'grass' || tile == 'door' || tile == 'shop' || tile == 'chest';
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
    final characterConfig = state.characterConfig;
    state = OptimizedGameState(
      characterConfig: characterConfig,
      characterStats: _createInitialCharacterStats(characterConfig),
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

  @override
  void dispose() {
    _movementTimer?.cancel();
    _visionUpdateTimer?.cancel();
    super.dispose();
  }
}

/// 优化的游戏状态提供者
final optimizedGameStateProvider = StateNotifierProvider<OptimizedGameStateNotifier, OptimizedGameState>((ref) {
  // 使用厨师角色作为默认角色
  return OptimizedGameStateNotifier('cook');
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