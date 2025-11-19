import 'dart:math';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

// A*寻路算法中的节点类
class _AStarNode {
  final Point<int> position;
  double g; // 从起点到当前节点的实际距离
  double h; // 当前节点到终点的估算距离
  double get f => g + h; // 总距离
  _AStarNode? parent;

  _AStarNode(this.position, {this.g = 0, this.h = 0, this.parent});
}

// 鬼的精确位置类（支持小数位置）
@immutable
class GhostPosition {
  final double x;
  final double y;
  final bool facingRight;

  const GhostPosition({
    required this.x,
    required this.y,
    this.facingRight = true,
  });

  GhostPosition copyWith({
    double? x,
    double? y,
    bool? facingRight,
  }) {
    return GhostPosition(
      x: x ?? this.x,
      y: y ?? this.y,
      facingRight: facingRight ?? this.facingRight,
    );
  }

  /// 转换为Point<int>，用于地图坐标
  Point<int> toPoint() {
    return Point<int>(x.round(), y.round());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GhostPosition &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          facingRight == other.facingRight;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ facingRight.hashCode;
}

// 鬼的移动状态类
@immutable
class GhostMovementState {
  final double velocityX;
  final double velocityY;
  final double targetX;
  final double targetY;
  final bool isMoving;
  final bool hasTarget;

  const GhostMovementState({
    this.velocityX = 0.0,
    this.velocityY = 0.0,
    this.targetX = 0.0,
    this.targetY = 0.0,
    this.isMoving = false,
    this.hasTarget = false,
  });

  GhostMovementState copyWith({
    double? velocityX,
    double? velocityY,
    double? targetX,
    double? targetY,
    bool? isMoving,
    bool? hasTarget,
  }) {
    return GhostMovementState(
      velocityX: velocityX ?? this.velocityX,
      velocityY: velocityY ?? this.velocityY,
      targetX: targetX ?? this.targetX,
      targetY: targetY ?? this.targetY,
      isMoving: isMoving ?? this.isMoving,
      hasTarget: hasTarget ?? this.hasTarget,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GhostMovementState &&
          runtimeType == other.runtimeType &&
          velocityX == other.velocityX &&
          velocityY == other.velocityY &&
          targetX == other.targetX &&
          targetY == other.targetY &&
          isMoving == other.isMoving &&
          hasTarget == other.hasTarget;

  @override
  int get hashCode =>
      velocityX.hashCode ^
      velocityY.hashCode ^
      targetX.hashCode ^
      targetY.hashCode ^
      isMoving.hashCode ^
      hasTarget.hashCode;
}

// 优化的A*寻路算法 - 添加距离限制和早期退出
List<Point<int>>? _findPath(Point<int> start, Point<int> end, List<List<String>> map) {
  // 性能优化：如果距离太远，不进行寻路
  final distance = _heuristic(start, end);
  if (distance > 20) return null; // 限制寻路距离，避免长距离计算
  
  final openList = <_AStarNode>[];
  final closedList = <_AStarNode>[];
  final visitedPositions = <String>{}; // 使用Set提高查找效率

  // 起点节点
  final startNode = _AStarNode(start, h: distance);
  openList.add(startNode);

  int iterations = 0;
  const maxIterations = 100; // 限制最大迭代次数，防止卡顿

  while (openList.isNotEmpty && iterations < maxIterations) {
    iterations++;
    
    // 找到f值最小的节点
    openList.sort((a, b) => a.f.compareTo(b.f));
    final currentNode = openList.removeAt(0);
    closedList.add(currentNode);
    
    final posKey = '${currentNode.position.x},${currentNode.position.y}';
    visitedPositions.add(posKey);

    // 如果到达终点，回溯路径
    if (currentNode.position.x == end.x && currentNode.position.y == end.y) {
      return _reconstructPath(currentNode);
    }

    // 检查相邻节点
    for (final neighbor in _getNeighbors(currentNode.position, map)) {
      final neighborKey = '${neighbor.x},${neighbor.y}';
      
      // 跳过已访问的节点
      if (visitedPositions.contains(neighborKey)) continue;

      // 计算g值
      final gScore = currentNode.g + 1;

      // 检查是否已经在openList中
      final existingIndex = openList.indexWhere((node) => node.position == neighbor);

      if (existingIndex == -1 || gScore < openList[existingIndex].g) {
        final neighborNode = existingIndex == -1 ? _AStarNode(neighbor) : openList[existingIndex];
        neighborNode.g = gScore;
        neighborNode.h = _heuristic(neighbor, end);
        neighborNode.parent = currentNode;

        if (existingIndex == -1) {
          openList.add(neighborNode);
        }
      }
    }
  }

  // 没有找到路径或超过迭代限制
  return null;
}

// 估算两点之间的曼哈顿距离
double _heuristic(Point<int> a, Point<int> b) {
  return (a.x - b.x).abs() + (a.y - b.y).abs().toDouble();
}

// 获取可移动的相邻节点
List<Point<int>> _getNeighbors(Point<int> position, List<List<String>> map) {
  final neighbors = <Point<int>>[];
  final directions = [
    Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)
  ];

  for (final dir in directions) {
    final newX = position.x + dir.x;
    final newY = position.y + dir.y;

    // 检查新位置是否可行走
    if (newX >= 0 && newX < map[0].length &&
        newY >= 0 && newY < map.length &&
        map[newY][newX] != 'wall' &&
        map[newY][newX] != 'water') {
      neighbors.add(Point(newX, newY));
    }
  }

  return neighbors;
}

// 从终点节点回溯路径
List<Point<int>> _reconstructPath(_AStarNode endNode) {
  final path = <Point<int>>[];
  var currentNode = endNode;

  while (currentNode.parent != null) {
    path.insert(0, currentNode.position);
    currentNode = currentNode.parent!;
  }

  return path;
}



// 鬼的基础类
abstract class Ghost {
  final String name;
  final String imagePath;
  final Color color;
  final int detectionRange; // 察觉范围(格子数)
  final double baseSpeed;   // 基础移动速度(像素/秒，类似玩家的moveSpeed)
  final int cooldownTime;   // 冷却时间(秒)
  final int maxAttacks;     // 最大攻击次数
  int remainingAttacks;     // 剩余攻击次数
  bool isInCooldown = false;
  bool isChasing = false;
  bool isInvisible = false; // 冷却期间不可见
  int maxHp = 100;
  int hp = 100;
  DateTime? lastDamageShownAt;
  int lastDamageShownValue = 0;
  bool lastDamageShownIsCrit = false;
  DateTime? lastMeleeHitAt;
  
