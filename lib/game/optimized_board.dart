// game/optimized_board.dart
// 性能优化的游戏界面

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escape_from_school/game/optimized_game_state.dart';
import 'package:escape_from_school/game/alchemy_effect_overlay.dart';
import 'package:escape_from_school/game/gameOver.dart';
import 'package:escape_from_school/game/inventory_page.dart';
import 'package:escape_from_school/game/joystick.dart';

import 'package:escape_from_school/game/hp_listener.dart';
import 'package:escape_from_school/game/smooth_vision.dart';
import 'package:escape_from_school/game/enhanced_vision.dart';
import 'package:escape_from_school/game/shop_view.dart';
import 'package:escape_from_school/game/alchemy_view.dart';
import 'package:escape_from_school/game/item_usage_progress.dart';
import 'package:escape_from_school/game/chest_exploration_progress.dart';
import 'package:escape_from_school/game/chest_search_overlay.dart';
import 'package:escape_from_school/game/safe_search_overlay.dart';
import 'package:escape_from_school/game/oxygen_system.dart';
import 'package:escape_from_school/game/oxygen_recovery_progress.dart';
import 'package:escape_from_school/game/music.dart';
import 'package:escape_from_school/game/ui_theme.dart'
    as ui_theme; // 关键区域：引入 UI 主题工具（避免作用域歧义）
import 'package:escape_from_school/data/props.dart'; // 关键区域：引入物品定义，确保预加载覆盖所有物品图片
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class OptimizedBoardPage extends StatefulWidget {
  final Map<String, dynamic> characterStats;
  final String characterImage;

  const OptimizedBoardPage({
    Key? key,
    required this.characterStats,
    required this.characterImage,
  }) : super(key: key);

  @override
  State<OptimizedBoardPage> createState() => _OptimizedBoardPageState();
}

// 顶层心电图绘制器（与精神值联动）
class SanityECGPainter extends CustomPainter {
  final double phase;
  final double san; // 0-250
  final double hpRatio; // 0-1
  final double oxygenRatio; // 0-1
  final double moveFactor; // 0-1
  final double castingFactor; // 0-1
  final double damagePulse; // 0-1
  final bool isInWater;
  final double proximityFactor; // 0-1 距离鬼的危险接近度（近=1，远=0）
  SanityECGPainter({
    required this.phase,
    required this.san,
    required this.hpRatio,
    required this.oxygenRatio,
    required this.moveFactor,
    required this.castingFactor,
    required this.damagePulse,
    required this.isInWater,
    required this.proximityFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint =
        Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 科技感网格线（青色微光）
    final gridPaint =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.18)
          ..strokeWidth = 0.7;
    for (double x = 0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 中心轴线稍亮
    final axisPaint =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.35)
          ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      axisPaint,
    );

    // 归一化指标
    final sanityRatio = (san / 250.0).clamp(0.0, 1.0);
    final double hpR = hpRatio.clamp(0.0, 1.0);
    final double o2R = oxygenRatio.clamp(0.0, 1.0);
    final double moveR = moveFactor.clamp(0.0, 1.0);
    final double castR = castingFactor.clamp(0.0, 1.0);
    final double dmgP = damagePulse.clamp(0.0, 1.0);

    // 全新模式：心率主要受“鬼接近度”驱动，其他因素弱化或不参与
    double hrBpm =
        60 +
        90 *
            proximityFactor // 鬼越近越心跳加速
            +
        10 *
            dmgP // 受伤脉冲仍有轻微影响
            +
        (isInWater ? 5 : 0); // 水中轻微提升
    hrBpm = hrBpm.clamp(50, 165);

    // 振幅：低SAN与低O2增加振幅与不稳定性
    final double baseAmp =
        6.0 + (1.0 - sanityRatio) * 4.0 + (1.0 - o2R) * 2.0; // ~6-12

    // 尖峰间隔：心率越高，尖峰越密集
    final double spikeInterval = 42.0 * (60.0 / hrBpm); // 基于60bpm的缩放
    final double spikeWidth = 8.0;
    final double spikeHeight = baseAmp * (2.0 + (1.0 - hpR) * 0.6 + dmgP * 0.8);

    // 颜色：完全以接近度为主驱动，越近越偏危险红
    final double stress = proximityFactor;
    final Color calmColor = Colors.greenAccent;
    final Color techColor = Colors.cyanAccent;
    final Color alertColor = Colors.orangeAccent;
    final Color dangerColor = Colors.redAccent;
    final Color waveColor =
        (stress < 0.33)
            ? Color.lerp(calmColor, techColor, 0.6)!
            : (stress < 0.66)
            ? Color.lerp(techColor, alertColor, (stress - 0.33) / 0.33)!
            : Color.lerp(alertColor, dangerColor, (stress - 0.66) / 0.34)!;

    final wavePaint =
        Paint()
          ..color = waveColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final path = Path();
    // ECG样式：平缓段 + 尖峰（间隔与心率相关）
    final double mid = size.height / 2;

    double x = 0.0;
    double y = mid;
    path.moveTo(x, y);

    while (x <= size.width) {
      // 平缓段：正弦 + 轻微抖动，低O2和低SAN增加不稳定性
      final jitter = proximityFactor * 0.8; // 接近越高，抖动越明显
      final noise =
          math.sin((x * 0.12) + phase * 1.7) * baseAmp * 0.15 * jitter;
      final smoothY =
          mid +
          math.sin((x / size.width) * math.pi * 2 + phase) * baseAmp * 0.6 +
          noise;

      // 是否绘制尖峰
      final double offsetPhase = (phase * 30) % spikeInterval;
      final double distToSpike = ((x + offsetPhase) % spikeInterval);
      if (distToSpike < 1.0) {
        // 上升
        path.lineTo(x + spikeWidth * 0.2, mid - spikeHeight);
        // 回落到下方
        path.lineTo(x + spikeWidth * 0.6, mid + spikeHeight * 0.6);
        // 回到平缓线
        path.lineTo(x + spikeWidth, smoothY);
        x += spikeWidth;
        y = smoothY;
      } else {
        final double nextX = x + 2.0;
        final double nextY = smoothY;
        path.lineTo(nextX, nextY);
        x = nextX;
        y = nextY;
      }
    }

    // 光晕（科技感）：叠加两层虚化效果
    final glow1 =
        Paint()
          ..color = waveColor.withOpacity(0.25)
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke;
    final glow2 =
        Paint()
          ..color = waveColor.withOpacity(0.12)
          ..strokeWidth = 10.0
          ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glow2);
    canvas.drawPath(path, glow1);
    canvas.drawPath(path, wavePaint);

    // 扫描线（向右移动的淡青色线）
    final double phaseNorm = (phase % (math.pi * 2)) / (math.pi * 2);
    final double scanX = phaseNorm * size.width;
    final scanPaint =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.15)
          ..strokeWidth = 2.0;
    canvas.drawLine(Offset(scanX, 0), Offset(scanX, size.height), scanPaint);
  }

  @override
  bool shouldRepaint(covariant SanityECGPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.san != san ||
        oldDelegate.hpRatio != hpRatio ||
        oldDelegate.oxygenRatio != oxygenRatio ||
        oldDelegate.moveFactor != moveFactor ||
        oldDelegate.castingFactor != castingFactor ||
        oldDelegate.damagePulse != damagePulse ||
        oldDelegate.isInWater != isInWater ||
        oldDelegate.proximityFactor != proximityFactor;
  }
}

