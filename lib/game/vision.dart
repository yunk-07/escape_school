import 'dart:math';
import '../data/mapData.dart';

class VisionSystem {
  final List<List<String>> map;
  final Random _random = Random();

  VisionSystem({required this.map});

  // 获取基础视野范围
  static const int baseViewRadius = 5;

  // 获取当前地形的视野修正
  double _getTerrainVisionModifier(String terrain) {
    switch (terrain) {
      case 'woods':
        return 0.6; // 树林中视野缩小40%
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

  // 获取可见的格子
  Set<Point<int>> getVisibleTiles(Point<int> playerPos) {
    Set<Point<int>> visible = {};
    final terrain = map[playerPos.y][playerPos.x];
    final radius = (baseViewRadius * _getTerrainVisionModifier(terrain)).round();

    // 首先添加所有在视野范围内的墙体
    for (int y = -radius; y <= radius; y++) {
      for (int x = -radius; x <= radius; x++) {
        final tileX = playerPos.x + x;
        final tileY = playerPos.y + y;

        if (tileX < 0 || tileX >= map[0].length ||
            tileY < 0 || tileY >= map.length) continue;

        if (map[tileY][tileX] == 'wall' &&
            x * x + y * y <= radius * radius) {
          visible.add(Point(tileX, tileY));
        }
      }
    }

    // 然后添加可见的非墙体格子
    for (int y = -radius; y <= radius; y++) {
      for (int x = -radius; x <= radius; x++) {
        if (x * x + y * y > radius * radius) continue;

        final tileX = playerPos.x + x;
        final tileY = playerPos.y + y;

        if (tileX < 0 || tileX >= map[0].length ||
            tileY < 0 || tileY >= map.length) continue;

        // 跳过已经添加的墙体
        if (map[tileY][tileX] == 'wall') continue;

        // 检查视线
        if (_hasLineOfSight(playerPos, Point(tileX, tileY))) {
          visible.add(Point(tileX, tileY));
        }
      }
    }

    return visible;
  }
}