  // 新的位置和移动系统
  GhostPosition? position;  // 精确位置
  GhostMovementState movementState; // 移动状态
  
  // 逃跑相关属性
  Point<int>? fleeDestination; // 逃跑目标位置（网格坐标）
  int fleeDistance; // 逃跑距离
  bool isFleeing = false; // 是否正在逃跑

  Ghost({
    required this.name,
    required this.imagePath,
    required this.color,
    required this.detectionRange,
    required this.baseSpeed,
    required this.cooldownTime,
    required this.maxAttacks,
    this.fleeDistance = 10, // 默认逃跑10格距离
  }) : remainingAttacks = maxAttacks,
        movementState = const GhostMovementState();

  // 攻击玩家时的效果
  Map<String, int> attackEffects();

  // 重置攻击次数
  void resetAttacks() {
    remainingAttacks = maxAttacks;
  }

  void applyDamage(int amount, {bool isCrit = false}) {
    if (amount <= 0) return;
    hp = (hp - amount).clamp(0, maxHp);
    lastDamageShownAt = DateTime.now();
    lastDamageShownValue = amount;
    lastDamageShownIsCrit = isCrit;
  }

  // 复制方法，用于创建新实例
  Ghost copy();
  
  // 获取当前网格位置
  Point<int>? get gridPosition => position?.toPoint();
  
  // 设置精确位置
  void setPosition(double x, double y) {
    position = GhostPosition(x: x, y: y);
  }
  
  // 设置网格位置（转换为精确位置）
  void setGridPosition(int x, int y) {
    position = GhostPosition(x: x.toDouble(), y: y.toDouble());
  }
}

// 具体鬼类实现
class NormalGhost extends Ghost {
  NormalGhost({GhostPosition? position})
      : super(
    name: '普通鬼',
    imagePath: 'images/gui.png',
    // 关键区域：普通鬼颜色调整为黑色
    color: Colors.black,
    detectionRange: 8,
    baseSpeed: 90.0,  // 使用与玩家相似的移动速度
    cooldownTime: 60,
    maxAttacks: 1,
  ) {
    this.position = position;
  }

  @override
  Map<String, int> attackEffects() {
    return {'hp': -50};
  }

