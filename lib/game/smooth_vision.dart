// 平滑视野系统 - 实现像手电筒一样的流畅视野过渡效果
// 支持瓦片的渐进显示和隐藏，避免突然的视野切换
// 支持圆形视野边界和墙体遮挡效果

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'enhanced_vision.dart';

/// 瓦片的视野状态
class TileVisionState {
  final math.Point<int> position;
  double opacity; // 当前透明度 (0.0 - 1.0)
  double targetOpacity; // 目标透明度
  TileVisibility visibility; // 可见性级别
  DateTime lastUpdateTime; // 最后更新时间

  TileVisionState({
    required this.position,
    this.opacity = 0.0,
    this.targetOpacity = 0.0,
    this.visibility = TileVisibility.notVisible,
    DateTime? lastUpdateTime,
  }) : lastUpdateTime = lastUpdateTime ?? DateTime.now();

  /// 更新透明度，返回是否需要重绘
  bool updateOpacity(DateTime currentTime) {
    const fadeSpeed = 3.0; // 透明度变化速度 (每秒)
    final deltaTime = currentTime.difference(lastUpdateTime).inMilliseconds / 1000.0;
    lastUpdateTime = currentTime;

    if ((opacity - targetOpacity).abs() < 0.01) {
      opacity = targetOpacity;
      return false; // 已达到目标，无需重绘
    }

    final change = fadeSpeed * deltaTime;
    if (opacity < targetOpacity) {
      opacity = math.min(opacity + change, targetOpacity);
    } else {
      opacity = math.max(opacity - change, targetOpacity);
    }

    return true; // 需要重绘
  }

  /// 设置为完全可见状态
  void setFullyVisible() {
    visibility = TileVisibility.fullyVisible;
    targetOpacity = 1.0;
  }

  /// 设置为部分可见状态（被遮挡）
  void setPartiallyVisible() {
    visibility = TileVisibility.partiallyVisible;
    targetOpacity = EnhancedVisionSystem.partialVisibilityOpacity;
  }

  /// 设置为可见但有雾霾装饰状态
  void setVisibleWithFogDecoration() {
    visibility = TileVisibility.visibleWithFogDecoration;
    targetOpacity = 1.0; // 完全可见，但会有雾霾装饰效果
  }

  /// 设置为部分可见但有雾霾装饰状态
  void setPartiallyVisibleWithFogDecoration() {
    visibility = TileVisibility.partiallyVisibleWithFogDecoration;
    targetOpacity = EnhancedVisionSystem.partialVisibilityOpacity; // 部分可见，但会有雾霾装饰效果
  }

  /// 设置为不可见状态
  void setInvisible() {
    visibility = TileVisibility.notVisible;
    targetOpacity = 0.0;
  }

  /// 是否在视野范围内（兼容性getter）
  bool get isVisible => visibility != TileVisibility.notVisible;

  /// 是否应该渲染（透明度 > 0）
  bool get shouldRender => opacity > 0.01;
}

/// 平滑视野管理器
class SmoothVisionManager {
  // 所有瓦片的视野状态
  final Map<math.Point<int>, TileVisionState> _tileStates = {};
  
  // 当前可见的瓦片集合（用于快速查询）
  Set<math.Point<int>> _currentVisibleTiles = {};
  
  // 上次更新时间
  DateTime _lastUpdateTime = DateTime.now();
  
  // 性能优化：缓存需要渲染的瓦片
  Map<math.Point<int>, double> _cachedRenderableTiles = {};
  bool _renderableTilesCacheValid = false;
  
  // 性能优化：限制最大瓦片数量，防止内存泄漏
  static const int _maxTileStates = 2000;

  /// 更新视野状态（使用增强版视野系统）
  void updateVisionWithLevels(Map<math.Point<int>, TileVisibility> tilesWithVisibility) {
    final currentTime = DateTime.now();
    bool hasChanges = false;
    
    // 更新所有瓦片的可见性级别
    for (final entry in tilesWithVisibility.entries) {
      final tile = entry.key;
      final newVisibility = entry.value;
      
      final state = _tileStates.putIfAbsent(
        tile, 
        () => TileVisionState(position: tile),
      );
      
      if (state.visibility != newVisibility) {
        switch (newVisibility) {
          case TileVisibility.fullyVisible:
            state.setFullyVisible();
            break;
          case TileVisibility.partiallyVisible:
            state.setPartiallyVisible();
            break;
          case TileVisibility.visibleWithFogDecoration:
            state.setVisibleWithFogDecoration();
            break;
          case TileVisibility.partiallyVisibleWithFogDecoration:
            state.setPartiallyVisibleWithFogDecoration();
            break;
          case TileVisibility.notVisible:
            state.setInvisible();
            break;
        }
        hasChanges = true;
      }
    }

    // 标记不再在视野范围内的瓦片为不可见
    final currentTiles = tilesWithVisibility.keys.toSet();
    for (final tile in _currentVisibleTiles) {
      if (!currentTiles.contains(tile)) {
        final state = _tileStates[tile];
        if (state != null && state.isVisible) {
          state.setInvisible();
          hasChanges = true;
        }
      }
    }

    // 性能优化：限制瓦片状态数量
    if (_tileStates.length > _maxTileStates) {
      _cleanupOldTileStates();
    }

    _currentVisibleTiles = currentTiles;
    _lastUpdateTime = currentTime;
    
    // 如果有变化，使缓存失效
    if (hasChanges) {
      _renderableTilesCacheValid = false;
    }
  }

