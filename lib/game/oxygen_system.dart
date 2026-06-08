import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 氧气系统状态枚举
enum OxygenState {
  normal, // 正常状态（不在水中）
  underwater, // 水中状态
  recovering, // 恢复状态（刚离开水）
}

/// 氧气系统类
/// 管理角色在水中的氧气值、生命值扣除和视野缩小效果
class OxygenSystem extends ChangeNotifier {
  // 氧气相关属性
  double _currentOxygen = 10.0; // 当前氧气值
  double _maxOxygen = 10.0; // 最大氧气值
  OxygenState _state = OxygenState.normal;

  // 计时器
  Timer? _oxygenTimer;
  Timer? _damageTimer;

  // 配置参数
  static const double _oxygenDecreaseRate = 1.0; // 氧气消耗速率（每秒）
  static const double _oxygenRecoveryRate = 2.0; // 氧气恢复速率（每秒）
  static const double _damageInterval = 1.0; // 伤害间隔（秒）
  static const int _damageAmount = 1; // 每次伤害值（与饱食度扣血保持一致）
  static const double _visionReductionFactor = 0.6; // 水中视野缩小系数

  // 回调函数
  Function(int damage)? onHealthDamage; // 生命值扣除回调
  Function(double factor)? onVisionChange; // 视野变化回调

  // Getters
  double get currentOxygen => _currentOxygen;
  double get maxOxygen => _maxOxygen;
  double get oxygenPercentage =>
      _maxOxygen > 0 ? _currentOxygen / _maxOxygen : 0.0;
  OxygenState get state => _state;
  bool get isUnderwater => _state == OxygenState.underwater;
  bool get shouldShowOxygenBar => _state != OxygenState.normal;
  double get visionFactor => isUnderwater ? _visionReductionFactor : 1.0;
  double get oxygenDecreaseRate => _oxygenDecreaseRate;

  /// 构造函数
  OxygenSystem({
    double maxOxygen = 10.0,
    this.onHealthDamage,
    this.onVisionChange,
  }) {
    _maxOxygen = maxOxygen;
    _currentOxygen = maxOxygen;
  }

  /// 设置最大氧气值（根据角色配置）
  void setMaxOxygen(double maxOxygen) {
    _maxOxygen = maxOxygen;
    if (_currentOxygen > _maxOxygen) {
      _currentOxygen = _maxOxygen;
    }
    notifyListeners();
  }

  /// 设置当前氧气值
  void setCurrentOxygen(double oxygen) {
    _currentOxygen = oxygen.clamp(0.0, _maxOxygen);
    notifyListeners();
  }

  /// 强制启动氧气恢复（用于道具使用后的氧气恢复）
  void forceStartRecovery() {
    // 如果当前氧气值小于最大氧气值，启动恢复
    if (_currentOxygen < _maxOxygen) {
      // 停止任何正在进行的计时器
      _stopOxygenDecrease();
      _stopDamage();

      // 设置为恢复状态
      _state = OxygenState.recovering;

      // 启动氧气恢复
      _startOxygenRecovery();

      notifyListeners();
    }
  }

  /// 进入水中
  void enterWater() {

    if (_state != OxygenState.underwater) {
      // 停止任何正在进行的氧气恢复
      _stopOxygenRecovery();
      _stopDamage();

      _state = OxygenState.underwater;
  
      _startOxygenDecrease();
      _notifyVisionChange();
      notifyListeners();
    } else {
  
    }
  }

  /// 离开水中
  void exitWater() {

    if (_state == OxygenState.underwater) {
      _state = OxygenState.recovering;
  
      _stopOxygenDecrease();
      _stopDamage();
      _startOxygenRecovery();
      _notifyVisionChange();
      notifyListeners();
    } else {
  
    }
  }