  @override
  Ghost copy() => NormalGhost(position: position);
}

class FastGhost extends Ghost {
  FastGhost({GhostPosition? position})
      : super(
    name: '快速鬼',
    imagePath: 'images/gui.png',
    color: Colors.blue,
    detectionRange: 6,
    baseSpeed: 120.0,  // 比普通鬼更快
    cooldownTime: 30,
    maxAttacks: 2,
  ) {
    this.position = position;
  }

  @override
  Map<String, int> attackEffects() {
    return {'san': -10, 'food': -2};
  }

  @override
  Ghost copy() => FastGhost(position: position);
}

class StrongGhost extends Ghost {
  StrongGhost({GhostPosition? position})
      : super(
    name: '强壮鬼',
    imagePath: 'images/gui.png',
    color: Colors.red,
    detectionRange: 10,
    baseSpeed: 70.0,  // 比普通鬼慢但攻击力强
    cooldownTime: 90,
    maxAttacks: 1,
  ) {
    this.position = position;
  }

  @override
  Map<String, int> attackEffects() {
    return {'hp': -80, 'san': -5};
  }

  @override
  Ghost copy() => StrongGhost(position: position);
}

class TricksterGhost extends Ghost {
  TricksterGhost({GhostPosition? position})
      : super(
    name: '诡计鬼',
    imagePath: 'images/gui.png',
    color: Colors.purple,
    detectionRange: 12,
    baseSpeed: 100.0,  // 中等速度
    cooldownTime: 45,
    maxAttacks: 3,
  ) {
    this.position = position;
  }

  @override
  Map<String, int> attackEffects() {
    return {'san': -10, 'moveSpeed': -5};
  }

  @override
  Ghost copy() => TricksterGhost(position: position);
}

// 鬼管理器
class GhostManager {
  final List<List<String>> map; // 添加地图数据成员
  final List<Ghost> _ghosts = [];
  final Random _random = Random();
  
  // 路径缓存 - 提高性能
  final Map<String, List<Point<int>>?> _pathCache = {};
  int _cacheCleanupCounter = 0;
  static const int _cacheCleanupInterval = 50; // 每50次更新清理一次缓存

  GhostManager({required this.map});

  List<Ghost> get ghosts => List.unmodifiable(_ghosts);

  // 添加鬼
  void addGhost(Ghost ghost) {
    _ghosts.add(ghost);
  }

  // 移除鬼
  void removeGhost(Ghost ghost) {
    _ghosts.remove(ghost);
  }

  // 清空所有鬼
  void clearAllGhosts() {
    _ghosts.clear();
  }

  // 在随机位置添加指定类型的鬼
  void addRandomGhost(Type ghostType, List<Point<int>> walkablePositions, Point<int> playerPosition) {
    // 过滤掉玩家位置附近的点
    final availablePositions = walkablePositions.where((p) {
      final dx = (p.x - playerPosition.x).abs();
      final dy = (p.y - playerPosition.y).abs();
      return dx > 5 || dy > 5; // 确保不会生成在玩家附近
    }).toList();

    if (availablePositions.isEmpty) return;

    final position = availablePositions[_random.nextInt(availablePositions.length)];
    final ghostPosition = GhostPosition(x: position.x.toDouble(), y: position.y.toDouble());
    
    Ghost newGhost;
    if (ghostType == NormalGhost) {
      newGhost = NormalGhost(position: ghostPosition);
    } else if (ghostType == FastGhost) {
      newGhost = FastGhost(position: ghostPosition);
    } else if (ghostType == StrongGhost) {
      newGhost = StrongGhost(position: ghostPosition);
    } else if (ghostType == TricksterGhost) {
      newGhost = TricksterGhost(position: ghostPosition);
    } else {
      newGhost = NormalGhost(position: ghostPosition);
    }

    addGhost(newGhost);
  }

  // 更新所有鬼的状态（新的平滑移动版本）
  void updateAll(
      Point<int> playerPosition,
      Function(Map<String, int>) onPlayerAttacked,
      Function()? onGhostDetect,
      ) {
    for (final ghost in _ghosts) {
      // 冷却期间处于隐形状态的鬼不进行更新（不移动、不攻击）
      if (ghost.isInvisible) continue;
      _updateGhost(ghost, playerPosition, onPlayerAttacked, onGhostDetect);
    }
  }

