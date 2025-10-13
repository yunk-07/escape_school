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
import 'package:escape_from_school/game/gameOver.dart';
import 'package:escape_from_school/game/inventory_page.dart';
import 'package:escape_from_school/game/joystick.dart';
import 'package:escape_from_school/game/damage_effect.dart';
import 'package:escape_from_school/game/hp_listener.dart';
import 'package:escape_from_school/game/smooth_vision.dart';
import 'package:escape_from_school/game/enhanced_vision.dart';

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

class _OptimizedBoardPageState extends State<OptimizedBoardPage> {
  late OptimizedGameStateNotifier gameStateNotifier;
  final Map<String, ui.Image> terrainImages = {};

  @override
  void initState() {
    super.initState();
    
    // 初始化游戏状态管理器 - 使用完整的角色数据
    gameStateNotifier = OptimizedGameStateNotifier(widget.characterStats);

    // 预加载地形图片
    _preloadTerrainImages();
  }

  Future<void> _preloadTerrainImages() async {
    final terrainTypes = ['grass', 'wall', 'water', 'path', 'building', 'woods', 'shop', 'chest'];
    
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
              print('Focus收到键盘事件: ${event.runtimeType} - ${event.logicalKey}');
              return _handleKeyEvent(event);
            },
            child: Consumer(
              builder: (context, ref, child) {
              final gameState = ref.watch(optimizedGameStateProvider);
            
              // 检查游戏结束状态
              if (gameState.isGameOver) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameOverPage(
                        deathReason: gameState.deathReason,
                        characterImage: gameState.characterStats['image'] ?? 'images/man/cook.png',
                      ),
                    ),
                  );
                });
              }
              
              // 根据当前页面状态显示不同内容
              if (gameState.currentPage == GamePage.inventory) {
                return const InventoryPage();
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
      final notifier = ProviderScope.containerOf(context).read(optimizedGameStateProvider.notifier);
      
      // 检查按键并模拟摇杆输入
      double x = 0.0;
      double y = 0.0;
      bool hasInput = false;
      
      if (event.logicalKey == LogicalKeyboardKey.keyW || event.logicalKey == LogicalKeyboardKey.arrowUp) {
        y = -1.0;
        hasInput = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyS || event.logicalKey == LogicalKeyboardKey.arrowDown) {
        y = 1.0;
        hasInput = true;
      }
      
      if (event.logicalKey == LogicalKeyboardKey.keyA || event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        x = -1.0;
        hasInput = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyD || event.logicalKey == LogicalKeyboardKey.arrowRight) {
        x = 1.0;
        hasInput = true;
      }
      
      if (hasInput) {
        print('键盘输入: x=$x, y=$y');
        notifier.onJoystickMove(x, y, 1.0);
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      // 键盘释放时停止移动
      final notifier = ProviderScope.containerOf(context).read(optimizedGameStateProvider.notifier);
      
      if (event.logicalKey == LogicalKeyboardKey.keyW || 
          event.logicalKey == LogicalKeyboardKey.keyS ||
          event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        print('键盘释放，停止移动');
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
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            '退出游戏',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '确定要退出游戏吗？',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '取消',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
                _exitToMainMenu(context);
              },
              child: const Text(
                '退出',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
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
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.settings,
            color: Colors.white,
            size: 24,
          ),
        ),
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
              borderRadius: BorderRadius.circular(20),
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade800.withOpacity(0.3),
                        Colors.purple.shade800.withOpacity(0.3),
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
                            borderRadius: BorderRadius.circular(8),
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
                                  borderRadius: BorderRadius.circular(12),
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
                                    borderRadius: BorderRadius.circular(12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
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
                              child: _UnstuckButton(onPressed: () {
                                Navigator.of(context).pop();
                                _unstuckPlayer();
                              }),
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
      
      print('脱离卡死功能已执行');
    } catch (e) {
      print('脱离卡死功能执行失败: $e');
      
      // 错误信息已移除，仅在控制台输出
    }
  }

  // 退出到主菜单
  void _exitToMainMenu(BuildContext context) {
    // 直接导航到主页面，清除所有之前的页面
    // 不需要手动重置游戏状态，因为新的游戏实例会自动创建
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (Route<dynamic> route) => false,
    );
  }

  // 显示详细状态面板


  @override
  void dispose() {
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
        child: CustomPaint(
          painter: _GameAreaPainter(
            gameState: gameState,
            terrainImages: terrainImages,
            smoothVisionManager: gameStateNotifier.smoothVisionManager,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  // 构建精神值环形图（左上角）- 立体效果
  Widget _buildSanityCircle(OptimizedGameState gameState) {
    final double currentSan = (gameState.characterStats['san'] ?? 0).toDouble();
    final double maxSan = (gameState.characterStats['maxSan'] ?? 100).toDouble();
    final double percentage = (currentSan / maxSan).clamp(0.0, 1.0);
    
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
                  colors: [
                    Colors.grey.shade800,
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.7, 1.0],
                ),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.4), 
                  width: 2,
                ),
              ),
            ),
            // 内层进度圆环容器
            Container(
              width: 76,
              height: 76,
              child: CustomPaint(
                painter: _3DCircularProgressPainter(
                  percentage: percentage,
                  strokeWidth: 14,
                ),
              ),
            ),
            // 内层光泽效果
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
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

  // 构建底部状态条（生命值和饱食度）
  Widget _buildBottomStatusBars(OptimizedGameState gameState) {
    final double currentHp = (gameState.characterStats['hp'] ?? 0).toDouble();
    final double maxHp = (gameState.characterStats['maxHp'] ?? 100).toDouble();
    final double currentFood = (gameState.characterStats['food'] ?? 0).toDouble();
    final double maxFood = 100.0;
    
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 生命值条（红色）- 移到左边
          _buildStatusBar(
            Icons.favorite,
            currentHp,
            maxHp,
            Colors.red,
            '生命值',
          ),
          
          const SizedBox(width: 40),
          
          // 饱食度条（橘色）- 移到右边
          _buildStatusBar(
            Icons.restaurant,
            currentFood,
            maxFood,
            Colors.orange,
            '饱食度',
          ),
        ],
      ),
    );
  }

  // 构建单个状态条（更细更长的设计）
  Widget _buildStatusBar(IconData icon, double current, double max, Color color, String label) {
    final double percentage = (current / max).clamp(0.0, 1.0);
    
    return Container(
      width: 180,  // 进一步增加宽度从160到180
      height: 16,  // 进一步减少高度从20到16
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),  // 调整圆角
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
            width: 176,  // 调整内部宽度
            height: 12,  // 调整内部高度
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          // 进度条
          Positioned(
            left: 2,
            child: Container(
              width: (176 * percentage).clamp(0.0, 176.0),  // 调整进度条宽度
              height: 12,  // 调整进度条高度
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          // 数值文本
          Text(
            '${current.round()}/${max.round()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,  // 进一步减小字体
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



  // 构建探索结果显示
  Widget _buildExplorationResult(OptimizedGameState gameState) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.3,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '探索结果:',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              gameState.explorationResult,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // 清除探索结果的方法需要在游戏状态中实现
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建移动控制
  Widget _buildMovementControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Consumer(
        builder: (context, ref, child) {
          return Container(
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



  // 构建功能按钮
  Widget _buildActionButtons(OptimizedGameState gameState) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 背包按钮
          GestureDetector(
            onTap: () {
              final ref = ProviderScope.containerOf(context).read(optimizedGameStateProvider.notifier);
              ref.toggleInventory();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'images/bag.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.brown.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.backpack, color: Colors.white, size: 24),
                    );
                  },
                ),
              ),
            ),
          ),
          // 探索按钮
          GestureDetector(
            onTap: () {
              // 探索功能暂未实现，静默处理
              print('探索功能开发中...');
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'images/get.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.search, color: Colors.white, size: 24),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建角色信息面板（左侧）
  Widget _buildCharacterInfoView(OptimizedGameState gameState) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: gameState.showCharacterInfo ? 0 : -MediaQuery.of(context).size.width * 0.35,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade800,
                      Colors.blue.shade700,
                    ],
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
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        onPressed: () {
                          final ref = ProviderScope.containerOf(context).read(optimizedGameStateProvider.notifier);
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
                    child: const Icon(Icons.person, color: Colors.white, size: 40),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // 角色描述
          Text(
            gameState.characterStats['description'] ?? '无描述',
            style: TextStyle(
              color: Colors.blue.shade200,
              fontSize: 14,
            ),
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
          _buildStatRow('生命值', '${stats['hp']}/${stats['maxHp']}', 
                       Icons.favorite, Colors.red, stats['hp'] / stats['maxHp']),
          
          // 理智值
          _buildStatRow('理智值', '${stats['san']}/${stats['maxSan']}', 
                       Icons.psychology, Colors.blue, stats['san'] / stats['maxSan']),
          
          // 移动速度
          _buildStatRow('移动速度', '${stats['moveSpeed']?.toInt() ?? 100}', 
                       Icons.directions_run, Colors.orange, 1.0),
          
          // 饱食度
          _buildStatRow('饱食度', '${stats['food']}', 
                       Icons.restaurant, Colors.green, stats['food'] / 100.0),
          
          // 金币
          _buildStatRow('金币', '${stats['gold']}', 
                       Icons.monetization_on, Colors.yellow, 1.0),
          
          // 移动速度
          _buildStatRow('移动速度', '${(gameState.characterStats['moveSpeed'] ?? 5.0).toInt()}', 
                       Icons.directions_run, Colors.cyan, 1.0),
          
          // 调试信息：饥饿扣血监控
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '饥饿扣血监控',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'HP: ${stats['hp']?.toStringAsFixed(1)} / ${stats['maxHp']?.toStringAsFixed(1)}',
                  style: TextStyle(color: Colors.red, fontSize: 10),
                ),
                Text(
                  '食物: ${stats['food']?.toStringAsFixed(1)}',
                  style: TextStyle(color: Colors.red, fontSize: 10),
                ),
                Text(
                  '时间: ${DateTime.now().second}秒',
                  style: TextStyle(color: Colors.red, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建单个属性行
  Widget _buildStatRow(String label, String value, IconData icon, Color color, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (progress < 1.0) ...[
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
    final abilities = gameState.characterStats['specialAbilities'] as List<String>? ?? [];
    
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
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          ...abilities.map((ability) => Padding(
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
          )).toList(),
        ],
      ),
    );
  }

  // 构建游戏页面
  Widget _buildGamePage(OptimizedGameState gameState) {
    return HPListener(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 主游戏内容区域（包含伤害效果）
          DamageEffectWrapper(
            child: SizedBox.expand(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 主游戏区域
                  _buildGameArea(gameState),
                
                  // 精神值环形图（左上角）
                  _buildSanityCircle(gameState),
                  
                  // 生命值和饱食度条（下方居中）
                  _buildBottomStatusBars(gameState),
                  
                  // 设置按钮（右上角）
                  _buildSettingsButton(),
                  
                  // 探索结果显示
                  if (gameState.explorationResult.isNotEmpty)
                    _buildExplorationResult(gameState),
                  
                  // 角色信息面板（左侧）
                  _buildCharacterInfoView(gameState),
                  
                  // 商店界面
                  if (gameState.showShop && gameState.schoolShop != null)
                    _buildShopView(gameState),
                ],
              ),
            ),
          ),
          
          // 交互控制组件（最高优先级，不受伤害效果影响）
          // 移动控制（摇杆）
          _buildMovementControls(),
          
          // 功能按钮
          _buildActionButtons(gameState),
        ],
      ),
    );
  }

  // 构建商店界面
  Widget _buildShopView(OptimizedGameState gameState) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                // 商店标题栏
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '商店',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          final ref = ProviderScope.containerOf(context).read(optimizedGameStateProvider.notifier);
                          ref.toggleShop();
                        },
                      ),
                    ],
                  ),
                ),
                // 商店内容
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView.builder(
                      itemCount: gameState.schoolShop?.items.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = gameState.schoolShop!.items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                item.item.image,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.item.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      item.item.description,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${item.currentPrice} 金币',
                                    style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  ElevatedButton(
                                    onPressed: (gameState.characterStats['gold'] >= item.currentPrice) ? () {
                                      final ref = ProviderScope.containerOf(context).read(optimizedGameStateProvider.notifier);
                                      ref.buyItem(item);
                                    } : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(60, 30),
                                    ),
                                    child: const Text('购买', style: TextStyle(fontSize: 10)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}

// 自定义3D环形进度绘制器
class _3DCircularProgressPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;

  _3DCircularProgressPainter({
    required this.percentage,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // 背景圆环（深色阴影）
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // 进度圆环（渐变效果）
    final progressPaint = Paint()
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
      final highlightPaint = Paint()
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
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _3DCircularProgressPainter ||
        oldDelegate.percentage != percentage ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// 自定义画笔类用于绘制游戏区域
class _GameAreaPainter extends CustomPainter {
  final OptimizedGameState gameState;
  final Map<String, ui.Image> terrainImages;
  final SmoothVisionManager? smoothVisionManager;

  _GameAreaPainter({
    required this.gameState,
    required this.terrainImages,
    this.smoothVisionManager,
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
    final double mapOffsetX = playerScreenX - (gameState.playerPosition.x * tileSize);
    final double mapOffsetY = playerScreenY - (gameState.playerPosition.y * tileSize);
    
    // 先绘制黑色背景
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black);
    
    // 绘制地图（只绘制可见的瓦片）
    for (int y = 0; y < gameState.map.length; y++) {
      for (int x = 0; x < gameState.map[y].length; x++) {
        final double tileX = mapOffsetX + (x * tileSize);
        final double tileY = mapOffsetY + (y * tileSize);
        
        // 只绘制在屏幕范围内的瓦片
        if (tileX > -tileSize && tileX < size.width && 
            tileY > -tileSize && tileY < size.height) {
          
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
            final Rect srcRect = Rect.fromLTWH(0, 0, terrainImage.width.toDouble(), terrainImage.height.toDouble());
            final Paint imagePaint = Paint()
              ..color = Colors.white.withOpacity(tileOpacity);
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
          final Paint borderPaint = Paint()
            ..color = Colors.black12.withOpacity(0.5 * tileOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          canvas.drawRect(tileRect, borderPaint);
          
          // 绘制雾霾装饰效果（如果该瓦片需要雾霾装饰）
          if (smoothVisionManager != null) {
            _drawFogDecorationIfNeeded(canvas, tilePoint, tileRect, tileOpacity);
          }
        }
      }
    }
    
    // 绘制玩家角色
    final Paint playerPaint = Paint()..color = Colors.red;
    canvas.drawCircle(
      Offset(playerScreenX, playerScreenY),
      tileSize / 3,
      playerPaint,
    );
    
    // 绘制玩家边框
    final Paint playerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(playerScreenX, playerScreenY),
      tileSize / 3,
      playerBorderPaint,
    );
    
    // 绘制圆形视野边界效果
    _drawCircularVisionBoundary(canvas, size, playerScreenX, playerScreenY, tileSize);
    
    // 视线遮挡系统已通过visibleTiles实现，无需额外的雾效遮罩
  }

  /// 绘制圆形视野边界效果
  void _drawCircularVisionBoundary(Canvas canvas, Size size, double playerX, double playerY, double tileSize) {
    // 获取当前精神值来计算动态视野半径
    final currentSanity = (gameState.characterStats['san'] ?? 100).toDouble();
    final maxSanity = (gameState.characterStats['maxSan'] ?? 100).toDouble();
    final sanityPercentage = (currentSanity / maxSanity).clamp(0.0, double.infinity);
    
    // 计算动态视野半径（与EnhancedVisionSystem保持一致）
    const int minViewRadius = 1;
    const int maxViewRadius = 5; // 更新为新的最大视野半径
    
    // 当精神值在0-100%时，使用非线性函数；超过100%时，线性增长
    double adjustedPercentage;
    if (sanityPercentage <= 1.0) {
      adjustedPercentage = sanityPercentage * sanityPercentage; // 平方函数
    } else {
      adjustedPercentage = 1.0 + (sanityPercentage - 1.0); // 超过100%时线性增长
    }
    
    final currentViewRadius = (minViewRadius + (maxViewRadius - minViewRadius) * adjustedPercentage).round().clamp(minViewRadius, double.infinity).toInt();
    final double visionRadius = currentViewRadius * tileSize;
    
    // 绘制多层雾效，创建更自然的视野过渡
    _drawMultiLayerFog(canvas, size, playerX, playerY, visionRadius, sanityPercentage);
    
    // 绘制动态边界效果
    _drawDynamicVisionBorder(canvas, playerX, playerY, visionRadius, sanityPercentage);
  }

  /// 绘制多层雾效
  void _drawMultiLayerFog(Canvas canvas, Size size, double playerX, double playerY, double visionRadius, double sanityPercentage) {
    // 外层浓雾（视野外完全黑暗）
    final Path outerFogPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(
        center: Offset(playerX, playerY),
        radius: visionRadius + 20, // 稍微扩大一点，避免硬边界
      ));
    outerFogPath.fillType = PathFillType.evenOdd;
    
    final Paint outerFogPaint = Paint()
      ..color = Colors.black.withOpacity(0.95 - sanityPercentage * 0.1); // 精神值越低，雾越浓
    canvas.drawPath(outerFogPath, outerFogPaint);
    
    // 中层雾效（渐变过渡区域）
    final double transitionRadius = visionRadius + 15;
    final Paint middleFogPaint = Paint()
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
      ).createShader(Rect.fromCircle(
        center: Offset(playerX, playerY),
        radius: transitionRadius,
      ));
    
    canvas.drawCircle(
      Offset(playerX, playerY),
      transitionRadius,
      middleFogPaint,
    );
    
    // 内层轻雾（视野边缘的细微雾效）
    final double innerRadius = visionRadius * 0.9;
    final Paint innerFogPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          Colors.transparent,
          Colors.black.withOpacity(0.1 + (1.0 - sanityPercentage) * 0.2),
        ],
        stops: const [0.0, 0.8, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(playerX, playerY),
        radius: visionRadius,
      ));
    
    canvas.drawCircle(
      Offset(playerX, playerY),
      visionRadius,
      innerFogPaint,
    );
  }

  /// 绘制动态视野边界
  void _drawDynamicVisionBorder(Canvas canvas, double playerX, double playerY, double visionRadius, double sanityPercentage) {
    // 主边界线（根据精神值调整颜色和透明度）
    final Paint borderPaint = Paint()
      ..color = Color.lerp(
        Colors.red.withOpacity(0.6), // 低精神值时的红色边界
        Colors.blue.withOpacity(0.3), // 高精神值时的蓝色边界
        sanityPercentage,
      )!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + (1.0 - sanityPercentage) * 2.0; // 精神值越低，边界线越粗
    
    canvas.drawCircle(
      Offset(playerX, playerY),
      visionRadius,
      borderPaint,
    );
    
    // 脉动效果（低精神值时更明显）
    if (sanityPercentage < 0.5) {
      final double pulseIntensity = (1.0 - sanityPercentage * 2.0);
      final Paint pulsePaint = Paint()
        ..color = Colors.red.withOpacity(0.3 * pulseIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * pulseIntensity;
      
      canvas.drawCircle(
        Offset(playerX, playerY),
        visionRadius + 5 * pulseIntensity,
        pulsePaint,
      );
    }
    
    // 内部光晕效果
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.1 * sanityPercentage),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(playerX, playerY),
        radius: visionRadius * 0.3,
      ));
    
    canvas.drawCircle(
      Offset(playerX, playerY),
      visionRadius * 0.3,
      glowPaint,
    );
  }
  
  /// 绘制雾霾装饰效果（如果该瓦片需要雾霾装饰）
  void _drawFogDecorationIfNeeded(Canvas canvas, math.Point<int> tilePoint, Rect tileRect, double tileOpacity) {
    // 获取瓦片的可见性状态
    final tileVisibility = smoothVisionManager!.getTileVisibility(tilePoint);
    if (tileVisibility == null) return;
    
    // 只有带雾霾装饰的瓦片才需要绘制雾霾效果
    if (tileVisibility == TileVisibility.visibleWithFogDecoration ||
        tileVisibility == TileVisibility.partiallyVisibleWithFogDecoration) {
      
      // 创建雾霾装饰效果
      final Paint fogPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3 * tileOpacity)
        ..style = PaintingStyle.fill;
      
      // 绘制半透明的雾霾覆盖层
      canvas.drawRect(tileRect, fogPaint);
      
      // 添加一些噪声纹理效果
      final Paint noisePaint = Paint()
        ..color = Colors.white.withOpacity(0.1 * tileOpacity)
        ..style = PaintingStyle.fill;
      
      // 使用简单的点状纹理模拟雾霾颗粒
      final double dotSize = tileRect.width * 0.05;
      for (int i = 0; i < 8; i++) {
        final double x = tileRect.left + (tileRect.width * (i % 3) / 3) + (dotSize * (i % 2));
        final double y = tileRect.top + (tileRect.height * (i ~/ 3) / 3) + (dotSize * ((i + 1) % 2));
        canvas.drawCircle(Offset(x, y), dotSize, noisePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
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
    bool isOnCooldown = gameState.unstuckCooldownEnd != null && 
                       now.isBefore(gameState.unstuckCooldownEnd!);
    
    int remainingSeconds = 0;
    double cooldownProgress = 0.0;
    if (isOnCooldown) {
      final totalCooldown = const Duration(seconds: 60);
      final elapsed = now.difference(gameState.unstuckCooldownEnd!.subtract(totalCooldown));
      cooldownProgress = elapsed.inMilliseconds / totalCooldown.inMilliseconds;
      cooldownProgress = cooldownProgress.clamp(0.0, 1.0);
      remainingSeconds = gameState.unstuckCooldownEnd!.difference(now).inSeconds;
    }
    
    // 检查是否处于无视地形模式
    bool isNoClipActive = gameState.isNoClipMode && 
                          gameState.noClipEndTime != null && 
                          now.isBefore(gameState.noClipEndTime!);
    
    String buttonText = '脱离卡死';
    Color iconColor = Colors.orange;
    
    if (isNoClipActive) {
      buttonText = '激活中';
      iconColor = Colors.green;
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
          colors: isNoClipActive
              ? [
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
          color: isNoClipActive
              ? Colors.green.withOpacity(0.4)
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
                               backgroundColor: Colors.grey.shade600.withOpacity(0.3),
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
                        isNoClipActive ? Icons.flash_on : Icons.refresh,
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
                             ? '无视地形模式'
                             : '点击自行移动脱离卡死（60s冷却）',
                         style: TextStyle(
                           color: isNoClipActive
                               ? Colors.green.shade300
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