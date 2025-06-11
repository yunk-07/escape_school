import 'dart:math';
import 'package:flutter/material.dart';

// 鬼的基础类
abstract class Ghost {
  final String name;
  final String imagePath;
  final Color color;
  final int detectionRange; // 察觉范围(格子数)
  final double moveSpeed;   // 移动速度(秒/次)
  final int cooldownTime;   // 冷却时间(秒)
  final int maxAttacks;     // 最大攻击次数
  int remainingAttacks;     // 剩余攻击次数
  bool isInCooldown = false;
  bool isChasing = false;
  Point<int>? position;

  Ghost({
    required this.name,
    required this.imagePath,
    required this.color,
    required this.detectionRange,
    required this.moveSpeed,
    required this.cooldownTime,
    required this.maxAttacks,
  }) : remainingAttacks = maxAttacks;

  // 攻击玩家时的效果
  Map<String, int> attackEffects();

  // 重置攻击次数
  void resetAttacks() {
    remainingAttacks = maxAttacks;
  }

  // 复制方法，用于创建新实例
  Ghost copy();
}

// 具体鬼类实现
class NormalGhost extends Ghost {
  NormalGhost({Point<int>? position})
      : super(
    name: '普通鬼',
    imagePath: 'images/gui.png',
    color: Colors.grey,
    detectionRange: 8,
    moveSpeed: 1.5,
    cooldownTime: 60,
    maxAttacks: 1,
  ) {
    this.position = position;
  }

  @override
  Map<String, int> attackEffects() {
    return {'hp': -5};
  }

  @override
  Ghost copy() => NormalGhost(position: position);
}

class FastGhost extends Ghost {
  FastGhost({Point<int>? position})
      : super(
    name: '快速鬼',
    imagePath: 'images/gui.png',
    color: Colors.blue,
    detectionRange: 6,
    moveSpeed: 0.8,
    cooldownTime: 30,
    maxAttacks: 2,
  ) {
    this.position = position;
  }

  @override
  Map<String, int> attackEffects() {
    return {'san': -3, 'food': -2};
  }

  @override
  Ghost copy() => FastGhost(position: position);
}

class StrongGhost extends Ghost {
  StrongGhost({Point<int>? position})
      : super(
    name: '强壮鬼',
    imagePath: 'images/gui.png',
    color: Colors.red,
    detectionRange: 10,
    moveSpeed: 2.0,
    cooldownTime: 90,
    maxAttacks: 1,
  ) {
    this.position = position;
  }

  @override
  Map<String, int> attackEffects() {
    return {'hp': -10, 'san': -5};
  }

  @override
  Ghost copy() => StrongGhost(position: position);
}

class TricksterGhost extends Ghost {
  TricksterGhost({Point<int>? position})
      : super(
    name: '诡计鬼',
    imagePath: 'images/gui.png',
    color: Colors.purple,
    detectionRange: 12,
    moveSpeed: 1.2,
    cooldownTime: 120,
    maxAttacks: 3,
  ) {
    this.position = position;
  }

  @override
  Map<String, int> attackEffects() {
    final random = Random();
    return {
      'hp': -random.nextInt(6),
      'san': -random.nextInt(6),
      'food': -random.nextInt(6),
      'gold': -random.nextInt(10),
    };
  }

  @override
  Ghost copy() => TricksterGhost(position: position);
}

// 鬼管理器
class GhostManager {
  final List<Ghost> _ghosts = [];
  final Random _random = Random();

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

    Ghost newGhost;
    if (ghostType == NormalGhost) {
      newGhost = NormalGhost(position: position);
    } else if (ghostType == FastGhost) {
      newGhost = FastGhost(position: position);
    } else if (ghostType == StrongGhost) {
      newGhost = StrongGhost(position: position);
    } else if (ghostType == TricksterGhost) {
      newGhost = TricksterGhost(position: position);
    } else {
      newGhost = NormalGhost(position: position);
    }