  // 更新单个鬼的状态（新的平滑移动版本）
  void _updateGhost(
      Ghost ghost,
      Point<int> playerPosition,
      Function(Map<String, int>) onPlayerAttacked,
      Function()? onGhostDetect,
      ) {
    if (ghost.position == null) return;

    final wasChasing = ghost.isChasing;
    final inRange = _isPlayerInDetectionRange(ghost, playerPosition);
    ghost.isChasing = inRange;



    if (!wasChasing && inRange && onGhostDetect != null) {
      onGhostDetect();
    }

    // 更新鬼的移动状态和目标
    _updateGhostMovementTarget(ghost, playerPosition);
    
    // 执行平滑移动
    _updateGhostSmoothMovement(ghost, onPlayerAttacked, playerPosition);
  }

  // 更新鬼的移动目标 - 优化状态切换
  void _updateGhostMovementTarget(Ghost ghost, Point<int> playerPosition) {
    // 检查是否需要更新目标（避免频繁计算）
    final currentTarget = Point(ghost.movementState.targetX.round(), ghost.movementState.targetY.round());
    final ghostPos = ghost.position!.toPoint();
    final isNearTarget = (ghostPos.x - currentTarget.x).abs() <= 1 && (ghostPos.y - currentTarget.y).abs() <= 1;
    
    if (ghost.isFleeing) {
      // 逃跑状态：目标是逃跑目的地
      if (ghost.fleeDestination != null && (isNearTarget || !ghost.movementState.isMoving)) {
        ghost.movementState = ghost.movementState.copyWith(
          targetX: ghost.fleeDestination!.x.toDouble(),
          targetY: ghost.fleeDestination!.y.toDouble(),
          isMoving: true,
        );
      }
    } else if (!ghost.isInCooldown) {
      if (ghost.isChasing) {
        // 追逐状态：只有在接近目标或没有移动时才重新计算路径
        if (isNearTarget || !ghost.movementState.isMoving) {
          _setChaseTarget(ghost, playerPosition);
        }
      } else {
        // 随机游荡状态：只有在接近目标时才设置新的随机目标
        if (isNearTarget || !ghost.movementState.isMoving) {
          _setRandomTarget(ghost);
        }
      }
    } else {
      // 冷却状态：停止移动
      ghost.movementState = ghost.movementState.copyWith(
        isMoving: false,
        velocityX: 0.0,
        velocityY: 0.0,
      );
    }
  }

  // 设置追逐目标 - 使用缓存优化
  void _setChaseTarget(Ghost ghost, Point<int> playerPosition) {
    final ghostGridPos = ghost.position!.toPoint();
    
    // 如果鬼和玩家在同一位置，直接攻击
    if (ghostGridPos.x == playerPosition.x && ghostGridPos.y == playerPosition.y) {
      _ghostAttackPlayer(ghost, (effects) {});
      return;
    }

    // 检查路径缓存
    final cacheKey = '${ghostGridPos.x},${ghostGridPos.y}->${playerPosition.x},${playerPosition.y}';
    List<Point<int>>? path = _pathCache[cacheKey];
    
    // 如果缓存中没有路径，计算新路径
    if (path == null) {
      path = _findPath(ghostGridPos, playerPosition, map);
      _pathCache[cacheKey] = path; // 缓存结果（包括null）
      
      // 定期清理缓存，防止内存泄漏
      _cacheCleanupCounter++;
      if (_cacheCleanupCounter >= _cacheCleanupInterval) {
        _pathCache.clear();
        _cacheCleanupCounter = 0;
      }
    }

    if (path != null && path.isNotEmpty) {
      // 取路径中的第一步作为目标
      final nextStep = path[0];

      ghost.movementState = ghost.movementState.copyWith(
        targetX: nextStep.x.toDouble(),
        targetY: nextStep.y.toDouble(),
        isMoving: true,
      );
    } else {
      // 如果找不到路径，设置随机目标
      _setRandomTarget(ghost);
    }
  }

  // 设置随机移动目标
  void _setRandomTarget(Ghost ghost) {
    final currentPos = ghost.position!.toPoint();
    final directions = [
      Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)
    ]..shuffle(_random);

