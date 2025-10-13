// 增强版视野系统 - 支持圆形视野边界和墙体遮挡效果
// 提供三种可见性级别：完全可见、被遮挡但在视野范围内、完全不可见

import 'dart:math';

/// 瓦片可见性级别
enum TileVisibility {
  /// 完全可见 - 在视野范围内且无遮挡
  fullyVisible,
  
  /// 部分可见 - 在视野范围内但被墙体遮挡
  partiallyVisible,
  
  /// 完全可见但有雾霾装饰 - 可见但覆盖雾霾装饰效果
  visibleWithFogDecoration,
  
  /// 部分可见但有雾霾装饰 - 被遮挡但覆盖雾霾装饰效果
  partiallyVisibleWithFogDecoration,
  
  /// 不可见 - 超出视野范围
  notVisible,
}

/// 增强版视野系统
class EnhancedVisionSystem {
  final List<List<String>> map;
  
  // 视野配置
  static const int baseViewRadius = 5;
  static const int minViewRadius = 1; // 最小视野半径（精神值为0时）
  static const int maxViewRadius = 5; // 最大视野半径（精神值为100时）
  static const int rayCount = 64; // 射线数量，影响精度
  static const double partialVisibilityOpacity = 0.4;
  
  // 雾状效果配置
  static const double foggyEdgeOpacity = 0.7; // 雾状边缘透明度
  static const double deepFogOpacity = 0.3; // 深度雾状透明度
  static const double fogTransitionZone = 1.5; // 雾状过渡区域大小
  
  // 不规则雾霾效果配置
  static const double noiseScale = 0.15; // 噪声缩放因子 - 增加细节
  static const double noiseAmplitude = 0.8; // 噪声强度 - 减少过度扰动
  static const double fogVariation = 0.6; // 雾状变化程度 - 平衡规则性和随机性
  static const int noiseSeed = 42; // 噪声种子
  static const double fogDensityVariation = 0.3; // 雾密度变化

  // 性能优化缓存
  Point<int>? _lastPlayerPos;
  double? _lastSanityValue;
  Map<Point<int>, TileVisibility>? _cachedResult;
  Set<Point<int>>? _cachedCircularTiles;
  Set<Point<int>>? _cachedDirectlyVisible;

  EnhancedVisionSystem({required this.map});

  /// 根据精神值计算动态视野半径
  int calculateViewRadius(double sanityValue, double maxSanity) {
    // 精神值百分比 (可以超过1.0，允许视野超过100%)
    final sanityPercentage = (sanityValue / maxSanity).clamp(0.0, double.infinity);
    
    // 当精神值在0-100%时，使用非线性函数
    // 当精神值超过100%时，线性增长
    double adjustedPercentage;
    if (sanityPercentage <= 1.0) {
      // 使用平方函数，让精神值低时视野急剧缩小
      adjustedPercentage = sanityPercentage * sanityPercentage;
    } else {
      // 超过100%时，线性增长
      adjustedPercentage = 1.0 + (sanityPercentage - 1.0);
    }
    
    // 计算视野半径：从最小值开始，可以无限增长
    final radius = (minViewRadius + (maxViewRadius - minViewRadius) * adjustedPercentage).round();
    
    // 只限制最小值，不限制最大值
    return radius.clamp(minViewRadius, double.infinity).toInt();
  }