  /// 更新所有瓦片的透明度动画
  bool updateAnimations() {
    final currentTime = DateTime.now();
    bool needsRepaint = false;

    // 只更新有动画的瓦片，提高性能
    final tilesToRemove = <math.Point<int>>[];
    
    for (final entry in _tileStates.entries) {
      final state = entry.value;
      
      // 只更新需要动画的瓦片
      if (state.opacity != state.targetOpacity) {
        final updated = state.updateOpacity(currentTime);
        
        if (updated) {
          needsRepaint = true;
          _renderableTilesCacheValid = false; // 使缓存失效
        }
      }

      // 清理完全不可见且不在视野中的瓦片（延迟清理，避免频繁操作）
      if (!state.isVisible && 
          state.opacity <= 0.01 && 
          currentTime.difference(state.lastUpdateTime).inSeconds > 2) {
        tilesToRemove.add(entry.key);
      }
    }

    // 批量移除不需要的瓦片状态
    if (tilesToRemove.isNotEmpty) {
      for (final tile in tilesToRemove) {
        _tileStates.remove(tile);
      }
      _renderableTilesCacheValid = false; // 使缓存失效
    }

    return needsRepaint;
  }

  /// 获取瓦片的当前透明度
  double getTileOpacity(math.Point<int> tile) {
    final state = _tileStates[tile];
    return state?.opacity ?? 0.0;
  }

  /// 获取所有应该渲染的瓦片（透明度 > 0）
  Map<math.Point<int>, double> getRenderableTiles() {
    // 使用缓存提高性能
    if (_renderableTilesCacheValid) {
      return _cachedRenderableTiles;
    }
    
    final result = <math.Point<int>, double>{};
    
    for (final entry in _tileStates.entries) {
      final state = entry.value;
      if (state.shouldRender) {
        result[entry.key] = state.opacity;
      }
    }
    
    _cachedRenderableTiles = result;
    _renderableTilesCacheValid = true;
    
    return result;
  }

  /// 检查瓦片是否应该渲染
  bool shouldRenderTile(math.Point<int> tile) {
    final state = _tileStates[tile];
    return state?.shouldRender ?? false;
  }
  
  /// 获取瓦片的可见性状态
  TileVisibility? getTileVisibility(math.Point<int> tile) {
    final state = _tileStates[tile];
    return state?.visibility;
  }

  /// 获取当前活跃的瓦片数量（用于调试）
  int get activeTileCount => _tileStates.length;

  /// 清理旧的瓦片状态，防止内存泄漏
  void _cleanupOldTileStates() {
    final currentTime = DateTime.now();
    final tilesToRemove = <math.Point<int>>[];
    
    // 找出最旧的、不可见的、透明度为0的瓦片
    for (final entry in _tileStates.entries) {
      final state = entry.value;
      if (!state.isVisible && 
          state.opacity <= 0.01 && 
          currentTime.difference(state.lastUpdateTime).inSeconds > 5) {
        tilesToRemove.add(entry.key);
      }
    }
    
    // 如果还是太多，强制移除一些最旧的
    if (_tileStates.length - tilesToRemove.length > _maxTileStates) {
      final sortedEntries = _tileStates.entries.toList()
        ..sort((a, b) => a.value.lastUpdateTime.compareTo(b.value.lastUpdateTime));
      
      final additionalRemoveCount = _tileStates.length - tilesToRemove.length - _maxTileStates + 100;
      for (int i = 0; i < additionalRemoveCount && i < sortedEntries.length; i++) {
        if (!tilesToRemove.contains(sortedEntries[i].key)) {
          tilesToRemove.add(sortedEntries[i].key);
        }
      }
    }
    
    // 移除选定的瓦片
    for (final tile in tilesToRemove) {
      _tileStates.remove(tile);
    }
    
    // 使缓存失效
    _renderableTilesCacheValid = false;
  }

  /// 清理所有状态
  void clear() {
    _tileStates.clear();
    _currentVisibleTiles.clear();
    _cachedRenderableTiles.clear();
    _renderableTilesCacheValid = false;
  }

  /// 调试信息
  void printDebugInfo() {
    if (kDebugMode) {
      print('平滑视野状态:');
      print('  活跃瓦片数: ${_tileStates.length}');
      print('  当前可见瓦片数: ${_currentVisibleTiles.length}');
      
      int fadingIn = 0;
      int fadingOut = 0;
      int stable = 0;
      
      for (final state in _tileStates.values) {
        if ((state.opacity - state.targetOpacity).abs() < 0.01) {
          stable++;
        } else if (state.opacity < state.targetOpacity) {
          fadingIn++;
        } else {
          fadingOut++;
        }
      }
      
      print('  渐入: $fadingIn, 渐出: $fadingOut, 稳定: $stable');
    }
  }
}