    for (final dir in directions) {
      final targetX = currentPos.x + dir.x;
      final targetY = currentPos.y + dir.y;

      // 检查目标位置是否可行走
      if (targetX >= 0 && targetX < map[0].length &&
          targetY >= 0 && targetY < map.length &&
          map[targetY][targetX] != 'wall' &&
          map[targetY][targetX] != 'water') {
        
        ghost.movementState = ghost.movementState.copyWith(
          targetX: targetX.toDouble(),
          targetY: targetY.toDouble(),
          isMoving: true,
        );
        return;
      }
    }

    // 如果没有找到合适的目标，停止移动
    ghost.movementState = ghost.movementState.copyWith(
      isMoving: false,
    );
  }

  // 执行鬼的平滑移动
  void _updateGhostSmoothMovement(Ghost ghost, Function(Map<String, int>) onPlayerAttacked, Point<int> playerPosition) {
    if (!ghost.movementState.isMoving) return;

    // 计算移动速度，使用与玩家相同的规则
    // 玩家的规则：baseSpeed = characterStats['moveSpeed']，currentMaxSpeed = baseSpeed / 20.0
    final baseSpeed = ghost.baseSpeed; // 基础移动速度（像素/秒）
    final currentMaxSpeed = (baseSpeed / 20.0).clamp(0.1, double.infinity); // 与玩家相同的计算规则
    
    // 计算到目标的距离和方向
    final dx = ghost.movementState.targetX - ghost.position!.x;
    final dy = ghost.movementState.targetY - ghost.position!.y;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance < 0.1) {
      // 已到达目标位置
      ghost.position = GhostPosition(
        x: ghost.movementState.targetX,
        y: ghost.movementState.targetY,
        facingRight: ghost.position!.facingRight,
      );
      ghost.movementState = ghost.movementState.copyWith(
        isMoving: false,
        velocityX: 0.0,
        velocityY: 0.0,
      );
      
      // 检查是否碰到玩家
      final gridPos = ghost.position!.toPoint();
      if (gridPos.x == playerPosition.x && gridPos.y == playerPosition.y) {
        _ghostAttackPlayer(ghost, onPlayerAttacked);
      }
      
      return;
    }

    // 计算移动方向（单位向量）
    final dirX = dx / distance;
    final dirY = dy / distance;

    // 计算目标速度
    final targetVelocityX = dirX * currentMaxSpeed;
    final targetVelocityY = dirY * currentMaxSpeed;

    // 应用加速度和摩擦力，针对100ms更新间隔优化
    const acceleration = 2.0; // 提高加速度，适应更短的更新间隔
    const friction = 0.95; // 降低摩擦力，使移动更平滑
    const deltaTime = 0.1; // 鬼的更新间隔是100ms
    
    double newVelocityX, newVelocityY;
    
    // 如果有目标速度，应用加速度
    if (targetVelocityX.abs() > 0.01 || targetVelocityY.abs() > 0.01) {
      newVelocityX = ghost.movementState.velocityX + (targetVelocityX - ghost.movementState.velocityX) * acceleration * deltaTime;
      newVelocityY = ghost.movementState.velocityY + (targetVelocityY - ghost.movementState.velocityY) * acceleration * deltaTime;
    } else {
      // 没有目标速度，应用摩擦力
      newVelocityX = ghost.movementState.velocityX * (1.0 - friction * deltaTime);
      newVelocityY = ghost.movementState.velocityY * (1.0 - friction * deltaTime);
      
      // 速度很小时直接停止
      if (newVelocityX.abs() < 0.01) newVelocityX = 0.0;
      if (newVelocityY.abs() < 0.01) newVelocityY = 0.0;
    }

    // 计算新位置
    final newX = ghost.position!.x + newVelocityX * deltaTime;
    final newY = ghost.position!.y + newVelocityY * deltaTime;

    // 改进的碰撞检测 - 支持滑动移动
    double finalX = ghost.position!.x;
    double finalY = ghost.position!.y;
    double finalVelocityX = newVelocityX;
    double finalVelocityY = newVelocityY;
    
