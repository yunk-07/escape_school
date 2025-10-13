import 'dart:math';

class VisionSystem {
  final List<List<String>> map;

  VisionSystem({required this.map});

  // 获取基础视野范围
  static const int baseViewRadius = 5;

  // 获取当前地形的视野修正
  double _getTerrainVisionModifier(String terrain) {
    switch (terrain) {
      case 'woods':
        return 0.4; // 树林中视野缩小40%
      case 'building':
        return 1.0; // 建筑内视野缩小20%
      default:
        return 1.0; // 其他地形无修正
    }
  }

  // 检查两点之间是否有阻挡(墙)
  bool _hasLineOfSight(Point<int> from, Point<int> to) {
    List<Point<int>> line = _getLine(from, to);
    for (Point<int> p in line) {
      // 跳过起点和终点
      if (p.x == from.x && p.y == from.y) continue;
      if (p.x == to.x && p.y == to.y) continue;

      // 如果是墙，则阻挡后续视野
      if (map[p.y][p.x] == 'wall') {
        return false;
      }
    }
    return true;
  }

  // 新增方法：获取相连的墙体组
  Set<Point<int>> _getConnectedWalls(Point<int> start, int radius) {
    Set<Point<int>> walls = {};
    Set<Point<int>> visited = {};
    List<Point<int>> queue = [start];

    while (queue.isNotEmpty) {
      Point<int> current = queue.removeLast();
      if (visited.contains(current)) continue;
      visited.add(current);

      // 边界检查 - 确保坐标在地图范围内
      if (current.x < 0 || current.x >= map[0].length ||
          current.y < 0 || current.y >= map.length) {
        continue;
      }

      // 检查是否在视野半径内
      final distance = sqrt(pow(current.x - start.x, 2) + pow(current.y - start.y, 2));
      if (distance > radius) continue;

      // 检查是否是墙体
      if (map[current.y][current.x] == 'wall') {
        walls.add(current);
        // 检查四个方向的相邻格子（带边界检查）
        final neighbors = [
          Point(current.x + 1, current.y),
          Point(current.x - 1, current.y),
          Point(current.x, current.y + 1),
          Point(current.x, current.y - 1),
        ];

        // 过滤掉越界的邻居
        queue.addAll(neighbors.where((p) =>
        p.x >= 0 && p.x < map[0].length &&
            p.y >= 0 && p.y < map.length
        ));
      }
    }
    return walls;
  }

  // Bresenham直线算法
  List<Point<int>> _getLine(Point<int> from, Point<int> to) {
    List<Point<int>> points = [];
    int x0 = from.x, y0 = from.y;
    int x1 = to.x, y1 = to.y;

    int dx = (x1 - x0).abs();
    int dy = -(y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy, e2;

    while (true) {
      points.add(Point(x0, y0));
      if (x0 == x1 && y0 == y1) break;
      e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x0 += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y0 += sy;
      }
    }
    return points;
  }

  // 获取可见的格子 - 带视线遮挡的圆形视野（半径5格）
  Set<Point<int>> getVisibleTiles(Point<int> playerPos) {
    // 首先检查玩家位置是否有效
    if (playerPos.x < 0 || playerPos.x >= map[0].length ||
        playerPos.y < 0 || playerPos.y >= map.length) {
      return {};
    }

    Set<Point<int>> visible = {};
    // 固定视野半径为5格，不受地形影响
    const radius = baseViewRadius;

    // 玩家当前位置总是可见的
    visible.add(playerPos);

    // 遍历以玩家为中心的圆形区域
    for (int y = -radius; y <= radius; y++) {
      for (int x = -radius; x <= radius; x++) {
        // 跳过玩家自己的位置
        if (x == 0 && y == 0) continue;
        
        // 计算距离的平方
        final distanceSquared = x * x + y * y;
        
        // 只有在圆形范围内的格子才需要检查
        if (distanceSquared <= radius * radius) {
          final tileX = playerPos.x + x;
          final tileY = playerPos.y + y;

          // 边界检查
          if (tileX >= 0 && tileX < map[0].length &&
              tileY >= 0 && tileY < map.length) {
            
            final targetPos = Point(tileX, tileY);
            
            // 检查从玩家位置到目标位置是否有视线
            if (_hasLineOfSight(playerPos, targetPos)) {
              visible.add(targetPos);
            }
          }
        }
      }
    }

    return visible;
  }
}