    addGhost(newGhost);
  }

  // 更新所有鬼的状态
  void updateAll(
      Point<int> playerPosition,
      List<List<String>> map,
      Function(Map<String, int>) onPlayerAttacked,
      ) {
    for (final ghost in _ghosts) {
      _updateGhost(ghost, playerPosition, map, onPlayerAttacked);
    }
  }

  // 更新单个鬼的状态
  void _updateGhost(
      Ghost ghost,
      Point<int> playerPosition,
      List<List<String>> map,
      Function(Map<String, int>) onPlayerAttacked,
      ) {
    if (ghost.position == null || ghost.isInCooldown) return;

    // 检查玩家是否在察觉范围内
    final dx = (ghost.position!.x - playerPosition.x).abs();
    final dy = (ghost.position!.y - playerPosition.y).abs();
    final inRange = dx <= ghost.detectionRange && dy <= ghost.detectionRange;

    if (inRange) {
      ghost.isChasing = true;
      _moveGhostTowardsPlayer(ghost, playerPosition, map, onPlayerAttacked);
    } else {
      ghost.isChasing = false;
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

    // 计算移动方向
    int dx = 0;
    int dy = 0;

    if (ghost.position!.x < playerPosition.x) dx = 1;
    else if (ghost.position!.x > playerPosition.x) dx = -1;

    if (ghost.position!.y < playerPosition.y) dy = 1;
    else if (ghost.position!.y > playerPosition.y) dy = -1;

    // 随机决定优先移动水平还是垂直方向
    if (_random.nextBool()) {
      if (dx != 0) _tryMoveGhost(ghost, dx, 0, map, playerPosition, onPlayerAttacked);
      else if (dy != 0) _tryMoveGhost(ghost, 0, dy, map, playerPosition, onPlayerAttacked);
    } else {
      if (dy != 0) _tryMoveGhost(ghost, 0, dy, map, playerPosition, onPlayerAttacked);
      else if (dx != 0) _tryMoveGhost(ghost, dx, 0, map, playerPosition, onPlayerAttacked);
    }
  }

  // 鬼随机移动
  void _moveGhostRandomly(Ghost ghost, List<List<String>> map) {
    if (ghost.position == null) return;

    final directions = [
      Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)
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
      int dx,
      int dy,
      List<List<String>> map,
      Point<int>? playerPosition,
      Function(Map<String, int>)? onPlayerAttacked,
      ) {
    if (ghost.position == null) return false;

    final newX = ghost.position!.x + dx;
    final newY = ghost.position!.y + dy;

    // 检查新位置是否可行走
    if (newX >= 0 && newX < map[0].length &&
        newY >= 0 && newY < map.length &&
        map[newY][newX] != 'wall' &&
        map[newY][newX] != 'water') {

      ghost.position = Point(newX, newY);

      // 检查是否碰到玩家
      if (playerPosition != null &&
          onPlayerAttacked != null &&
          newX == playerPosition.x &&
          newY == playerPosition.y) {
        _ghostAttackPlayer(ghost, onPlayerAttacked);
      }

      return true;
    }

    return false;
  }

  // 鬼攻击玩家
  void _ghostAttackPlayer(Ghost ghost, Function(Map<String, int>) onPlayerAttacked) {
    if (ghost.remainingAttacks <= 0) {
      ghost.isInCooldown = true;
      Future.delayed(Duration(seconds: ghost.cooldownTime), () {
        ghost.isInCooldown = false;
        ghost.resetAttacks();
      });
      return;
    }

    ghost.remainingAttacks--;
    final effects = ghost.attackEffects();
    onPlayerAttacked(effects);

    if (ghost.remainingAttacks <= 0) {
      ghost.isInCooldown = true;
      Future.delayed(Duration(seconds: ghost.cooldownTime), () {
        ghost.isInCooldown = false;
        ghost.resetAttacks();
      });
    }
  }
}