    // 首先尝试完整移动
    if (_canGhostMoveToPosition(newX, newY)) {
      finalX = newX;
      finalY = newY;
    } else {
      // 如果无法完整移动，尝试分别在X轴和Y轴上移动（滑动效果）
      bool canMoveX = _canGhostMoveToPosition(newX, ghost.position!.y);
      bool canMoveY = _canGhostMoveToPosition(ghost.position!.x, newY);
      
      if (canMoveX && canMoveY) {
        // 两个方向都可以移动，选择移动距离更大的方向
        double deltaX = (newX - ghost.position!.x).abs();
        double deltaY = (newY - ghost.position!.y).abs();
        
        if (deltaX > deltaY) {
          finalX = newX;
          finalVelocityY = 0.0; // 停止Y方向的速度
        } else {
          finalY = newY;
          finalVelocityX = 0.0; // 停止X方向的速度
        }
      } else if (canMoveX) {
        finalX = newX;
        finalVelocityY = 0.0; // 停止Y方向的速度
      } else if (canMoveY) {
        finalY = newY;
        finalVelocityX = 0.0; // 停止X方向的速度
      } else {
        // 两个方向都无法移动，停止所有移动
        finalVelocityX = 0.0;
        finalVelocityY = 0.0;
      }
    }

    // 更新位置和速度
    ghost.position = GhostPosition(
      x: finalX,
      y: finalY,
      facingRight: finalVelocityX > 0 ? true : (finalVelocityX < 0 ? false : ghost.position!.facingRight),
    );
    
    ghost.movementState = ghost.movementState.copyWith(
      velocityX: finalVelocityX,
      velocityY: finalVelocityY,
    );

    // 检查是否碰到玩家
    final gridX = finalX.round();
    final gridY = finalY.round();
    if (gridX == playerPosition.x && gridY == playerPosition.y) {
      _ghostAttackPlayer(ghost, onPlayerAttacked);
    }
  }

  /// 优化的鬼碰撞检测 - 简化计算，提高性能
  bool _canGhostMoveToPosition(double x, double y) {
    // 简化碰撞检测：只检查中心点和主要边界
    final gridX = x.round();
    final gridY = y.round();
    
    // 检查边界
    if (gridX < 0 || gridX >= map[0].length ||
        gridY < 0 || gridY >= map.length) {
      return false;
    }
    
    // 检查中心点
    if (map[gridY][gridX] == 'wall' || map[gridY][gridX] == 'water') {
      return false;
    }
    
    // 只在移动距离较大时检查额外的点
    final dx = (x - x.round()).abs();
    final dy = (y - y.round()).abs();
    
    if (dx > 0.3 || dy > 0.3) {
      // 检查移动方向上的关键点
      final checkX = dx > 0.3 ? (x > gridX ? gridX + 1 : gridX - 1) : gridX;
      final checkY = dy > 0.3 ? (y > gridY ? gridY + 1 : gridY - 1) : gridY;
      
      if (checkX >= 0 && checkX < map[0].length &&
          checkY >= 0 && checkY < map.length) {
        if (map[checkY][checkX] == 'wall' || map[checkY][checkX] == 'water') {
          return false;
        }
      }
    }
    
    return true;
  }

  // 新增方法：鬼逃跑移动
  void _moveGhostToFlee(Ghost ghost, List<List<String>> map) {
    if (ghost.position == null || ghost.fleeDestination == null) return;

    // 计算移动方向
    double dx = 0.0;
    double dy = 0.0;

    if (ghost.position!.x < ghost.fleeDestination!.x) dx = 1.0;
    else if (ghost.position!.x > ghost.fleeDestination!.x) dx = -1.0;

    if (ghost.position!.y < ghost.fleeDestination!.y) dy = 1.0;
    else if (ghost.position!.y > ghost.fleeDestination!.y) dy = -1.0;

    // 尝试移动
    if (dx != 0.0 || dy != 0.0) {
      _tryMoveGhost(ghost, dx, dy, map, null, null);
    } else {
      // 到达逃跑目的地，随机游荡
      _moveGhostRandomly(ghost, map);
    }
  }

  // 鬼向玩家移动
  void _moveGhostTowardsPlayer(
      Ghost ghost,
      Point<int> playerPosition,
      List<List<String>> map,
      Function(Map<String, int>) onPlayerAttacked,
      ) {
    if (ghost.position == null) return;

    final ghostGridPos = ghost.position!.toPoint();
    
    // 如果鬼和玩家在同一位置，直接攻击
    if (ghostGridPos.x == playerPosition.x && ghostGridPos.y == playerPosition.y) {
      _ghostAttackPlayer(ghost, onPlayerAttacked);
      return;
    }

    // 使用A*算法寻找路径
    final path = _findPath(ghostGridPos, playerPosition, map);

    if (path != null && path.isNotEmpty) {
      // 取路径中的第一步作为移动方向
      final nextStep = path[0];
      final dx = nextStep.x - ghostGridPos.x;
      final dy = nextStep.y - ghostGridPos.y;

      _tryMoveGhost(ghost, dx.toDouble(), dy.toDouble(), map, playerPosition, onPlayerAttacked);
    } else {
      // 如果找不到路径，尝试随机移动
      _moveGhostRandomly(ghost, map);
    }
  }

