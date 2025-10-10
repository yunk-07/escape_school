// game/optimized_board.dart
// 性能优化的游戏界面

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escape_from_school/game/optimized_game_state.dart';
import 'package:escape_from_school/game/gameOver.dart';
import 'package:escape_from_school/game/joystick.dart';

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
    
    // 初始化游戏状态管理器 - 使用角色ID而不是统计数据
    final characterId = widget.characterStats['id'] ?? 'cook';
    gameStateNotifier = OptimizedGameStateNotifier(characterId);

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
            
              return SizedBox.expand(
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
                    
                    // 移动控制
                    _buildMovementControls(),
                    
                    // 功能按钮
                    _buildActionButtons(gameState),
                    
                    // 角色信息面板（左侧）
                    _buildCharacterInfoView(gameState),
                    
                    // 背包界面（右侧）
                    _buildInventoryView(gameState),
                    
                    // 商店界面
                    if (gameState.showShop && gameState.schoolShop != null)
                      _buildShopView(gameState),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 构建空背包界面
  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.white30,
          ),
          const SizedBox(height: 16),
          const Text(
            '背包是空的',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '探索世界来收集物品吧！',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 构建背包槽位
  Widget _buildInventorySlot(dynamic item, bool hasItem) {
    return Container(
      decoration: BoxDecoration(
        gradient: hasItem
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.brown.shade700.withOpacity(0.8),
                  Colors.brown.shade600.withOpacity(0.6),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade800.withOpacity(0.5),
                  Colors.grey.shade700.withOpacity(0.3),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasItem ? Colors.brown.shade400.withOpacity(0.6) : Colors.white12,
          width: hasItem ? 2 : 1,
        ),
        boxShadow: hasItem
            ? [
                BoxShadow(
                  color: Colors.brown.shade900.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: hasItem
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Image.asset(
                          item.image,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: Colors.white54,
                              size: 24,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    flex: 1,
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Icon(
                Icons.add,
                color: Colors.white24,
                size: 24,
              ),
            ),
    );
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
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 退出到主菜单
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
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            '游戏设置',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  '退出游戏',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showExitConfirmDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text(
                  '脱离卡死',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  '将角色传送到最近的安全位置',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _unstuckPlayer();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '关闭',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  // 脱离卡死功能
  void _unstuckPlayer() {
    final ref = ProviderScope.containerOf(context).read(optimizedGameStateProvider.notifier);
    ref.unstuckPlayer();
    
    // 显示提示信息
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已将角色传送到安全位置'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 显示详细状态面板


  @override
  void dispose() {
    gameStateNotifier.dispose();
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
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  // 构建精神值环形图（左上角）- 立体效果
  Widget _buildSanityCircle(OptimizedGameState gameState) {
    final int currentSan = gameState.characterStats['san'] ?? 0;
    final int maxSan = gameState.characterStats['maxSan'] ?? 100;
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
              '$currentSan',
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
    final int currentHp = gameState.characterStats['hp'] ?? 0;
    final int maxHp = gameState.characterStats['maxHp'] ?? 100;
    final int currentFood = gameState.characterStats['food'] ?? 0;
    final int maxFood = 100;
    
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
  Widget _buildStatusBar(IconData icon, int current, int max, Color color, String label) {
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
            '$current/$max',
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
              // 探索功能暂未实现
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('探索功能开发中...'),
                  duration: Duration(seconds: 1),
                ),
              );
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
            gameState.characterConfig.description,
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
          
          // 攻击力
          _buildStatRow('攻击力', '${stats['att']}', 
                       Icons.flash_on, Colors.orange, 1.0),
          
          // 饱食度
          _buildStatRow('饱食度', '${stats['food']}', 
                       Icons.restaurant, Colors.green, stats['food'] / 100.0),
          
          // 金币
          _buildStatRow('金币', '${stats['金币']}', 
                       Icons.monetization_on, Colors.yellow, 1.0),
          
          // 移动速度
          _buildStatRow('移动速度', '${gameState.characterConfig.moveSpeed.toInt()}', 
                       Icons.directions_run, Colors.cyan, 1.0),
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
    final abilities = gameState.characterConfig.specialAbilities;
    
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
          
          ...abilities.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${entry.key}: ${entry.value}',
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

  // 构建背包界面
  Widget _buildInventoryView(OptimizedGameState gameState) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: gameState.showInventory ? 0 : -MediaQuery.of(context).size.width,
      top: 0,
      bottom: 0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade900,
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white30, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // 背包标题栏
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.brown.shade800,
                        Colors.brown.shade700,
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
                          Icon(Icons.inventory, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            '背包',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
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
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () {
                            final ref = ProviderScope.containerOf(context).read(optimizedGameStateProvider.notifier);
                            ref.toggleInventory();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 背包统计信息
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    border: Border(
                      bottom: BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '物品数量: ${gameState.playerInventory.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '容量: ${gameState.playerInventory.length}/20',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 背包内容
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: gameState.playerInventory.isEmpty
                        ? _buildEmptyInventory()
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: 20, // 固定20个槽位
                            itemBuilder: (context, index) {
                              if (index < gameState.playerInventory.length) {
                                final item = gameState.playerInventory[index];
                                return _buildInventorySlot(item, true);
                              } else {
                                return _buildInventorySlot(null, false);
                              }
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

  _GameAreaPainter({
    required this.gameState,
    required this.terrainImages,
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
    
    // 绘制地图
    for (int y = 0; y < gameState.map.length; y++) {
      for (int x = 0; x < gameState.map[y].length; x++) {
        final double tileX = mapOffsetX + (x * tileSize);
        final double tileY = mapOffsetY + (y * tileSize);
        
        // 只绘制在屏幕范围内的瓦片
        if (tileX > -tileSize && tileX < size.width && 
            tileY > -tileSize && tileY < size.height) {
          
          final String terrain = gameState.map[y][x];
          final Rect tileRect = Rect.fromLTWH(tileX, tileY, tileSize, tileSize);
          
          // 尝试使用贴图渲染，如果没有贴图则使用颜色渲染
          final ui.Image? terrainImage = terrainImages[terrain];
          
          if (terrainImage != null) {
            // 使用贴图渲染
            final Rect srcRect = Rect.fromLTWH(0, 0, terrainImage.width.toDouble(), terrainImage.height.toDouble());
            canvas.drawImageRect(terrainImage, srcRect, tileRect, Paint());
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
            
            // 添加渐变效果使地形更美观
            final gradient = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                terrainColor.withOpacity(0.9),
                terrainColor,
                terrainColor.withOpacity(0.8),
              ],
            );
            
            terrainPaint.shader = gradient.createShader(tileRect);
            canvas.drawRect(tileRect, terrainPaint);
          }
          
          // 绘制细微边框以增强视觉效果
          final Paint borderPaint = Paint()
            ..color = Colors.black12
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          canvas.drawRect(tileRect, borderPaint);
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}