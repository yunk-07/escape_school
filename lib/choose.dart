
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'data/manData.dart';
import 'eff.dart';
import 'eff02.dart';
import 'game/optimized_board.dart';

class ChooseCharacterPage extends StatefulWidget {
  const ChooseCharacterPage({super.key});

  @override
  State<ChooseCharacterPage> createState() => _ChooseCharacterPageState();
}

class _ChooseCharacterPageState extends State<ChooseCharacterPage> {

  @override
  Widget build(BuildContext context) {
    GlobalState.enableAllCards();
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          // 背景层
          Positioned.fill(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/background_1.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: FloatingTextBackground(
                child: Container(),
              ),
            ),
          ),

          // 渐变遮罩层
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),

          // 主要内容
          SafeArea(
            child: Column(
              children: [
                // 顶部标题区域
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isLandscape ? 20 : 30,
                  ),
                  child: Column(
                    children: [
                      // 返回按钮
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),

                // 角色卡片区域
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 根据屏幕尺寸调整布局
                      if (isLandscape && screenSize.width > 1000) {
                        // 大屏幕横屏：网格布局
                        return _buildGridLayout(constraints);
                      } else {
                        // 默认：水平滚动布局
                        return _buildHorizontalScrollLayout(constraints, isLandscape);
                      }
                    },
                  ),
                ),

                // 底部提示区域
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isLandscape ? 15 : 25,
                  ),
                  child: Column(
                    children: [
                      // 装饰线
                      Container(
                        width: 60,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // 提示文字
                      Text(
                        '点击卡片选择角色开始游戏',
                        style: TextStyle(
                          fontSize: isLandscape ? 12 : 14,
                          fontFamily: 'MicC',
                          color: Colors.white.withOpacity(0.7),
                          shadows: const [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
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
    );
  }

  Widget _buildHorizontalScrollLayout(BoxConstraints constraints, bool isLandscape) {
    return Center(
      child: SizedBox(
        height: isLandscape ? constraints.maxHeight * 0.8 : 350,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: manData.length,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 40 : 60,
          ),
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 15 : 20,
              ),
              child: TiltCard(
                character: manData[index],
                isCompact: isLandscape,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridLayout(BoxConstraints constraints) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 30,
            mainAxisSpacing: 20,
            childAspectRatio: 0.7,
          ),
          itemCount: manData.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return TiltCard(
              character: manData[index],
              isCompact: true,
            );
          },
        ),
      ),
    );
  }
}

class GlobalState {
  static bool _cardsDisabled = false;

  static bool get cardsDisabled => _cardsDisabled;

  static void disableAllCards() {
    _cardsDisabled = true;
  }

  static void enableAllCards() {
    _cardsDisabled = false;
  }
}

class TiltCard extends StatefulWidget {
  final Map<String, dynamic> character;
  final bool isCompact;

  const TiltCard({
    super.key, 
    required this.character,
    this.isCompact = false,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _animation;
  Alignment _dragAlignment = Alignment.center;
  bool _isPressed = false;
  bool _isHovering = false;
  bool _isAnimating = false;
  Offset? _tapPosition;

  final SpringDescription _spring = SpringDescription(
    mass: 10,
    stiffness: 1000,
    damping: 0.5,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() => _dragAlignment = _animation.value));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Matrix4 _getTransform(Alignment alignment) {
    final x = alignment.x;
    final y = alignment.y;
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(y * 0.1)
      ..rotateY(-x * 0.2);
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isAnimating) {
      setState(() {
        _isPressed = true;
        _tapPosition = details.localPosition;
      });
    }
  }

  void _onPanDown(DragDownDetails details) {
    if (!_isAnimating) {
      setState(() {
        _isPressed = true;
        _tapPosition = details.localPosition;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isAnimating) {
      setState(() {
        _tapPosition = details.localPosition;
        final cardSize = widget.isCompact ? Size(180, 320) : Size(200, 350);
        final x = (_tapPosition!.dx - cardSize.width / 2) / (cardSize.width / 2);
        final y = (_tapPosition!.dy - cardSize.height / 2) / (cardSize.height / 2);
        _dragAlignment = Alignment(
            x.clamp(-1.0, 1.0),
            y.clamp(-1.0, 1.0)
        );
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isAnimating) {
      setState(() => _isPressed = false);
      _animateBackToCenter();
    }
  }

  void _handleTap() {
    if (GlobalState.cardsDisabled) return;

    GlobalState.disableAllCards();

    setState(() {
      _isAnimating = true;
      _isPressed = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isPressed = false);
    });
  }

  void _onParticleComplete() {
    if (mounted) {
      setState(() => _isAnimating = false);
      _navigateToMap();
    }
  }

  void _navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OptimizedBoardPage(
          characterStats: {
            'id': widget.character['name'],
            'name': widget.character['name'], // 添加name字段用于技能初始化
            'hp': (widget.character['hp'] as num).toDouble(),
            'maxHp': (widget.character['hp'] as num).toDouble(),
            'san': (widget.character['san'] as num).toDouble(),
            'maxSan': (widget.character['san'] as num).toDouble(),
            'moveSpeed': widget.character['moveSpeed'],
            'gold': (widget.character['gold'] as num).toDouble(),
            'food': (widget.character['food'] as num).toDouble(),
            'image': widget.character['image'], // 添加image字段
          },
          characterImage: widget.character['image'],
        ),
      ),
    );
  }

