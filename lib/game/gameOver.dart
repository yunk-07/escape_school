// game_over.dart
// 游戏结束页面 - 优化设计风格，符合当前游戏的整体视觉风格

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'optimized_game_state.dart';
import '../data/props.dart';
import 'time.dart';

class GameOverPage extends ConsumerStatefulWidget {
  final String deathReason;
  final String characterImage;

  const GameOverPage({
    Key? key,
    required this.deathReason,
    required this.characterImage,
  }) : super(key: key);

  @override
  ConsumerState<GameOverPage> createState() => _GameOverPageState();
}

class _GameOverPageState extends ConsumerState<GameOverPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glitchController;
  late AnimationController _autoScrollController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glitchAnimation;
  late Animation<double> _autoScrollAnimation;
  
  late ScrollController _scrollController;
  bool _isDisposed = false;
  bool _isAutoScrolling = false;
  bool _hasUserScrolled = false;
  
  // 固定的生存时间，在初始化时计算一次
  late String _finalSurvivalTime;

  @override
  void initState() {
    super.initState();
    
    // 初始化固定的生存时间为空字符串，稍后在 didChangeDependencies 中计算
    _finalSurvivalTime = '';
    
    // 淡入动画
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    // 缩放动画
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // 故障效果动画
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _glitchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glitchController, curve: Curves.easeInOut),
    );
    
    // 自动滚动动画控制器
    _autoScrollController = AnimationController(
      duration: const Duration(seconds: 4), // 8秒缓慢滚动到底部
      vsync: this,
    );
    _autoScrollAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _autoScrollController, curve: Curves.easeInOut),
    );
    
    // 滚动控制器
    _scrollController = ScrollController();
    
    // 启动动画序列
    _startAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在依赖项准备好后计算固定的生存时间
    if (_finalSurvivalTime.isEmpty) {
      _calculateFinalSurvivalTime();
    }
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted && !_isDisposed) {
      _fadeController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && !_isDisposed) {
      _scaleController.forward();
    }
    // 关键区域：先展示 GAME OVER 标题，待标题动画完成后再开始滚动
    void _maybeStartScroll() {
      if (!_isDisposed && mounted && !_hasUserScrolled &&
          _fadeController.status == AnimationStatus.completed &&
          _scaleController.status == AnimationStatus.completed) {
        // 给予标题一个停留时间（800ms），再开始滚动
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && !_isDisposed) {
            _startAutoScroll();
          }
        });
      }
    }
    // 监听淡入与缩放完成状态，以标题完成为准触发滚动
    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _maybeStartScroll();
      }
    });
    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _maybeStartScroll();
      }
    });

    // 定期触发故障效果
    _triggerGlitchEffect();
  }

  void _triggerGlitchEffect() {
    Future.delayed(Duration(milliseconds: 2000 + math.Random().nextInt(3000)), () {
      if (mounted && !_isDisposed) {
        _glitchController.forward().then((_) {
          if (mounted && !_isDisposed) {
            _glitchController.reverse();
            _triggerGlitchEffect();
          }
        });
      }
    });
  }

  void _startAutoScroll() {
    if (_hasUserScrolled || _isAutoScrolling || _isDisposed) return;
    
    _isAutoScrolling = true;
    
    // 监听自动滚动动画
    _autoScrollAnimation.addListener(_onAutoScrollUpdate);
    
    // 开始自动滚动动画
    _autoScrollController.forward();
  }

  void _onAutoScrollUpdate() {
    if (!_hasUserScrolled && _scrollController.hasClients && !_isDisposed) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final targetOffset = maxScrollExtent * _autoScrollAnimation.value;
      
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 100),
        curve: Curves.linear,
      );
    }
  }

  void _stopAutoScroll() {
    if (_isAutoScrolling) {
      _hasUserScrolled = true;
      _isAutoScrolling = false;
      _autoScrollController.stop();
      _autoScrollAnimation.removeListener(_onAutoScrollUpdate);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopAutoScroll();
    _fadeController.dispose();
    _scaleController.dispose();
    _glitchController.dispose();
    _autoScrollController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background_1.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.red.withOpacity(0.1),
                Colors.black.withOpacity(0.9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                // 检测用户手动滑动
                if (notification is ScrollStartNotification && 
                    notification.dragDetails != null) {
                  _stopAutoScroll();
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_fadeAnimation, _scaleAnimation, _glitchAnimation]),
                  builder: (context, child) {
                    // Impeller 修复：避免使用 Opacity 包裹含 ShaderMask/ColorFiltered 内容，
                    // 改为叠加黑色遮罩实现淡入，规避 Contents::SetInheritedOpacity 报错。
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.9,
                              minHeight: MediaQuery.of(context).size.height * 0.6,
                            ),
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.8),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 关键区域：布局重构——英雄头部（标题+死亡原因+分隔），保持滚动展示
                                _buildHeroHeader(),
                                
                                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                                
                                // 关键区域：主内容（两栏布局），左侧头像与生存时间，右侧玩家数据与背包
                                _buildMainContent(),
                                
                                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                                
                                // 按钮区域
                                _buildButtonSection(),
                              ],
                            ),
                          ),
                          // 关键区域：遮罩淡入层，随 _fadeAnimation 从黑到透明
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: Colors.black.withOpacity(1.0 - _fadeAnimation.value),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarSize = (screenWidth * 0.25).clamp(80.0, 120.0);
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.shade400.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：角色头像
          Column(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(avatarSize / 2),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.6),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular((avatarSize / 2) - 3),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.red.withOpacity(0.3),
                      BlendMode.overlay,
                    ),
                    child: Image.asset(
                      widget.characterImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 角色状态文本
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: const Text(
                  '角色已死亡',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 生存时间显示
              _buildSurvivalTime(),
            ],
          ),
          
          const SizedBox(width: 20),
          
          // 右侧：玩家数据和背包物品
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 玩家死前数据
                _buildPlayerDataSection(),
                
                const SizedBox(height: 16),
                
                // 背包剩余物品
                _buildInventorySection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverTitle() {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = (screenWidth * 0.12).clamp(32.0, 48.0);
    
    return AnimatedBuilder(
      animation: _glitchAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _glitchAnimation.value * (math.Random().nextDouble() - 0.5) * 10,
            _glitchAnimation.value * (math.Random().nextDouble() - 0.5) * 5,
          ),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  Colors.red.shade300,
                  Colors.red.shade600,
                  Colors.red.shade900,
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds);
            },
            child: Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                fontFamily: 'Terror',
                color: Colors.white,
                letterSpacing: screenWidth * 0.008,
                shadows: [
                  Shadow(
                    blurRadius: 15,
                    color: Colors.red.withOpacity(0.8),
                    offset: const Offset(0, 0),
                  ),
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 关键区域：英雄头部（标题 + 死亡原因 + 装饰分隔线）
  Widget _buildHeroHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = (screenWidth * 0.01).clamp(8.0, 16.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildDividerLine(),
        SizedBox(height: spacing),
        _buildGameOverTitle(),
        SizedBox(height: spacing * 0.75),
        _buildDeathReason(),
        SizedBox(height: spacing),
        _buildDividerLine(),
      ],
    );
  }

  // 关键区域：主内容（复用原左头像+右数据/背包布局）
  Widget _buildMainContent() {
    return _buildCharacterSection();
  }

  // 关键区域：装饰分隔线（渐变发光效果）
  Widget _buildDividerLine() {
    return Container(
      width: double.infinity,
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.red.withOpacity(0.0),
            Colors.red.shade400,
            Colors.red.shade700,
            Colors.red.withOpacity(0.0),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildDeathReason() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade400,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            '死亡原因',
            style: TextStyle(
              color: Colors.red.shade300,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.deathReason,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontFamily: 'MicroBrew',
              height: 1.4,
              shadows: [
                Shadow(
                  blurRadius: 5,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = (screenHeight * 0.07).clamp(48.0, 56.0);
    
    return Column(
      children: [
        // 重新开始按钮
        Container(
          width: double.infinity,
          height: buttonHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade600,
                Colors.blue.shade800,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.shade400.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      '重新开始',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'MicroBrew',
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        SizedBox(height: screenHeight * 0.02),
        
        // 返回主菜单按钮
        Container(
          width: double.infinity,
          height: buttonHeight * 0.85,
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade600.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: const Center(
                child: Text(
                  '返回主菜单',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 构建玩家死前数据区域
  Widget _buildPlayerDataSection() {
    final gameState = ref.watch(optimizedGameStateProvider);
    // 关键区域：优先使用死亡快照；若缺失则回退当前状态，所有数值安全格式化
    final snapshot = gameState.deathTimeStats;
    final live = gameState.characterStats;
    final stats = snapshot ?? live;

    // 安全提取与格式化，保留原先展示方式
    int _toInt(dynamic v, int d) => (v is num ? v.toInt() : d);
    final hp = _toInt(stats['hp'], _toInt(live['hp'], 0));
    final maxHp = _toInt(stats['maxHp'], _toInt(live['maxHp'], 100));
    final food = _toInt(stats['food'], _toInt(live['food'], 0));
    final san = _toInt(stats['san'], _toInt(live['san'], 0));
    final maxSan = _toInt(stats['maxSan'], _toInt(live['maxSan'], 250));
    final moveSpeed = _toInt(stats['moveSpeed'], _toInt(live['moveSpeed'], 100));
    final gold = _toInt(stats['gold'], _toInt(live['gold'], 0));
    
    // 关键区域：玩家数据采用统一面板样式，优化间距与可读性
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '玩家数据',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildDataRow('生命值', '$hp/$maxHp'),
          _buildDataRow('饱食度', '$food'),
          _buildDataRow('精神值', '$san/$maxSan'),
          _buildDataRow('移动速度', '$moveSpeed'),
          _buildDataRow('金币', '$gold'),
        ],
      ),
    );
  }

  // 构建背包物品区域
  Widget _buildInventorySection() {
    final gameState = ref.watch(optimizedGameStateProvider);
    // 关键区域：优先使用死亡快照；若缺失则回退当前背包，保留原先展示方式
    final inventory = gameState.deathTimeInventory ?? gameState.playerInventory;
    
    // 关键区域：背包区域采用统一面板样式，并限制高度避免溢出，支持滚动
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade400.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '背包剩余物品',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (inventory.isEmpty)
            const Text(
              '背包为空',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: inventory.map((item) => _buildInventoryItem(item)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 构建数据行
  Widget _buildDataRow(String label, String value) {
    // 检查是否为归零数据
    bool isZeroValue = _isZeroValue(value);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isZeroValue ? Colors.red.shade200 : Colors.white70,
              fontSize: isZeroValue ? 14 : 12,
              fontWeight: isZeroValue ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isZeroValue ? Colors.red.shade100 : Colors.white,
              fontSize: isZeroValue ? 16 : 12,
              fontWeight: isZeroValue ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 检查数值是否为零
  bool _isZeroValue(String value) {
    // 处理 "0/100" 这样的格式
    if (value.contains('/')) {
      String firstPart = value.split('/')[0];
      return firstPart.trim() == '0' || firstPart.trim() == '0.0';
    }
    // 处理单独的数值
    return value.trim() == '0' || value.trim() == '0.0';
  }

  // 构建背包物品
  Widget _buildInventoryItem(Item item) {
    // 关键区域：背包物品底色按 level 渲染，并添加图片容错以保证展示
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getItemLevelColor(item.level).withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getItemBorderColor(item.type),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getItemLevelColor(item.level).withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: item.image.isNotEmpty
                ? Image.asset(
                    item.image,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        _getItemTypeIcon(item.type),
                        color: Colors.white,
                        size: 18,
                      );
                    },
                  )
                : Icon(
                    _getItemTypeIcon(item.type),
                    color: Colors.white,
                    size: 18,
                  ),
          ),
          if (item.count > 1)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getItemLevelColor(item.level),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '${item.count}',
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
    );
  }

  // 构建生存时间显示
  Widget _buildSurvivalTime() {
    // 使用在初始化时计算的固定生存时间
    final survivalTimeText = _finalSurvivalTime;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.blue.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        '生存时间: $survivalTimeText',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // 根据物品类型获取边框颜色
  Color _getItemBorderColor(String type) {
    switch (type) {
      case 'food':
        return Colors.green.withOpacity(0.6);
      case 'tool':
        return Colors.blue.withOpacity(0.6);
      case 'weapon':
        return Colors.red.withOpacity(0.6);
      default:
        return Colors.grey.withOpacity(0.6);
    }
  }

  // 关键区域：按物品等级返回底色（与背包页面一致）
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
        return Colors.orange.shade400; // 橙色
      case 7:
        return Colors.red.shade400; // 红色
      default:
        return Colors.grey.shade600; // 默认无色
    }
  }

  // 关键区域：图片容错时按类型显示图标
  IconData _getItemTypeIcon(String type) {
    switch (type) {
      case 'potion':
        return Icons.local_pharmacy;
      case 'food':
        return Icons.restaurant;
      case 'tool':
        return Icons.build;
      case 'weapon':
        return Icons.security;
      default:
        return Icons.inventory_2;
    }
  }
  
  // 计算并保存固定的生存时间
  void _calculateFinalSurvivalTime() {
    final gameState = ref.read(optimizedGameStateProvider);
    // 如果游戏已结束且有结束时间，使用结束时间；否则使用当前时间
    final endTime = gameState.isGameOver && gameState.gameEndTime != null 
        ? gameState.gameEndTime! 
        : DateTime.now();
    final survivalDuration = endTime.difference(gameState.gameStartTime);
    _finalSurvivalTime = GameTime.formatSurvivalTime(survivalDuration.inMilliseconds);
  }
}