  /// 获取玩家视野内的所有瓦片及其可见性级别
  Map<Point<int>, TileVisibility> getVisibleTilesWithLevel(Point<int> playerPos, {double sanityValue = 100.0, double maxSanity = 100.0}) {
    // 首先检查玩家位置是否有效
    if (playerPos.x < 0 || playerPos.x >= map[0].length ||
        playerPos.y < 0 || playerPos.y >= map.length) {
      return {};
    }

    // 检查缓存（包括精神值变化）
    if (_lastPlayerPos == playerPos && _lastSanityValue == sanityValue && _cachedResult != null) {
      return _cachedResult!;
    }

    final result = <Point<int>, TileVisibility>{};
    
    // 根据精神值计算动态视野半径
    final currentViewRadius = calculateViewRadius(sanityValue, maxSanity);
    
    // 玩家当前位置总是完全可见的
    result[playerPos] = TileVisibility.fullyVisible;
    
    // 计算多层视野区域
    final coreRadius = currentViewRadius * 0.7; // 核心清晰区域
    final fogRadius = currentViewRadius + fogTransitionZone; // 雾状区域
    final deepFogRadius = currentViewRadius + fogTransitionZone * 2; // 深度雾状区域
    
    // 获取所有可能影响的瓦片（包括雾状区域）
    final allTiles = _getCircularVisionTiles(playerPos, radius: deepFogRadius.ceil());
    
    // 计算直接可见的瓦片（无遮挡）
    final directlyVisibleTiles = _getDirectlyVisibleTiles(playerPos, allTiles);
    
    // 为每个瓦片分配可见性级别（雾霾作为装饰效果）
    for (final tile in allTiles) {
      final distance = _getDistance(playerPos, tile);
      final isDirectlyVisible = directlyVisibleTiles.contains(tile);
      
      if (distance <= currentViewRadius) {
        // 在实际视野范围内的瓦片
        
        // 检查是否应该添加雾霾装饰效果
        bool shouldHaveFogDecoration = _shouldHaveFogDecoration(tile, playerPos);
        
        if (shouldHaveFogDecoration) {
          // 添加雾霾装饰效果
          if (isDirectlyVisible) {
            result[tile] = TileVisibility.visibleWithFogDecoration;
          } else {
            result[tile] = TileVisibility.partiallyVisibleWithFogDecoration;
          }
        } else {
          // 正常显示
          if (isDirectlyVisible) {
            result[tile] = TileVisibility.fullyVisible;
          } else {
            result[tile] = TileVisibility.partiallyVisible;
          }
        }
      }
      // 超出视野范围的瓦片保持不可见（不添加到result中）
    }
    
    // 更新缓存
    _lastPlayerPos = playerPos;
    _lastSanityValue = sanityValue;
    _cachedResult = result;
    
    return result;
  }
  
  /// 获取圆形视野范围内的所有瓦片
  Set<Point<int>> _getCircularVisionTiles(Point<int> center, {int? radius}) {
    final tiles = <Point<int>>{};
    final viewRadius = radius ?? baseViewRadius;
    
    // 遍历以玩家为中心的圆形区域
    for (int y = -viewRadius; y <= viewRadius; y++) {
      for (int x = -viewRadius; x <= viewRadius; x++) {
        // 计算距离的平方
        final distanceSquared = x * x + y * y;
        
        // 只有在圆形范围内的格子才需要检查
        if (distanceSquared <= viewRadius * viewRadius) {
          final tileX = center.x + x;
          final tileY = center.y + y;

          // 边界检查
          if (tileX >= 0 && tileX < map[0].length &&
              tileY >= 0 && tileY < map.length) {
            tiles.add(Point(tileX, tileY));
          }
        }
      }
    }
    
    return tiles;
  }
  
  /// 获取直接可见的瓦片（无遮挡）
  Set<Point<int>> _getDirectlyVisibleTiles(Point<int> center, Set<Point<int>> candidateTiles) {
    final directlyVisible = <Point<int>>{};
    
    // 玩家位置总是可见的
    directlyVisible.add(center);
    
    // 按距离排序候选瓦片，优先处理近距离瓦片
    final sortedTiles = candidateTiles.toList()
      ..sort((a, b) {
        final distA = (a.x - center.x) * (a.x - center.x) + (a.y - center.y) * (a.y - center.y);
        final distB = (b.x - center.x) * (b.x - center.x) + (b.y - center.y) * (b.y - center.y);
        return distA.compareTo(distB);
      });
    
    // 对每个候选瓦片，检查是否有直接视线
    for (final tile in sortedTiles) {
      if (tile == center) continue; // 跳过中心点
      
      if (_hasLineOfSight(center, tile)) {
        directlyVisible.add(tile);
      }
    }
    
    return directlyVisible;
  }

  /// 清理缓存（当地图发生变化时调用）
  void clearCache() {
    _lastPlayerPos = null;
    _lastSanityValue = null;
    _cachedResult = null;
    _cachedCircularTiles = null;
    _cachedDirectlyVisible = null;
  }
  
  /// 检查两点之间是否有直接视线（无墙体遮挡）
  bool _hasLineOfSight(Point<int> from, Point<int> to) {
    final line = _getLine(from, to);
    
    // 检查线上的每个点（除了起点和终点）
    for (int i = 1; i < line.length - 1; i++) {
      final point = line[i];
      
      // 如果是墙，则阻挡视线
      if (_isWall(point)) {
        return false;
      }
    }
    
    return true;
  }
  
