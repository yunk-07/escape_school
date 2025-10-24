/**
 * 生命值监听器
 * 
 * 功能：
 * - 监听生命值变化
 * - 检测生命值减少并触发伤害效果
 * - 支持动态强度和持续时间调整
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'optimized_game_state.dart';

/// 伤害事件数据类
class DamageEvent {
  final double damageAmount;
  final DateTime timestamp;
  final int intensity; // 1-100
  final int duration; // 100-800毫秒
  final double effectRadius; // 0.2-3.0格

  DamageEvent({
    required this.damageAmount,
    required this.timestamp,
    required this.intensity,
    required this.duration,
    required this.effectRadius,
  });

  /// 根据伤害量计算效果参数 
  factory DamageEvent.fromDamage(double damage) {
    // 调整伤害量到强度的映射，使小伤害产生小效果
    // 假设最大伤害为20HP，将0.1-20的伤害映射到1-100的强度
    final intensity = ((damage / 20.0) * 99 + 1).clamp(1, 100).toInt();
    
    // 持续时间：固定为400毫秒（0.4秒），不再根据伤害量变化
    final duration = 400;
    
    // 效果半径：直接基于伤害量计算，0.1-20伤害映射到0.1-2.0格
    // 这样1点伤害只产生0.1格的小红边，而不是之前的1格
    final effectRadius = (0.1 + (damage / 20.0) * 1.9).clamp(0.1, 2.0);

    return DamageEvent(
      damageAmount: damage,
      timestamp: DateTime.now(),
      intensity: intensity,
      duration: duration,
      effectRadius: effectRadius,
    );
  }

  @override
  String toString() {
    return 'DamageEvent(damage: $damageAmount, intensity: $intensity, duration: ${duration}ms, radius: ${effectRadius.toStringAsFixed(1)})';
  }
}

/// HP监听器组件
class HPListener extends ConsumerStatefulWidget {
  final Widget child;
  final Function(DamageEvent)? onDamageDetected;

  const HPListener({
    Key? key,
    required this.child,
    this.onDamageDetected,
  }) : super(key: key);

  @override
  ConsumerState<HPListener> createState() => _HPListenerState();
}

class _HPListenerState extends ConsumerState<HPListener> {
  double? _previousHp;
  DateTime? _lastDamageTime;

  @override
  Widget build(BuildContext context) {
    // ref.listen必须在build方法中使用，但我们使用延迟回调避免构建期间状态修改
    ref.listen<OptimizedGameState>(optimizedGameStateProvider, (previous, current) {
      // 使用addPostFrameCallback延迟处理，确保不在构建期间修改状态
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            _checkHPChange(previous, current);
          } catch (e) {
            print('HP监听器处理错误: $e');
          }
        }
      });
    });
    
    return widget.child;
  }

  /// 检查HP变化
  void _checkHPChange(OptimizedGameState? previous, OptimizedGameState current) {
    final currentHp = current.characterStats['hp']?.toDouble() ?? 0.0;
    
    // 初始化或获取之前的HP值
    final previousHp = _previousHp ?? currentHp;
    
    // 检测HP减少
    if (currentHp < previousHp) {
      final damageAmount = previousHp - currentHp;
      final now = DateTime.now();
      
      // 防止重复触发（100毫秒内的变化视为同一次伤害）
      if (_lastDamageTime == null || 
          now.difference(_lastDamageTime!).inMilliseconds > 100) {
        
        final damageEvent = DamageEvent.fromDamage(damageAmount);
        
        print('HP监听器检测到伤害: ${damageEvent.toString()}');
        
        // 触发伤害事件
        widget.onDamageDetected?.call(damageEvent);
        
        _lastDamageTime = now;
      }
    }
    
    // 更新之前的HP值
    _previousHp = currentHp;
  }
}

/// 伤害事件状态管理
class DamageEventNotifier extends StateNotifier<DamageEvent?> {
  DamageEventNotifier() : super(null);

  /// 触发新的伤害事件
  void triggerDamage(DamageEvent event) {
    state = event;
  }

  /// 清除伤害事件
  void clearDamage() {
    state = null;
  }
}

/// 伤害事件Provider
final damageEventProvider = StateNotifierProvider<DamageEventNotifier, DamageEvent?>((ref) {
  return DamageEventNotifier();
});