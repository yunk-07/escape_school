
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
                          Colors.black.withOpacity(0.85),
                          Colors.grey[900]!.withOpacity(0.8),
                          Colors.black.withOpacity(0.9),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isHovering ? const Color(0xFFFF6B35) : const Color(0xFFFF4444),
                        width: _isHovering ? 3 : 2,
                      ),
                      boxShadow: [
                        // 主阴影
                        BoxShadow(
                          color: Colors.black.withOpacity(_isHovering ? 0.9 : 0.7),
                          blurRadius: _isHovering ? 40 : 30,
                          spreadRadius: _isHovering ? 15 : 10,
                          offset: Offset(
                            _dragAlignment.x * (_isHovering ? 20 : 15),
                            _dragAlignment.y * (_isHovering ? 20 : 15) + 8,
                          ),
                        ),
                        // 内发光效果
                        if (_isHovering)
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 8,
                            offset: const Offset(0, 0),
                          ),
                        // 边缘高光
                        BoxShadow(
                          color: Colors.white.withOpacity(_isHovering ? 0.1 : 0.05),
                          blurRadius: 2,
                          spreadRadius: 0,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 顶部图片区域 - 减少占比，为数据区域让出更多空间
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.grey[800]!.withOpacity(0.9),
                                    Colors.grey[900]!.withOpacity(0.95),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: Stack(
                                    children: [
                                      // 背景渐变
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            center: Alignment.center,
                                            radius: 0.8,
                                            colors: [
                                              Colors.grey[700]!.withOpacity(0.3),
                                              Colors.grey[900]!.withOpacity(0.8),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // 角色图片
                                      Center(
                                        child: Image.asset(
                                          widget.character['image'],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      // 顶部高光效果
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        height: 30,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(14),
                                              topRight: Radius.circular(14),
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.white.withOpacity(0.15),
                                                Colors.transparent,
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

                        // 底部信息区域 - 增大占比，为属性显示提供更多空间
                        Expanded(
                          flex: 7,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 角色名称 - 增大字体，更突出
                                Text(
                                  widget.character['name'],
                                  style: TextStyle(
                                    fontSize: widget.isCompact ? 18 : 20,
                                    fontFamily: 'MicC',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 6,
                                        color: Colors.black,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 6),

                                // 角色描述 - 减少占比，为属性显示让出空间
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    widget.character['description'],
                                    style: TextStyle(
                                      fontSize: widget.isCompact ? 8 : 9,
                                      fontFamily: 'MicC',
                                      color: Colors.white70,
                                      height: 1.1,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // 属性信息 - 增大占比，让数据更突出
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      // 第一行：生命和精神
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(child: _buildCompactStatItem('生命', widget.character['hp'], const Color(0xFFFF4444))),
                                            const SizedBox(width: 4),
                                            Expanded(child: _buildCompactStatItem('精神', widget.character['san'], const Color(0xFF44AAFF))),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 4),
                                      
                                      // 第二行：金币和速度
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(child: _buildCompactStatItem('金币', widget.character['gold'], const Color(0xFFFFD700))),
                                            const SizedBox(width: 4),
                                            Expanded(child: _buildCompactStatItem('速度', (widget.character['moveSpeed'] as num).toInt(), const Color(0xFF44FF44))),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 4),
                                      
                                      // 第三行：饱食度（居中显示）
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(child: Container()),
                                            Expanded(
                                              flex: 2,
                                              child: _buildCompactStatItem('饱食', widget.character['food'], const Color(0xFFFF8844)),
                                            ),
                                            Expanded(child: Container()),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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

  // 紧凑的属性显示组件 - 增大高度，让数据更突出
  Widget _buildCompactStatItem(String label, dynamic value, Color color) {
    final numValue = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    final maxValue = _getMaxValueForAttribute(label);
    // 对于精神值，允许超过100%显示，其他属性保持原有限制
    final progress = label == '精神' 
        ? (numValue / maxValue).clamp(0.0, double.infinity) 
        : (numValue / maxValue).clamp(0.0, 1.0);
    
    return Container(
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.grey[900]!.withOpacity(0.8),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 进度条背景
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.5),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[800]!.withOpacity(0.9),
                  Colors.grey[900]!.withOpacity(0.95),
                ],
              ),
            ),
          ),
          
          // 进度条填充
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            child: FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.9),
                      color,
                      color.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.5),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 标签和数值 - 增大字体，提高可读性
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 属性标签
                Text(
                  label,
                  style: TextStyle(
                    fontSize: widget.isCompact ? 12 : 14,
                    fontFamily: 'MicC',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                
                // 数值
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: widget.isCompact ? 13 : 15,
                    fontFamily: 'MicC',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        blurRadius: 4,
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
    );
  }

  // 获取属性的最大值
  double _getMaxValueForAttribute(String label) {
    switch (label) {
      case '金币':
        return 100.0;
      case '生命':
        return 100.0;
      case '精神':
        return 100.0;
      case '速度':
        return 200.0;
      case '饱食':
        return 30.0;
      default:
        return 100.0;
    }
  }
}