  /// 检查指定位置是否是墙
  bool _isWall(Point<int> point) {
    // 边界检查
    if (point.x < 0 || point.x >= map[0].length ||
        point.y < 0 || point.y >= map.length) {
      return true; // 地图边界视为墙
    }
    
    return map[point.y][point.x] == 'wall';
  }
  
  /// 计算两点之间的欧几里得距离
  double _getDistance(Point<int> from, Point<int> to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    return sqrt(dx * dx + dy * dy);
  }
  
  /// Bresenham直线算法 - 获取两点之间的所有点
  List<Point<int>> _getLine(Point<int> from, Point<int> to) {
    final points = <Point<int>>[];
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
  
  /// 简化的噪声函数 - 生成基于位置的伪随机值
  double _noise(double x, double y) {
    // 使用简单的哈希函数生成噪声
    int n = ((x * 374761393 + y * 668265263) + noiseSeed).floor();
    n = (n << 13) ^ n;
    return (1.0 - ((n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0);
  }
  
  /// 平滑噪声函数
  double _smoothNoise(double x, double y) {
    double corners = (_noise(x-1, y-1) + _noise(x+1, y-1) + _noise(x-1, y+1) + _noise(x+1, y+1)) / 16;
    double sides = (_noise(x-1, y) + _noise(x+1, y) + _noise(x, y-1) + _noise(x, y+1)) / 8;
    double center = _noise(x, y) / 4;
    return corners + sides + center;
  }
  
  /// 插值噪声函数
  double _interpolatedNoise(double x, double y) {
    int intX = x.floor();
    double fracX = x - intX;
    int intY = y.floor();
    double fracY = y - intY;
    
    double v1 = _smoothNoise(intX.toDouble(), intY.toDouble());
    double v2 = _smoothNoise((intX + 1).toDouble(), intY.toDouble());
    double v3 = _smoothNoise(intX.toDouble(), (intY + 1).toDouble());
    double v4 = _smoothNoise((intX + 1).toDouble(), (intY + 1).toDouble());
    
    double i1 = _cosineInterpolate(v1, v2, fracX);
    double i2 = _cosineInterpolate(v3, v4, fracX);
    
    return _cosineInterpolate(i1, i2, fracY);
  }
  
  /// 余弦插值函数
  double _cosineInterpolate(double a, double b, double x) {
    double ft = x * pi;
    double f = (1 - cos(ft)) * 0.5;
    return a * (1 - f) + b * f;
  }
  
  /// 多层噪声函数（类似Perlin噪声）
  double _perlinNoise(double x, double y) {
    double total = 0;
    double persistence = 0.5;
    int octaves = 4;
    
    for (int i = 0; i < octaves; i++) {
      double frequency = pow(2, i).toDouble();
      double amplitude = pow(persistence, i).toDouble();
      total += _interpolatedNoise(x * frequency, y * frequency) * amplitude;
    }
    
    return total;
  }
  
  /// 计算带噪声扰动的距离
  double _getDistanceWithNoise(Point<int> from, Point<int> to) {
    double baseDistance = _getDistance(from, to);
    
    // 生成基于位置的噪声
    double noiseX = to.x * noiseScale;
    double noiseY = to.y * noiseScale;
    double noiseValue = _perlinNoise(noiseX, noiseY);
    
    // 应用噪声扰动
    double disturbance = noiseValue * noiseAmplitude;
    return baseDistance + disturbance;
  }
  
  /// 判断瓦片是否应该有雾霾装饰效果
  bool _shouldHaveFogDecoration(Point<int> tile, Point<int> playerPos) {
    // 使用多层噪声创建不规则的雾霾装饰区域
    double primaryNoise = _perlinNoise(tile.x * noiseScale, tile.y * noiseScale);
    double secondaryNoise = _perlinNoise(tile.x * noiseScale * 2.0, tile.y * noiseScale * 2.0) * 0.5;
    double combinedNoise = primaryNoise + secondaryNoise;
    
    // 基于距离调整雾霾出现的概率
    double distance = _getDistance(playerPos, tile);
    double maxDistance = calculateViewRadius(100.0, 100.0).toDouble(); // 使用最大视野半径
    double distanceRatio = distance / maxDistance;
    
    // 距离越远，雾霾出现概率越高
    double fogThreshold = 0.2 - distanceRatio * 0.4;
    
    // 添加一些随机性，让雾霾分布更自然
    double randomFactor = _perlinNoise(tile.x * 0.05, tile.y * 0.05) * 0.3;
    
    return combinedNoise + randomFactor > fogThreshold;
  }
}