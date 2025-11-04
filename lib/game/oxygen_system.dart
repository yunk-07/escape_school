import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// 氧气系统状态枚举
enum OxygenState {
  normal,      // 正常状态（不在水中）
  underwater,  // 水中状态
  recovering,  // 恢复状态（刚离开水）
}

/// 氧气系统类
/// 管理角色在水中的氧气值、生命值扣除和视野缩小效果
class OxygenSystem extends ChangeNotifier {
  // 氧气相关属性
  double _currentOxygen = 10.0;  // 当前氧气值
  double _maxOxygen = 10.0;      // 最大氧气值
  OxygenState _state = OxygenState.normal;
  
  // 计时器
  Timer? _oxygenTimer;
  Timer? _damageTimer;
  
  // 配置参数
  static const double _oxygenDecreaseRate = 1.0;  // 氧气消耗速率（每秒）
  static const double _oxygenRecoveryRate = 2.0;  // 氧气恢复速率（每秒）
  static const double _damageInterval = 1.0;      // 伤害间隔（秒）
  static const int _damageAmount = 1;             // 每次伤害值（与饱食度扣血保持一致）
  static const double _visionReductionFactor = 0.6; // 水中视野缩小系数
  
  // 回调函数
  Function(int damage)? onHealthDamage;  // 生命值扣除回调
  Function(double factor)? onVisionChange; // 视野变化回调
  
  // Getters
  double get currentOxygen => _currentOxygen;
  double get maxOxygen => _maxOxygen;
  double get oxygenPercentage => _maxOxygen > 0 ? _currentOxygen / _maxOxygen : 0.0;
  OxygenState get state => _state;
  bool get isUnderwater => _state == OxygenState.underwater;
  bool get shouldShowOxygenBar => _state != OxygenState.normal;
  double get visionFactor => isUnderwater ? _visionReductionFactor : 1.0;
  
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
    print('氧气系统：尝试进入水中 - 当前状态: $_state');
    if (_state != OxygenState.underwater) {
      // 停止任何正在进行的氧气恢复
      _stopOxygenRecovery();
      _stopDamage();
      
      _state = OxygenState.underwater;
      print('氧气系统：已进入水中状态，开始氧气消耗');
      _startOxygenDecrease();
      _notifyVisionChange();
      notifyListeners();
    } else {
      print('氧气系统：已经在水中，无需重复进入');
    }
  }
  
  /// 离开水中
  void exitWater() {
    print('氧气系统：尝试离开水中 - 当前状态: $_state');
    if (_state == OxygenState.underwater) {
      _state = OxygenState.recovering;
      print('氧气系统：已离开水中，开始氧气恢复');
      _stopOxygenDecrease();
      _stopDamage();
      _startOxygenRecovery();
      _notifyVisionChange();
      notifyListeners();
    } else {
      print('氧气系统：不在水中，无需离开');
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
    print('氧气系统：开始伤害计时器 - 氧气值: $currentOxygen, 状态: $state');
    _damageTimer?.cancel();
    _damageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      print('氧气系统：伤害计时器触发 - 氧气值: $currentOxygen, 状态: $state');
      if (_currentOxygen <= 0 && _state == OxygenState.underwater) {
        print('氧气系统：调用伤害回调，伤害值: $_damageAmount');
        onHealthDamage?.call(_damageAmount);
      } else {
        print('氧气系统：停止伤害计时器 - 氧气值: $currentOxygen, 状态: $state');
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
  
  /// 获取氧气条颜色（根据氧气百分比）
  Color getOxygenBarColor() {
    final percentage = oxygenPercentage;
    if (percentage > 0.6) {
      return Colors.blue;
    } else if (percentage > 0.3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  /// 获取氧气条背景颜色
  Color getOxygenBarBackgroundColor() {
    return Colors.grey.withOpacity(0.3);
  }
}

/// 氧气进度条UI组件
class OxygenBar extends StatelessWidget {
  final OxygenSystem oxygenSystem;
  final double width;
  final double height;
  final EdgeInsets margin;
  
  const OxygenBar({
    Key? key,
    required this.oxygenSystem,
    this.width = 200.0,
    this.height = 20.0,
    this.margin = const EdgeInsets.all(8.0),
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: oxygenSystem,
      builder: (context, child) {
        if (!oxygenSystem.shouldShowOxygenBar) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: margin,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 氧气标签
              Text(
                '氧气',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // 氧气进度条
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: oxygenSystem.getOxygenBarBackgroundColor(),
                  borderRadius: BorderRadius.circular(height / 2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // 进度条填充
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: width * oxygenSystem.oxygenPercentage,
                      height: height,
                      decoration: BoxDecoration(
                        color: oxygenSystem.getOxygenBarColor(),
                        borderRadius: BorderRadius.circular(height / 2),
                        boxShadow: [
                          BoxShadow(
                            color: oxygenSystem.getOxygenBarColor().withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    // 氧气值文本
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          '${oxygenSystem.currentOxygen.toStringAsFixed(1)}/${oxygenSystem.maxOxygen.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.8),
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