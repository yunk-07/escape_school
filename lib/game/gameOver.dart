// game_over.dart
// 游戏结束页面 - 优化设计风格，符合当前游戏的整体视觉风格

import 'package:flutter/material.dart';
import 'dart:math' as math;

class GameOverPage extends StatefulWidget {
  final String deathReason;
  final String characterImage;

  const GameOverPage({
    Key? key,
    required this.deathReason,
    required this.characterImage,
  }) : super(key: key);

  @override
  State<GameOverPage> createState() => _GameOverPageState();
}

class _GameOverPageState extends State<GameOverPage>
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

  @override
  void initState() {
    super.initState();
    
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

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted && !_isDisposed) {
      _fadeController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && !_isDisposed) {
      _scaleController.forward();
    }
    
    // 等待动画完成后开始自动滚动
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted && !_isDisposed) {
      _startAutoScroll();
    }
    
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
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
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
                            // 角色头像区域
                            _buildCharacterSection(),
                            
                            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                            
                            // 游戏结束标题
                            _buildGameOverTitle(),
                            
                            SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                            
                            // 死亡原因
                            _buildDeathReason(),
                            
                            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                            
                            // 按钮区域
                            _buildButtonSection(),
                          ],
                        ),
                      ),
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
      child: Column(
        children: [
          // 角色头像
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
}