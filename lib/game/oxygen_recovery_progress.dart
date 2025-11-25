import 'dart:async';
import 'package:flutter/material.dart';

/// 氧气恢复进度条组件
/// 在使用道具后显示氧气值恢复到上限的进度
class OxygenRecoveryProgress extends StatefulWidget {
  final double startOxygen; // 开始时的氧气值
  final double targetOxygen; // 目标氧气值（上限）
  final Duration duration; // 恢复持续时间
  final VoidCallback? onComplete; // 完成回调
  final Function(double)? onProgress; // 进度回调，返回当前氧气值

  const OxygenRecoveryProgress({
    Key? key,
    required this.startOxygen,
    required this.targetOxygen,
    this.duration = const Duration(seconds: 3),
    this.onComplete,
    this.onProgress,
  }) : super(key: key);

  @override
  State<OxygenRecoveryProgress> createState() => _OxygenRecoveryProgressState();
}

class _OxygenRecoveryProgressState extends State<OxygenRecoveryProgress>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    // 如果开始氧气值已经等于目标值，直接完成
    if (widget.startOxygen >= widget.targetOxygen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete?.call();
      });
      return;
    }

    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _animation.addListener(() {
      final currentOxygen =
          widget.startOxygen +
          (widget.targetOxygen - widget.startOxygen) * _animation.value;
      widget.onProgress?.call(currentOxygen);
    });

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    // 启动动画
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果开始氧气值已经等于目标值，不显示进度条
    if (widget.startOxygen >= widget.targetOxygen) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentOxygen =
            widget.startOxygen +
            (widget.targetOxygen - widget.startOxygen) * _animation.value;
        final progress = _animation.value;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.air, color: Colors.cyan, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '氧气恢复中...',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 进度条
              Container(
                width: 200,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.cyan.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // 进度填充
                    Container(
                      width: 200 * progress,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.cyan.withOpacity(0.6), Colors.cyan],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // 进度文本
                    Container(
                      width: 200,
                      height: 20,
                      alignment: Alignment.center,
                      child: Text(
                        '${currentOxygen.toStringAsFixed(1)}/${widget.targetOxygen.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // 百分比文本
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.cyan.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 氧气恢复管理器
/// 管理氧气恢复进度条的显示和隐藏
class OxygenRecoveryManager extends ChangeNotifier {
  bool _isRecovering = false;
  double _startOxygen = 0.0;
  double _targetOxygen = 0.0;
  Duration _duration = const Duration(seconds: 3);
  Function(double)? _onProgress;

  bool get isRecovering => _isRecovering;
  double get startOxygen => _startOxygen;
  double get targetOxygen => _targetOxygen;
  Duration get duration => _duration;
  Function(double)? get onProgress => _onProgress;

  /// 开始氧气恢复
  void startRecovery({
    required double startOxygen,
    required double targetOxygen,
    Duration duration = const Duration(seconds: 3),
    Function(double)? onProgress,
  }) {
    if (startOxygen >= targetOxygen) {
      return; // 不需要恢复
    }

    _isRecovering = true;
    _startOxygen = startOxygen;
    _targetOxygen = targetOxygen;
    _duration = duration;
    _onProgress = onProgress;
    notifyListeners();
  }

  /// 完成氧气恢复
  void completeRecovery() {
    _isRecovering = false;
    _onProgress = null;
    notifyListeners();
  }

  /// 取消氧气恢复
  void cancelRecovery() {
    _isRecovering = false;
    _onProgress = null;
    notifyListeners();
  }
}
