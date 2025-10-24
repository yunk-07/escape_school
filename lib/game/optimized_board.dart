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

import 'package:escape_from_school/game/hp_listener.dart';
import 'package:escape_from_school/game/smooth_vision.dart';
import 'package:escape_from_school/game/enhanced_vision.dart';
import 'package:escape_from_school/game/shop_view.dart';
import 'package:escape_from_school/game/item_usage_progress.dart';
import 'package:escape_from_school/game/chest_exploration_progress.dart';

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

class _OptimizedBoardPageState extends State<OptimizedBoardPage> with SingleTickerProviderStateMixin {
  late OptimizedGameStateNotifier gameStateNotifier;
  final Map<String, ui.Image> terrainImages = {};
  ui.Image? characterImage;
  bool _hasNavigatedToGameOver = false; // 防止重复导航到游戏结束页面
  
  // 视野边界闪烁动画控制器
  AnimationController? _visionBorderFlashController;
  Animation<double>? _visionBorderFlashAnimation;

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
    
    // 创建闪烁动画（从1.0到0.3再回到1.0）
    _visionBorderFlashAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _visionBorderFlashController!,
      curve: Curves.easeInOut,
    ));

    // 预加载地形图片和角色图片
    _preloadImages();
  }

  Future<void> _preloadImages() async {
    // 加载地形图片
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
              
              // 监听伤害事件，触发视野边界闪烁动画
              if (damageEvent != null && _visionBorderFlashController != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _visionBorderFlashController != null) {
                    _visionBorderFlashController!.reset();
                    _visionBorderFlashController!.forward();
                  }
                });
              }
            
              // 检查游戏结束状态
              if (gameState.isGameOver && !_hasNavigatedToGameOver) {
                _hasNavigatedToGameOver = true; // 设置标志，防止重复导航
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) { // 确保组件仍然挂载
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameOverPage(
                          deathReason: gameState.deathReason,
                          characterImage: gameState.characterStats['image'] ?? 'images/man/cook.png',
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
                
                // 技能内容
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildSkillsList(gameState),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建技能列表
  Widget _buildSkillsList(OptimizedGameState gameState) {
    final notifier = ProviderScope.containerOf(context).read(optimizedGameStateProvider.notifier);
    final characterSkills = gameState.characterSkills;
    
    if (characterSkills.isEmpty) {
      return const Center(
        child: Text(
          '该角色暂无可用技能',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
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
    final bool isOnCooldown = skillState?.isOnCooldown(skill.cooldownSeconds) ?? false;
    final bool isCasting = skillState?.isCurrentlyCasting ?? false;
    final int remainingCooldown = skillState?.getRemainingCooldown(skill.cooldownSeconds) ?? 0;
    final int remainingCastTime = skillState?.getRemainingCastTime(skill.castTimeSeconds) ?? 0;
    
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
              color: isOnCooldown ? Colors.grey.withOpacity(0.3) : Colors.purple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
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
              onPressed: (isOnCooldown || isCasting) ? null : () {
                notifier.useSkill(skill.id);
                Navigator.of(context).pop(); // 关闭对话框
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isOnCooldown || isCasting 
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.purple.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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



  // 构建播报框（设置按钮左边）
  Widget _buildBroadcastBox(OptimizedGameState gameState) {
    // 清理过期消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gameStateNotifier.cleanupExpiredMessages();
    });

    final messages = gameState.broadcastMessages;
    if (messages.isNotEmpty) {
      for (int i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final age = DateTime.now().difference(msg.timestamp).inSeconds;
      }
    }
    
    return Positioned(
      top: 40,
      right: 80, // 设置按钮右边距20 + 按钮宽度50 + 间距10 = 80
      child: Container(
        width: 200,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(4), // 简单的四方形，圆角很小
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 消息列表
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无消息',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(4),
                      itemCount: messages.length,
                      reverse: true, // 最新消息在底部
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        return _buildBroadcastMessage(message);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建单条播报消息
  Widget _buildBroadcastMessage(BroadcastMessage message) {
    Color textColor;
    switch (message.type) {
      case BroadcastMessageType.damage:
        textColor = Colors.red;
        break;
      case BroadcastMessageType.heal:
        textColor = Colors.green;
        break;
      case BroadcastMessageType.item:
        textColor = Colors.yellow;
        break;
      case BroadcastMessageType.system:
        textColor = Colors.white;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        message.text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
      
    } catch (e) {
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
    // 清理动画控制器
    _visionBorderFlashController?.dispose();
    
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
                animation: _visionBorderFlashAnimation ?? const AlwaysStoppedAnimation(1.0),
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GameAreaPainter(
                      gameState: gameState,
                      terrainImages: terrainImages,
                      characterImage: characterImage,
                      smoothVisionManager: gameStateNotifier.smoothVisionManager,
                      damageEvent: damageEvent,
                      visionBorderFlashValue: _visionBorderFlashAnimation?.value ?? 1.0,
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
      final Rect chestRect = Rect.fromLTWH(chestScreenX, chestScreenY, tileSize, tileSize);
      print('宝箱位置: (${chestPos.x}, ${chestPos.y}), 屏幕坐标: ($chestScreenX, $chestScreenY), 点击位置: (${localPosition.dx}, ${localPosition.dy})');
      
      if (chestRect.contains(localPosition)) {
        print('点击命中宝箱区域!');
        
        // 检查宝箱是否可见
        final math.Point<int> chestPoint = math.Point(chestPos.x.toInt(), chestPos.y.toInt());
        bool isChestVisible = false;
        
        if (gameStateNotifier.smoothVisionManager != null) {
          final opacity = gameStateNotifier.smoothVisionManager!.getTileOpacity(chestPoint);
          isChestVisible = opacity > 0.0;
          print('宝箱可见性检查 (smoothVision): opacity = $opacity, visible = $isChestVisible');
        } else {
          isChestVisible = gameState.visibleTiles.contains(chestPoint);
          print('宝箱可见性检查 (visibleTiles): visible = $isChestVisible');
        }
        
        if (isChestVisible) {
           print('宝箱可见，直接打开宝箱...');
           // 直接打开宝箱，不检查距离
           gameStateNotifier.openChestAtPosition(chestPos);
           return; // 找到点击的宝箱后退出循环
         } else {
           print('宝箱不可见，无法交互');
         }
      }
    }
    
    // 检查商店点击（如果商店存在）
    if (gameState.schoolShop != null) {
      final shopPos = gameState.schoolShop!.position;
      final double shopScreenX = mapOffsetX + (shopPos.x * tileSize);
      final double shopScreenY = mapOffsetY + (shopPos.y * tileSize);
      
      // 检查点击是否在商店区域内
      final Rect shopRect = Rect.fromLTWH(shopScreenX, shopScreenY, tileSize, tileSize);
      if (shopRect.contains(localPosition)) {
        // 检查商店是否可见
        final math.Point<int> shopPoint = math.Point(shopPos.x.toInt(), shopPos.y.toInt());
        bool isShopVisible = false;
        
        if (gameStateNotifier.smoothVisionManager != null) {
          final opacity = gameStateNotifier.smoothVisionManager!.getTileOpacity(shopPoint);
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
  }

  // 构建精神值环形图（左上角）- 立体效果
  Widget _buildSanityCircle(OptimizedGameState gameState) {
    final double currentSan = (gameState.characterStats['san'] ?? 0).toDouble().clamp(0, 250);
    final double maxSan = 250.0; // 精神值上限固定为250
    final double percentage = (currentSan / maxSan).clamp(0.0, 1.0); // 限制在100%以内
    
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
          
          // 饱食度条（橘色）
          _buildFoodBar(currentFood, maxFood),
          
          // 施法进度条（如果正在施法）
          if (gameState.currentCastingSkillId != null) ...[
            const SizedBox(width: 20),
            _buildCastingBar(gameState.castingProgress, gameState.currentCastingSkillId!),
          ],
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
              borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
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

  // 构建饱食度条
  Widget _buildFoodBar(double currentFood, double maxFood) {
    final double foodPercentage = (currentFood / maxFood).clamp(0.0, 1.0);
    
    return Container(
      width: 180,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
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
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // 饱食度进度条
          Positioned(
            left: 2,
            child: Container(
              width: (176 * foodPercentage).clamp(0.0, 176.0),
              height: 12,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
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
        final notifier = ProviderScope.containerOf(context).read(optimizedGameStateProvider.notifier);
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
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.withOpacity(0.5), width: 1),
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
                    borderRadius: BorderRadius.circular(8),
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
                      borderRadius: BorderRadius.circular(8),
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
          
          // 当背包打开时隐藏摇杆
          if (gameState.showInventory) {
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

  // 构建功能按钮
  Widget _buildActionButtons(OptimizedGameState gameState) {
    final notifier = ProviderScope.containerOf(context).read(optimizedGameStateProvider.notifier);
    final characterSkills = gameState.characterSkills;
    
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 技能按钮组 - 为每个技能创建单独的按钮
          ...characterSkills.map((skill) {
            final skillState = notifier.getSkillState(skill.id);
            final bool isOnCooldown = skillState?.isOnCooldown(skill.cooldownSeconds) ?? false;
            final bool isCasting = skillState?.isCurrentlyCasting ?? false;
            final int remainingCooldown = skillState?.getRemainingCooldown(skill.cooldownSeconds) ?? 0;
            final int remainingCastTime = skillState?.getRemainingCastTime(skill.castTimeSeconds) ?? 0;
            
            return GestureDetector(
              onTap: (isOnCooldown || isCasting) ? null : () {
                notifier.useSkill(skill.id);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (isOnCooldown || isCasting) 
                    ? Colors.grey.withOpacity(0.5)
                    : Colors.purple.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 技能图标
                    const Center(
                      child: Icon(
                        Icons.auto_fix_high,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // 冷却时间或施法时间显示
                    if (isOnCooldown || isCasting)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isCasting ? Colors.orange : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCasting ? '$remainingCastTime' : '$remainingCooldown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          
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
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        final notifier = ref.read(optimizedGameStateProvider.notifier);
                        notifier.openInventory(); // 只负责打开背包
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.yellow, width: 3), // 添加黄色边框
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '背包',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // 角色描述
          Text(
            gameState.characterStats['description'] ?? '无描述',
            style: TextStyle(
              color: Colors.blue.shade200,
              fontSize: 16,
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
          _buildStatRow('理智值', '${(stats['san'] as num).toDouble().clamp(0, 250).toInt()}/250', 
                       Icons.psychology, Colors.blue, ((stats['san'] as num).toDouble().clamp(0, 250) / 250.0).clamp(0.0, 1.0)), // 精神值上限250，限制在100%以内
          
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
        ],
      ),
    );
  }

  // 构建单个属性行
  Widget _buildStatRow(String label, String value, IconData icon, Color color, double progress) {
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
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
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
              fontSize: 18,
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
                
                // 生命值和饱食度条（下方居中）
                _buildBottomStatusBars(gameState),
                
                // 设置按钮（右上角）
                _buildSettingsButton(),
                
                // 播报框（设置按钮左边）
                _buildBroadcastBox(gameState),
                
                // 角色信息面板（左侧）
                _buildCharacterInfoView(gameState),
                
                // 商店界面（独立组件，避免不必要的刷新）
                const ShopView(),
                
                // 物品使用进度条（动态显示）
                const ItemUsageProgress(),
                
                // 宝箱探索进度条（动态显示）
                const ChestExplorationProgress(),
                
              ],
            ),
          ),
          
          // 背包界面（需要在功能按钮之前，避免覆盖按钮）
          if (gameState.showInventory) const InventoryView(),
          
          // 交互控制组件（最高优先级，不受伤害效果影响）
          // 移动控制（摇杆）
          _buildMovementControls(),
          
          // 功能按钮
          _buildActionButtons(gameState),
          
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
    return const Positioned.fill(
      child: InventoryPage(),
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
  final ui.Image? characterImage;
  final SmoothVisionManager? smoothVisionManager;
  final DamageEvent? damageEvent;
  final double visionBorderFlashValue; // 视野边界闪烁动画值

  _GameAreaPainter({
    required this.gameState,
    required this.terrainImages,
    this.characterImage,
    this.smoothVisionManager,
    this.damageEvent,
    this.visionBorderFlashValue = 1.0, // 默认值为1.0（不闪烁）
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
    
    // 绘制商店
    if (gameState.schoolShop != null) {
      final shopPos = gameState.schoolShop!.position;
      final double shopX = mapOffsetX + (shopPos.x * tileSize);
      final double shopY = mapOffsetY + (shopPos.y * tileSize);
      
      // 只在屏幕范围内且可见时绘制商店
      if (shopX > -tileSize && shopX < size.width && 
          shopY > -tileSize && shopY < size.height) {
        
        final math.Point<int> shopPoint = math.Point(shopPos.x.toInt(), shopPos.y.toInt());
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
    
    // 绘制宝箱
    for (final chestPos in gameState.chestPositions) {
      final double chestX = mapOffsetX + (chestPos.x * tileSize);
      final double chestY = mapOffsetY + (chestPos.y * tileSize);
      
      // 只在屏幕范围内且可见时绘制宝箱
      if (chestX > -tileSize && chestX < size.width && 
          chestY > -tileSize && chestY < size.height) {
        
        final math.Point<int> chestPoint = math.Point(chestPos.x.toInt(), chestPos.y.toInt());
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
    }
    
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
        0, 0, 
        characterImage!.width.toDouble(), 
        characterImage!.height.toDouble()
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
    
    // 绘制圆形视野边界效果
    _drawCircularVisionBoundary(canvas, size, playerScreenX, playerScreenY, tileSize);
    
    // 视线遮挡系统已通过visibleTiles实现，无需额外的雾效遮罩
  }

  /// 绘制圆形视野边界效果
  void _drawCircularVisionBoundary(Canvas canvas, Size size, double playerX, double playerY, double tileSize) {
    // 获取当前精神值来计算动态视野半径
    final currentSanity = (gameState.characterStats['san'] ?? 100).toDouble().clamp(0, 250);
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
    // 检查是否有伤害事件（受伤状态）
    final isDamaged = damageEvent != null;
    
    // 主边界线（只有受伤时才变红，否则保持蓝色）
    Color borderColor;
    double borderOpacity;
    double strokeWidth;
    
    if (isDamaged) {
      // 受伤时：视野边界变为红色，根据伤害强度调整透明度和粗细
      final damageIntensity = damageEvent!.intensity / 100.0; // 标准化到0-1
      borderColor = Colors.red;
      // 应用闪烁动画效果：透明度会在0.7-1.0之间闪烁
      borderOpacity = (0.7 + damageIntensity * 0.3) * visionBorderFlashValue;
      strokeWidth = 3.0 + damageIntensity * 3.0; // 3.0-6.0的线宽
    } else {
      // 正常状态：始终保持蓝色边界，不受精神值影响
      borderColor = Colors.blue;
      borderOpacity = 0.4; // 固定透明度
      strokeWidth = 2.0; // 固定线宽
    }
    
    final Paint borderPaint = Paint()
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
  
  /// 绘制商店
  void _drawShop(Canvas canvas, double shopX, double shopY, double tileSize, double opacity) {
    final Rect shopRect = Rect.fromLTWH(shopX, shopY, tileSize, tileSize);
    
    // 绘制商店背景（紫色）
    final Paint shopBgPaint = Paint()
      ..color = Colors.purple.shade600.withOpacity(opacity);
    canvas.drawRect(shopRect, shopBgPaint);
    
    // 绘制商店图标（简单的房子形状）
    final Paint shopIconPaint = Paint()
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
    final Paint roofPaint = Paint()
      ..color = Colors.red.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final Path roofPath = Path();
    roofPath.moveTo(shopX + tileSize * 0.5, shopY + tileSize * 0.2); // 顶点
    roofPath.lineTo(houseX - tileSize * 0.1, houseY); // 左下
    roofPath.lineTo(houseX + houseWidth + tileSize * 0.1, houseY); // 右下
    roofPath.close();
    
    canvas.drawPath(roofPath, roofPaint);
    
    // 绘制门
    final Paint doorPaint = Paint()
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
    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(shopRect, borderPaint);
  }

  /// 绘制宝箱
  void _drawChest(Canvas canvas, double chestX, double chestY, double tileSize, double opacity) {
    final Rect chestRect = Rect.fromLTWH(chestX, chestY, tileSize, tileSize);
    
    // 尝试使用宝箱贴图
    final ui.Image? chestImage = terrainImages['chest'];
    
    if (chestImage != null) {
      // 使用贴图渲染宝箱
      final Rect srcRect = Rect.fromLTWH(0, 0, chestImage.width.toDouble(), chestImage.height.toDouble());
      final Paint imagePaint = Paint()
        ..color = Colors.white.withOpacity(opacity);
      canvas.drawImageRect(chestImage, srcRect, chestRect, imagePaint);
    } else {
      // 回退到手绘宝箱
      // 绘制宝箱主体（棕色）
      final Paint chestBodyPaint = Paint()
        ..color = Colors.brown.shade700.withOpacity(opacity);
      
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
      final Paint chestLidPaint = Paint()
        ..color = Colors.brown.shade600.withOpacity(opacity);
      
      final double lidHeight = chestHeight * 0.4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chestBodyX, chestBodyY, chestWidth, lidHeight),
          const Radius.circular(4),
        ),
        chestLidPaint,
      );
      
      // 绘制锁扣（金色）
      final Paint lockPaint = Paint()
        ..color = Colors.amber.shade600.withOpacity(opacity);
      
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
      final Paint metalPaint = Paint()
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
    final Paint glowPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.3 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(chestRect, glowPaint);
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
    bool isOnCooldown = gameState.unstuckCooldownEnd != null && 
                       now.isBefore(gameState.unstuckCooldownEnd!);
    
    // 检查是否等待移动开始冷却
    bool isWaitingForMovement = gameState.isWaitingForMovement;
    
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
          colors: isNoClipActive
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
          color: isNoClipActive
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
                        isNoClipActive 
                            ? (isWaitingForMovement ? Icons.directions_walk : Icons.flash_on)
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
                             ? (isWaitingForMovement 
                                 ? '移动后开始冷却'
                                 : '无视地形模式')
                             : '点击自行移动脱离卡死（60s冷却）',
                         style: TextStyle(
                           color: isNoClipActive
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