  void _animateBackToCenter() {
    _animation = _controller.drive(
      AlignmentTween(begin: _dragAlignment, end: Alignment.center),
    );
    final simulation = SpringSimulation(
        _spring, _dragAlignment.x, 0, _dragAlignment.y);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final cardSize = widget.isCompact ? Size(180, 320) : Size(200, 350);

    return AbsorbPointer(
      absorbing: GlobalState.cardsDisabled && !_isAnimating,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          MouseRegion(
            onEnter: (_) => !_isAnimating ? setState(() => _isHovering = true) : null,
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTap: _handleTap,
              onPanDown: _onPanDown,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onPanCancel: () => setState(() => _isPressed = false),
              child: AnimatedScale(
                scale: _isPressed ? 0.95 : _isHovering ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Transform(
                  transform: _getTransform(_dragAlignment),
                  alignment: FractionalOffset.center,
                  child: Container(
                    width: cardSize.width,
                    height: cardSize.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isHovering ? Colors.orange : Colors.red,
                        width: _isHovering ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_isHovering ? 0.8 : 0.6),
                          blurRadius: _isHovering ? 35 : 25,
                          spreadRadius: _isHovering ? 12 : 8,
                          offset: Offset(
                            _dragAlignment.x * (_isHovering ? 18 : 12),
                            _dragAlignment.y * (_isHovering ? 18 : 12) + 5,
                          ),
                        ),
                        if (_isHovering)
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 0),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 顶部图片区域
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.asset(
                                  widget.character['image'],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 底部信息区域
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 角色名称
                                  Text(
                                    widget.character['name'],
                                    style: TextStyle(
                                      fontSize: widget.isCompact ? 20 : 22,
                                      fontFamily: 'MicC',
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: const [
                                        Shadow(
                                          blurRadius: 8,
                                          color: Colors.black,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // 角色描述 - 移除maxLines限制，允许完整显示
                                  Text(
                                    widget.character['description'],
                                    style: TextStyle(
                                      fontSize: widget.isCompact ? 11 : 13,
                                      fontFamily: 'MicC',
                                      color: Colors.white70,
                                      height: 1.3, // 增加行高提升可读性
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // 属性信息 - 使用网格布局以更好地展示进度条
                                  Container(
                                    width: double.infinity,
                                    child: Column(
                                      children: [
                                        // 第一行：金币和生命
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildStatItem('金币', widget.character['gold']),
                                            _buildStatItem('生命', widget.character['hp']),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                        // 第二行：精神和速度
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildStatItem('精神', widget.character['san']),
                                            _buildStatItem('速度', (widget.character['moveSpeed'] as num).toInt()),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                        // 第三行：饱食度（居中显示）
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildStatItem('饱食', widget.character['food']),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 添加底部间距，确保滚动时有足够空间
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isAnimating && _tapPosition != null)
            Positioned(
              left: 0,
              top: 0,
              width: cardSize.width,
              height: cardSize.height,
              child: ParticleEffect(
                position: _tapPosition!,
                onComplete: _onParticleComplete,
                containerSize: cardSize,
                particleColor: Colors.white,
                minSize: 1.0,
                maxSize: 3.0,
                blurIntensity: 1,
                particleCount: 10,
              )
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value) {
    // 获取属性的颜色和最大值配置
    final config = _getAttributeConfig(label);
    final numValue = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    final progress = (numValue / config['maxValue']).clamp(0.0, 1.0);
    
    return Container(
      width: widget.isCompact ? 60 : 70,
      child: Column(
        children: [
          // 属性标签
          Text(
            label,
            style: TextStyle(
              fontSize: widget.isCompact ? 9 : 11,
              fontFamily: 'MicC',
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // 进度条容器
          Container(
            height: widget.isCompact ? 16 : 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withOpacity(0.3),
              border: Border.all(
                color: config['color'].withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // 进度条背景
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[700]!,
                      ],
                    ),
                  ),
                ),
                
                // 进度条填充
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  width: (widget.isCompact ? 58 : 68) * progress,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: LinearGradient(
                      colors: [
                        config['color'],
                        config['color'].withOpacity(0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: config['color'].withOpacity(_isHovering ? 0.6 : 0.4),
                        blurRadius: _isHovering ? 6 : 4,
                        spreadRadius: _isHovering ? 2 : 1,
                      ),
                      if (_isHovering)
                        BoxShadow(
                          color: config['color'].withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                    ],
                  ),
                  child: _isHovering && progress > 0.1 ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                          Colors.white.withOpacity(0.1),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ) : null,
                ),
                
                // 数值文本
                Center(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: widget.isCompact ? 10 : 12,
                      fontFamily: 'MicC',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black,
                          offset: Offset(0.5, 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 获取属性配置（颜色和最大值）
  Map<String, dynamic> _getAttributeConfig(String label) {
    switch (label) {
      case '金币':
        return {
          'color': const Color(0xFFFFD700), // 金色
          'maxValue': 100.0,
        };
      case '生命':
        return {
          'color': const Color(0xFFFF4444), // 红色
          'maxValue': 100.0,
        };
      case '精神':
        return {
          'color': const Color(0xFF44AAFF), // 蓝色
          'maxValue': 100.0,
        };
      case '速度':
        return {
          'color': const Color(0xFF44FF44), // 绿色
          'maxValue': 200.0,
        };
      case '饱食':
        return {
          'color': const Color(0xFFFF8844), // 橙色
          'maxValue': 30.0,
        };
      default:
        return {
          'color': Colors.grey,
          'maxValue': 100.0,
        };
    }
  }
}