  /// 开始氧气消耗
  void _startOxygenDecrease() {
    _oxygenTimer?.cancel();
    _oxygenTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _currentOxygen -= _oxygenDecreaseRate * 0.1; // 每100ms消耗

      if (_currentOxygen <= 0) {
        _currentOxygen = 0;
        // 只有当伤害计时器还没启动时才启动
        if (_damageTimer == null) {
          _startDamage();
        }
      }

      notifyListeners();
    });
  }

  /// 停止氧气消耗
  void _stopOxygenDecrease() {
    _oxygenTimer?.cancel();
    _oxygenTimer = null;
  }

  /// 开始氧气恢复
  void _startOxygenRecovery() {
    _oxygenTimer?.cancel();
    _oxygenTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _currentOxygen += _oxygenRecoveryRate * 0.1; // 每100ms恢复

      if (_currentOxygen >= _maxOxygen) {
        _currentOxygen = _maxOxygen;
        _state = OxygenState.normal;
        _stopOxygenRecovery();
        notifyListeners();
        return;
      }

      notifyListeners();
    });
  }

  /// 停止氧气恢复
  void _stopOxygenRecovery() {
    _oxygenTimer?.cancel();
    _oxygenTimer = null;
  }

  /// 开始生命值扣除
  void _startDamage() {
    
    _damageTimer?.cancel();
    _damageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {

      if (_currentOxygen <= 0 && _state == OxygenState.underwater) {
        
        onHealthDamage?.call(_damageAmount);
      } else {
  
        _stopDamage();
      }
    });
  }

  /// 停止生命值扣除
  void _stopDamage() {
    _damageTimer?.cancel();
    _damageTimer = null;
  }

  /// 通知视野变化
  void _notifyVisionChange() {
    onVisionChange?.call(visionFactor);
  }

  /// 重置氧气系统
  void reset() {
    _stopOxygenDecrease();
    _stopOxygenRecovery();
    _stopDamage();
    _currentOxygen = _maxOxygen;
    _state = OxygenState.normal;
    _notifyVisionChange();
    notifyListeners();
  }

  /// 销毁资源
  @override
  void dispose() {
    _stopOxygenDecrease();
    _stopOxygenRecovery();
    _stopDamage();
    super.dispose();
  }

  /// 获取氧气条颜色（始终为蓝色渐变）
  Color getOxygenBarColor() {
    // 始终返回蓝色，创建渐变效果
    return Colors.blue;
  }

  /// 获取氧气条背景颜色
  Color getOxygenBarBackgroundColor() {
    return Colors.grey.withValues(alpha: 0.3);
  }
}

/// 水波动画绘制器
class _WaterWavePainter extends CustomPainter {
  final double oxygenPercentage;
  final double phase;
  final Color waveColor;
  final Color backgroundColor;

  _WaterWavePainter({
    required this.oxygenPercentage,
    required this.phase,
    required this.waveColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.fill;

    // 绘制背景
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.width / 2),
      ),
      paint,
    );

    // 计算水位高度（从上往下）
    final waterHeight = size.height * (1.0 - oxygenPercentage);

    if (waterHeight < size.height) {
      // 绘制水波效果
      final wavePaint =
          Paint()
            ..color = waveColor
            ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, waterHeight);

      // 添加水波曲线
      for (double x = 0; x <= size.width; x += 2) {
        final waveHeight = math.sin(x * 0.1 + phase) * 3;
        final y = waterHeight + waveHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, wavePaint);

      // 添加水波高光
      final highlightPaint =
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;

      final highlightPath = Path();
      highlightPath.moveTo(0, waterHeight + math.sin(phase) * 3);

      for (double x = 0; x <= size.width; x += 2) {
        final waveHeight = math.sin(x * 0.1 + phase + 0.5) * 2;
        final y = waterHeight + waveHeight;
        highlightPath.lineTo(x, y);
      }

      canvas.drawPath(highlightPath, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(_WaterWavePainter oldDelegate) {
    return oxygenPercentage != oldDelegate.oxygenPercentage ||
        phase != oldDelegate.phase ||
        waveColor != oldDelegate.waveColor ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

/// 竖式氧气条UI组件（带水波效果）
class OxygenBar extends StatefulWidget {
  final OxygenSystem oxygenSystem;
  final double width;
  final double height;
  final EdgeInsets margin;

  const OxygenBar({
    Key? key,
    required this.oxygenSystem,
    this.width = 24.0,
    this.height = 120.0,
    this.margin = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  State<OxygenBar> createState() => _OxygenBarState();
}

class _OxygenBarState extends State<OxygenBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _waveAnimation = Tween<double>(
      begin: 0,
      end: math.pi * 2,
    ).animate(_waveController);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.oxygenSystem, _waveAnimation]),
      builder: (context, child) {
        if (!widget.oxygenSystem.shouldShowOxygenBar) {
          return const SizedBox.shrink();
        }

        // 计算剩余时间（秒）
        final remainingTime =
            widget.oxygenSystem.currentOxygen /
            widget.oxygenSystem.oxygenDecreaseRate;
        final timeText =
            remainingTime > 60
                ? '${(remainingTime / 60).toStringAsFixed(0)}m'
                : '${remainingTime.toStringAsFixed(0)}s';

        return Container(
          margin: widget.margin,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // // 氧气标签
              // Text(
              //   '氧气',
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 12,
              //     fontWeight: FontWeight.bold,
              //     shadows: [
              //       Shadow(
              //         offset: const Offset(1, 1),
              //         blurRadius: 2,
              //         color: Colors.black.withValues(alpha: 0.8),
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 4),
              // 竖式氧气条容器
              Container(
                width: widget.width,
                height: widget.height,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: widget.oxygenSystem.getOxygenBarBackgroundColor(),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 水波进度条
                    CustomPaint(
                      painter: _WaterWavePainter(
                        oxygenPercentage: widget.oxygenSystem.oxygenPercentage,
                        phase: _waveAnimation.value,
                        waveColor: widget.oxygenSystem.getOxygenBarColor(),
                        backgroundColor: Colors.transparent,
                      ),
                      size: Size(widget.width, widget.height),
                    ),
                    // 倒计时文本（居中显示，正过来显示）
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          timeText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