  // 鬼随机移动
  void _moveGhostRandomly(Ghost ghost, List<List<String>> map) {
    if (ghost.position == null) return;

    final directions = [
      Point(1.0, 0.0), Point(-1.0, 0.0), Point(0.0, 1.0), Point(0.0, -1.0)
    ]..shuffle(_random);

    for (final dir in directions) {
      if (_tryMoveGhost(ghost, dir.x, dir.y, map, null, null)) {
        break;
      }
    }
  }

  // 尝试移动鬼
  bool _tryMoveGhost(
      Ghost ghost,
      double dx,
      double dy,
      List<List<String>> map,
      Point<int>? playerPosition,
      Function(Map<String, int>)? onPlayerAttacked,
      ) {
    if (ghost.position == null) return false;

    final newX = ghost.position!.x + dx;
    final newY = ghost.position!.y + dy;

    // 检查新位置是否可行走
    final gridX = newX.round();
    final gridY = newY.round();
    
    if (gridX >= 0 && gridX < map[0].length &&
        gridY >= 0 && gridY < map.length &&
        map[gridY][gridX] != 'wall' &&
        map[gridY][gridX] != 'water') {

      ghost.position = GhostPosition(x: newX, y: newY);

      // 检查是否碰到玩家
      if (playerPosition != null &&
          onPlayerAttacked != null &&
          gridX == playerPosition.x &&
          gridY == playerPosition.y) {
        _ghostAttackPlayer(ghost, onPlayerAttacked);
      }

      return true;
    }

    return false;
  }

  // 鬼攻击玩家
  void _ghostAttackPlayer(Ghost ghost, Function(Map<String, int>) onPlayerAttacked) {
    if (ghost.remainingAttacks <= 0) {
      _startGhostCooldown(ghost);
      return;
    }

    ghost.remainingAttacks--;
    final effects = ghost.attackEffects();
    onPlayerAttacked(effects);

    if (ghost.remainingAttacks <= 0) {
      _startGhostCooldown(ghost);
    }
  }

  // 新增方法：开始鬼的冷却和逃跑
  void _startGhostCooldown(Ghost ghost) {
    // 修改：攻击完成后直接进入隐形冷却，不再现场逃跑。
    ghost.isInCooldown = true;
    ghost.isInvisible = true;
    ghost.isFleeing = false;
    ghost.isChasing = false;

    Future.delayed(Duration(seconds: ghost.cooldownTime), () {
      // 冷却结束后重新显示并重置攻击次数
      ghost.isInCooldown = false;
      ghost.isInvisible = false;
      ghost.isFleeing = false;
      ghost.resetAttacks();
    });
  }

  bool _isPlayerInDetectionRange(Ghost ghost, Point<int> playerPosition) {
    if (ghost.position == null) return false;

    final dx = (ghost.position!.x - playerPosition.x).abs();
    final dy = (ghost.position!.y - playerPosition.y).abs();
    final inRange = dx <= ghost.detectionRange && dy <= ghost.detectionRange;
    


    return inRange;
  }

  // 新增方法：设置逃跑目标
  void _setFleeDestination(Ghost ghost) {
    if (ghost.position == null) return;

    // 随机选择一个远离玩家的方向
    final directions = [
      Point(1, 1), Point(-1, 1), Point(1, -1), Point(-1, -1),
      Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)
    ]..shuffle(_random);

    // 尝试每个方向直到找到可行的逃跑路径
    for (final dir in directions) {
      final targetX = (ghost.position!.x + dir.x * ghost.fleeDistance).round();
      final targetY = (ghost.position!.y + dir.y * ghost.fleeDistance).round();

      // 确保目标位置在地图范围内
      if (targetX >= 0 && targetX < map[0].length &&
          targetY >= 0 && targetY < map.length) {
        ghost.fleeDestination = Point(targetX, targetY);
        return;
      }
    }

    // 如果没有找到合适的目标，随机选择一个附近位置
    ghost.fleeDestination = Point(
      (ghost.position!.x + _random.nextInt(5) - 2).round(),
      (ghost.position!.y + _random.nextInt(5) - 2).round(),
    );
  }
}