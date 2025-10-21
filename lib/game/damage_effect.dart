/**
 * 伤害效果组件 - 重新设计版本
 * 
 * 功能：
 * - 显示红色雾状边框效果
 * - 支持动态强度调整（1-100）
 * - 支持动态持续时间（100-800毫秒）
 * - 支持动态效果半径（0.2-3.0格）
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hp_listener.dart';

class DynamicDamageEffect extends ConsumerStatefulWidget {
  final Widget child;

  const DynamicDamageEffect({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<DynamicDamageEffect> createState() => _DynamicDamageEffectState();
}

class _DynamicDamageEffectState extends ConsumerState<DynamicDamageEffect>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _opacityAnimation;
  Animation<double>? _scaleAnimation;
  DamageEvent? _currentEvent;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    // 创建持久的动画控制器
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300), // 默认持续时间
      vsync: this,
    );

    // 添加状态监听器（只添加一次）
    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller!.reverse();
      } else if (status == AnimationStatus.dismissed) {
        // 动画完成后清除伤害事件和状态
        _isAnimating = false;
        // 使用异步方式清除provider状态，避免在动画回调中直接修改
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              ref.read(damageEventProvider.notifier).clearDamage();
            } catch (e) {
              print('清除伤害事件时出错: $e');
            }
          }
        });
        setState(() {
          _currentEvent = null;
        });
      }
    });
  }

  @override
  void dispose() {
    if (_controller != null) {
      try {
        _controller!.dispose();
      } catch (e) {
        // 忽略重复销毁的错误
      }
    }
    super.dispose();
  }

  /// 配置动画控制器
  void _configureAnimationController(DamageEvent event) {
    // 如果正在动画中，先停止当前动画
    if (_isAnimating) {
      _controller!.stop();
      _controller!.reset();
      _isAnimating = false;
    }

    // 更新动画持续时间
    _controller!.duration = Duration(milliseconds: event.duration);
    _isAnimating = true;

    // 透明度动画：快速出现，平缓消失，更适合屏幕红边效果
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller!,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOut), // 更快出现
      reverseCurve: const Interval(0.2, 1.0, curve: Curves.easeInQuad), // 平缓消失
    ));

    // 缩放动画：轻微的脉冲效果，模拟屏幕震动感
    final scaleIntensity = 1.0 + (event.intensity / 100.0) * 0.02; // 1.0 - 1.02，减小缩放幅度
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: scaleIntensity,
    ).animate(CurvedAnimation(
      parent: _controller!,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut), // 弹性效果
      reverseCurve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    // 开始动画
    _controller!.forward();
  }

  /// 根据伤害事件计算屏幕边缘红边的厚度
  double _calculateEdgeThickness(DamageEvent event) {
    // 根据强度计算边缘厚度：5-25像素，减小厚度使效果更精细
    return 5.0 + (event.intensity / 100.0) * 20.0;
  }

  /// 根据伤害事件计算红边的透明度
  double _calculateEdgeOpacity(DamageEvent event) {
    // 根据强度计算透明度：0.3-0.7，适中的透明度范围
    return 0.3 + (event.intensity / 100.0) * 0.4;
  }

  /// 根据伤害事件计算模糊半径
  double _calculateBlurRadius(DamageEvent event) {
    // 减小模糊半径，让边缘更清晰：3.0 - 12.0
    return 3.0 + (event.intensity / 100.0) * 9.0;
  }

  @override
  Widget build(BuildContext context) {
    // 监听伤害事件
    final damageEvent = ref.watch(damageEventProvider);
    
    // 当有新的伤害事件时，创建动画
    if (damageEvent != null && damageEvent != _currentEvent) {
      _currentEvent = damageEvent;
      _configureAnimationController(damageEvent);
    }

    // 如果没有动画控制器或当前事件，只显示子组件
    if (_controller == null || _currentEvent == null) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        final event = _currentEvent!;
        final opacity = _opacityAnimation?.value ?? 0.0;
        final scale = _scaleAnimation?.value ?? 1.0;
        final edgeThickness = _calculateEdgeThickness(event);
        final edgeOpacity = _calculateEdgeOpacity(event);
        final blurRadius = _calculateBlurRadius(event);

        // 使用Container包装，避免嵌套Stack导致的ParentDataWidget错误
        return Container(
          decoration: opacity > 0.0 ? BoxDecoration(
            // 使用边框创建屏幕边缘红边效果
            border: Border.all(
              color: Colors.red.withOpacity(edgeOpacity * opacity),
              width: edgeThickness,
            ),
            // 添加内阴影效果，让红边向内渐变
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(edgeOpacity * opacity * 0.8),
                blurRadius: blurRadius,
                spreadRadius: -edgeThickness / 2, // 负值创建内阴影效果
                offset: Offset.zero,
              ),
              BoxShadow(
                color: Colors.red.withOpacity(edgeOpacity * opacity * 0.4),
                blurRadius: blurRadius * 2,
                spreadRadius: -edgeThickness / 4,
                offset: Offset.zero,
              ),
            ],
          ) : null,
          child: Transform.scale(
            scale: scale,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// 伤害效果包装器 - 用于向后兼容
class DamageEffectWrapper extends StatelessWidget {
  final Widget child;

  const DamageEffectWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HPListener(
      onDamageDetected: (event) {
        // 使用异步方式延迟状态更新，避免在widget构建期间修改provider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            final container = ProviderScope.containerOf(context);
            container.read(damageEventProvider.notifier).triggerDamage(event);
          } catch (e) {
            print('触发伤害事件时出错: $e');
          }
        });
      },
      child: DynamicDamageEffect(
         child: child,
       ),
    );
  }
}