class _OptimizedBoardPageState extends State<OptimizedBoardPage>
    with TickerProviderStateMixin {
  late OptimizedGameStateNotifier gameStateNotifier;
  final Map<String, ui.Image> terrainImages = {};
  ui.Image? characterImage;
  bool _hasNavigatedToGameOver = false; // 防止重复导航到游戏结束页面
  Offset? _aimTouchPoint;
  double _aimNX = 0.0;
  double _aimNY = 0.0;
  bool _aimActive = false;

  // 视野边界闪烁动画控制器
  AnimationController? _visionBorderFlashController;
  Animation<double>? _visionBorderFlashAnimation;
  // 心电图动画控制器
  AnimationController? _ecgController;
  double _ecgPhase = 0.0;

  // 关键区域：用于进度条动画与端点发光的上次百分比记录
  double _lastHpPercentage = 0.0;
  double _lastFoodPercentage = 0.0;
  double _lastSanityPercentage = 0.0;

  @override
  void initState() {
    super.initState();

    // 初始化游戏状态管理器 - 使用完整的角色数据
    gameStateNotifier = OptimizedGameStateNotifier(widget.characterStats);

    // 初始化视野边界闪烁动画控制器
    _visionBorderFlashController = AnimationController(
      duration: const Duration(milliseconds: 400), // 0.4秒闪烁
      vsync: this,
    );

    // 创建颜色变化动画（从蓝色到红色再回到蓝色）
    _visionBorderFlashAnimation = Tween<double>(
      begin: 0.0, // 0.0 = 蓝色，1.0 = 红色
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _visionBorderFlashController!,
        curve: Curves.easeInOut,
      ),
    );

    // 初始化心电图动画控制器（循环刷新）
    _ecgController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..addListener(() {
      setState(() {
        _ecgPhase = (_ecgPhase + 0.04) % (math.pi * 2);
      });
    });
    _ecgController!.repeat();

    // 预加载地形图片和角色图片
    _preloadImages();
  }

  Future<void> _preloadImages() async {
    // 加载地形图片
    final terrainTypes = [
      'grass',
      'wall',
      'water',
      'path',
      'building',
      'woods',
      'shop',
      'chest',
      'safe',
    ];

    try {
      for (String terrain in terrainTypes) {
        final ByteData data = await rootBundle.load('images/map/$terrain.png');
        final Uint8List bytes = data.buffer.asUint8List();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        terrainImages[terrain] = frameInfo.image;
      }
    } catch (e) {
      print('Error loading terrain images: $e');
      // 如果加载失败，继续使用颜色渲染
    }

    // 关键区域：加载所有地面物品图片
    // 说明：统一从 props.dart 的 allItems 读取 image 路径，以避免遗漏导致地面物品不显示
    try {
      final Set<String> itemImagePaths =
          allItems
              .map((item) => item.image)
              .where((path) => path.isNotEmpty)
              .toSet();

      for (final imagePath in itemImagePaths) {
        try {
          final ByteData data = await rootBundle.load(imagePath);
          final Uint8List bytes = data.buffer.asUint8List();
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo frameInfo = await codec.getNextFrame();
          terrainImages[imagePath] = frameInfo.image; // 使用完整路径作为key
        } catch (e) {
          // 单个物品加载失败时继续，不影响其它物品显示
          if (kDebugMode) {
            print('Warn: failed to load item image $imagePath: $e');
          }
        }
      }
    } catch (e) {
      print('Error preparing item images from allItems: $e');
      // 如果全局准备失败，将使用回退图标
    }

    // 加载角色图片
    try {
      final ByteData data = await rootBundle.load(widget.characterImage);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      characterImage = frameInfo.image;
      setState(() {}); // 触发重绘以显示角色图片
    } catch (e) {
      print('Error loading character image: $e');
      // 如果加载失败，将使用红色圆圈作为回退
    }
  }

  @override
  Widget build(BuildContext context) {
    // 设置全屏模式，隐藏状态栏和导航栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return WillPopScope(
      onWillPop: () async {
        // 处理系统返回按钮，防止直接返回到角色选择页面导致崩溃
        _showExitConfirmDialog(context);
        return false; // 阻止默认返回行为
      },
      child: ProviderScope(
        overrides: [
          optimizedGameStateProvider.overrideWith((ref) => gameStateNotifier),
        ],
        child: Material(
          color: Colors.black,
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              return _handleKeyEvent(event);
            },
            child: Consumer(
              builder: (context, ref, child) {
                final gameState = ref.watch(optimizedGameStateProvider);
                final damageEvent = ref.watch(damageEventProvider);

                // 监听伤害事件，触发视野边界颜色变化动画
                if (damageEvent != null &&
                    _visionBorderFlashController != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _visionBorderFlashController != null) {
                      // 停止当前动画（如果正在运行），确保新动画能够打断旧动画
                      _visionBorderFlashController!.stop();
                      _visionBorderFlashController!.reset();
                      // 执行往返动画：从蓝色变红色再变回蓝色
                      _visionBorderFlashController!.forward().then((_) {
                        if (mounted && _visionBorderFlashController != null) {
                          _visionBorderFlashController!.reverse();
                        }
                      });
                    }
                  });
                }

                // 检查游戏结束状态
                if (gameState.isGameOver && !_hasNavigatedToGameOver) {
                  _hasNavigatedToGameOver = true; // 设置标志，防止重复导航
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      // 确保组件仍然挂载
                      // 关键区域：避免使用已释放的 gameStateNotifier
                      // pushReplacement 后本页面会被销毁，如果将其成员 gameStateNotifier 透传给 GameOverPage，
                      // 会在后续 watch/read 时出现 “Tried to use OptimizedGameStateNotifier after dispose” 异常。
                      // 因此这里创建一个新的 Notifier，并以死亡时的快照初始化其 state，确保 GameOverPage 读到的是稳定的最终状态。
                      final snapshotState =
                          gameStateNotifier
                              .state; // 已含 deathTimeStats / deathTimeInventory / gameEndTime

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ProviderScope(
                                overrides: [
                                  optimizedGameStateProvider.overrideWith((
                                    ref,
                                  ) {
                                    final fresh = OptimizedGameStateNotifier(
                                      snapshotState.characterStats,
                                    );
                                    // 关键区域：用死亡快照覆盖新 Notifier 的状态，避免显示活跃状态并彻底规避 dispose 后使用问题
                                    fresh.state = snapshotState;
                                    return fresh;
                                  }),
                                ],
                                child: GameOverPage(
                                  deathReason: snapshotState.deathReason,
                                  characterImage:
                                      snapshotState.characterStats['image'] ??
                                      'images/man/cook.png',
                                ),
                              ),
                        ),
                      );
                    }
                  });
                }

                // 默认显示游戏页面
                return _buildGamePage(gameState);
              },
            ),
          ),
        ),
      ),
    );
  }

  // 处理键盘事件
  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final notifier = ProviderScope.containerOf(
        context,
      ).read(optimizedGameStateProvider.notifier);

      // 检查按键并模拟摇杆输入
      double x = 0.0;
      double y = 0.0;
      bool hasInput = false;

      if (event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        y = -1.0;
        hasInput = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyS ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        y = 1.0;
        hasInput = true;
      }

      if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        x = -1.0;
        hasInput = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        x = 1.0;
        hasInput = true;
      }

      if (hasInput) {
        notifier.onJoystickMove(x, y, 1.0);
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      // 键盘释放时停止移动
      final notifier = ProviderScope.containerOf(
        context,
      ).read(optimizedGameStateProvider.notifier);

      if (event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.keyS ||
          event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        notifier.onJoystickStop();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // 显示退出确认对话框
  void _showExitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              // 关键区域：统一边角为5（二级退出对话框外层容器）
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade900,
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部标题栏
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    // 关键区域：标题栏圆角统一为5
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey.shade800.withOpacity(0.35),
                        Colors.grey.shade700.withOpacity(0.25),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.06),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          // 关键区域：图标容器圆角统一为5
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(
                          Icons.exit_to_app,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '确认退出',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            // 关键区域：关闭按钮圆角统一为5
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 内容区域
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '确定要退出游戏吗？',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '将返回主菜单。未保存的进度可能会丢失。',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // 操作按钮
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade800,
                                Colors.grey.shade700,
                              ],
                            ),
                            // 关键区域：取消按钮圆角统一为5
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              // 关键区域：取消按钮点击反馈圆角统一为5
                              borderRadius: BorderRadius.circular(5),
                              child: const Center(
                                child: Text(
                                  '取消',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade700,
                                Colors.grey.shade600,
                              ],
                            ),
                            // 关键区域：退出按钮圆角统一为5
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                _exitToMainMenu(context);
                              },
                              // 关键区域：退出按钮点击反馈圆角统一为5
                              borderRadius: BorderRadius.circular(5),
                              child: const Center(
                                child: Text(
                                  '退出游戏',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 显示技能对话框
  void _showSkillsDialog(BuildContext context, OptimizedGameState gameState) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade900,
                  Colors.purple.shade800,
                  Colors.purple.shade900,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.purple.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade800.withOpacity(0.4),
                        Colors.blue.shade800.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_fix_high,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          '角色技能',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Flexible(child: SizedBox.shrink()),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建技能列表
  Widget _buildSkillsList(OptimizedGameState gameState) {
    final notifier = ProviderScope.containerOf(
      context,
    ).read(optimizedGameStateProvider.notifier);
    final characterSkills = gameState.characterSkills;

    if (characterSkills.isEmpty) {
      return const Center(
        child: Text(
          '该角色暂无可用技能',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '可用技能：',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: characterSkills.length,
            itemBuilder: (context, index) {
              final skill = characterSkills[index];
              final skillState = notifier.getSkillState(skill.id);

              return _buildSkillItem(skill, skillState, notifier);
            },
          ),
        ),
      ],
    );
  }

  // 构建单个技能项
  Widget _buildSkillItem(dynamic skill, dynamic skillState, dynamic notifier) {
    final bool isOnCooldown =
        skillState?.isOnCooldown(skill.cooldownSeconds) ?? false;
    final bool isCasting = skillState?.isCurrentlyCasting ?? false;
    final int remainingCooldown =
        skillState?.getRemainingCooldown(skill.cooldownSeconds) ?? 0;
    final int remainingCastTime =
        skillState?.getRemainingCastTime(skill.castTimeSeconds) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnCooldown ? Colors.grey : Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 技能图标
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color:
                  isOnCooldown
                      ? Colors.grey.withOpacity(0.3)
                      : Colors.purple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.auto_fix_high,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // 技能信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: TextStyle(
                    color: isOnCooldown ? Colors.grey : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skill.description,
                  style: TextStyle(
                    color: isOnCooldown ? Colors.grey.shade400 : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                if (isOnCooldown || isCasting) ...[
                  const SizedBox(height: 4),
                  Text(
                    isCasting
                        ? '施放中... ${remainingCastTime}秒'
                        : '冷却中... ${remainingCooldown}秒',
                    style: TextStyle(
                      color: isCasting ? Colors.orange : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 使用按钮
          Container(
            width: 80,
            height: 36,
            child: ElevatedButton(
              onPressed:
                  (isOnCooldown || isCasting)
                      ? null
                      : () {
                        notifier.useSkill(skill.id);
                        Navigator.of(context).pop(); // 关闭对话框
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isOnCooldown || isCasting
                        ? Colors.grey.withOpacity(0.3)
                        : Colors.purple.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                isCasting ? '施放中' : (isOnCooldown ? '冷却中' : '使用'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建设置按钮（右上角）
  Widget _buildSettingsButton() {
    return Positioned(
      top: 40,
      right: 20,
      child: GestureDetector(
        onTap: () => _showSettingsDialog(context),
        child: Container(
          width: 50,
          height: 50,
          // 关键区域：美化设置按钮样式，统一采用 UITheme 渐变与高光
          decoration: BoxDecoration(
            gradient: ui_theme.UITheme.progressBackground(),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x30FFFFFF), Color(0x00000000)],
              stops: [0.0, 1.0],
            ),
          ),
          child: const Icon(Icons.settings, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  // 关键区域：右上角“处分单”显示 —— 左侧紧邻设置按钮
  Widget _buildPunishmentCard(OptimizedGameState gameState) {
    final int maxPun =
        ((gameState.characterStats['maxPunish'] ?? 10) as num).toInt();
    final int pun = ((gameState.characterStats['punish'] ?? 0) as num)
        .toInt()
        .clamp(0, maxPun);
    return Positioned(
      top: 40,
      right: 80, // 紧邻设置按钮左侧（设置按钮 right: 20，间隔约60）
      child: Container(
        width: 175,
        height: 50,
        decoration: BoxDecoration(
          gradient: ui_theme.UITheme.progressBackground(),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Text(
              '处分',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(maxPun, (index) {
                  final bool filled = index < pun;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      border: Border.all(color: Colors.white24, width: 1),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors:
                            filled
                                ? [
                                  Colors.redAccent.withOpacity(0.9),
                                  Colors.redAccent.withOpacity(0.6),
                                ]
                                : [Colors.white10, Colors.white12],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // 关键区域：提示方式改为——中上位置显示一个长方形小方框，显示一条消息
  Widget _buildBroadcastBox(OptimizedGameState gameState) {
    // 清理过期消息（确保一秒钟提示及时消失）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gameStateNotifier.cleanupExpiredMessages();
    });

    // 过滤掉不需要显示的消息（例如包含“鬼”字样）
    final messages =
        gameState.broadcastMessages
            .where((m) => !m.text.contains('鬼'))
            .toList();

    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    // 只显示最新一条消息，作为短提示
    final BroadcastMessage latest = messages.last;

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: BackdropFilter(
            // 关键区域：玻璃立体效果——背景模糊
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              constraints: const BoxConstraints(
                // 关键区域：缩小默认尺寸，同时去掉高度上限以便长文本自适应换行
                minWidth: 96,
                maxWidth: 280,
                minHeight: 22,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                // 关键区域：半透明底色 + 细白边 + 轻微阴影，形成玻璃质感
                color: Colors.white.withOpacity(0.10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.30),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                borderRadius: BorderRadius.circular(5),
              ),
              // 关键区域：顶部高光渐变，增强立体感
              foregroundDecoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x55FFFFFF), Color(0x00000000)],
                  stops: [0.0, 1.0],
                ),
              ),
              child: Center(child: _buildBroadcastMessage(latest)),
            ),
          ),
        ),
      ),
    );
  }

  // 构建单条播报消息
  Widget _buildBroadcastMessage(BroadcastMessage message) {
    // 关键区域：提示框文字统一为白色、居中显示
    const Color textColor = Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        message.text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        softWrap: true, // 关键区域：允许文本自动换行，适应更长提示
      ),
    );
  }

  // 显示设置对话框
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              // 关键区域：统一边角为5（设置对话框外层容器）
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade900,
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    // 关键区域：标题栏圆角统一为5
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade800.withOpacity(0.3),
                        Colors.purple.shade800.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          // 关键区域：图标容器圆角统一为5
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          '游戏设置',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            // 关键区域：关闭按钮圆角统一为5
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 设置内容
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 按钮行
                        Row(
                          children: [
                            // 退出游戏按钮
                            Expanded(
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.red.shade800.withOpacity(0.3),
                                      Colors.red.shade600.withOpacity(0.2),
                                    ],
                                  ),
                                  // 关键区域：设置对话框中的退出游戏按钮圆角统一为5
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _showExitConfirmDialog(context);
                                    },
                                    // 关键区域：按钮点击反馈圆角统一为5
                                    borderRadius: BorderRadius.circular(5),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.exit_to_app,
                                          color: Colors.red.shade300,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '退出游戏',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 脱离卡死按钮
                            Expanded(
                              child: _UnstuckButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _unstuckPlayer();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 脱离卡死功能
  void _unstuckPlayer() {
    try {
      // 直接使用类成员变量 gameStateNotifier
      gameStateNotifier.unstuckPlayer();

      // 提示信息已移除，功能静默执行
    } catch (e) {
      // 错误信息已移除，仅在控制台输出
    }
  }

  // 退出到主菜单
  void _exitToMainMenu(BuildContext context) {
    // 直接导航到主页面，清除所有之前的页面
    // 不需要手动重置游戏状态，因为新的游戏实例会自动创建
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  // 显示详细状态面板

  @override
  void dispose() {
    // 清理动画控制器
    _visionBorderFlashController?.dispose();
    _ecgController?.dispose();

    // 安全地 dispose gameStateNotifier
    try {
      if (gameStateNotifier.mounted) {
        gameStateNotifier.dispose();
      }
    } catch (e) {
      // 忽略 dispose 时的异常
      if (kDebugMode) {
        print('Dispose gameStateNotifier 时出现异常: $e');
      }
    }
    super.dispose();
  }

  // 构建游戏区域
  Widget _buildGameArea(OptimizedGameState gameState) {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: GestureDetector(
          onTapDown: (details) => _handleMapTap(details, gameState),
          child: Consumer(
            builder: (context, ref, child) {
              final damageEvent = ref.watch(damageEventProvider);
              return AnimatedBuilder(
                animation:
                    _visionBorderFlashAnimation ??
                    const AlwaysStoppedAnimation(1.0),
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GameAreaPainter(
                      gameState: gameState,
                      terrainImages: terrainImages,
                      characterImage: characterImage,
                      smoothVisionManager:
                          gameStateNotifier.smoothVisionManager,
                      damageEvent: damageEvent,
                      visionBorderFlashValue:
                          _visionBorderFlashAnimation?.value ?? 1.0,
                      aimTouchPoint: _aimTouchPoint,
                      aimNX: _aimNX,
                      aimNY: _aimNY,
                      aimActive: _aimActive,
                    ),
                    size: Size.infinite,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // 处理地图点击事件
  void _handleMapTap(TapDownDetails details, OptimizedGameState gameState) {
    // 获取点击位置
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset localPosition = details.localPosition;

    // 计算地图参数
    const double tileSize = 40.0;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // 计算地图偏移
    final double mapOffsetX = centerX - (gameState.playerPosition.x * tileSize);
    final double mapOffsetY = centerY - (gameState.playerPosition.y * tileSize);

    // 检查宝箱点击
    print('检查宝箱点击 - 宝箱数量: ${gameState.chestPositions.length}');
    for (final chestPos in gameState.chestPositions) {
      final double chestScreenX = mapOffsetX + (chestPos.x * tileSize);
      final double chestScreenY = mapOffsetY + (chestPos.y * tileSize);

      // 检查点击是否在宝箱区域内
      final Rect chestRect = Rect.fromLTWH(
        chestScreenX,
        chestScreenY,
        tileSize,
        tileSize,
      );
      print(
        '宝箱位置: (${chestPos.x}, ${chestPos.y}), 屏幕坐标: ($chestScreenX, $chestScreenY), 点击位置: (${localPosition.dx}, ${localPosition.dy})',
      );

      if (chestRect.contains(localPosition)) {
        print('点击命中宝箱区域!');

        // 检查宝箱是否可见
        final math.Point<int> chestPoint = math.Point(
          chestPos.x.toInt(),
          chestPos.y.toInt(),
        );
        bool isChestVisible = false;

        if (gameStateNotifier.smoothVisionManager != null) {
          final opacity = gameStateNotifier.smoothVisionManager!.getTileOpacity(
            chestPoint,
          );
          isChestVisible = opacity > 0.0;
          print(
            '宝箱可见性检查 (smoothVision): opacity = $opacity, visible = $isChestVisible',
          );
        } else {
          isChestVisible = gameState.visibleTiles.contains(chestPoint);
          print('宝箱可见性检查 (visibleTiles): visible = $isChestVisible');
        }

        if (isChestVisible) {
          // 关键区域：为宝箱开启添加与拾取物品一致的距离检测（<= 1.5格）
          final double playerX = gameState.playerPosition.x;
          final double playerY = gameState.playerPosition.y;
          final double distance = math.sqrt(
            math.pow(playerX - chestPos.x, 2) +
                math.pow(playerY - chestPos.y, 2),
          );

          if (distance <= 1.5) {
            print('宝箱可见，距离满足 ($distance <= 1.5)，打开宝箱');
            gameStateNotifier.openChestAtPosition(chestPos);
            return; // 找到点击的宝箱并打开后退出循环
          } else {
            print('宝箱可见，但距离过远：$distance > 1.5');
            // 与拾取物品一致的提示样式
            gameStateNotifier.addBroadcastMessage(
              '距离太远，无法打开宝箱',
              BroadcastMessageType.system,
            );
            return; // 已处理当前点击，退出循环避免重复提示
          }
        } else {
          print('宝箱不可见，无法交互');
        }
      }
    }

    // 检查保险箱点击
    if (gameState.safePositions.isNotEmpty) {
      for (final safePos in gameState.safePositions) {
        final double safeScreenX = mapOffsetX + (safePos.x * tileSize);
        final double safeScreenY = mapOffsetY + (safePos.y * tileSize);
        final Rect safeRect = Rect.fromLTWH(
          safeScreenX,
          safeScreenY,
          tileSize,
          tileSize,
        );
        if (safeRect.contains(localPosition)) {
          final math.Point<int> safePoint = math.Point(
            safePos.x.toInt(),
            safePos.y.toInt(),
          );
          bool isSafeVisible = false;
          if (gameStateNotifier.smoothVisionManager != null) {
            final opacity = gameStateNotifier.smoothVisionManager!
                .getTileOpacity(safePoint);
            isSafeVisible = opacity > 0.0;
          } else {
            isSafeVisible = gameState.visibleTiles.contains(safePoint);
          }
          if (isSafeVisible) {
            final double playerX = gameState.playerPosition.x;
            final double playerY = gameState.playerPosition.y;
            final double distance = math.sqrt(
              math.pow(playerX - safePos.x, 2) +
                  math.pow(playerY - safePos.y, 2),
            );
            if (distance <= 1.5) {
              gameStateNotifier.openSafeAtPosition(safePos);
              return;
            } else {
              gameStateNotifier.addBroadcastMessage(
                '距离太远，无法打开保险箱',
                BroadcastMessageType.system,
              );
              return;
            }
          }
        }
      }
    }

    // 检查商店点击（如果商店存在）
    if (gameState.schoolShop != null) {
      final shopPos = gameState.schoolShop!.position;
      final double shopScreenX = mapOffsetX + (shopPos.x * tileSize);
      final double shopScreenY = mapOffsetY + (shopPos.y * tileSize);

      // 检查点击是否在商店区域内
      final Rect shopRect = Rect.fromLTWH(
        shopScreenX,
        shopScreenY,
        tileSize,
        tileSize,
      );
      if (shopRect.contains(localPosition)) {
        // 检查商店是否可见
        final math.Point<int> shopPoint = math.Point(
          shopPos.x.toInt(),
          shopPos.y.toInt(),
        );
        bool isShopVisible = false;

        if (gameStateNotifier.smoothVisionManager != null) {
          final opacity = gameStateNotifier.smoothVisionManager!.getTileOpacity(
            shopPoint,
          );
          isShopVisible = opacity > 0.0;
        } else {
          isShopVisible = gameState.visibleTiles.contains(shopPoint);
        }

        if (isShopVisible) {
          // 打开商店
          gameStateNotifier.toggleShop();
        }
      }
    }

    // 检查炼金机点击（如果存在位置）
    if (gameState.alchemyStation != null) {
      final alchPos = gameState.alchemyStation!;
      final double alchScreenX = mapOffsetX + (alchPos.x * tileSize);
      final double alchScreenY = mapOffsetY + (alchPos.y * tileSize);
      final Rect alchRect = Rect.fromLTWH(
        alchScreenX,
        alchScreenY,
        tileSize,
        tileSize,
      );
      if (alchRect.contains(localPosition)) {
        final math.Point<int> alchPoint = math.Point(
          alchPos.x.toInt(),
          alchPos.y.toInt(),
        );
        bool isAlchemyVisible = false;
        if (gameStateNotifier.smoothVisionManager != null) {
          final opacity = gameStateNotifier.smoothVisionManager!.getTileOpacity(
            alchPoint,
          );
          isAlchemyVisible = opacity > 0.0;
        } else {
          isAlchemyVisible = gameState.visibleTiles.contains(alchPoint);
        }

        if (isAlchemyVisible) {
          // 关键区域：距离判定与宝箱一致（<=1.5）
          final double playerX = gameState.playerPosition.x;
          final double playerY = gameState.playerPosition.y;
          final double distance = math.sqrt(
            math.pow(playerX - alchPos.x, 2) + math.pow(playerY - alchPos.y, 2),
          );
          if (distance <= 1.5) {
            gameStateNotifier.toggleAlchemy();
          } else {
            gameStateNotifier.addBroadcastMessage(
              '距离太远，无法操作炼金机',
              BroadcastMessageType.system,
            );
          }
          return;
        }
      }
    }

    // 检查地面物品点击
    for (final entry in gameState.groundItems.entries) {
      final itemPos = entry.key;
      final items = entry.value;

      if (items.isEmpty) continue;

      final double itemScreenX = mapOffsetX + (itemPos.x * tileSize);
      final double itemScreenY = mapOffsetY + (itemPos.y * tileSize);

      // 检查点击是否在物品区域内
      final Rect itemRect = Rect.fromLTWH(
        itemScreenX,
        itemScreenY,
        tileSize,
        tileSize,
      );
      if (itemRect.contains(localPosition)) {
        // 检查物品是否可见
        final math.Point<int> itemPoint = math.Point(itemPos.x, itemPos.y);
        bool isItemVisible = false;

        if (gameStateNotifier.smoothVisionManager != null) {
          final opacity = gameStateNotifier.smoothVisionManager!.getTileOpacity(
            itemPoint,
          );
          isItemVisible = opacity > 0.0;
        } else {
          isItemVisible = gameState.visibleTiles.contains(itemPoint);
        }

        if (isItemVisible) {
          // 检查玩家是否在拾取范围内（相邻格子或同一格子）
          final double playerX = gameState.playerPosition.x;
          final double playerY = gameState.playerPosition.y;
          final double distance = math.sqrt(
            math.pow(playerX - itemPos.x, 2) + math.pow(playerY - itemPos.y, 2),
          );

          // 拾取范围为1.5格（允许对角线拾取）
          if (distance <= 1.5) {
            // 拾取第一个物品
            final itemToPickup = items.first;
            final success = gameStateNotifier.pickupItemFromGround(
              itemPos,
              itemToPickup,
            );

            if (success) {
              print('成功拾取物品: ${itemToPickup.name}');
            } else {
              print('拾取失败，可能是背包已满');
            }
            return; // 找到点击的物品后退出循环
          } else {
            // 显示距离太远的提示
            gameStateNotifier.addBroadcastMessage(
              '距离太远，无法拾取',
              BroadcastMessageType.system,
            );
          }
        }
      }
    }
  }

  // 构建精神值环形图（左上角）- 立体效果
  Widget _buildSanityCircle(OptimizedGameState gameState) {
    final double currentSan = (gameState.characterStats['san'] ?? 0)
        .toDouble()
        .clamp(0, 250);
    final double maxSan = 250.0; // 精神值上限固定为250
    final double percentage = (currentSan / maxSan).clamp(
      0.0,
      1.0,
    ); // 限制在100%以内
    final bool sanChanged = (_lastSanityPercentage != percentage);
    // 关键区域：帧结束后更新上次百分比，用于下次构建的动画起点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lastSanityPercentage = percentage;
    });

    return Positioned(
      top: 40,
      left: 20,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // 立体阴影效果
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(4, 4),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(-2, -2),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 外层立体背景圆环
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.grey.shade800, Colors.black.withOpacity(0.9)],
                  stops: const [0.7, 1.0],
                ),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.4),
                  width: 2,
                ),
              ),
            ),
            // 关键区域：精神值环过渡动画 + 末端发光
            SizedBox(
              width: 76,
              height: 76,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: _lastSanityPercentage,
                  end: percentage,
                ),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, animPercent, child) {
                  return CustomPaint(
                    painter: _3DCircularProgressPainter(
                      percentage: animPercent,
                      strokeWidth: 14,
                      glowOpacity: sanChanged ? 0.9 : 0.0,
                    ),
                  );
                },
              ),
            ),
            // 内层光泽效果
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
            // 中心数字显示
            Text(
              '${currentSan.round()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                  Shadow(
                    color: Colors.blue,
                    offset: Offset(-1, -1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建精神值右侧心电图（实时）
  Widget _buildSanityECG(OptimizedGameState gameState) {
    final stats = gameState.characterStats;
    final double currentSan = (stats['san'] ?? 0).toDouble().clamp(0, 250);
    final double hp = (stats['hp'] ?? 0).toDouble();
    final double maxHp = (stats['maxHp'] ?? 100).toDouble();
    final double hpRatio = maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0.0;
    final double o2Ratio =
        (gameState.actualMaxOxygen > 0)
            ? (gameState.currentOxygen / gameState.actualMaxOxygen).clamp(
              0.0,
              1.0,
            )
            : 1.0;
    final double moveSpeed = ((stats['moveSpeed'] ?? 1.0) as num).toDouble();
    // 将移动速度映射到0-1（假设1-3为常见范围）
    final double moveFactor = ((moveSpeed - 1.0) / 2.0).clamp(0.0, 1.0);
    final double castingFactor =
        gameState.currentCastingSkillId != null ? 1.0 : 0.0;
    final double damagePulse =
        (gameState.shouldShowDamageEffect == true)
            ? (gameState.lastDamageAmount.clamp(0.0, 50.0) / 50.0).clamp(
              0.2,
              1.0,
            )
            : 0.0;
    final bool isInWater = gameState.isInWater;

    // 计算最近可见鬼与玩家的距离并映射为接近度因子（0-1）
    final playerGrid = gameState.playerPosition.toPoint();
    double minGhostDistance = double.infinity;
    for (final ghost in gameState.ghostManager.ghosts) {
      if (ghost.position != null && !ghost.isInvisible) {
        final gp = ghost.position!.toPoint();
        final dx = (playerGrid.x - gp.x).toDouble();
        final dy = (playerGrid.y - gp.y).toDouble();
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < minGhostDistance) minGhostDistance = d;
      }
    }
    const double dangerRange = 25.0; // 在25格内开始显著影响心跳
    final double proximityFactor =
        minGhostDistance.isFinite
            ? ((dangerRange - minGhostDistance) / dangerRange).clamp(0.0, 1.0)
            : 0.0;
    // 根据接近度触发心跳音效（平时静音，靠近时响起并加速）
    MusicManager().updateHeartbeat(proximityFactor);
    return Positioned(
      top: 50,
      left: 110,
      child: Container(
        width: 160,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.88),
              Colors.grey.shade900.withOpacity(0.92),
            ],
          ),
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 0),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: SanityECGPainter(
                  phase: _ecgPhase,
                  san: currentSan,
                  hpRatio: hpRatio,
                  oxygenRatio: o2Ratio,
                  moveFactor: moveFactor,
                  castingFactor: castingFactor,
                  damagePulse: damagePulse,
                  isInWater: isInWater,
                  proximityFactor: proximityFactor,
                ),
              ),
            ),
            // HUD 标签（右上角）
            Positioned(
              top: 6,
              right: 8,
              child: Row(
                children: [
                  Icon(Icons.show_chart, color: Colors.cyanAccent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'ECG',
                    style: TextStyle(
                      color: Colors.cyanAccent.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建底部状态条（生命值和饱食度）
  Widget _buildBottomStatusBars(OptimizedGameState gameState) {
    final double currentHp = (gameState.characterStats['hp'] ?? 0).toDouble();
    final double maxHp = (gameState.characterStats['maxHp'] ?? 100).toDouble();
    final double currentFood =
        (gameState.characterStats['food'] ?? 0).toDouble();
    // 关键区域：饱食度上限改为动态 maxFood
    final double maxFood =
        (gameState.characterStats['maxFood'] ?? 100).toDouble();
    // 关键区域：记录当前百分比用于端点发光与过渡动画起点
    final double hpPct = (currentHp / maxHp).clamp(0.0, 1.0);
    final double foodPct = (currentFood / maxFood).clamp(0.0, 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lastHpPercentage = hpPct;
      _lastFoodPercentage = foodPct;
    });

    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 生命值条（红色）- 移到左边
          _buildStatusBar(Icons.favorite, currentHp, maxHp, Colors.red, '生命值'),

          const SizedBox(width: 40),

          // 饱食度条（橘色）
          _buildFoodBar(currentFood, maxFood),
        ],
      ),
    );
  }

  // 构建单个状态条（更细更长的设计）
  Widget _buildStatusBar(
    IconData icon,
    double current,
    double max,
    Color color,
    String label,
  ) {
    final double percentage = (current / max).clamp(0.0, 1.0);
    final double fillWidth = (176 * percentage).clamp(0.0, 176.0);
    final bool changed = (_lastHpPercentage != percentage);

    return Container(
      width: 180, // 进一步增加宽度从160到180
      height: 16, // 进一步减少高度从20到16
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(5), // 调整圆角
        border: Border.all(color: color.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景进度条
          Container(
            width: 176, // 调整内部宽度
            height: 12, // 调整内部高度
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: ui_theme.UITheme.progressBackground(),
            ),
          ),
          // 进度条
          Positioned(
            left: 2,
            child: AnimatedContainer(
              width: fillWidth, // 调整进度条宽度
              height: 12, // 调整进度条高度
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: ui_theme.UITheme.progressFill(color),
              ),
            ),
          ),
          // 关键区域：端点发光（值变化时亮起后渐隐）
          Positioned(
            left: (2 + fillWidth - 8).clamp(2.0, 170.0),
            child: AnimatedOpacity(
              opacity: changed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              child: Container(
                width: 14,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.9),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 数值文本
          Text(
            '${current.round()}/${max.round()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10, // 进一步减小字体
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建饱食度条
  Widget _buildFoodBar(double currentFood, double maxFood) {
    final double foodPercentage = (currentFood / maxFood).clamp(0.0, 1.0);
    final double fillWidth = (176 * foodPercentage).clamp(0.0, 176.0);
    final bool changed = (_lastFoodPercentage != foodPercentage);

    return Container(
      width: 180,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景进度条
          Container(
            width: 176,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: ui_theme.UITheme.progressBackground(),
            ),
          ),
          // 饱食度进度条
          Positioned(
            left: 2,
            child: AnimatedContainer(
              width: fillWidth,
              height: 12,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: ui_theme.UITheme.progressFill(Colors.orange),
              ),
            ),
          ),
          // 关键区域：端点发光（值变化时亮起后渐隐）
          Positioned(
            left: (2 + fillWidth - 8).clamp(2.0, 170.0),
            child: AnimatedOpacity(
              opacity: changed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              child: Container(
                width: 14,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.9),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 数值文本
          Text(
            '${currentFood.round()}/${maxFood.round()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建施法进度条
  Widget _buildCastingBar(double castingProgress, String castingSkillId) {
    return GestureDetector(
      onTap: () {
        // 取消施法
        final notifier = ProviderScope.containerOf(
          context,
        ).read(optimizedGameStateProvider.notifier);
        notifier.cancelSkillCasting();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 150,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.purple.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 施法进度条背景
                Container(
                  width: 146,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                // 施法进度条
                Positioned(
                  left: 2,
                  child: Container(
                    width: (146 * castingProgress).clamp(0.0, 146.0),
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.5),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                // 施法进度文本
                Text(
                  '施法 ${(castingProgress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '点击取消施法',
            style: TextStyle(
              color: Colors.purple.shade300,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 构建移动控制
  Widget _buildMovementControls() {
    return Positioned(
      bottom: 40,
      left: 60,
      child: Consumer(
        builder: (context, ref, child) {
          final gameState = ref.watch(optimizedGameStateProvider);

          // 关键区域：当背包、商店或炼金界面打开时隐藏并遮挡摇杆
          // 说明：确保商店页面与炼金页面位于摇杆之上（视觉与触控均不受摇杆影响）
          if (gameState.showInventory ||
              gameState.showShop ||
              gameState.showAlchemy) {
            return const SizedBox.shrink();
          }

          return
          // 摇杆控制器
          Container(
            width: 120,
            height: 120,
            child: JoystickController(
              onMove: (dx, dy, intensity) {
                final notifier = ref.read(optimizedGameStateProvider.notifier);
                notifier.onJoystickMove(dx, dy, intensity);
              },
              onStop: () {
                final notifier = ref.read(optimizedGameStateProvider.notifier);
                notifier.onJoystickStop();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeaponControls() {
    return Positioned(
      bottom: 50,
      right: 30,
      child: Consumer(
        builder: (context, ref, child) {
          final gameState = ref.watch(optimizedGameStateProvider);
          if (gameState.showInventory ||
              gameState.showShop ||
              gameState.showAlchemy) {
            return const SizedBox.shrink();
          }
          final hasWeapon = (gameState.equipmentSlots['weapon'] != null);
          if (!hasWeapon) {
            return const SizedBox.shrink();
          }
          final bool showAmmo =
              gameState.selectedAttackMode == AttackMode.ranged &&
              gameState.weaponMagazineSize > 0;
          final String ammoText =
              showAmmo
                  ? '${gameState.weaponClipAmmo}/${gameState.weaponTotalAmmo}'
                  : '';
          final Color ammoColor =
              (gameState.weaponClipAmmo <= 0) ? Colors.redAccent : Colors.white;
          final bool canReload =
              showAmmo &&
              !gameState.isReloading &&
              gameState.weaponClipAmmo < gameState.weaponMagazineSize &&
              gameState.weaponTotalAmmo > 0;
          final double reloadProgress =
              gameState.isReloading ? gameState.reloadProgress : 0.0;
          final notifier = ref.read(optimizedGameStateProvider.notifier);
          final double fireBtnSize = 72.0; // 关键区域：开火按钮圆形尺寸

          return SizedBox(
            width: 260,
            height: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showAmmo)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.black.withOpacity(0.35),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              MdiIcons.ammunition,
                              color: Color(
                                (gameState.selectedAttackMode ==
                                            AttackMode.ranged
                                        ? gameState.rangedAttackTemplate.color
                                        : gameState.meleeAttackTemplate.color)
                                    .value,
                              ),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ammoText,
                              style: TextStyle(
                                color: ammoColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 72,
                              height: 28,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: Colors.white.withOpacity(0.10),
                                      ),
                                    ),
                                  ),
                                  if (gameState.isReloading)
                                    Positioned.fill(
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: reloadProgress,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            color: Colors.lightBlueAccent
                                                .withOpacity(0.35),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    gameState.isReloading ? '换弹中' : '换弹',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap:
                                            canReload
                                                ? () => notifier.startReload()
                                                : null,
                                        splashColor: Colors.white24,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                // 关键区域：开火按钮改为圆形，并以按钮滑动方向作为武器朝向
                GestureDetector(
                  onTap: () {
                    final gs = ProviderScope.containerOf(
                      context,
                    ).read(optimizedGameStateProvider);
                    if (gs.selectedAttackMode == AttackMode.ranged) {
                      // 全自动也支持单点开火；长按才进入连发
                      notifier.fireWeapon();
                    } else if (gs.selectedAttackMode == AttackMode.melee) {
                      notifier.fireWeapon();
                    }
                  },
                  onPanStart: (details) {
                    if (gameState.equipmentSlots['weapon'] == null) return;
                    final double cx = fireBtnSize / 2;
                    final double cy = fireBtnSize / 2;
                    final double dx = details.localPosition.dx - cx;
                    final double dy = details.localPosition.dy - cy;
                    final double norm = math.sqrt(dx * dx + dy * dy);
                    final double radius = fireBtnSize / 2;
                    final double intensity = (norm / radius).clamp(0.0, 1.0);
                    final double nx = norm > 0.0 ? (dx / norm) : 0.0;
                    final double ny = norm > 0.0 ? (dy / norm) : 0.0;
                    notifier.onWeaponJoystickMove(nx, ny, intensity);
                  },
                  onPanUpdate: (details) {
                    if (gameState.equipmentSlots['weapon'] == null) return;
                    final double cx = fireBtnSize / 2;
                    final double cy = fireBtnSize / 2;
                    final double dx = details.localPosition.dx - cx;
                    final double dy = details.localPosition.dy - cy;
                    final double norm = math.sqrt(dx * dx + dy * dy);
                    final double radius = fireBtnSize / 2;
                    final double intensity = (norm / radius).clamp(0.0, 1.0);
                    final double nx = norm > 0.0 ? (dx / norm) : 0.0;
                    final double ny = norm > 0.0 ? (dy / norm) : 0.0;
                    notifier.onWeaponJoystickMove(nx, ny, intensity);
                  },
                  onPanEnd: (details) {
                    notifier.onWeaponJoystickMove(0.0, 0.0, 0.0);
                  },
                  onLongPressStart: (details) {
                    final gs = ProviderScope.containerOf(
                      context,
                    ).read(optimizedGameStateProvider);
                    if (gs.selectedAttackMode == AttackMode.ranged &&
                        gs.weaponFireMode == FireMode.fullAuto) {
                      final Offset localPos = details.localPosition;
                      final double cx = fireBtnSize / 2;
                      final double cy = fireBtnSize / 2;
                      final double dx = localPos.dx - cx;
                      final double dy = localPos.dy - cy;
                      final double norm = math.sqrt(dx * dx + dy * dy);
                      final double radius = fireBtnSize / 2;
                      final double intensity = (norm / radius).clamp(0.0, 1.0);
                      final double nx = norm > 0.0 ? (dx / norm) : 0.0;
                      final double ny = norm > 0.0 ? (dy / norm) : 0.0;
                      notifier.onWeaponJoystickMove(nx, ny, intensity);
                      notifier.handleFireButtonPress();
                    }
                  },
                  onLongPressMoveUpdate: (details) {
                    final gs = ProviderScope.containerOf(
                      context,
                    ).read(optimizedGameStateProvider);
                    if (gs.selectedAttackMode == AttackMode.ranged &&
                        gs.weaponFireMode == FireMode.fullAuto) {
                      final Offset localPos = details.localPosition;
                      final double cx = fireBtnSize / 2;
                      final double cy = fireBtnSize / 2;
                      final double dx = localPos.dx - cx;
                      final double dy = localPos.dy - cy;
                      final double norm = math.sqrt(dx * dx + dy * dy);
                      final double radius = fireBtnSize / 2;
                      final double intensity = (norm / radius).clamp(0.0, 1.0);
                      final double nx = norm > 0.0 ? (dx / norm) : 0.0;
                      final double ny = norm > 0.0 ? (dy / norm) : 0.0;
                      notifier.onWeaponJoystickMove(nx, ny, intensity);
                    }
                  },
                  onLongPressEnd: (details) {
                    final gs = ProviderScope.containerOf(
                      context,
                    ).read(optimizedGameStateProvider);
                    if (gs.selectedAttackMode == AttackMode.ranged &&
                        gs.weaponFireMode == FireMode.fullAuto) {
                      notifier.handleFireButtonRelease();
                      notifier.onWeaponJoystickMove(0.0, 0.0, 0.0);
                    }
                  },
                  child: Builder(
                    builder: (context) {
                      final ui.Color accentUI =
                          gameState.selectedAttackMode == AttackMode.ranged
                              ? gameState.rangedAttackTemplate.color
                              : const ui.Color(0xFF00E5FF);
                      final Color accent = Color(accentUI.value);
                      return SizedBox(
                        width: fireBtnSize,
                        height: fireBtnSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 基础立体圆（深色渐变，不使用淡黄色）
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: const Alignment(-0.4, -0.4),
                                  radius: 0.9,
                                  colors: const [
                                    Color(0xFF1F2329),
                                    Color(0xFF343A41),
                                  ],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x66000000),
                                    blurRadius: 14,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                                border: Border.all(
                                  color: accent.withOpacity(0.9),
                                  width: 2,
                                ),
                              ),
                            ),
                            // 内侧斜面高光（模拟倒角）
                            Center(
                              child: Container(
                                width: fireBtnSize * 0.92,
                                height: fireBtnSize * 0.92,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0x33FFFFFF),
                                      Color(0x00000000),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // 顶部光泽层
                            Align(
                              alignment: Alignment.topCenter,
                              child: ClipOval(
                                child: SizedBox(
                                  width: fireBtnSize,
                                  height: fireBtnSize * 0.6,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0x44FFFFFF),
                                          Color(0x00000000),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 中心图标
                            Transform.rotate(
                              angle: 45 * 3.14159 / 180,
                              child: Icon(
                                MdiIcons.bullet,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 构建功能按钮
  Widget _buildActionButtons(OptimizedGameState gameState) {
    final notifier = ProviderScope.containerOf(
      context,
    ).read(optimizedGameStateProvider.notifier);
    final characterSkills = gameState.characterSkills;

    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 背包按钮（背包打开时隐藏）
          if (!gameState.showInventory)
            Consumer(
              builder: (context, ref, child) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 50,
                  height: 50,
                  child: Material(
                    color: Colors.red.withOpacity(0.8), // 临时改为红色，更容易识别
                    borderRadius: BorderRadius.circular(5),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () {
                        final notifier = ref.read(
                          optimizedGameStateProvider.notifier,
                        );
                        notifier.openInventory(); // 只负责打开背包
                      },
                      // 关键区域：美化背包按钮为胶囊样式（渐变 + 图标 + 边框）
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.amber.shade700,
                              Colors.amber.shade800,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.amber.shade400.withOpacity(0.7),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.shade200.withOpacity(0.4),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.inventory_2,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // 关键区域：左下角显示玩家坐标 X/Y，实时更新（不拦截交互）
  Widget _buildPlayerCoordinates(OptimizedGameState gameState) {
    final int gridX = gameState.playerPosition.x.round();
    final int gridY = gameState.playerPosition.y.round();
    return Positioned(
      left: 8,
      bottom: 8,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(5), // 统一圆角为5
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Text(
            'X: $gridX  Y: $gridY',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoneLabel(OptimizedGameState gameState) {
    final zoneName = gameState.currentZoneName;
    final until = gameState.zoneNameVisibleUntil;
    if (zoneName == null ||
        zoneName.isEmpty ||
        until == null ||
        DateTime.now().isAfter(until)) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 130,
      left: 110,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Text(
            zoneName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // 构建角色信息面板（左侧）
  Widget _buildCharacterInfoView(OptimizedGameState gameState) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left:
          gameState.showCharacterInfo
              ? 0
              : -MediaQuery.of(context).size.width * 0.35,
      top: 0,
      bottom: 0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.35, // 左侧面板宽度
        color: Colors.black.withOpacity(0.85),
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade900,
                Colors.blue.shade800,
                Colors.blue.shade900,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 20,
                offset: const Offset(5, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // 角色信息标题栏
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade800, Colors.blue.shade700],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          '角色信息',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () {
                          final ref = ProviderScope.containerOf(
                            context,
                          ).read(optimizedGameStateProvider.notifier);
                          ref.toggleCharacterInfo();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 角色详细信息内容
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 角色头像和基本信息
                        _buildCharacterBasicInfo(gameState),
                        const SizedBox(height: 20),

                        // 角色属性详情
                        _buildCharacterStats(gameState),
                        const SizedBox(height: 20),

                        // 角色能力和特殊属性
                        _buildCharacterAbilities(gameState),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建角色基本信息
  Widget _buildCharacterBasicInfo(OptimizedGameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // 角色头像
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.blue.shade300, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(37),
              child: Image.asset(
                gameState.characterStats['image'] ?? 'images/man/cook.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(37),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 角色名称
          Text(
            gameState.characterStats['name'] ?? '未知角色',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // 角色描述
          Text(
            gameState.characterStats['description'] ?? '无描述',
            style: TextStyle(color: Colors.blue.shade200, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 构建角色属性统计
  Widget _buildCharacterStats(OptimizedGameState gameState) {
    final stats = gameState.characterStats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '属性详情',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // 生命值
          _buildStatRow(
            '生命值',
            '${stats['hp']}/${stats['maxHp']}',
            Icons.favorite,
            Colors.red,
            stats['hp'] / stats['maxHp'],
          ),

          // 理智值
          _buildStatRow(
            '理智值',
            '${(stats['san'] as num).toDouble().clamp(0, 250).toInt()}/250',
            Icons.psychology,
            Colors.blue,
            ((stats['san'] as num).toDouble().clamp(0, 250) / 250.0).clamp(
              0.0,
              1.0,
            ),
          ), // 精神值上限250，限制在100%以内
          // 移动速度
          _buildStatRow(
            '移动速度',
            '${stats['moveSpeed']?.toInt() ?? 100}',
            Icons.directions_run,
            Colors.orange,
            1.0,
          ),

          // 子弹显示（在饱食度条上方，仅远程模式）
          if (gameState.selectedAttackMode == AttackMode.ranged &&
              gameState.weaponMagazineSize > 0)
            _buildStatRow(
              '子弹',
              '${gameState.weaponClipAmmo}/${gameState.weaponTotalAmmo}',
              MdiIcons.ammunition,
              (gameState.weaponClipAmmo <= 0) ? Colors.redAccent : Colors.amber,
              1.0,
            ),

          // 饱食度（使用动态上限）
          _buildStatRow(
            '饱食度',
            '${stats['food']}/${stats['maxFood']}',
            Icons.restaurant,
            Colors.green,
            (((stats['food'] ?? 0) as num).toDouble() /
                    (((stats['maxFood'] ?? 100) as num).toDouble()))
                .clamp(0.0, 1.0),
          ),

          // 金币
          _buildStatRow(
            '金币',
            '${stats['gold']}',
            Icons.monetization_on,
            Colors.yellow,
            1.0,
          ),

          // 移动速度
          _buildStatRow(
            '移动速度',
            '${(gameState.characterStats['moveSpeed'] ?? 5.0).toInt()}',
            Icons.directions_run,
            Colors.cyan,
            1.0,
          ),
        ],
      ),
    );
  }

  // 构建单个属性行
  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (progress < 1.0) ...[
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建角色能力信息
  Widget _buildCharacterAbilities(OptimizedGameState gameState) {
    final abilities =
        gameState.characterStats['specialAbilities'] as List<String>? ?? [];

    if (abilities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text(
            '暂无特殊能力',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '特殊能力',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...abilities
              .map(
                (ability) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ability,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  // 构建游戏页面
  Widget _buildGamePage(OptimizedGameState gameState) {
    return HPListener(
      onDamageDetected: (event) {
        // 触发伤害事件到provider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              final container = ProviderScope.containerOf(context);
              container.read(damageEventProvider.notifier).triggerDamage(event);
            } catch (e) {
              print('触发伤害事件时出错: $e');
            }
          }
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 主游戏内容区域（移除伤害效果包装器）
          SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 主游戏区域
                _buildGameArea(gameState),

                // 精神值环形图（左上角）
                _buildSanityCircle(gameState),
                // 心电图（紧邻精神值右侧）
                _buildSanityECG(gameState),

                // 生命值和饱食度条（下方居中）
                _buildBottomStatusBars(gameState),

                // 设置按钮（右上角）
                _buildSettingsButton(),
                // 处分单（右上角设置按钮左侧）
                _buildPunishmentCard(gameState),

                // 播报框（移至最顶层外层Stack显示，避免被遮挡）

                // 角色信息面板（左侧）
                _buildCharacterInfoView(gameState),

                // 商店界面（独立组件，避免不必要的刷新）
                const ShopView(),

                // 炼金界面（独立组件，按需显示）
                const AlchemyView(),

                // 炼金抽奖特效覆盖层（按需显示）
                const AlchemyEffectOverlay(),

                // 物品使用进度条（动态显示）
                const ItemUsageProgress(),

                // 宝箱探索进度条（动态显示）
                const ChestExplorationProgress(),

                // 氧气恢复进度条（动态显示）
                Consumer(
                  builder: (context, ref, child) {
                    final gameState = ref.watch(optimizedGameStateProvider);
                    if (gameState.oxygenRecoveryManager?.isRecovering == true) {
                      return Positioned(
                        top:
                            250, // 在宝箱探索进度条下方（宝箱进度条top: 200 + height: 40 + 间距: 10）
                        right: 80, // 与其他进度条右对齐
                        width: 200, // 与其他进度条同宽
                        child: OxygenRecoveryProgress(
                          startOxygen:
                              gameState.oxygenRecoveryManager!.startOxygen,
                          targetOxygen:
                              gameState.oxygenRecoveryManager!.targetOxygen,
                          duration: gameState.oxygenRecoveryManager!.duration,
                          onProgress:
                              gameState.oxygenRecoveryManager!.onProgress,
                          onComplete: () {
                            gameState.oxygenRecoveryManager!.completeRecovery();
                          },
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // 氧气条（显示在生命值条上方）
                Consumer(
                  builder: (context, ref, child) {
                    final gameState = ref.watch(optimizedGameStateProvider);
                    if (gameState.oxygenSystem?.shouldShowOxygenBar == true) {
                      return Positioned(
                        bottom: 120, // 在生命值条(bottom: 80)上方40像素
                        left: 0,
                        right: 0,
                        child: Center(
                          child: OxygenBar(
                            oxygenSystem: gameState.oxygenSystem!,
                            width: 180, // 与生命值条相同宽度
                            height: 16, // 与生命值条相同高度
                            margin: EdgeInsets.zero, // 移除默认边距
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // 关键区域：为背包界面添加打开/关闭动画（AnimatedSwitcher）
          // 使用淡入淡出 + 轻微缩放，覆盖显示与隐藏两种动作
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child:
                gameState.showInventory
                    ? const InventoryView()
                    : const SizedBox.shrink(),
            transitionBuilder: (child, animation) {
              final fade = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              );
              final scale = Tween<double>(
                begin: 0.96,
                end: 1.0,
              ).animate(animation);
              return FadeTransition(
                opacity: fade,
                child: ScaleTransition(scale: scale, child: child),
              );
            },
          ),

          // 交互控制组件（最高优先级，不受伤害效果影响）
          // 移动控制（摇杆）
          _buildMovementControls(),
          _buildWeaponControls(),
          // 关键区域：在左下角常显玩家坐标（不影响操作）
          _buildPlayerCoordinates(gameState),
          _buildZoneLabel(gameState),

          // 功能按钮
          _buildActionButtons(gameState),
          // 宝箱/保险箱搜索页面叠加层（整页覆盖，拦截交互）
          const ChestSearchOverlay(),
          const SafeSearchOverlay(),

          // 关键区域：提示框置于最上层，不被任何叠加层遮挡
          _buildBroadcastBox(gameState),
        ],
      ),
    );
  }
}

/// 背包界面组件 - 类似于ShopView的实现
class InventoryView extends ConsumerWidget {
  const InventoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 直接显示背包页面（外部已有条件判断）
    return const Positioned.fill(child: InventoryPage());
  }
}

// 自定义3D环形进度绘制器
class _3DCircularProgressPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final double glowOpacity; // 关键区域：端点发光透明度（变化时提升）

  _3DCircularProgressPainter({
    required this.percentage,
    required this.strokeWidth,
    this.glowOpacity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 背景圆环（深色阴影）
    final backgroundPaint =
        Paint()
          ..color = Colors.grey.shade900
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆环（渐变效果）
    final progressPaint =
        Paint()
          ..shader = SweepGradient(
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade600,
              Colors.blue.shade800,
              Colors.blue.shade400,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // 绘制进度弧
    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 从顶部开始
      sweepAngle,
      false,
      progressPaint,
    );

    // 添加高光效果
    if (percentage > 0) {
      final highlightPaint =
          Paint()
            ..color = Colors.white.withOpacity(0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth / 3
            ..strokeCap = StrokeCap.round;

      // 绘制高光弧（较短的弧段）
      final highlightAngle = math.min(sweepAngle, math.pi / 4);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        highlightAngle,
        false,
        highlightPaint,
      );

      // 关键区域：在进度末端添加发光（变化时可见）
      if (glowOpacity > 0) {
        final double endAngle = -math.pi / 2 + sweepAngle;
        final Offset endPoint = Offset(
          center.dx + radius * math.cos(endAngle),
          center.dy + radius * math.sin(endAngle),
        );

        final glowPaint =
            Paint()
              ..color = Colors.blueAccent.withOpacity(glowOpacity)
              ..style = PaintingStyle.fill
              ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);

        // 端点发光圆斑
        canvas.drawCircle(endPoint, strokeWidth * 0.45, glowPaint);

        // 端点短弧加权发光
        final glowArcPaint =
            Paint()
              ..color = Colors.blueAccent.withOpacity(glowOpacity * 0.9)
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth * 0.8
              ..strokeCap = StrokeCap.round
              ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          endAngle - 0.08,
          0.16,
          false,
          glowArcPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _3DCircularProgressPainter ||
        oldDelegate.percentage != percentage ||
        oldDelegate.strokeWidth != strokeWidth ||
        (oldDelegate is _3DCircularProgressPainter &&
            oldDelegate.glowOpacity != glowOpacity);
  }
}

// 自定义画笔类用于绘制游戏区域
class _GameAreaPainter extends CustomPainter {
  final OptimizedGameState gameState;
  final Map<String, ui.Image> terrainImages;
  final ui.Image? characterImage;
  final SmoothVisionManager? smoothVisionManager;
  final DamageEvent? damageEvent;
  final double visionBorderFlashValue; // 视野边界闪烁动画值
  final Offset? aimTouchPoint;
  final double aimNX;
  final double aimNY;
  final bool aimActive;

  _GameAreaPainter({
    required this.gameState,
    required this.terrainImages,
    this.characterImage,
    this.smoothVisionManager,
    this.damageEvent,
    this.visionBorderFlashValue = 1.0, // 默认值为1.0（不闪烁）
    this.aimTouchPoint,
    this.aimNX = 0.0,
    this.aimNY = 0.0,
    this.aimActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制游戏地图和角色的逻辑
    final double tileSize = 40.0;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // 计算玩家在屏幕中心的偏移
    final double playerScreenX = centerX;
    final double playerScreenY = centerY;

    // 计算地图偏移，使玩家始终在屏幕中心
    final double mapOffsetX =
        playerScreenX - (gameState.playerPosition.x * tileSize);
    final double mapOffsetY =
        playerScreenY - (gameState.playerPosition.y * tileSize);

    // 先绘制黑色背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    // 绘制地图（只绘制可见的瓦片）
    for (int y = 0; y < gameState.map.length; y++) {
      for (int x = 0; x < gameState.map[y].length; x++) {
        final double tileX = mapOffsetX + (x * tileSize);
        final double tileY = mapOffsetY + (y * tileSize);

        // 只绘制在屏幕范围内的瓦片
        if (tileX > -tileSize &&
            tileX < size.width &&
            tileY > -tileSize &&
            tileY < size.height) {
          // 获取瓦片的透明度 - 支持平滑视野过渡
          final math.Point<int> tilePoint = math.Point(x, y);
          double tileOpacity = 1.0;

          if (smoothVisionManager != null) {
            // 使用平滑视野管理器获取透明度
            tileOpacity = smoothVisionManager!.getTileOpacity(tilePoint);

            // 如果透明度为0，跳过渲染
            if (tileOpacity <= 0.0) {
              continue;
            }
          } else {
            // 回退到原始的可见性检查
            final bool isVisible = gameState.visibleTiles.contains(tilePoint);
            if (!isVisible) {
              continue;
            }
          }

          final String terrain = gameState.map[y][x];
          final Rect tileRect = Rect.fromLTWH(tileX, tileY, tileSize, tileSize);

          // 尝试使用贴图渲染，如果没有贴图则使用颜色渲染
          final ui.Image? terrainImage = terrainImages[terrain];

          if (terrainImage != null) {
            // 使用贴图渲染，应用透明度
            final Rect srcRect = Rect.fromLTWH(
              0,
              0,
              terrainImage.width.toDouble(),
              terrainImage.height.toDouble(),
            );
            final Paint imagePaint =
                Paint()..color = Colors.white.withValues(alpha: tileOpacity);
            canvas.drawImageRect(terrainImage, srcRect, tileRect, imagePaint);
          } else {
            // 回退到颜色渲染（使用改进的颜色和渐变效果）
            final Paint terrainPaint = Paint();
            Color terrainColor;

            switch (terrain) {
              case 'grass':
                terrainColor = Colors.green.shade600;
                break;
              case 'wall':
                terrainColor = Colors.grey.shade700;
                break;
              case 'water':
                terrainColor = Colors.blue.shade600;
                break;
              case 'path':
                terrainColor = Colors.brown.shade400;
                break;
              case 'building':
                terrainColor = Colors.grey.shade800;
                break;
              case 'woods':
                terrainColor = Colors.green.shade800;
                break;
              case 'shop':
                terrainColor = Colors.purple.shade600;
                break;
              case 'chest':
                terrainColor = Colors.orange.shade600;
                break;
              default:
                terrainColor = Colors.grey.shade500;
            }

            // 添加渐变效果使地形更美观，应用透明度
            final gradient = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                terrainColor.withOpacity(0.9 * tileOpacity),
                terrainColor.withOpacity(tileOpacity),
                terrainColor.withOpacity(0.8 * tileOpacity),
              ],
            );

            terrainPaint.shader = gradient.createShader(tileRect);
            canvas.drawRect(tileRect, terrainPaint);
          }

          // 绘制细微边框以增强视觉效果，应用透明度
          final Paint borderPaint =
              Paint()
                ..color = Colors.black12.withOpacity(0.5 * tileOpacity)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.5;
          canvas.drawRect(tileRect, borderPaint);

          // 绘制雾霾装饰效果（如果该瓦片需要雾霾装饰）
          if (smoothVisionManager != null) {
            _drawFogDecorationIfNeeded(
              canvas,
              tilePoint,
              tileRect,
              tileOpacity,
            );
          }
        }
      }
    }

    // 绘制商店
    if (gameState.schoolShop != null) {
      final shopPos = gameState.schoolShop!.position;
      final double shopX = mapOffsetX + (shopPos.x * tileSize);
      final double shopY = mapOffsetY + (shopPos.y * tileSize);

      // 只在屏幕范围内且可见时绘制商店
      if (shopX > -tileSize &&
          shopX < size.width &&
          shopY > -tileSize &&
          shopY < size.height) {
        final math.Point<int> shopPoint = math.Point(
          shopPos.x.toInt(),
          shopPos.y.toInt(),
        );
        double shopOpacity = 1.0;

        if (smoothVisionManager != null) {
          shopOpacity = smoothVisionManager!.getTileOpacity(shopPoint);
          if (shopOpacity <= 0.0) {
            // 商店不可见，跳过绘制
          } else {
            _drawShop(canvas, shopX, shopY, tileSize, shopOpacity);
          }
        } else {
          // 回退到原始的可见性检查
          final bool isVisible = gameState.visibleTiles.contains(shopPoint);
          if (isVisible) {
            _drawShop(canvas, shopX, shopY, tileSize, shopOpacity);
          }
        }
      }
    }

    // 绘制炼金机
    if (gameState.alchemyStation != null) {
      final stationPos = gameState.alchemyStation!;
      final double alcX = mapOffsetX + (stationPos.x * tileSize);
      final double alcY = mapOffsetY + (stationPos.y * tileSize);

      // 只在屏幕范围内且可见时绘制炼金机
      if (alcX > -tileSize &&
          alcX < size.width &&
          alcY > -tileSize &&
          alcY < size.height) {
        final math.Point<int> alcPoint = math.Point(
          stationPos.x.toInt(),
          stationPos.y.toInt(),
        );
        double alcOpacity = 1.0;
        if (smoothVisionManager != null) {
          alcOpacity = smoothVisionManager!.getTileOpacity(alcPoint);
          if (alcOpacity > 0.0) {
            _drawAlchemy(canvas, alcX, alcY, tileSize, alcOpacity);
          }
        } else {
          final bool isVisible = gameState.visibleTiles.contains(alcPoint);
          if (isVisible) {
            _drawAlchemy(canvas, alcX, alcY, tileSize, alcOpacity);
          }
        }
      }
    }

    // 绘制宝箱
    for (final chestPos in gameState.chestPositions) {
      final double chestX = mapOffsetX + (chestPos.x * tileSize);
      final double chestY = mapOffsetY + (chestPos.y * tileSize);

      // 只在屏幕范围内且可见时绘制宝箱
      if (chestX > -tileSize &&
          chestX < size.width &&
          chestY > -tileSize &&
          chestY < size.height) {
        final math.Point<int> chestPoint = math.Point(
          chestPos.x.toInt(),
          chestPos.y.toInt(),
        );
        double chestOpacity = 1.0;

        if (smoothVisionManager != null) {
          chestOpacity = smoothVisionManager!.getTileOpacity(chestPoint);
          if (chestOpacity <= 0.0) {
            // 宝箱不可见，跳过绘制
            continue;
          }
        } else {
          // 回退到原始的可见性检查
          final bool isVisible = gameState.visibleTiles.contains(chestPoint);
          if (!isVisible) {
            continue;
          }
        }

        _drawChest(canvas, chestX, chestY, tileSize, chestOpacity);
      }

      // 绘制保险箱（仅在可见时）
      for (final safePos in gameState.safePositions) {
        final double safeX = mapOffsetX + (safePos.x * tileSize);
        final double safeY = mapOffsetY + (safePos.y * tileSize);
        if (safeX > -tileSize &&
            safeX < size.width &&
            safeY > -tileSize &&
            safeY < size.height) {
          final math.Point<int> safePoint = math.Point(
            safePos.x.toInt(),
            safePos.y.toInt(),
          );
          double safeOpacity = 1.0;
          if (smoothVisionManager != null) {
            safeOpacity = smoothVisionManager!.getTileOpacity(safePoint);
            if (safeOpacity <= 0.0) {
              continue;
            }
          } else {
            final bool isVisible = gameState.visibleTiles.contains(safePoint);
            if (!isVisible) {
              continue;
            }
          }
          _drawSafe(canvas, safeX, safeY, tileSize, safeOpacity);
        }
      }
    }

    // 绘制地面物品
    for (final entry in gameState.groundItems.entries) {
      final position = entry.key;
      final items = entry.value;

      if (items.isNotEmpty) {
        final double itemX = mapOffsetX + (position.x * tileSize);
        final double itemY = mapOffsetY + (position.y * tileSize);

        // 只在屏幕范围内且可见时绘制地面物品
        if (itemX > -tileSize &&
            itemX < size.width &&
            itemY > -tileSize &&
            itemY < size.height) {
          final math.Point<int> itemPoint = math.Point(position.x, position.y);
          double itemOpacity = 1.0;

          if (smoothVisionManager != null) {
            itemOpacity = smoothVisionManager!.getTileOpacity(itemPoint);
            if (itemOpacity <= 0.0) {
              // 地面物品不可见，跳过绘制
              continue;
            }
          } else {
            // 回退到原始的可见性检查
            final bool isVisible = gameState.visibleTiles.contains(itemPoint);
            if (!isVisible) {
              continue;
            }
          }

          _drawGroundItems(canvas, itemX, itemY, tileSize, items, itemOpacity);
        }
      }
    }

    // 绘制鬼
    _drawGhosts(canvas, mapOffsetX, mapOffsetY, tileSize, size);

    // 绘制玩家角色
    if (characterImage != null) {
      // 使用角色贴图
      final double characterSize = tileSize * 0.8; // 角色大小为瓦片大小的80%
      final Rect characterRect = Rect.fromCenter(
        center: Offset(playerScreenX, playerScreenY),
        width: characterSize,
        height: characterSize,
      );

      final Rect srcRect = Rect.fromLTWH(
        0,
        0,
        characterImage!.width.toDouble(),
        characterImage!.height.toDouble(),
      );

      // 根据玩家朝向决定是否翻转贴图
      final bool shouldFlip = !gameState.playerPosition.facingRight;

      if (shouldFlip) {
        // 需要翻转时，先保存画布状态
        canvas.save();
        // 移动到角色中心
        canvas.translate(playerScreenX, playerScreenY);
        // 水平翻转
        canvas.scale(-1.0, 1.0);
        // 移回原位置
        canvas.translate(-playerScreenX, -playerScreenY);
      }

      canvas.drawImageRect(characterImage!, srcRect, characterRect, Paint());

      if (shouldFlip) {
        // 恢复画布状态
        canvas.restore();
      }
    } else {
      // 回退到红色圆圈（如果没有角色图片）
      final Paint playerPaint = Paint()..color = Colors.red;
      canvas.drawCircle(
        Offset(playerScreenX, playerScreenY),
        tileSize / 3,
        playerPaint,
      );
    }
    final weaponItem = gameState.equipmentSlots['weapon'];
    if (weaponItem != null) {
      final ui.Image? weaponImage = terrainImages[weaponItem.image];
      final double baseSize = tileSize * 0.6;
      double dirX = gameState.weaponJoystickX ?? 0.0;
      double dirY = gameState.weaponJoystickY ?? 0.0;
      if (dirX == 0.0 && dirY == 0.0) {
        dirX = gameState.lastWeaponAimX;
        dirY = gameState.lastWeaponAimY;
      }
      final double angle = math.atan2(
        dirY,
        dirX == 0.0 && dirY == 0.0 ? 1e-6 : dirX,
      );
      final double offsetR = tileSize * 0.45;
      final double wx = playerScreenX + math.cos(angle) * offsetR;
      final double wy = playerScreenY + math.sin(angle) * offsetR;
      if (weaponImage != null) {
        final Rect srcRect = Rect.fromLTWH(
          0,
          0,
          weaponImage.width.toDouble(),
          weaponImage.height.toDouble(),
        );
        final Rect dstRect = Rect.fromCenter(
          center: const Offset(0, 0),
          width: baseSize,
          height: baseSize,
        );
        canvas.save();
        canvas.translate(wx, wy);
        canvas.rotate(angle);
        if (dirX < 0) {
          canvas.scale(1.0, -1.0);
        }
        canvas.drawImageRect(weaponImage, srcRect, dstRect, Paint());
        canvas.restore();
      } else {
        final Rect fallbackRect = Rect.fromCenter(
          center: Offset(wx, wy),
          width: baseSize,
          height: baseSize,
        );
        final Paint p = Paint()..color = Colors.redAccent;
        canvas.drawRect(fallbackRect, p);
      }
      // 关键区域：远程预瞄线改为虚线（仅滑动瞄准时显示）
      if (gameState.isWeaponAiming &&
          gameState.selectedAttackMode == AttackMode.ranged) {
        final double maxDist =
            gameState.rangedAttackTemplate.distance * tileSize;
        final double dx = math.cos(angle);
        final double dy = math.sin(angle);
        final Paint dashPaint =
            Paint()
              ..color = Colors.white.withValues(alpha: 0.75)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0
              ..strokeCap = StrokeCap.round;
        final double dash = math.max(6.0, tileSize * 0.12);
        final double gap = dash * 0.7;
        double t = 0.0;
        while (t < maxDist) {
          final double t2 = math.min(t + dash, maxDist);
          final Offset p1 = Offset(wx + dx * t, wy + dy * t);
          final Offset p2 = Offset(wx + dx * t2, wy + dy * t2);
          canvas.drawLine(p1, p2, dashPaint);
          t += dash + gap;
        }
      }
      // 关键区域：近战模式预瞄扇形（基于模板的距离与范围）
      if (gameState.isWeaponAiming &&
          gameState.selectedAttackMode == AttackMode.melee) {
        final double radius = gameState.meleeAttackTemplate.distance * tileSize;
        final double sweep = gameState.meleeAttackTemplate.range;
        final Rect arcRect = Rect.fromCircle(
          center: Offset(playerScreenX, playerScreenY),
          radius: radius,
        );
        final Paint arcPaint =
            Paint()
              ..color = gameState.meleeAttackTemplate.color.withValues(
                alpha: 0.5,
              )
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4.0
              ..strokeCap = StrokeCap.round;
        canvas.drawArc(arcRect, angle - sweep / 2, sweep, false, arcPaint);
      }
      if (gameState.isReloading &&
          gameState.selectedAttackMode == AttackMode.ranged) {
        final double r = tileSize * 0.55;
        final Rect ringRect = Rect.fromCircle(
          center: Offset(wx, wy),
          radius: r,
        );
        final double sweep = 2 * math.pi * gameState.reloadProgress;
        final Paint bg =
            Paint()
              ..color = Colors.white.withValues(alpha: 0.15)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6.0;
        final Paint fg =
            Paint()
              ..color = Colors.lightBlueAccent.withValues(alpha: 0.85)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6.0
              ..strokeCap = StrokeCap.round;
        canvas.drawArc(ringRect, -math.pi / 2, 2 * math.pi, false, bg);
        canvas.drawArc(ringRect, -math.pi / 2, sweep, false, fg);
      }
      // 关键区域：近战挥刀动作效果（从起始角扫到终止角，附带拖影）
      if (gameState.weaponAttackStartTime != null &&
          gameState.selectedAttackMode == AttackMode.melee) {
        final int elapsed =
            DateTime.now()
                .difference(gameState.weaponAttackStartTime!)
                .inMilliseconds;
        const int maxDuration = 420;
        if (elapsed >= 0 && elapsed <= maxDuration) {
          final double t = (elapsed / maxDuration).clamp(0.0, 1.0);
          final double radius =
              gameState.meleeAttackTemplate.distance * tileSize;
          final double totalSweep = gameState.meleeAttackTemplate.range;
          final Rect arcRect = Rect.fromCircle(
            center: Offset(playerScreenX, playerScreenY),
            radius: radius,
          );

          // 刀锋当前所在角度区段（随时间推进）
          final double segmentSweep = math.max(totalSweep * 0.2, 0.35);
          final double headPos =
              -totalSweep / 2 + t * totalSweep; // [-sweep/2, +sweep/2]
          final double segStart = angle + headPos - segmentSweep / 2;

          // 刀锋核心轨迹
          final Paint corePaint =
              Paint()
                ..color = gameState.meleeAttackTemplate.color.withValues(
                  alpha: 0.9,
                )
                ..style = PaintingStyle.stroke
                ..strokeWidth = 6.0
                ..strokeCap = StrokeCap.round
                ..blendMode = ui.BlendMode.plus;
          canvas.drawArc(arcRect, segStart, segmentSweep, false, corePaint);

          // 刀锋光晕
          final Paint glowPaint =
              Paint()
                ..color = gameState.meleeAttackTemplate.color.withValues(
                  alpha: 0.5,
                )
                ..style = PaintingStyle.stroke
                ..strokeWidth = 10.0
                ..strokeCap = StrokeCap.round
                ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
          canvas.drawArc(arcRect, segStart, segmentSweep, false, glowPaint);

          // 更强的外层光晕（提升模糊真实感）
          final Paint glowPaint2 =
              Paint()
                ..color = gameState.meleeAttackTemplate.color.withValues(
                  alpha: 0.35,
                )
                ..style = PaintingStyle.stroke
                ..strokeWidth = 14.0
                ..strokeCap = StrokeCap.round
                ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
          canvas.drawArc(arcRect, segStart, segmentSweep, false, glowPaint2);

          // 最外层柔化光晕（极低透明度，扩大模糊半径）
          final Paint glowPaint3 =
              Paint()
                ..color = gameState.meleeAttackTemplate.color.withValues(
                  alpha: 0.18,
                )
                ..style = PaintingStyle.stroke
                ..strokeWidth = 18.0
                ..strokeCap = StrokeCap.round
                ..maskFilter = const ui.MaskFilter.blur(
                  ui.BlurStyle.normal,
                  12,
                );
          canvas.drawArc(arcRect, segStart, segmentSweep, false, glowPaint3);

          // 拖影（向后若干段逐渐衰减）
          for (int i = 1; i <= 3; i++) {
            final double trailOffset = segmentSweep * 0.6 * i;
            final double trailAlpha = (0.35 * (1.0 - i / 4)).clamp(0.0, 0.35);
            final Paint trailPaint =
                Paint()
                  ..color = gameState.meleeAttackTemplate.color.withValues(
                    alpha: trailAlpha,
                  )
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 4.0
                  ..strokeCap = StrokeCap.round;
            canvas.drawArc(
              arcRect,
              segStart - trailOffset,
              segmentSweep,
              false,
              trailPaint,
            );
          }

          // 关键区域：挥刀扇形涂抹（径向渐变填充，配合轻度模糊）
          final ui.Color smearStart = gameState.meleeAttackTemplate.color
              .withValues(alpha: 0.0);
          final ui.Color smearEnd = gameState.meleeAttackTemplate.color
              .withValues(alpha: 0.22);
          final Paint smearPaint =
              Paint()
                ..style = PaintingStyle.fill
                ..blendMode = ui.BlendMode.srcOver
                ..shader = ui.Gradient.radial(
                  Offset(playerScreenX, playerScreenY),
                  radius,
                  [smearStart, smearEnd],
                  [0.6, 1.0],
                )
                ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
          canvas.drawArc(arcRect, segStart, segmentSweep, true, smearPaint);

          // 刀锋尖端高光
          final double tipAngle = angle + headPos;
          final Offset tip = Offset(
            playerScreenX + math.cos(tipAngle) * radius,
            playerScreenY + math.sin(tipAngle) * radius,
          );
          final Paint tipPaint =
              Paint()
                ..color = Colors.white.withValues(alpha: 0.9)
                ..style = PaintingStyle.fill
                ..blendMode = ui.BlendMode.plus;
          canvas.drawCircle(tip, 2.0, tipPaint);
        }
      }
      if (gameState.projectiles.isNotEmpty) {
        for (final p in gameState.projectiles) {
          final int elapsed =
              DateTime.now().difference(p.startTime).inMilliseconds;
          final double maxDistPx =
              gameState.rangedAttackTemplate.distance * tileSize;
          final double speedTilesPerSec = gameState.rangedAttackTemplate.range;
          final double speedPxPerMs = speedTilesPerSec * tileSize / 1000.0;
          final int maxDuration =
              speedPxPerMs <= 0 ? 320 : (maxDistPx / speedPxPerMs).ceil();
          if (elapsed < 0 || elapsed > maxDuration) continue;
          final double t = (elapsed / maxDuration).clamp(0.0, 1.0);
          final double alpha = (1.0 - t).clamp(0.0, 1.0);
          final double travel = math.min(maxDistPx, speedPxPerMs * elapsed);
          final Offset start = Offset(
            mapOffsetX + (p.startX * tileSize),
            mapOffsetY + (p.startY * tileSize),
          );
          final Offset end = Offset(
            start.dx + math.cos(p.angle) * travel,
            start.dy + math.sin(p.angle) * travel,
          );

          final ui.Color base = gameState.rangedAttackTemplate.color;
          final Paint gradientPaint =
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3.0
                ..strokeCap = StrokeCap.round
                ..blendMode = ui.BlendMode.plus
                ..shader = ui.Gradient.linear(
                  start,
                  end,
                  [
                    Colors.white.withValues(alpha: alpha),
                    base.withValues(alpha: alpha),
                  ],
                  const [0.0, 1.0],
                );
          canvas.drawLine(start, end, gradientPaint);

          final Paint glowPaint =
              Paint()
                ..color = Color(base.value).withOpacity(alpha * 0.6)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 6.0
                ..strokeCap = StrokeCap.round
                ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
          canvas.drawLine(start, end, glowPaint);

          final Paint tipPaint =
              Paint()
                ..color = Colors.white.withValues(alpha: alpha)
                ..style = PaintingStyle.fill
                ..blendMode = ui.BlendMode.plus;
          canvas.drawCircle(end, 2.2, tipPaint);

          final int trailDots = 4;
          for (int i = 1; i <= trailDots; i++) {
            final double back = 3.0 * i;
            final Offset pt = Offset(
              end.dx - math.cos(p.angle) * back,
              end.dy - math.sin(p.angle) * back,
            );
            final double ta = alpha * (1.0 - i / (trailDots + 1));
            final Paint dotPaint =
                Paint()
                  ..color = Color(base.value).withOpacity(ta)
                  ..style = PaintingStyle.fill
                  ..blendMode = ui.BlendMode.plus;
            canvas.drawCircle(pt, 1.6, dotPaint);
          }
        }
      }
    }

    // 绘制圆形视野边界效果
    _drawCircularVisionBoundary(
      canvas,
      size,
      playerScreenX,
      playerScreenY,
      tileSize,
    );

    // 视线遮挡系统已通过visibleTiles实现，无需额外的雾效遮罩
  }

  /// 绘制圆形视野边界效果
  void _drawCircularVisionBoundary(
    Canvas canvas,
    Size size,
    double playerX,
    double playerY,
    double tileSize,
  ) {
    // 获取当前精神值来计算动态视野半径
    final currentSanity = (gameState.characterStats['san'] ?? 100)
        .toDouble()
        .clamp(0, 250);
    final maxSanity = 250.0; // 精神值上限固定为250

    // 使用与EnhancedVisionSystem相同的绝对数值计算逻辑
    int currentViewRadius;
    if (currentSanity <= 0) {
      currentViewRadius = 1;
    } else if (currentSanity <= 25) {
      // 0-25: 线性插值从1到2
      currentViewRadius = (1 + (currentSanity / 25.0)).round();
    } else if (currentSanity <= 50) {
      // 25-50: 线性插值从2到3
      currentViewRadius = (2 + ((currentSanity - 25) / 25.0)).round();
    } else if (currentSanity <= 75) {
      // 50-75: 线性插值从3到4
      currentViewRadius = (3 + ((currentSanity - 50) / 25.0)).round();
    } else if (currentSanity <= 100) {
      // 75-100: 线性插值从4到5
      currentViewRadius = (4 + ((currentSanity - 75) / 25.0)).round();
    } else {
      // 超过100时，每25点增加1半径
      currentViewRadius = (5 + ((currentSanity - 100) / 25.0).floor()).toInt();
    }

    // 确保最小视野半径为1
    currentViewRadius = currentViewRadius.clamp(1, 999).toInt();
    final double visionRadius = currentViewRadius * tileSize;

    // 计算精神值百分比用于视觉效果，限制在0.0到1.0之间
    final sanityPercentage = (currentSanity / maxSanity).clamp(0.0, 1.0);

    // 绘制多层雾效，创建更自然的视野过渡
    _drawMultiLayerFog(
      canvas,
      size,
      playerX,
      playerY,
      visionRadius,
      sanityPercentage,
    );

    // 绘制动态边界效果
    _drawDynamicVisionBorder(
      canvas,
      playerX,
      playerY,
      visionRadius,
      sanityPercentage,
    );
  }

  /// 绘制多层雾效
  void _drawMultiLayerFog(
    Canvas canvas,
    Size size,
    double playerX,
    double playerY,
    double visionRadius,
    double sanityPercentage,
  ) {
    // 外层浓雾（视野外完全黑暗）
    final Path outerFogPath =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addOval(
            Rect.fromCircle(
              center: Offset(playerX, playerY),
              radius: visionRadius + 20, // 稍微扩大一点，避免硬边界
            ),
          );
    outerFogPath.fillType = PathFillType.evenOdd;

    final Paint outerFogPaint =
        Paint()
          ..color = Colors.black.withOpacity(
            0.95 - sanityPercentage * 0.1,
          ); // 精神值越低，雾越浓
    canvas.drawPath(outerFogPath, outerFogPaint);

    // 中层雾效（渐变过渡区域）
    final double transitionRadius = visionRadius + 15;
    final Paint middleFogPaint =
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.2 + (1.0 - sanityPercentage) * 0.3),
              Colors.black.withOpacity(0.6 + (1.0 - sanityPercentage) * 0.3),
              Colors.black.withOpacity(0.9),
            ],
            stops: const [0.0, 0.7, 0.9, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(playerX, playerY),
              radius: transitionRadius,
            ),
          );

    canvas.drawCircle(
      Offset(playerX, playerY),
      transitionRadius,
      middleFogPaint,
    );

    // 内层轻雾（视野边缘的细微雾效）
    final double innerRadius = visionRadius * 0.9;
    final Paint innerFogPaint =
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.1 + (1.0 - sanityPercentage) * 0.2),
            ],
            stops: const [0.0, 0.8, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(playerX, playerY),
              radius: visionRadius,
            ),
          );

    canvas.drawCircle(Offset(playerX, playerY), visionRadius, innerFogPaint);
  }

  /// 绘制动态视野边界
  void _drawDynamicVisionBorder(
    Canvas canvas,
    double playerX,
    double playerY,
    double visionRadius,
    double sanityPercentage,
  ) {
    // 检查是否有伤害事件（受伤状态）
    final isDamaged = damageEvent != null;

    // 主边界线颜色和样式
    Color borderColor;
    double borderOpacity;
    double strokeWidth;

    if (isDamaged) {
      // 受伤时：根据动画值在蓝色和红色之间插值
      final damageIntensity = damageEvent!.intensity / 100.0; // 标准化到0-1
      // 使用动画值进行颜色插值：0.0=蓝色，1.0=红色
      borderColor =
          Color.lerp(Colors.blue, Colors.red, visionBorderFlashValue) ??
          Colors.red;
      borderOpacity = 0.7 + damageIntensity * 0.3; // 固定透明度，不再闪烁
      strokeWidth = 3.0 + damageIntensity * 3.0; // 3.0-6.0的线宽
    } else {
      // 正常状态：始终保持蓝色边界
      borderColor = Colors.blue;
      borderOpacity = 0.4; // 固定透明度
      strokeWidth = 2.0; // 固定线宽
    }

    final Paint borderPaint =
        Paint()
          ..color = borderColor.withOpacity(borderOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    // 绘制左右两个弧形，而不是完整的圆圈
    final Rect circleRect = Rect.fromCircle(
      center: Offset(playerX, playerY),
      radius: visionRadius,
    );

    // 定义间隙角度（弧度），在顶部和底部留出间隙
    final double gapAngle = math.pi / 6; // 30度的间隙

    // 左侧弧形：从左上开始，到左下结束，留出顶部和底部的间隙
    canvas.drawArc(
      circleRect,
      -math.pi / 2 + gapAngle / 2, // 起始角度：从顶部偏移一点开始
      math.pi - gapAngle, // 扫描角度：180度减去间隙
      false, // 不连接到中心
      borderPaint,
    );

    // 右侧弧形：从右下开始，到右上结束，留出顶部和底部的间隙
    canvas.drawArc(
      circleRect,
      math.pi / 2 + gapAngle / 2, // 起始角度：从底部偏移一点开始
      math.pi - gapAngle, // 扫描角度：180度减去间隙
      false, // 不连接到中心
      borderPaint,
    );

    // 脉动效果已移除，不再与精神值相关

    // 内部光晕效果
    final Paint glowPaint =
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Colors.white.withOpacity(0.1 * sanityPercentage),
              Colors.transparent,
            ],
            stops: const [0.0, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(playerX, playerY),
              radius: visionRadius * 0.3,
            ),
          );

    canvas.drawCircle(Offset(playerX, playerY), visionRadius * 0.3, glowPaint);
  }

  /// 绘制商店
  void _drawShop(
    Canvas canvas,
    double shopX,
    double shopY,
    double tileSize,
    double opacity,
  ) {
    final Rect shopRect = Rect.fromLTWH(shopX, shopY, tileSize, tileSize);

    // 绘制商店背景（紫色）
    final Paint shopBgPaint =
        Paint()..color = Colors.purple.shade600.withOpacity(opacity);
    canvas.drawRect(shopRect, shopBgPaint);

    // 绘制商店图标（简单的房子形状）
    final Paint shopIconPaint =
        Paint()
          ..color = Colors.yellow.withOpacity(opacity)
          ..style = PaintingStyle.fill;

    // 绘制房子主体
    final double houseWidth = tileSize * 0.6;
    final double houseHeight = tileSize * 0.4;
    final double houseX = shopX + (tileSize - houseWidth) / 2;
    final double houseY = shopY + tileSize * 0.4;

    canvas.drawRect(
      Rect.fromLTWH(houseX, houseY, houseWidth, houseHeight),
      shopIconPaint,
    );

    // 绘制房顶（三角形）
    final Paint roofPaint =
        Paint()
          ..color = Colors.red.withOpacity(opacity)
          ..style = PaintingStyle.fill;

    final Path roofPath = Path();
    roofPath.moveTo(shopX + tileSize * 0.5, shopY + tileSize * 0.2); // 顶点
    roofPath.lineTo(houseX - tileSize * 0.1, houseY); // 左下
    roofPath.lineTo(houseX + houseWidth + tileSize * 0.1, houseY); // 右下
    roofPath.close();

    canvas.drawPath(roofPath, roofPaint);

    // 绘制门
    final Paint doorPaint =
        Paint()
          ..color = Colors.brown.withOpacity(opacity)
          ..style = PaintingStyle.fill;

    final double doorWidth = tileSize * 0.15;
    final double doorHeight = tileSize * 0.25;
    final double doorX = shopX + (tileSize - doorWidth) / 2;
    final double doorY = shopY + tileSize * 0.55;

    canvas.drawRect(
      Rect.fromLTWH(doorX, doorY, doorWidth, doorHeight),
      doorPaint,
    );

    // 绘制边框
    final Paint borderPaint =
        Paint()
          ..color = Colors.white.withOpacity(opacity * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRect(shopRect, borderPaint);
  }

  /// 绘制炼金机
  void _drawAlchemy(
    Canvas canvas,
    double x,
    double y,
    double tileSize,
    double opacity,
  ) {
    final Rect rect = Rect.fromLTWH(x, y, tileSize, tileSize);

    // 背景（青色，与商店区分）
    final Paint bgPaint =
        Paint()..color = Colors.teal.shade600.withOpacity(opacity);
    canvas.drawRect(rect, bgPaint);

    // 关键区域：简化的炼金坩埚图标（避免引入多余资源）
    final double cauldronWidth = tileSize * 0.65;
    final double cauldronHeight = tileSize * 0.45;
    final double cx = x + (tileSize - cauldronWidth) / 2;
    final double cy = y + tileSize * 0.50;

    // 坩埚主体
    final Paint bodyPaint =
        Paint()
          ..color = Colors.black.withOpacity(opacity)
          ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx, cy, cauldronWidth, cauldronHeight),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // 坩埚边口
    final Paint rimPaint =
        Paint()
          ..color = Colors.grey.shade400.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final Rect rimRect = Rect.fromLTWH(
      cx,
      cy - tileSize * 0.06,
      cauldronWidth,
      tileSize * 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rimRect, const Radius.circular(6)),
      rimPaint,
    );

    // 冒泡效果
    final Paint bubblePaint =
        Paint()..color = Colors.greenAccent.withOpacity(opacity);
    canvas.drawCircle(
      Offset(x + tileSize * 0.45, y + tileSize * 0.35),
      tileSize * 0.05,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(x + tileSize * 0.55, y + tileSize * 0.25),
      tileSize * 0.04,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(x + tileSize * 0.40, y + tileSize * 0.22),
      tileSize * 0.03,
      bubblePaint,
    );

    // 边框
    final Paint borderPaint =
        Paint()
          ..color = Colors.white.withOpacity(opacity * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);
  }

  /// 绘制宝箱
  void _drawChest(
    Canvas canvas,
    double chestX,
    double chestY,
    double tileSize,
    double opacity,
  ) {
    final Rect chestRect = Rect.fromLTWH(chestX, chestY, tileSize, tileSize);

    // 尝试使用宝箱贴图
    final ui.Image? chestImage = terrainImages['chest'];

    if (chestImage != null) {
      // 使用贴图渲染宝箱
      final Rect srcRect = Rect.fromLTWH(
        0,
        0,
        chestImage.width.toDouble(),
        chestImage.height.toDouble(),
      );
      final Paint imagePaint =
          Paint()..color = Colors.white.withOpacity(opacity);
      canvas.drawImageRect(chestImage, srcRect, chestRect, imagePaint);
    } else {
      // 回退到手绘宝箱
      // 绘制宝箱主体（棕色）
      final Paint chestBodyPaint =
          Paint()..color = Colors.brown.shade700.withOpacity(opacity);

      final double chestWidth = tileSize * 0.8;
      final double chestHeight = tileSize * 0.6;
      final double chestBodyX = chestX + (tileSize - chestWidth) / 2;
      final double chestBodyY = chestY + tileSize * 0.3;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chestBodyX, chestBodyY, chestWidth, chestHeight),
          const Radius.circular(4),
        ),
        chestBodyPaint,
      );

      // 绘制宝箱盖子（稍浅的棕色）
      final Paint chestLidPaint =
          Paint()..color = Colors.brown.shade600.withOpacity(opacity);

      final double lidHeight = chestHeight * 0.4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chestBodyX, chestBodyY, chestWidth, lidHeight),
          const Radius.circular(4),
        ),
        chestLidPaint,
      );

      // 绘制锁扣（金色）
      final Paint lockPaint =
          Paint()..color = Colors.amber.shade600.withOpacity(opacity);

      final double lockSize = tileSize * 0.15;
      final double lockX = chestX + (tileSize - lockSize) / 2;
      final double lockY = chestBodyY + lidHeight * 0.6;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(lockX, lockY, lockSize, lockSize * 0.8),
          const Radius.circular(2),
        ),
        lockPaint,
      );

      // 绘制金属边框
      final Paint metalPaint =
          Paint()
            ..color = Colors.grey.shade400.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1;

      // 宝箱边框
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chestBodyX, chestBodyY, chestWidth, chestHeight),
          const Radius.circular(4),
        ),
        metalPaint,
      );

      // 盖子边框
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chestBodyX, chestBodyY, chestWidth, lidHeight),
          const Radius.circular(4),
        ),
        metalPaint,
      );
    }

    // 绘制发光效果（表示可交互）
    final Paint glowPaint =
        Paint()
          ..color = Colors.yellow.withOpacity(0.3 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    canvas.drawRect(chestRect, glowPaint);
  }

  void _drawSafe(
    Canvas canvas,
    double safeX,
    double safeY,
    double tileSize,
    double opacity,
  ) {
    final ui.Image? safeImage = terrainImages['safe'];
    final Rect safeRect = Rect.fromLTWH(safeX, safeY, tileSize, tileSize);
    if (safeImage != null) {
      final Rect srcRect = Rect.fromLTWH(
        0,
        0,
        safeImage.width.toDouble(),
        safeImage.height.toDouble(),
      );
      final Paint imagePaint =
          Paint()..color = Colors.white.withValues(alpha: opacity);
      canvas.drawImageRect(safeImage, srcRect, safeRect, imagePaint);
    } else {
      final Paint paint =
          Paint()..color = Colors.lightBlueAccent.withValues(alpha: opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(safeRect, const Radius.circular(6)),
        paint,
      );
      final Paint border =
          Paint()
            ..color = Colors.blueAccent.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(safeRect, const Radius.circular(6)),
        border,
      );
      final double lockSize = tileSize * 0.28;
      final Rect lockRect = Rect.fromCenter(
        center: Offset(safeX + tileSize / 2, safeY + tileSize / 2),
        width: lockSize,
        height: lockSize,
      );
      final Paint lockPaint =
          Paint()..color = Colors.blueGrey.withValues(alpha: opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(lockRect, const Radius.circular(4)),
        lockPaint,
      );
    }
  }

  /// 绘制地面物品
  void _drawGroundItems(
    Canvas canvas,
    double itemX,
    double itemY,
    double tileSize,
    List<dynamic> items,
    double opacity,
  ) {
    if (items.isEmpty) return;

    // 绘制第一个物品（如果有多个物品，只显示第一个）
    final item = items.first;

    // 地面物品比正常尺寸小一些
    final double itemSize = tileSize * 0.6;
    final double centerX = itemX + tileSize / 2;
    final double centerY = itemY + tileSize / 2;
    final double drawX = centerX - itemSize / 2;
    final double drawY = centerY - itemSize / 2;

    final Rect itemRect = Rect.fromLTWH(drawX, drawY, itemSize, itemSize);

    // 尝试使用物品图片
    if (item.image != null &&
        item.image.isNotEmpty &&
        terrainImages.containsKey(item.image)) {
      final ui.Image? itemImage = terrainImages[item.image];
      if (itemImage != null) {
        final Rect srcRect = Rect.fromLTWH(
          0,
          0,
          itemImage.width.toDouble(),
          itemImage.height.toDouble(),
        );
        final Paint imagePaint = Paint()..filterQuality = FilterQuality.medium;
        canvas.drawImageRect(itemImage, srcRect, itemRect, imagePaint);

        // 关键区域：为地面物品添加按等级的边框颜色（最小改动，不引入额外特效）
        final Paint levelBorderPaint =
            Paint()
              ..color = _getItemLevelColor(
                item.level,
              ).withValues(alpha: opacity * 0.85)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(itemRect, const Radius.circular(3)),
          levelBorderPaint,
        );
      } else {
        _drawItemFallback(canvas, itemRect, item, opacity);
      }
    } else {
      _drawItemFallback(canvas, itemRect, item, opacity);
    }

    // 如果有多个物品，显示数量
    if (items.length > 1) {
      final Paint textBackgroundPaint =
          Paint()..color = Colors.black.withValues(alpha: 0.7 * opacity);

      // 绘制数量背景圆圈
      final double badgeRadius = tileSize * 0.12;
      final Offset badgeCenter = Offset(
        itemX + tileSize * 0.8,
        itemY + tileSize * 0.2,
      );
      canvas.drawCircle(badgeCenter, badgeRadius, textBackgroundPaint);

      // 绘制数量文字
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${items.length}',
          style: TextStyle(
            color: Colors.white.withOpacity(opacity),
            fontSize: tileSize * 0.15,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // 居中绘制文字
      textPainter.paint(
        canvas,
        Offset(
          badgeCenter.dx - textPainter.width / 2,
          badgeCenter.dy - textPainter.height / 2,
        ),
      );
    }

    // 关键区域：微弱描边使用物品等级颜色，替换类型色为等级色
    final Paint glowPaint =
        Paint()
          ..color = _getItemLevelColor(item.level).withOpacity(0.25 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(itemRect, const Radius.circular(3)),
      glowPaint,
    );
  }

  /// 绘制物品后备方案（当没有图片时）
  void _drawItemFallback(
    Canvas canvas,
    Rect itemRect,
    dynamic item,
    double opacity,
  ) {
    // 关键区域：后备绘制按物品等级着色（不再使用类型色）
    final Paint itemPaint =
        Paint()
          ..color = _getItemLevelColor(item.level).withOpacity(opacity * 0.85)
          ..style = PaintingStyle.fill;

    // 根据物品类型绘制不同形状
    switch (item.type) {
      case 'food':
        // 绘制圆形（食物）
        canvas.drawCircle(itemRect.center, itemRect.width * 0.3, itemPaint);
        break;
      case 'tool':
        // 绘制矩形（工具）
        canvas.drawRect(
          Rect.fromCenter(
            center: itemRect.center,
            width: itemRect.width * 0.6,
            height: itemRect.height * 0.4,
          ),
          itemPaint,
        );
        break;
      case 'weapon':
        // 绘制菱形（武器）
        final Path weaponPath = Path();
        weaponPath.moveTo(
          itemRect.center.dx,
          itemRect.top + itemRect.height * 0.1,
        );
        weaponPath.lineTo(
          itemRect.right - itemRect.width * 0.1,
          itemRect.center.dy,
        );
        weaponPath.lineTo(
          itemRect.center.dx,
          itemRect.bottom - itemRect.height * 0.1,
        );
        weaponPath.lineTo(
          itemRect.left + itemRect.width * 0.1,
          itemRect.center.dy,
        );
        weaponPath.close();
        canvas.drawPath(weaponPath, itemPaint);
        break;
      case 'book':
        // 绘制矩形（书籍）
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: itemRect.center,
              width: itemRect.width * 0.5,
              height: itemRect.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          itemPaint,
        );
        break;
      default:
        // 默认绘制小圆点
        canvas.drawCircle(itemRect.center, itemRect.width * 0.2, itemPaint);
    }
  }

  /// 根据物品类型获取颜色
  Color _getItemTypeColor(String itemType) {
    switch (itemType) {
      case 'equipment':
        return Colors.indigo;
      case 'item':
        return Colors.amber;
      case 'food':
        return Colors.green;
      case 'tool':
        return Colors.blue;
      case 'weapon':
        return Colors.red;
      case 'book':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // 关键区域：按物品等级返回颜色（用于地面物品着色，与背包/宝箱一致）
  Color _getItemLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.grey.shade600; // 无色
      case 2:
        return Colors.green.shade400; // 绿色
      case 3:
        return Colors.blue.shade400; // 蓝色
      case 4:
        return Colors.purple.shade400; // 紫色
      case 5:
        return Colors.amber.shade400; // 金色
      case 6:
        return Colors.red.shade400; // 红色
      default:
        return Colors.grey.shade600; // 默认无色
    }
  }

  /// 绘制雾霾装饰效果（如果该瓦片需要雾霾装饰）
  void _drawFogDecorationIfNeeded(
    Canvas canvas,
    math.Point<int> tilePoint,
    Rect tileRect,
    double tileOpacity,
  ) {
    // 获取瓦片的可见性状态
    final tileVisibility = smoothVisionManager!.getTileVisibility(tilePoint);
    if (tileVisibility == null) return;

    // 只有带雾霾装饰的瓦片才需要绘制雾霾效果
    if (tileVisibility == TileVisibility.visibleWithFogDecoration ||
        tileVisibility == TileVisibility.partiallyVisibleWithFogDecoration) {
      // 创建雾霾装饰效果
      final Paint fogPaint =
          Paint()
            ..color = Colors.grey.withOpacity(0.3 * tileOpacity)
            ..style = PaintingStyle.fill;

      // 绘制半透明的雾霾覆盖层
      canvas.drawRect(tileRect, fogPaint);

      // 添加一些噪声纹理效果
      final Paint noisePaint =
          Paint()
            ..color = Colors.white.withOpacity(0.1 * tileOpacity)
            ..style = PaintingStyle.fill;

      // 使用简单的点状纹理模拟雾霾颗粒
      final double dotSize = tileRect.width * 0.05;
      for (int i = 0; i < 8; i++) {
        final double x =
            tileRect.left +
            (tileRect.width * (i % 3) / 3) +
            (dotSize * (i % 2));
        final double y =
            tileRect.top +
            (tileRect.height * (i ~/ 3) / 3) +
            (dotSize * ((i + 1) % 2));
        canvas.drawCircle(Offset(x, y), dotSize, noisePaint);
      }
    }
  }

  /// 绘制鬼
  void _drawGhosts(
    Canvas canvas,
    double mapOffsetX,
    double mapOffsetY,
    double tileSize,
    Size size,
  ) {
    for (final ghost in gameState.ghostManager.ghosts) {
      // 隐形状态下不绘制
      if (ghost.isInvisible) continue;
      if (ghost.position == null) continue;

      final double ghostX = mapOffsetX + (ghost.position!.x * tileSize);
      final double ghostY = mapOffsetY + (ghost.position!.y * tileSize);

      // 只在屏幕范围内绘制鬼
      if (ghostX > -tileSize &&
          ghostX < size.width &&
          ghostY > -tileSize &&
          ghostY < size.height) {
        final math.Point<int> ghostPoint = ghost.position!.toPoint();
        double ghostOpacity = 1.0;

        // 检查鬼是否在可见范围内
        if (smoothVisionManager != null) {
          ghostOpacity = smoothVisionManager!.getTileOpacity(ghostPoint);
          if (ghostOpacity <= 0.0) {
            // 鬼不可见，跳过绘制
            continue;
          }
        } else {
          // 回退到原始的可见性检查
          final bool isVisible = gameState.visibleTiles.contains(ghostPoint);
          if (!isVisible) {
            continue;
          }
        }

        _drawGhost(canvas, ghost, ghostX, ghostY, tileSize, ghostOpacity);
      }
    }
  }

  /// 绘制单个鬼
  void _drawGhost(
    Canvas canvas,
    dynamic ghost,
    double ghostX,
    double ghostY,
    double tileSize,
    double opacity,
  ) {
    final double ghostSize = tileSize * 0.9; // 鬼的大小为瓦片大小的90%
    final Rect ghostRect = Rect.fromCenter(
      center: Offset(ghostX + tileSize / 2, ghostY + tileSize / 2),
      width: ghostSize,
      height: ghostSize,
    );

    // 根据鬼的状态设置颜色和透明度
    Color ghostColor = ghost.color;
    double finalOpacity = opacity;

    if (ghost.isInCooldown) {
      // 冷却状态下变暗
      ghostColor = ghostColor.withOpacity(0.5);
      finalOpacity *= 0.5;
    } else if (ghost.isChasing) {
      // 追逐状态下发红光
      ghostColor = Colors.red;
    } else if (ghost.isFleeing) {
      // 逃跑状态下变蓝
      ghostColor = Colors.blue;
    }

    // 绘制鬼的主体（圆形）
    final Paint ghostPaint =
        Paint()
          ..color = ghostColor.withOpacity(finalOpacity)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(ghostRect.center, ghostSize / 2, ghostPaint);

    // 绘制鬼的边框
    final Paint borderPaint =
        Paint()
          ..color = Colors.black.withOpacity(finalOpacity * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    canvas.drawCircle(ghostRect.center, ghostSize / 2, borderPaint);

    // 绘制鬼的眼睛
    final double eyeSize = ghostSize * 0.15;
    final Paint eyePaint =
        Paint()
          ..color = Colors.white.withOpacity(finalOpacity)
          ..style = PaintingStyle.fill;

    // 左眼
    canvas.drawCircle(
      Offset(
        ghostRect.center.dx - ghostSize * 0.2,
        ghostRect.center.dy - ghostSize * 0.1,
      ),
      eyeSize,
      eyePaint,
    );

    // 右眼
    canvas.drawCircle(
      Offset(
        ghostRect.center.dx + ghostSize * 0.2,
        ghostRect.center.dy - ghostSize * 0.1,
      ),
      eyeSize,
      eyePaint,
    );

    // 绘制眼珠
    final Paint pupilPaint =
        Paint()
          ..color = Colors.black.withOpacity(finalOpacity)
          ..style = PaintingStyle.fill;

    final double pupilSize = eyeSize * 0.6;

    // 左眼珠
    canvas.drawCircle(
      Offset(
        ghostRect.center.dx - ghostSize * 0.2,
        ghostRect.center.dy - ghostSize * 0.1,
      ),
      pupilSize,
      pupilPaint,
    );

    // 右眼珠
    canvas.drawCircle(
      Offset(
        ghostRect.center.dx + ghostSize * 0.2,
        ghostRect.center.dy - ghostSize * 0.1,
      ),
      pupilSize,
      pupilPaint,
    );

    // 如果鬼在追逐状态，绘制警告效果
    if (ghost.isChasing) {
      final Paint warningPaint =
          Paint()
            ..color = Colors.red.withOpacity(finalOpacity * 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0;

      canvas.drawCircle(ghostRect.center, ghostSize / 2 + 5, warningPaint);
    }

    // 伤害数字（显示1秒）
    final DateTime now = DateTime.now();
    if (ghost.lastDamageShownAt != null &&
        now.difference(ghost.lastDamageShownAt!).inMilliseconds <= 1000) {
      final String dmgText = '-${ghost.lastDamageShownValue}';
      final Color dmgColor =
          ghost.lastDamageShownIsCrit
              ? Colors.redAccent.withOpacity(finalOpacity)
              : Colors.white.withOpacity(finalOpacity);
      final textPainter = TextPainter(
        text: TextSpan(
          text: dmgText,
          style: TextStyle(
            color: dmgColor,
            fontSize: tileSize * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final Offset textPos = Offset(
        ghostRect.center.dx - textPainter.width / 2,
        ghostRect.center.dy - ghostSize / 2 - textPainter.height,
      );
      textPainter.paint(canvas, textPos);
    }
  }

  @override
  bool shouldRepaint(covariant _GameAreaPainter oldDelegate) {
    return gameState != oldDelegate.gameState ||
        terrainImages != oldDelegate.terrainImages ||
        characterImage != oldDelegate.characterImage ||
        smoothVisionManager != oldDelegate.smoothVisionManager ||
        damageEvent != oldDelegate.damageEvent ||
        visionBorderFlashValue != oldDelegate.visionBorderFlashValue;
  }
}

// 脱离卡死按钮 - 带实时更新的StatefulWidget
class _UnstuckButton extends ConsumerStatefulWidget {
  final VoidCallback onPressed;

  const _UnstuckButton({required this.onPressed});

  @override
  ConsumerState<_UnstuckButton> createState() => _UnstuckButtonState();
}

class _UnstuckButtonState extends ConsumerState<_UnstuckButton> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // 启动定时器，每秒更新一次UI
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // 强制重建UI以更新冷却状态
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(optimizedGameStateProvider);
    final now = DateTime.now();

    // 检查是否在冷却期间
    bool isOnCooldown =
        gameState.unstuckCooldownEnd != null &&
        now.isBefore(gameState.unstuckCooldownEnd!);

    // 检查是否等待移动开始冷却
    bool isWaitingForMovement = gameState.isWaitingForMovement;

    int remainingSeconds = 0;
    double cooldownProgress = 0.0;
    if (isOnCooldown) {
      final totalCooldown = const Duration(seconds: 60);
      final elapsed = now.difference(
        gameState.unstuckCooldownEnd!.subtract(totalCooldown),
      );
      cooldownProgress = elapsed.inMilliseconds / totalCooldown.inMilliseconds;
      cooldownProgress = cooldownProgress.clamp(0.0, 1.0);
      remainingSeconds =
          gameState.unstuckCooldownEnd!.difference(now).inSeconds;
    }

    // 检查是否处于无视地形模式
    bool isNoClipActive =
        gameState.isNoClipMode &&
        gameState.noClipEndTime != null &&
        now.isBefore(gameState.noClipEndTime!);

    String buttonText = '脱离卡死';
    Color iconColor = Colors.orange;

    if (isNoClipActive) {
      if (isWaitingForMovement) {
        buttonText = '等待移动';
        iconColor = Colors.blue;
      } else {
        buttonText = '激活中';
        iconColor = Colors.green;
      }
    } else if (isOnCooldown) {
      buttonText = '冷却中';
      iconColor = Colors.grey.shade400;
    }

    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isNoClipActive
                  ? isWaitingForMovement
                      ? [
                        Colors.blue.shade800.withOpacity(0.3),
                        Colors.blue.shade600.withOpacity(0.2),
                      ]
                      : [
                        Colors.green.shade800.withOpacity(0.3),
                        Colors.green.shade600.withOpacity(0.2),
                      ]
                  : isOnCooldown
                  ? [
                    Colors.grey.shade800.withOpacity(0.2),
                    Colors.grey.shade700.withOpacity(0.15),
                  ]
                  : [
                    Colors.orange.shade800.withOpacity(0.3),
                    Colors.orange.shade600.withOpacity(0.2),
                  ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isNoClipActive
                  ? isWaitingForMovement
                      ? Colors.blue.withOpacity(0.4)
                      : Colors.green.withOpacity(0.4)
                  : isOnCooldown
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // 冷却进度条背景（覆盖整个按钮）
          if (isOnCooldown)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: cooldownProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange.withOpacity(0.3),
                  ),
                  minHeight: 80,
                ),
              ),
            ),

          // 冷却时的暗化遮罩
          if (isOnCooldown)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),

          // 基础按钮内容
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isOnCooldown ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 图标和倒计时数字
                    if (isOnCooldown) ...[
                      // 圆形进度指示器和倒计时数字
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // 圆形进度指示器
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: 1.0 - cooldownProgress, // 倒计时进度
                              strokeWidth: 3,
                              backgroundColor: Colors.grey.shade600.withOpacity(
                                0.3,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange.shade300,
                              ),
                            ),
                          ),
                          // 倒计时数字
                          Text(
                            '$remainingSeconds',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // 正常状态的图标和文字
                      Icon(
                        isNoClipActive
                            ? (isWaitingForMovement
                                ? Icons.directions_walk
                                : Icons.flash_on)
                            : Icons.refresh,
                        color: iconColor,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        buttonText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // 提示文字
                      Text(
                        isNoClipActive
                            ? (isWaitingForMovement ? '移动后开始冷却' : '无视地形模式')
                            : '点击自行移动脱离卡死（60s冷却）',
                        style: TextStyle(
                          color:
                              isNoClipActive
                                  ? (isWaitingForMovement
                                      ? Colors.blue.shade300
                                      : Colors.green.shade300)
                                  : Colors.grey.shade400,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
